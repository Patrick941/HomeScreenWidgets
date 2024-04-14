import WidgetKit
import SwiftUI
import Foundation

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), widgetData: loadWidgetData())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), widgetData: loadWidgetData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()
        let entryData = loadWidgetData()
        
        // Generate a timeline consisting of only one entry
        let entry = SimpleEntry(date: currentDate, widgetData: entryData)
        entries.append(entry)
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
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

    func loadWidgetData() -> String {
        guard let url = Bundle.main.url(forResource: "output", withExtension: "plist") else {
            print("File does not exist in bundle")
            return "Default data - File does not exist in bundle"
        }

        do {
            let data = try Data(contentsOf: url)
            print("Data loaded")

            // Decode the data into a dictionary of [String: StockInfo]
            let result = try PropertyListDecoder().decode([String: StockInfo].self, from: data)
            print("Data decoded")

            // Combine all stock info into a single string
            return result.map { (symbol, info) in
                formatStockInfo(symbol: symbol, info: info)
            }.joined(separator: "\n\n")
        } catch {
            print("Error during data loading or decoding: \(error)")
            return "Default data - \(error.localizedDescription)"
        }
    }

    func formatStockInfo(symbol: String, info: StockInfo) -> String {
        var formattedString = "Symbol: \(symbol)\n"
        
        if let margin = info.margin {
            formattedString += "Margin: \(margin)\n"
        } else {
            formattedString += "Margin: N/A\n"
        }
        
        if let originalPrice = info.originalPrice {
            formattedString += "Original Price: \(originalPrice)\n"
        } else {
            formattedString += "Original Price: N/A\n"
        }
        
        if let price = info.price {
            formattedString += "Price: \(price)\n"
        } else {
            formattedString += "Price: N/A\n"
        }
        
        if let time = info.time {
            formattedString += "Time: \(time)\n"
        } else {
            formattedString += "Time: N/A\n"
        }
        
        if let value = info.value {
            formattedString += "Value: \(value)\n"
        } else {
            formattedString += "Value: N/A\n"
        }
        
        return formattedString
    }




}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let widgetData: String
}

struct WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.widgetData)
            .padding()
            .containerBackground(for: .widget) {
                            Color.gray.opacity(0.5) // Example of setting a semi-transparent grey background
                        }
            .widgetURL(URL(string: "your-url-scheme://action"))  // Optional: Add a deep link URL
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
        .description("This is an example widget showing data from plist.")
    }
}
