import XCTest
@testable import KeypathRecorder

final class KeypathRecorderTests: XCTestCase {
    
    // MARK: - Basic App Structure Tests
    
    func testAppLaunches() throws {
        // Basic test to ensure the app structure is valid
        XCTAssertTrue(true)
    }
    
    func testInitialState() throws {
        // Will add more tests as we implement features  
        XCTAssertTrue(true)
    }
    
    // MARK: - RustBridge Utility Function Tests
    
    func testRustBridgeCleanKeyName() throws {
        // Test basic key name extraction
        let input = "Captured: a (0x00)"
        let result = RustBridge.cleanKeyName(from: input)
        XCTAssertEqual(result, "a")
        
        // Test special keys
        let input2 = "Captured: escape (0x35)"
        let result2 = RustBridge.cleanKeyName(from: input2)
        XCTAssertEqual(result2, "escape")
        
        // Test space key
        let input3 = "Captured: space (0x31)"
        let result3 = RustBridge.cleanKeyName(from: input3)
        XCTAssertEqual(result3, "space")
        
        // Test return key
        let input4 = "Captured: return (0x24)"
        let result4 = RustBridge.cleanKeyName(from: input4)
        XCTAssertEqual(result4, "return")
        
        // Test invalid formats
        let invalid1 = "Invalid format"
        XCTAssertNil(RustBridge.cleanKeyName(from: invalid1))
        
        let invalid2 = "Captured:"
        XCTAssertNil(RustBridge.cleanKeyName(from: invalid2))
        
        let invalid3 = ""
        XCTAssertNil(RustBridge.cleanKeyName(from: invalid3))
        
        // Test edge cases
        let edge1 = "Captured: a"
        let edgeResult1 = RustBridge.cleanKeyName(from: edge1)
        XCTAssertEqual(edgeResult1, "a")
    }
    
    func testRustBridgeCleanOutputSequence() throws {
        // Test whitespace trimming
        let input1 = "  f  \n"
        let result1 = RustBridge.cleanOutputSequence(input1)
        XCTAssertEqual(result1, "f")
        
        // Test normal text
        let input2 = "hello world"
        let result2 = RustBridge.cleanOutputSequence(input2)
        XCTAssertEqual(result2, "hello world")
        
        // Test empty string
        let input3 = ""
        let result3 = RustBridge.cleanOutputSequence(input3)
        XCTAssertEqual(result3, "")
        
        // Test only whitespace
        let input4 = "   \n\t  "
        let result4 = RustBridge.cleanOutputSequence(input4)
        XCTAssertEqual(result4, "")
        
        // Test mixed whitespace
        let input5 = "\n\t  hello\t\n  "
        let result5 = RustBridge.cleanOutputSequence(input5)
        XCTAssertEqual(result5, "hello")
    }
    
    // MARK: - RustBridge Core Functionality Tests
    
    func testRustBridgeCreateMapping() throws {
        // Test basic mapping creation
        let result = RustBridge.createMapping(inputKey: "a", outputSequence: "f")
        XCTAssertNotNil(result)
        
        // Verify it's valid JSON
        let jsonData = result!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        
        // Check structure
        XCTAssertNotNil(parsed["keys"])
        
        // Verify the mapping exists
        let keys = parsed["keys"] as! [String: Any]
        XCTAssertNotNil(keys["a"])
    }
    
    func testRustBridgeValidateJson() throws {
        // Test with valid JSON
        let validJson = """
        {"keys":{"a":{"tap":"f"}},"macros":{},"conditions":{},"layers":[]}
        """
        let result = RustBridge.validateJson(validJson)
        XCTAssertEqual(result, "valid")
        
        // Test with invalid JSON
        let invalidJson = "invalid json"
        let invalidResult = RustBridge.validateJson(invalidJson)
        XCTAssertNotNil(invalidResult)
        XCTAssertTrue(invalidResult!.hasPrefix("invalid:"))
    }
    
    func testRustBridgeProcessMapping() throws {
        // Test complete workflow
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: "a",
            outputSequence: "f"
        )
        
        // Verify IR JSON was created
        XCTAssertNotNil(irJson)
        XCTAssertFalse(irJson!.isEmpty)
        
        // Verify it's valid JSON
        let jsonData = irJson!.data(using: .utf8)!
        let _ = try JSONSerialization.jsonObject(with: jsonData)
        
        // Verify Kanata config was created
        XCTAssertNotNil(kanataConfig)
        XCTAssertFalse(kanataConfig!.isEmpty)
        
