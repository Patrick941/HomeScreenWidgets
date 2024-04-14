import WidgetKit
import SwiftUI
import Foundation

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), widgetData: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), widgetData: loadWidgetData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        let entryData = loadWidgetData()
        
        // Generate a timeline consisting of only one entry
        let entry = SimpleEntry(date: currentDate, widgetData: entryData)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    struct StockInfo: Decodable {
        let margin: Double?
        let originalPrice: Double?
        let originalValue: Double?
        let price: Double?
        let symbol: String?
        let time: String?
        let value: Double?
    }

    func loadWidgetData() -> [StockInfo] {
        guard let url = Bundle.main.url(forResource: "output", withExtension: "plist") else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            if let result = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: [String: Any]] {
                return result.map { (symbol, info) -> StockInfo in
                    return parseStockInfo(symbol: symbol, info: info)
                }
            } else {
                return []
            }
        } catch {
            print("Error during data loading or decoding: \(error)")
            return []
        }
    }

    func parseStockInfo(symbol: String, info: [String: Any]) -> StockInfo {
        return StockInfo(
            margin: info["Margin"] as? Double,
            originalPrice: info["OriginalPrice"] as? Double,
            originalValue: info["OriginalValue"] as? Double,
            price: info["Price"] as? Double,
            symbol: symbol,
            time: info["Time"] as? String,
            value: info["Value"] as? Double
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let widgetData: [Provider.StockInfo]
}

struct WidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            ForEach(entry.widgetData, id: \.symbol) { stock in
                Text("\(stock.symbol ?? "N/A"): Val: \(stock.value.map { String(format: "%.2f", $0) } ?? "N/A"), Margin: \(stock.margin.map { String(format: "%.2f%", $0) } ?? "N/A"), Time: \(stock.time ?? "N/A")")
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.gray.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(5)
                    .foregroundColor(stock.margin ?? 0 >= 0 ? Color.green : Color.red)
            }
        }
        .widgetURL(URL(string: "your-url-scheme://action")) // Optional: Add a deep link URL
    }
}

@main
struct StockWidget: Widget {
    let kind: String = "SimpleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Your Widget Name")
        .description("This is an example widget for showing stock data.")
    }
}

