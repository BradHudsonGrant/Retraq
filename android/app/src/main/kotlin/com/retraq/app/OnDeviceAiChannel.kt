package com.retraq.app

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.generateContentRequest
import com.google.mlkit.genai.prompt.TextPart
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * MethodChannel bridge for Retraq's opt-in on-device AI recap feature.
 *
 * All inference runs in AICore, Google's sandboxed system service.
 * Prompts and responses never touch the network — we hand the text to
 * the OS and it returns a summary.
 *
 * Channel contracts (mirrored in Dart at `PlatformRecapAiProvider`):
 *
 *   MethodChannel "com.retraq.app/ondevice_ai":
 *     - "checkStatus"  -> "available" | "downloadable" | "downloading" | "unavailable"
 *     - "startDownload" -> null (idempotent; no-op if already AVAILABLE or DOWNLOADING)
 *     - "summarize" { prompt: String, maxOutputTokens: Int } -> String
 *
 *   EventChannel "com.retraq.app/ondevice_ai/events":
 *     - { status: "downloading", bytesDownloaded: N } — progress ticks
 *     - { status: "available" }                      — model ready
 *     - { status: "unavailable", errorMessage: "..." } — download failed
 *
 * Any uncaught failure on MethodChannel surfaces as PlatformException so
 * the Dart side can fall back to the deterministic template recap.
 */
class OnDeviceAiChannel(flutterEngine: FlutterEngine) {

    companion object {
        private const val TAG = "OnDeviceAiChannel"
        private const val METHOD_CHANNEL = "com.retraq.app/ondevice_ai"
        private const val EVENT_CHANNEL = "com.retraq.app/ondevice_ai/events"
    }

    // Supervisor scope so a failing coroutine doesn't cancel sibling calls.
    // Kept on the IO dispatcher because ML Kit inference is blocking work.
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // Lazily created so we only touch the GenAI SDK when the user actually
    // opts in. Created once and reused — creating a new client per call
    // adds meaningful latency to the second-and-subsequent summarization.
    private var generator: GenerativeModel? = null

    // Single in-flight download Job. Multiple `startDownload` calls (e.g.
    // from the settings card + recap screen both subscribing) collapse
    // into one actual ML Kit download.
    private var downloadJob: Job? = null

    // EventChannel sink + main-thread handler for posting events. ML Kit's
    // Flow<DownloadStatus> runs on a background thread but Flutter requires
    // EventChannel emissions on the main thread.
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun generator(): GenerativeModel {
        return generator ?: Generation.getClient().also { generator = it }
    }

    init {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkStatus" -> handleCheckStatus(result)
                "startDownload" -> handleStartDownload(result)
                "summarize" -> {
                    val prompt = call.argument<String>("prompt")
                    val maxTokens = call.argument<Int>("maxOutputTokens") ?: 256
                    if (prompt.isNullOrBlank()) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "prompt is required and must be non-empty",
                            null
                        )
                    } else {
                        handleSummarize(prompt, maxTokens, result)
                    }
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                // Send the current status immediately so the widget has
                // something to render on subscribe rather than waiting
                // for the next transition.
                scope.launch {
                    val label = currentStatusLabelSafe()
                    sendEvent(mapOf("status" to label))
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun sendEvent(map: Map<String, Any?>) {
        mainHandler.post {
            try {
                eventSink?.success(map)
            } catch (t: Throwable) {
                Log.w(TAG, "sendEvent failed", t)
            }
        }
    }

    private suspend fun currentStatusLabelSafe(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return "unavailable"
        return try {
            when (generator().checkStatus()) {
                FeatureStatus.AVAILABLE -> "available"
                FeatureStatus.DOWNLOADABLE -> "downloadable"
                FeatureStatus.DOWNLOADING -> "downloading"
                FeatureStatus.UNAVAILABLE -> "unavailable"
                else -> "unavailable"
            }
        } catch (t: Throwable) {
            Log.w(TAG, "currentStatusLabelSafe failed", t)
            "unavailable"
        }
    }

    private fun handleCheckStatus(result: MethodChannel.Result) {
        // ML Kit GenAI Prompt requires Android O (API 26). Users on 24/25
        // still see the app (with template recaps); they just can't flip
        // this toggle on. Short-circuit before touching the SDK so old OS
        // versions never load a class that wasn't built for them.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success("unavailable")
            return
        }
        scope.launch {
            val label = currentStatusLabelSafe()
            withContext(Dispatchers.Main) { result.success(label) }
        }
    }

