import SwiftUI
import Foundation

@main
struct StockViewerApp: App {
    @StateObject private var viewModel = StockViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(stockData: viewModel.stockData)
                .onAppear {
                    viewModel.loadData()
                }
                .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
                    viewModel.loadData()
                }
        }
    }
}

class StockViewModel: ObservableObject {
    @Published var stockData: [String: [String: Any]] = [:]

    init() {
        loadData()
    }

    func loadData() {
        let scriptPath = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/GetStonks.py"
        let infoPath = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/output.plist"
        runPythonScript(at: scriptPath, withArgument: infoPath)

        let plistPath = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/output.plist"
        stockData = loadPlist(from: plistPath)
        savePlistToSharedContainer(stockData: stockData)
    }
}

func savePlistToSharedContainer(stockData: [String: [String: Any]]) {
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "StockViewer") else {
        print("Failed to get shared container URL")
        return
    }
    let plistURL = containerURL.appendingPathComponent("output.plist")

    do {
        let data = try PropertyListSerialization.data(fromPropertyList: stockData, format: .xml, options: 0)
        try data.write(to: plistURL, options: .atomic)
        print("Successfully wrote plist to shared container at \(plistURL)")
    } catch {
        print("Failed to write plist to shared container:", error)
    }
}


func runPythonScript(at path: String, withArgument argument: String) {
    let process = Process()
    let pipe = Pipe()

    // Path to Python executable from your virtual environment
    let pythonInterpreter = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/stonksEnv/bin/python3"

    process.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
    process.executableURL = URL(fileURLWithPath: pythonInterpreter)
    process.arguments = [path, argument]
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? "No output"
        print("Python script output: \(output)")
    } catch {
        print("Failed to run Python script: \(error)")
    }
}

func loadPlist(from path: String) -> [String: [String: Any]] {
    let fileManager = FileManager.default
    let plistURL = URL(fileURLWithPath: path)

    guard fileManager.fileExists(atPath: plistURL.path) else {
        print("Plist file not found at the specified path.")
        return [:]
    }

    do {
        let data = try Data(contentsOf: plistURL)
        let stockDictionary = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: [String: Any]] ?? [:]
        return stockDictionary
    } catch {
        print("Failed to read plist file:", error)
        return [:]
    }
}
