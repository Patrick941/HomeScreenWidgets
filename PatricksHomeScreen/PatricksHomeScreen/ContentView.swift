import SwiftUI

struct ContentView: View {
    var stockData: [String: [String: Any]]

    var body: some View {
        NavigationView {
            List(stockData.keys.sorted(), id: \.self) { key in
                if let details = stockData[key] {
                    NavigationLink(destination: StockDetailView(stockDetails: details)) {
                        Text(key) // Stock symbol
                    }
                }
            }
            .navigationTitle("Stocks")
        }
    }
}

struct StockDetailView: View {
    var stockDetails: [String: Any]
    
    var body: some View {
        List {
            ForEach(stockDetails.keys.sorted(), id: \.self) { key in
                if let value = stockDetails[key] {
                    HStack {
                        Text(key) // Detail Key
                        Spacer()
                        Text("\(value)") // Convert all values to string
                    }
                }
            }
        }
        .navigationTitle("Details")
    }
}
