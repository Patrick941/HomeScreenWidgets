import SwiftUI
import Foundation

@main
struct StockViewerApp: App {
    let stockData: [String: [String: Any]] = {
        // Run the Python script
        let scriptPath = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/GetStonks.py"
        let infoPath = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/StockInfo.csv"
        runPythonScript(at: scriptPath, withArgument: infoPath)

        // Load the plist
        let plistPath = "/Users/patrick/Desktop/PatricksHomeScreen/StockWidget/output.plist"
        return loadPlist(from: plistPath)
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(stockData: stockData)
        }
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
