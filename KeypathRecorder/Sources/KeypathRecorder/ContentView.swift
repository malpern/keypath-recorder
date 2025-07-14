import SwiftUI

struct ContentView: View {
    @State private var isRecording = false
    @FocusState private var outputFieldFocused: Bool
    @State private var capturedInput = ""
    @State private var outputSequence = ""
    @State private var statusMessage = "Ready to record"
    @State private var keyboardCapture = KeyboardCapture()
    @State private var saveDirectory: URL?
    @State private var showingDirectoryPicker = false
    @State private var showingInstructions = false
    @State private var kanataInstructions = ""
    @StateObject private var helperManager = HelperManager()
    @State private var showingHelperSettings = false
    @State private var kanataRunning = false
    
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
            
            // Input capture section
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Key:")
                    .font(.headline)
                HStack {
                    Text(capturedInput.isEmpty ? "Click Start to capture input key" : capturedInput)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button(isRecording ? "Stop" : "Start") {
                        toggleInputCapture()
                    }
                    .controlSize(.regular)
                    .disabled(isRecording)
                }
            }
            .padding(.horizontal)
            
            // Output capture section
            VStack(alignment: .leading, spacing: 8) {
                Text("Output Sequence:")
                    .font(.headline)
                TextField("Type desired output sequence", text: $outputSequence)
                    .font(.system(.body, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .focused($outputFieldFocused)
                    .disabled(capturedInput.isEmpty || isRecording)
                    .onTapGesture {
                        Logger.shared.log("SwiftUI TextField tapped")
                        outputFieldFocused = true
                    }
            }
            .padding(.horizontal)
            
            // Save location
            VStack(alignment: .leading, spacing: 8) {
                Text("Save Location:")
                    .font(.headline)
                HStack {
                    Text(saveLocationText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Choose Folder") {
                        showingDirectoryPicker = true
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.horizontal)
            
            // Helper Status Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Privileged Helper Status:")
                    .font(.headline)
                HStack {
                    Circle()
                        .fill(helperManager.isHelperRegistered ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(helperStatusText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Settings") {
                        showingHelperSettings = true
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
                
                if helperManager.isHelperRegistered {
                    HStack {
                        Text("Kanata Status:")
                            .font(.caption)
                        Text(kanataRunning ? "Running" : "Stopped")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(kanataRunning ? .green : .secondary)
                        Spacer()
                        Button("Stop Kanata") {
                            Task {
                                await stopKanata()
                            }
                        }
                        .controlSize(.small)
                        .disabled(!kanataRunning)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            
            // Action buttons
            VStack(spacing: 12) {
                HStack(spacing: 15) {
                    Button("Clear All") {
                        clearAll()
                    }
                    .controlSize(.large)
                    .disabled(capturedInput.isEmpty && outputSequence.isEmpty)
                    
                    Button("Save Files") {
                        saveMapping()
                    }
                    .controlSize(.large)
                    .disabled(capturedInput.isEmpty || outputSequence.isEmpty || isRecording)
                    
                    if helperManager.isHelperRegistered {
                        Button("Save & Launch") {
                            saveAndLaunchKanata()
                        }
                        .controlSize(.large)
                        .disabled(capturedInput.isEmpty || outputSequence.isEmpty || isRecording)
                    } else {
                        Button("Save & Copy Command") {
                            saveAndShowInstructions()
                        }
                        .controlSize(.large)
                        .disabled(capturedInput.isEmpty || outputSequence.isEmpty || isRecording)
                    }
                }
                
                // Debug button
                Button("Show Debug Log") {
                    let logPath = Logger.shared.getLogPath()
                    Logger.shared.log("Log file location: \(logPath)")
                    statusMessage = "Debug log: \(URL(fileURLWithPath: logPath).lastPathComponent)"
                    NSWorkspace.shared.open(URL(fileURLWithPath: logPath))
                }
                .controlSize(.small)
                .foregroundColor(.secondary)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .onChange(of: keyboardCapture.capturedKey) { _, newKey in
            if !newKey.isEmpty {
                capturedInput = "Captured: \(newKey) (0x\(String(format: "%02X", keyboardCapture.capturedScanCode)))"
                statusMessage = "Key captured! Type in output field below"
                isRecording = false
                Logger.shared.log("UI updated with captured key: \(newKey)")
                
                // Auto-focus output field and ensure app is key
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Try to ensure the app window is key and in front
                    if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
                        window.makeKeyAndOrderFront(nil)
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        Logger.shared.log("Made app window key and front")
                    }
                    
                    outputFieldFocused = true
                    Logger.shared.log("Auto-focused SwiftUI TextField after key capture")
                }
                // Note: stopCapture() is already called in the keyboard capture callback
            }
        }
        .onChange(of: outputSequence) { oldValue, newValue in
            if oldValue != newValue {
                Logger.shared.log("SwiftUI output sequence changed from '\(oldValue)' to '\(newValue)'")
            }
        }
        .onChange(of: outputFieldFocused) { _, focused in
            Logger.shared.log("SwiftUI output field focus changed to: \(focused)")
        }
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    saveDirectory = url
                    statusMessage = "Save location updated"
                }
            case .failure(let error):
                statusMessage = "Error selecting folder: \(error.localizedDescription)"
            }
        }
        .alert("Run with Kanata", isPresented: $showingInstructions) {
            Button("Copy Command") {
                // Extract the actual command from instructions
                let lines = kanataInstructions.components(separatedBy: .newlines)
                if let commandLine = lines.first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("2. Run: ") }) {
                    let command = String(commandLine.dropFirst(8)) // Remove "2. Run: "
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    statusMessage = "Command copied to clipboard!"
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(kanataInstructions)
        }
        .sheet(isPresented: $showingHelperSettings) {
            HelperSettingsView(helperManager: helperManager)
        }
        .task {
            await checkKanataStatus()
        }
    }
    
    private var saveLocationText: String {
        if let dir = saveDirectory {
            return dir.path
        } else {
            return "~/Documents (default)"
        }
    }
    
    private var helperStatusText: String {
        switch helperManager.status {
        case .notRegistered:
            return "Not registered"
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Requires approval"
        case .notFound:
            return "Not found"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func toggleInputCapture() {
        isRecording.toggle()
        Logger.shared.log("Input capture toggled, now recording: \(isRecording)")
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
        isRecording = false
        outputFieldFocused = false
        statusMessage = "Ready to record"
        Logger.shared.log("Cleared all fields and reset state")
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
        
        guard let ir = irJson, let kanata = kanataConfig else {
            statusMessage = "Error: Failed to generate mapping"
            return
        }
        
        // Generate descriptive filename
        let baseName = "keypath_\(inputKey)_to_\(cleanOutput.replacingOccurrences(of: " ", with: "_"))"
        
        let (irPath, kanataPath, error): (String?, String?, String?)
        
        if let customDir = saveDirectory {
            // Save to custom directory
            (irPath, kanataPath, error) = RustBridge.saveFilesToDirectory(
                irJson: ir,
                kanataConfig: kanata,
                directory: customDir,
                baseName: baseName
            )
        } else {
            // Save to default Documents directory
            (irPath, kanataPath, error) = RustBridge.saveFiles(
                irJson: ir,
                kanataConfig: kanata,
                baseName: baseName
            )
        }
        
        if let error = error {
            statusMessage = "Error: \(error)"
        } else if let kPath = kanataPath {
            statusMessage = "Files saved! Kanata config: \(URL(fileURLWithPath: kPath).lastPathComponent)"
            print("Files saved:")
            print("IR JSON: \(irPath ?? "unknown")")
            print("Kanata config: \(kPath)")
            print("\nTo use with Kanata, run:")
            print("kanata \"\(kPath)\"")
        } else {
            statusMessage = "Error: Unknown save failure"
        }
    }
    
    private func saveAndShowInstructions() {
        guard let inputKey = RustBridge.cleanKeyName(from: capturedInput) else {
            statusMessage = "Error: Invalid input key format"
            return
        }
        
        let cleanOutput = RustBridge.cleanOutputSequence(outputSequence)
        
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: inputKey,
            outputSequence: cleanOutput
        )
        
        guard let ir = irJson, let kanata = kanataConfig else {
            statusMessage = "Error: Failed to generate mapping"
            return
        }
        
        // Generate descriptive filename
        let baseName = "keypath_\(inputKey)_to_\(cleanOutput.replacingOccurrences(of: " ", with: "_"))"
        
        let (kanataPath, instructions, error) = RustBridge.saveAndPrepareKanata(
            irJson: ir,
            kanataConfig: kanata,
            directory: saveDirectory,
            baseName: baseName
        )
        
        if let error = error {
            statusMessage = "Error: \(error)"
        } else if let kPath = kanataPath, let instr = instructions {
            let fileName = URL(fileURLWithPath: kPath).lastPathComponent
            statusMessage = "Files saved! Config: \(fileName)"
            kanataInstructions = instr
            showingInstructions = true
            
            print("Files saved:")
            print("Kanata config: \(kPath)")
            print("\nInstructions:")
            print(instr)
        } else {
            statusMessage = "Error: Unknown save failure"
        }
    }
    
    private func saveAndLaunchKanata() {
        guard let inputKey = RustBridge.cleanKeyName(from: capturedInput) else {
            statusMessage = "Error: Invalid input key format"
            return
        }
        
        let cleanOutput = RustBridge.cleanOutputSequence(outputSequence)
        
        let (irJson, kanataConfig) = RustBridge.processMapping(
            inputKey: inputKey,
            outputSequence: cleanOutput
        )
        
        guard let ir = irJson, let kanata = kanataConfig else {
            statusMessage = "Error: Failed to generate mapping"
            return
        }
        
        // Generate descriptive filename
        let baseName = "keypath_\(inputKey)_to_\(cleanOutput.replacingOccurrences(of: " ", with: "_"))"
        
        let (kanataPath, _, error) = RustBridge.saveAndPrepareKanata(
            irJson: ir,
            kanataConfig: kanata,
            directory: saveDirectory,
            baseName: baseName
        )
        
        if let error = error {
            statusMessage = "Error: \(error)"
            return
        }
        
        guard let kPath = kanataPath else {
            statusMessage = "Error: Failed to save Kanata config"
            return
        }
        
        // Launch Kanata via privileged helper
        Task {
            do {
                let result = try await helperManager.launchKanata(configPath: kPath)
                statusMessage = "Kanata launched: \(result)"
                kanataRunning = true
            } catch {
                statusMessage = "Error launching Kanata: \(error.localizedDescription)"
            }
        }
    }
    
    private func checkKanataStatus() async {
        guard helperManager.isHelperRegistered else {
            kanataRunning = false
            return
        }
        
        do {
            let status = try await helperManager.getKanataStatus()
            kanataRunning = status.contains("running")
        } catch {
            kanataRunning = false
        }
    }
    
    private func stopKanata() async {
        do {
            let result = try await helperManager.stopKanata()
            statusMessage = "Kanata stopped: \(result)"
            kanataRunning = false
        } catch {
            statusMessage = "Error stopping Kanata: \(error.localizedDescription)"
        }
    }
}