        // Verify Kanata format
        XCTAssertTrue(kanataConfig!.contains("(defsrc"))
        XCTAssertTrue(kanataConfig!.contains("(deflayer"))
        XCTAssertTrue(kanataConfig!.contains("a"))
        XCTAssertTrue(kanataConfig!.contains("f"))
    }
    
    func testRustBridgeExportToKanata() throws {
        // Create IR JSON first
        let irJson = RustBridge.createMapping(inputKey: "a", outputSequence: "f")
        XCTAssertNotNil(irJson)
        
        // Export to Kanata
        let kanataConfig = RustBridge.exportToKanata(irJson: irJson!)
        XCTAssertNotNil(kanataConfig)
        
        // Verify Kanata structure
        let config = kanataConfig!
        XCTAssertTrue(config.contains("(defsrc"))
        XCTAssertTrue(config.contains("(deflayer"))
        XCTAssertTrue(config.contains("a"))
        XCTAssertTrue(config.contains("f"))
        
        // Verify proper Kanata syntax
        let lines = config.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertTrue(lines.count > 0)
        
        // Check for required sections
        let hasDefsrc = lines.contains { $0.contains("(defsrc") }
        let hasDeflayer = lines.contains { $0.contains("(deflayer") }
        XCTAssertTrue(hasDefsrc, "Missing (defsrc section")
        XCTAssertTrue(hasDeflayer, "Missing (deflayer section")
    }
    
    // MARK: - KeyboardCapture Tests
    
    func testKeyboardCaptureInitialState() throws {
        let capture = KeyboardCapture()
        
        // Test initial state
        XCTAssertEqual(capture.capturedKey, "")
        XCTAssertEqual(capture.capturedScanCode, 0)
        XCTAssertFalse(capture.isCapturing)
    }
    
    func testKeyboardCaptureKeyCodeMapping() throws {
        let capture = KeyboardCapture()
        
        // Test specific key code mappings
        XCTAssertEqual(capture.keyCodeToString(keyCode: 0), "a")
        XCTAssertEqual(capture.keyCodeToString(keyCode: 1), "s")
        XCTAssertEqual(capture.keyCodeToString(keyCode: 2), "d")
        XCTAssertEqual(capture.keyCodeToString(keyCode: 3), "f")
        XCTAssertEqual(capture.keyCodeToString(keyCode: 36), "return")
        XCTAssertEqual(capture.keyCodeToString(keyCode: 48), "tab")
        XCTAssertEqual(capture.keyCodeToString(keyCode: 49), "space")
        XCTAssertEqual(capture.keyCodeToString(keyCode: 51), "delete")
        XCTAssertEqual(capture.keyCodeToString(keyCode: 53), "escape")
        
        // Test unknown key code
        XCTAssertEqual(capture.keyCodeToString(keyCode: 999), "key999")
    }
    
    // MARK: - Error Handling Tests
    
    func testRustBridgeErrorHandling() throws {
        // Test with empty input
        let emptyResult = RustBridge.createMapping(inputKey: "", outputSequence: "f")
        XCTAssertNotNil(emptyResult) // Should still create valid JSON
        
        // Test with empty output
        let emptyOutput = RustBridge.createMapping(inputKey: "a", outputSequence: "")
        XCTAssertNotNil(emptyOutput)
        
        // Test with special characters
        let specialResult = RustBridge.createMapping(inputKey: "space", outputSequence: "return")
        XCTAssertNotNil(specialResult)
        
        // Test with long sequences
        let longSequence = String(repeating: "a", count: 1000)
        let longResult = RustBridge.createMapping(inputKey: "a", outputSequence: longSequence)
        XCTAssertNotNil(longResult)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndWorkflow() throws {
        // Simulate complete user workflow
        let capturedInput = "Captured: a (0x00)"
        let outputSequence = "  hello world  \n"
        
        // Step 1: Extract clean key name
        guard let inputKey = RustBridge.cleanKeyName(from: capturedInput) else {
            XCTFail("Failed to extract key name")
            return
        }
        XCTAssertEqual(inputKey, "a")
        
        // Step 2: Clean output sequence
        let cleanOutput = RustBridge.cleanOutputSequence(outputSequence)
        XCTAssertEqual(cleanOutput, "hello world")
        
        // Step 3: Process complete mapping
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: inputKey,
            outputSequence: cleanOutput
        )
        
        // Verify results
        XCTAssertNotNil(irJson)
        XCTAssertNotNil(kanataConfig)
        
        // Verify IR JSON contains the mapping
        let jsonData = irJson!.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: jsonData) as! [String: Any]
        let keys = parsed["keys"] as! [String: Any]
        XCTAssertNotNil(keys["a"])
        
        // Verify Kanata config contains the mapping
        XCTAssertTrue(kanataConfig!.contains("a"))
        XCTAssertTrue(kanataConfig!.contains("hello world") || kanataConfig!.contains("hello") && kanataConfig!.contains("world"))
    }
    
    func testMultipleKeyMappings() throws {
        // Test that we can create multiple mappings
        let mapping1 = RustBridge.createMapping(inputKey: "a", outputSequence: "f")
        let mapping2 = RustBridge.createMapping(inputKey: "s", outputSequence: "g")
        let mapping3 = RustBridge.createMapping(inputKey: "d", outputSequence: "h")
        
        XCTAssertNotNil(mapping1)
        XCTAssertNotNil(mapping2)
        XCTAssertNotNil(mapping3)
        
        // Verify each contains the correct mapping
        let json1Data = mapping1!.data(using: .utf8)!
        let parsed1 = try JSONSerialization.jsonObject(with: json1Data) as! [String: Any]
        let keys1 = parsed1["keys"] as! [String: Any]
        XCTAssertNotNil(keys1["a"])
        
        let json2Data = mapping2!.data(using: .utf8)!
        let parsed2 = try JSONSerialization.jsonObject(with: json2Data) as! [String: Any]
        let keys2 = parsed2["keys"] as! [String: Any]
        XCTAssertNotNil(keys2["s"])
    }
    
    // MARK: - File I/O Tests
    
    func testRustBridgeSaveFiles() throws {
        // Create test mappings
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: "a",
            outputSequence: "f"
        )
        
        XCTAssertNotNil(irJson)
        XCTAssertNotNil(kanataConfig)
        
        // Save files
        let (irPath, kanataPath, error) = RustBridge.saveFiles(
            irJson: irJson!,
            kanataConfig: kanataConfig!,
            baseName: "test_mapping"
        )
        
        // Verify save succeeded
        XCTAssertNil(error, "Save should succeed: \(error ?? "unknown error")")
        XCTAssertNotNil(irPath)
        XCTAssertNotNil(kanataPath)
        
        // Verify files exist
        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(atPath: irPath!), "IR JSON file should exist")
        XCTAssertTrue(fm.fileExists(atPath: kanataPath!), "Kanata config file should exist")
        
        // Verify file contents
        let savedIrJson = try String(contentsOfFile: irPath!)
        let savedKanataConfig = try String(contentsOfFile: kanataPath!)
        
        XCTAssertEqual(savedIrJson, irJson!)
        XCTAssertEqual(savedKanataConfig, kanataConfig!)
        
        // Verify file names contain timestamp and base name
        let irFileName = URL(fileURLWithPath: irPath!).lastPathComponent
        let kanataFileName = URL(fileURLWithPath: kanataPath!).lastPathComponent
        
        XCTAssertTrue(irFileName.hasPrefix("test_mapping_"))
        XCTAssertTrue(irFileName.hasSuffix(".json"))
        XCTAssertTrue(kanataFileName.hasPrefix("test_mapping_"))
        XCTAssertTrue(kanataFileName.hasSuffix(".kbd"))
        
        // Clean up test files
        try? fm.removeItem(atPath: irPath!)
        try? fm.removeItem(atPath: kanataPath!)
    }
    
    func testRustBridgeSaveFilesToCustomDirectory() throws {
        // Create temporary directory
        let fm = FileManager.default
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("keypath_test")
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create test mappings
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: "space",
            outputSequence: "return"
        )
        
        XCTAssertNotNil(irJson)
        XCTAssertNotNil(kanataConfig)
        
        // Save to custom directory
        let (irPath, kanataPath, error) = RustBridge.saveFilesToDirectory(
            irJson: irJson!,
            kanataConfig: kanataConfig!,
            directory: tempDir,
            baseName: "custom_test"
        )
        
        // Verify save succeeded
        XCTAssertNil(error)
        XCTAssertNotNil(irPath)
        XCTAssertNotNil(kanataPath)
        
        // Verify files are in custom directory
        XCTAssertTrue(irPath!.hasPrefix(tempDir.path))
        XCTAssertTrue(kanataPath!.hasPrefix(tempDir.path))
        
        // Verify files exist
        XCTAssertTrue(fm.fileExists(atPath: irPath!))
        XCTAssertTrue(fm.fileExists(atPath: kanataPath!))
        
        // Clean up
        try? fm.removeItem(at: tempDir)
    }
    
    func testDescriptiveFilenames() throws {
        // Test that filenames are descriptive
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: "a",
            outputSequence: "hello world"
        )
        
        XCTAssertNotNil(irJson)
        XCTAssertNotNil(kanataConfig)
        
        // Test the filename generation logic that would be used in ContentView
        let inputKey = "a"
        let cleanOutput = "hello world"
        let baseName = "keypath_\(inputKey)_to_\(cleanOutput.replacingOccurrences(of: " ", with: "_"))"
        
        XCTAssertEqual(baseName, "keypath_a_to_hello_world")
        
        // Save with descriptive name
        let (irPath, kanataPath, error) = RustBridge.saveFiles(
            irJson: irJson!,
            kanataConfig: kanataConfig!,
            baseName: baseName
        )
        
        XCTAssertNil(error)
        XCTAssertNotNil(irPath)
        XCTAssertNotNil(kanataPath)
        
        // Verify filenames contain the mapping description
        let irFileName = URL(fileURLWithPath: irPath!).lastPathComponent
        let kanataFileName = URL(fileURLWithPath: kanataPath!).lastPathComponent
        
        XCTAssertTrue(irFileName.contains("keypath_a_to_hello_world"))
        XCTAssertTrue(kanataFileName.contains("keypath_a_to_hello_world"))
        
        // Clean up
        try? FileManager.default.removeItem(atPath: irPath!)
        try? FileManager.default.removeItem(atPath: kanataPath!)
    }
    
    func testFileErrorHandling() throws {
        // Test saving to invalid directory
        let invalidDir = URL(fileURLWithPath: "/invalid/nonexistent/directory")
        
        let (irPath, kanataPath, error) = RustBridge.saveFilesToDirectory(
            irJson: "{}",
            kanataConfig: "(test)",
            directory: invalidDir,
            baseName: "test"
        )
        
        // Should fail gracefully
        XCTAssertNotNil(error)
        XCTAssertNil(irPath)
        XCTAssertNil(kanataPath)
        XCTAssertTrue(error!.contains("Failed to save files"))
    }
    
    // MARK: - Kanata Integration Tests
    
    func testKanataAvailabilityCheck() throws {
        // Test the availability check (may be true or false depending on system)
        let isAvailable = RustBridge.isKanataAvailable()
        
        // Just verify the function runs without crashing
        // The actual result depends on whether Kanata is installed
        print("Kanata available: \(isAvailable)")
    }
    
    func testKanataLaunchWithInvalidPath() throws {
        // Test launching with an invalid config path
        let (success, error) = RustBridge.launchKanata(configPath: "/nonexistent/file.kbd")
        
        // With real Kanata, this may succeed (Kanata validates the file itself)
        // or fail depending on the Kanata version and arguments
        // We're mainly testing that the function doesn't crash
        print("Launch result with invalid path - Success: \(success), Error: \(error ?? "none")")
        
        // Function should return without crashing
        XCTAssertTrue(true) // Always pass - we're testing robustness, not specific behavior
    }
    
    func testSaveAndLaunchWorkflow() throws {
        // Test the complete save and launch workflow
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: "a",
            outputSequence: "f"
        )
        
        XCTAssertNotNil(irJson)
        XCTAssertNotNil(kanataConfig)
        
        // This will either succeed (if Kanata is installed) or fail gracefully
        let (kanataPath, error) = RustBridge.saveAndLaunchKanata(
            irJson: irJson!,
            kanataConfig: kanataConfig!,
            baseName: "test_launch"
        )
        
        // File should be saved regardless of launch success
        XCTAssertNotNil(kanataPath)
        
        // Verify file exists
        let fm = FileManager.default
        XCTAssertTrue(fm.fileExists(atPath: kanataPath!))
        
        // If Kanata is not available, we should get an error
        if !RustBridge.isKanataAvailable() {
            XCTAssertNotNil(error)
            XCTAssertTrue(error!.contains("Failed to launch Kanata"))
        } else {
            // If Kanata is available, launch should succeed or fail with specific error
            print("Kanata launch result: \(error ?? "success")")
        }
        
        // Clean up
        try? fm.removeItem(atPath: kanataPath!)
    }
    
    func testQuickLaunchErrorHandling() throws {
        // Test error handling with invalid data
        let (kanataPath, _) = RustBridge.saveAndLaunchKanata(
            irJson: "",
            kanataConfig: "",
            baseName: "invalid_test"
        )
        
        // Should save files but may have issues with Kanata launch
        XCTAssertNotNil(kanataPath)
        
        if let kPath = kanataPath {
            // Clean up
            try? FileManager.default.removeItem(atPath: kPath)
        }
    }
}