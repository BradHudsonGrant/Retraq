#version 460 core
#include <flutter/runtime_effect.glsl>

// Animated mesh-gradient background.
// Sums three Gaussian color "blobs" that drift across the screen with time,
// producing a soft mesh-gradient effect in one shader pass.

uniform vec2  uSize;     // canvas size in logical pixels
uniform float uTime;     // seconds since the controller started
uniform vec4  uColor1;   // RGBA, premultiplied alpha not assumed
uniform vec4  uColor2;
uniform vec4  uColor3;
uniform vec4  uBase;     // background tint (e.g. surface color)

out vec4 fragColor;

// Smooth Gaussian falloff centered at `center` with radius `r`.
float blob(vec2 uv, vec2 center, float r) {
  float d = distance(uv, center);
  return exp(-(d * d) / (2.0 * r * r));
}

void main() {
  vec2 fragCoord = FlutterFragCoord();
  // Normalised, aspect-corrected uv (so radii read consistently).
  vec2 uv = fragCoord / uSize;
  uv.x *= uSize.x / uSize.y;
  float ar = uSize.x / uSize.y;

  // Slow drifting blob centers using offset sine/cosine waves.
  vec2 c1 = vec2(0.30 * ar + 0.18 * sin(uTime * 0.35),
                 0.35 + 0.15 * cos(uTime * 0.27));
  vec2 c2 = vec2(0.70 * ar + 0.20 * sin(uTime * 0.21 + 1.7),
                 0.65 + 0.18 * cos(uTime * 0.31 + 0.9));
  vec2 c3 = vec2(0.50 * ar + 0.25 * sin(uTime * 0.18 + 3.1),
                 0.50 + 0.22 * cos(uTime * 0.24 + 2.2));

  float w1 = blob(uv, c1, 0.45);
  float w2 = blob(uv, c2, 0.50);
  float w3 = blob(uv, c3, 0.55);
  float wSum = w1 + w2 + w3 + 0.0001;

  vec3 mixed =
      (uColor1.rgb * w1 + uColor2.rgb * w2 + uColor3.rgb * w3) / wSum;

  // Blend the mesh into the base tint by the strongest blob's intensity.
  float intensity = clamp(max(max(w1, w2), w3) * 1.4, 0.0, 1.0);
  vec3 outRgb = mix(uBase.rgb, mixed, intensity);

  fragColor = vec4(outRgb, 1.0);
}