    private fun handleStartDownload(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(null)
            return
        }
        // Already running — collapse repeated taps into the same job.
        if (downloadJob?.isActive == true) {
            result.success(null)
            return
        }
        downloadJob = scope.launch {
            try {
                val model = generator()
                val status = model.checkStatus()
                if (status == FeatureStatus.AVAILABLE) {
                    sendEvent(mapOf("status" to "available"))
                    return@launch
                }
                if (status == FeatureStatus.UNAVAILABLE) {
                    sendEvent(
                        mapOf(
                            "status" to "unavailable",
                            "errorMessage" to "On-device AI not supported on this device"
                        )
                    )
                    return@launch
                }

                sendEvent(mapOf("status" to "downloading", "bytesDownloaded" to 0))
                Log.i(TAG, "Starting Gemini Nano download")

                model.download().collect { ds ->
                    when (ds) {
                        is DownloadStatus.DownloadStarted -> {
                            Log.i(TAG, "Gemini Nano download started")
                            sendEvent(
                                mapOf(
                                    "status" to "downloading",
                                    "bytesDownloaded" to 0
                                )
                            )
                        }
                        is DownloadStatus.DownloadProgress -> {
                            sendEvent(
                                mapOf(
                                    "status" to "downloading",
                                    "bytesDownloaded" to ds.totalBytesDownloaded
                                )
                            )
                        }
                        is DownloadStatus.DownloadCompleted -> {
                            Log.i(TAG, "Gemini Nano download complete")
                            sendEvent(mapOf("status" to "available"))
                        }
                        is DownloadStatus.DownloadFailed -> {
                            Log.w(TAG, "Gemini Nano download failed: ${ds.e.message}")
                            sendEvent(
                                mapOf(
                                    "status" to "unavailable",
                                    "errorMessage" to (ds.e.message ?: "download failed")
                                )
                            )
                        }
                    }
                }
            } catch (t: Throwable) {
                Log.w(TAG, "startDownload failed", t)
                sendEvent(
                    mapOf(
                        "status" to "unavailable",
                        "errorMessage" to (t.message ?: "download failed")
                    )
                )
            }
        }
        result.success(null)
    }

    private fun handleSummarize(
        prompt: String,
        maxOutputTokens: Int,
        result: MethodChannel.Result
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("NOT_AVAILABLE", "On-device AI requires Android 8.0+", null)
            return
        }
        scope.launch {
            try {
                val model = generator()
                val status = model.checkStatus()
                if (status != FeatureStatus.AVAILABLE) {
                    // Don't silently kick off a download here — the settings
                    // card drives downloads explicitly so the user sees
                    // progress. Just report NOT_AVAILABLE and let the Dart
                    // side fall back to the template recap.
                    withContext(Dispatchers.Main) {
                        result.error(
                            "NOT_AVAILABLE",
                            "On-device AI is not ready yet (status=$status)",
                            null
                        )
                    }
                    return@launch
                }

                Log.i(TAG, "Running Gemini Nano summarize (prompt length=${prompt.length})")
                val response = model.generateContent(
                    generateContentRequest(TextPart(prompt)) {
                        temperature = 0.6f
                    }
                )

                val text = response.candidates.firstOrNull()?.text?.trim().orEmpty()
                if (text.isEmpty()) {
                    Log.w(TAG, "Gemini Nano returned no candidates")
                    withContext(Dispatchers.Main) {
                        result.error(
                            "EMPTY_RESPONSE",
                            "On-device AI returned no candidates",
                            null
                        )
                    }
                } else {
                    Log.i(TAG, "Gemini Nano returned ${text.length} chars")
                    withContext(Dispatchers.Main) { result.success(text) }
                }
            } catch (t: Throwable) {
                Log.w(TAG, "summarize failed", t)
                withContext(Dispatchers.Main) {
                    result.error(
                        "INFERENCE_FAILED",
                        t.message ?: "On-device AI call failed",
                        null
                    )
                }
            }
        }
    }

    fun dispose() {
        try {
            downloadJob?.cancel()
        } catch (_: Throwable) {
        }
        try {
            generator?.close()
        } catch (_: Throwable) {
        }
        scope.cancel()
    }
}
