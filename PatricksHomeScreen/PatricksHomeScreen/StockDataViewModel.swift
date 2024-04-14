import Foundation
import Combine

class StockDataViewModel: ObservableObject {
    @Published var stockData: [String: [String: Any]] = [:]

    init() {
        loadData()
        Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { _ in
            self.loadData()
        }
    }

    func loadData() {
        // First, call the Python script
        let scriptPath = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/GetStonks.py"
        let infoPath = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/StockInfo.csv"
        runPythonScript(at: scriptPath, withArgument: infoPath)

        // After running the script, load the plist
        let plistPath = "/Users/patrick/Desktop/PatricksHomeScreen/PythonScripts/output.plist"
        stockData = loadPlist(from: plistPath)
    }
}

func runPythonScript(at path: String, withArgument argument: String) {
    let process = Process()
    let pipe = Pipe()
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
        if let stockDictionary = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: [String: Any]] {
            return stockDictionary
        } else {
            print("Data found, but could not be cast to expected type [String: [String: Any]].")
            return [:]
        }
    } catch {
        print("Failed to read plist file:", error)
        return [:]
    }
}
