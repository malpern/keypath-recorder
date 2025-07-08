import SwiftUI

struct ContentView: View {
    @State private var isRecording = false
    @State private var capturedInput = ""
    @State private var outputSequence = ""
    @State private var statusMessage = "Ready to record"
    @State private var keyboardCapture = KeyboardCapture()
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Keypath Recorder")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Status
            Text(statusMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Input display
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Key:")
                    .font(.headline)
                Text(capturedInput.isEmpty ? "Press Start to capture" : capturedInput)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // Output display
            VStack(alignment: .leading, spacing: 8) {
                Text("Output Sequence:")
                    .font(.headline)
                TextField("Type desired output, press Return to finish", text: $outputSequence)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if !outputSequence.isEmpty {
                            statusMessage = "Output sequence captured!"
                        }
                    }
                    .disabled(capturedInput.isEmpty)
            }
            .padding(.horizontal)
            
            // Control buttons
            HStack(spacing: 20) {
                Button(action: startRecording) {
                    Text(isRecording ? "Stop" : "Start")
                        .frame(minWidth: 100)
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                
                Button("Clear") {
                    clearAll()
                }
                .controlSize(.large)
                .disabled(capturedInput.isEmpty && outputSequence.isEmpty)
                
                Button("Save") {
                    saveMapping()
                }
                .controlSize(.large)
                .disabled(capturedInput.isEmpty || outputSequence.isEmpty)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .onChange(of: keyboardCapture.capturedKey) { _, newKey in
            if !newKey.isEmpty {
                capturedInput = "Captured: \(newKey) (0x\(String(format: "%02X", keyboardCapture.capturedScanCode)))"
                statusMessage = "Key captured! Now type output sequence and press Return"
                isRecording = false
            }
        }
    }
    
    private func startRecording() {
        isRecording.toggle()
        if isRecording {
            statusMessage = "Recording... Press a key"
            keyboardCapture.startCapture()
        } else {
            statusMessage = "Recording stopped"
            keyboardCapture.stopCapture()
        }
    }
    
    private func clearAll() {
        capturedInput = ""
        outputSequence = ""
        keyboardCapture.capturedKey = ""
        keyboardCapture.capturedScanCode = 0
        statusMessage = "Ready to record"
    }
    
    private func saveMapping() {
        guard let inputKey = RustBridge.cleanKeyName(from: capturedInput) else {
            statusMessage = "Error: Invalid input key format"
            return
        }
        
        let cleanOutput = RustBridge.cleanOutputSequence(outputSequence)
        
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: inputKey,
            outputSequence: cleanOutput
        )
        
        if let ir = irJson, let kanata = kanataConfig {
            print("Generated IR JSON:")
            print(ir)
            print("\nGenerated Kanata config:")
            print(kanata)
            statusMessage = "Mapping generated successfully!"
        } else {
            statusMessage = "Error: Failed to generate mapping"
        }
    }
}