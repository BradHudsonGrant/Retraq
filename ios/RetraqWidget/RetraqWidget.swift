import WidgetKit
import SwiftUI

/// Shared data keys (must match Flutter WidgetService keys).
private let appGroupId = "group.com.retraq.app"

struct JournalEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let totalEntries: Int
    let mood: Int // -1 = none, 1-5 = mood value
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> JournalEntry {
        JournalEntry(date: Date(), streak: 3, totalEntries: 12, mood: -1)
    }

    func getSnapshot(in context: Context, completion: @escaping (JournalEntry) -> Void) {
        let entry = readData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JournalEntry>) -> Void) {
        let entry = readData()
        // Refresh every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readData() -> JournalEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let streak = defaults?.integer(forKey: "streak") ?? 0
        let totalEntries = defaults?.integer(forKey: "totalEntries") ?? 0
        let mood = defaults?.integer(forKey: "mood") ?? -1
        return JournalEntry(
            date: Date(),
            streak: streak,
            totalEntries: totalEntries,
            mood: mood
        )
    }
}

struct RetraqWidgetEntryView: View {
    var entry: Provider.Entry

    private let moodEmojis = ["😢", "😔", "😐", "😊", "🤩"]
    private let moodLabels = ["Rough", "Low", "Neutral", "Good", "Amazing"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Retraq")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.11, green: 0.37, blue: 0.13))

            Divider()

            HStack(spacing: 6) {
                Text("🔥")
                    .font(.title3)
                Text("\(entry.streak) day streak")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            Text("\(entry.totalEntries) \(entry.totalEntries == 1 ? "traq" : "traqs")")
                .font(.caption)
                .foregroundColor(.secondary)

            if entry.mood >= 1 && entry.mood <= 5 {
                Text("Today: \(moodEmojis[entry.mood - 1]) \(moodLabels[entry.mood - 1])")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Drop a traq ✍️")
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding()
    }
}

@main
struct RetraqWidget: Widget {
    let kind: String = "RetraqWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RetraqWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Journal Stats")
        .description("Shows your journal streak and recent mood.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
