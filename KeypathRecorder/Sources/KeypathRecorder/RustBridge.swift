import Foundation

/// Swift wrapper for Rust FFI functions
class RustBridge {
    
    // MARK: - C Function Declarations
    
    /// Create IR JSON mapping from input key to output sequence
    @_silgen_name("create_mapping_json")
    private static func createMappingJson(_ inputKey: UnsafePointer<CChar>, _ outputSequence: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?
    
    /// Export IR JSON to Kanata format
    @_silgen_name("export_to_kanata")
    private static func exportToKanata(_ irJson: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?
    
    /// Validate IR JSON format
    @_silgen_name("validate_ir_json")
    private static func validateIrJson(_ irJson: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?
    
    /// Free a string allocated by Rust
    @_silgen_name("free_rust_string")
    private static func freeRustString(_ ptr: UnsafeMutablePointer<CChar>)
    
    // MARK: - Swift Wrapper Functions
    
    /// Create IR JSON from captured input and output sequence
    static func createMapping(inputKey: String, outputSequence: String) -> String? {
        return inputKey.withCString { inputCStr in
            return outputSequence.withCString { outputCStr in
                guard let resultPtr = createMappingJson(inputCStr, outputCStr) else {
                    return nil
                }
                
                let result = String(cString: resultPtr)
                freeRustString(resultPtr)
                return result
            }
        }
    }
    
    /// Export IR JSON to Kanata .kbd format
    static func exportToKanata(irJson: String) -> String? {
        return irJson.withCString { irCStr in
            guard let resultPtr = exportToKanata(irCStr) else {
                return nil
            }
            
            let result = String(cString: resultPtr)
            freeRustString(resultPtr)
            return result
        }
    }
    
    /// Validate IR JSON format
    static func validateJson(_ json: String) -> String? {
        return json.withCString { jsonCStr in
            guard let resultPtr = validateIrJson(jsonCStr) else {
                return nil
            }
            
            let result = String(cString: resultPtr)
            freeRustString(resultPtr)
            return result
        }
    }
    
    /// Convert captured UI data to complete workflow
    static func processMapping(inputKey: String, outputSequence: String) -> (irJson: String?, kanataConfig: String?) {
        // Step 1: Create IR JSON
        guard let irJson = createMapping(inputKey: inputKey, outputSequence: outputSequence) else {
            return (nil, nil)
        }
        
        // Step 2: Export to Kanata
        guard let kanataConfig = exportToKanata(irJson: irJson) else {
            return (irJson, nil)
        }
        
        return (irJson, kanataConfig)
    }
    
    /// Save IR JSON and Kanata config to files
    static func saveFiles(irJson: String, kanataConfig: String, baseName: String = "keypath") -> (irPath: String?, kanataPath: String?, error: String?) {
        let fm = FileManager.default
        
        // Get user's Documents directory
        guard let documentsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return (nil, nil, "Could not access Documents directory")
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let irFileName = "\(baseName)_\(timestamp).json"
        let kanataFileName = "\(baseName)_\(timestamp).kbd"
        
        let irURL = documentsDir.appendingPathComponent(irFileName)
        let kanataURL = documentsDir.appendingPathComponent(kanataFileName)
        
        do {
            // Save IR JSON
            try irJson.write(to: irURL, atomically: true, encoding: .utf8)
            
            // Save Kanata config
            try kanataConfig.write(to: kanataURL, atomically: true, encoding: .utf8)
            
            return (irURL.path, kanataURL.path, nil)
        } catch {
            return (nil, nil, "Failed to save files: \(error.localizedDescription)")
        }
    }
    
    /// Save files with custom directory selection
    static func saveFilesToDirectory(irJson: String, kanataConfig: String, directory: URL, baseName: String = "keypath") -> (irPath: String?, kanataPath: String?, error: String?) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let irFileName = "\(baseName)_\(timestamp).json"
        let kanataFileName = "\(baseName)_\(timestamp).kbd"
        
        let irURL = directory.appendingPathComponent(irFileName)
        let kanataURL = directory.appendingPathComponent(kanataFileName)
        
        do {
            // Save IR JSON
            try irJson.write(to: irURL, atomically: true, encoding: .utf8)
            
            // Save Kanata config
            try kanataConfig.write(to: kanataURL, atomically: true, encoding: .utf8)
            
            return (irURL.path, kanataURL.path, nil)
        } catch {
            return (nil, nil, "Failed to save files: \(error.localizedDescription)")
        }
    }
    
    /// Find Kanata executable path
    static func findKanataPath() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["kanata"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return path
            }
        } catch {
            // Ignore error
        }
        
        return nil
    }
    
    /// Generate instructions for manually running Kanata with sudo
    static func generateKanataInstructions(configPath: String) -> String {
        guard let kanataPath = findKanataPath() else {
            return """
            Kanata not found. Please install Kanata first:
            brew install kanata
            
            Then run with sudo:
            sudo kanata "\(configPath)"
            """
        }
        
        return """
        To run your keyboard mapping with Kanata:
        
        1. Open Terminal
        2. Run: sudo \(kanataPath) "\(configPath)"
        3. Enter your password when prompted
        4. Press Ctrl+C to stop Kanata when done
        
        Note: Kanata requires elevated privileges to access keyboard input.
        """
    }
    
    /// Check if user can run Kanata (but can't actually launch it with sudo from app)
    static func checkKanataSetup() -> (canRun: Bool, instructions: String) {
        guard let kanataPath = findKanataPath() else {
            return (false, """
            Kanata not installed. To install:
            brew install kanata
            """)
        }
        
        return (true, """
        Kanata found at: \(kanataPath)
        
        ⚠️  Note: Due to macOS security, this app cannot run Kanata directly.
        You'll need to run it manually in Terminal with sudo privileges.
        """)
    }
    
    /// Check if Kanata is available on the system
    static func isKanataAvailable() -> Bool {
        return findKanataPath() != nil
    }
    
    /// Complete workflow: save files and provide instructions
    static func saveAndPrepareKanata(irJson: String, kanataConfig: String, directory: URL? = nil, baseName: String = "keypath") -> (kanataPath: String?, instructions: String?, error: String?) {
        let (_, kanataPath, saveError): (String?, String?, String?)
        
        if let dir = directory {
            (_, kanataPath, saveError) = saveFilesToDirectory(irJson: irJson, kanataConfig: kanataConfig, directory: dir, baseName: baseName)
        } else {
            (_, kanataPath, saveError) = saveFiles(irJson: irJson, kanataConfig: kanataConfig, baseName: baseName)
        }
        
        guard let kPath = kanataPath, saveError == nil else {
            return (nil, nil, saveError ?? "Failed to save files")
        }
        
        let instructions = generateKanataInstructions(configPath: kPath)
        return (kPath, instructions, nil)
    }
}

/// Convenience extensions for key code to string conversion
extension RustBridge {
    
    /// Convert hex scan code string to clean key name for Rust bridge
    static func cleanKeyName(from capturedInput: String) -> String? {
        // Parse "Captured: a (0x00)" format to extract just "a"
        if capturedInput.hasPrefix("Captured: ") {
            let withoutPrefix = String(capturedInput.dropFirst(10))
            if let spaceIndex = withoutPrefix.firstIndex(of: " ") {
                return String(withoutPrefix[..<spaceIndex])
            } else {
                // Handle case without scan code: "Captured: a"
                return withoutPrefix.isEmpty ? nil : withoutPrefix
            }
        }
        return nil
    }
    
    /// Convert output sequence to clean string
    static func cleanOutputSequence(_ sequence: String) -> String {
        return sequence.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}