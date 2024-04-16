import WidgetKit
import SwiftUI
import Foundation

// Provider conforming to TimelineProvider protocol
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
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)! // Refresh in thirty minutes

        let entryData = loadWidgetData()
        let entry = SimpleEntry(date: currentDate, widgetData: entryData)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
    
    // StockInfo type defined within the Provider struct
    struct StockInfo {
        let margin: Double?
        let originalPrice: Double?
        let originalValue: Double?
        let price: Double?
        let symbol: String?
        let time: String?
        let value: Double?
    }

    func loadWidgetData() -> [StockInfo] {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "StockViewer")?.appendingPathComponent("output.plist") else {
            print("Failed to get shared container URL")
            return []
        }

        // Cache-busting by using a dummy query parameter
        let uniqueURL = URL(string: "\(containerURL.absoluteString)?t=\(NSDate().timeIntervalSince1970)")!

        do {
            let data = try Data(contentsOf: uniqueURL)
            if let result = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: [String: Any]] {
                return result.map { (symbol, info) -> StockInfo in
                    return StockInfo(
                        margin: info["Margin"] as? Double,
                        originalPrice: info["Original Price"] as? Double,
                        originalValue: info["Original Value"] as? Double,
                        price: info["Price"] as? Double,
                        symbol: symbol,
                        time: info["Time"] as? String,
                        value: info["Value"] as? Double
                    )
                }
            } else {
                return []
            }
        } catch {
            print("Error during data loading or decoding:", error)
            return []
        }
    }

}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let widgetData: [Provider.StockInfo]
}
struct WidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header row showing total values
            HStack {
                Text("Balance: \(String(format: "$%.2f", totalCurrentValue(entry.widgetData)))")
                    .font(.system(size: 18, weight: .bold))  // Set font size and weight for header
                
                Spacer() // Add spacer to push the next text to the right
                
                Text("Difference: \(String(format: "$%.2f", totalCurrentValue(entry.widgetData) - totalOriginalValue(entry.widgetData)))")
                    .font(.system(size: 18, weight: .bold))  // Set font size and weight for header
            }
            .padding(.all, 10)
            .foregroundColor(Color.blue)
            // Individual stock entries
            ForEach(entry.widgetData, id: \.symbol) { stock in
                HStack {
                    Text(stock.symbol ?? "N/A")
                        .frame(width: 70, alignment: .leading)
                    Text("\(stock.value.map { String(format: "$%.2f", $0) } ?? "N/A")")
                        .frame(width: 60, alignment: .leading)
                    Text("\(stock.margin.map { String(format: "%.2f%%", $0) } ?? "N/A")")
                        .frame(width: 60, alignment: .leading)
                    Text(stock.time ?? "N/A")
                        .frame(width: 100, alignment: .leading)
                }
                .padding(.all, 5)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(5)
                .foregroundColor(stock.margin ?? 0 >= 0 ? Color.green : Color.red)
            }
        }
        .widgetURL(URL(string: "your-url-scheme://action")) // Optional: Add a deep link URL
        .containerBackground(for: .widget) {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
        }
    }



    // Helper methods to compute totals
    func totalOriginalValue(_ widgetData: [Provider.StockInfo]) -> Double {
        widgetData.compactMap { $0.originalValue }.reduce(0, +)
    }

    func totalCurrentValue(_ widgetData: [Provider.StockInfo]) -> Double {
        widgetData.compactMap { $0.value }.reduce(0, +)
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

