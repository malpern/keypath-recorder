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
            }
        }
        return nil
    }
    
    /// Convert output sequence to clean string
    static func cleanOutputSequence(_ sequence: String) -> String {
        return sequence.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}