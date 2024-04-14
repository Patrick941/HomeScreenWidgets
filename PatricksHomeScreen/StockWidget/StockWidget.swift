import WidgetKit
import SwiftUI
import Intents

struct StockDetail: Codable {
    var price: String
    var volume: String
}

typealias StockData = [String: StockDetail]

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), stockData: [:])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), stockData: loadStockData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, stockData: loadStockData())
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func loadStockData() -> StockData {
        // This would be the way to load bundled data.
        guard let url = Bundle.main.url(forResource: "output", withExtension: "plist") else {
            print("Plist file not found in bundle.")
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            let stockData = try PropertyListDecoder().decode(StockData.self, from: data)
            return stockData
        } catch {
            print("Error reading plist: \(error)")
            return [:]
        }
    }

}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let stockData: StockData
}

struct StockWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(entry.stockData.keys.sorted(), id: \.self) { key in
                if let detail = entry.stockData[key] {
                    VStack(alignment: .leading) {
                        Text("\(key): \(detail.price)")
                        Text("Volume: \(detail.volume)")
                    }
                }
            }
        }
        .padding()
    }
}

@main
struct StockWidget: Widget {
    let kind: String = "StockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StockWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Stock Tracker")
        .description("Displays the latest stock prices.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
