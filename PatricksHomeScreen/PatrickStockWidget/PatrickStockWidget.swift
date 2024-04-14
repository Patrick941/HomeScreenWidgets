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

            // Attempt to decode the data into a generic dictionary
            if let result = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: [String: Any]] {
                print("Data decoded")

                // Combine all stock info into a single string
                return result.map { (symbol, info) in
                    formatStockInfo(symbol: symbol, info: info)
                }.joined(separator: "\n\n")
            } else {
                return "Data format is incorrect"
            }
        } catch {
            print("Error during data loading or decoding: \(error)")
            return "Default data - \(error.localizedDescription)"
        }
    }

    func formatStockInfo(symbol: String, info: [String: Any]) -> String {
        var formattedString = "\(symbol): "

        if let value = info["Value"] as? Double {
            formattedString += "Val: \(String(format: "%.2f", value)), "
        } else {
            formattedString += "Val: N/A, "
        }

        if let margin = info["Margin"] as? Double {
            formattedString += "Margin: \(String(format: "%.2f%", margin)), "
        } else {
            formattedString += "Margin: N/A, "
        }

        if let time = info["Time"] as? String {
            formattedString += "Time: \(time)"
        } else {
            formattedString += "Time: N/A"
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
    
    let textColour = Color.green

    var body: some View {
        Text(entry.widgetData)
            .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            .font(.custom("Helvetica Neue", size: 12))
            .foregroundColor(textColour) // Ensuring the text color is white for better contrast
            .lineLimit(nil)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.gray.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .containerBackground(for: .widget) {
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.gray.opacity(0.5)]), startPoint: .topLeading, endPoint: .bottomTrailing)
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
    }
}
