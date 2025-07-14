import SwiftUI

/// Settings view for managing the privileged helper
struct HelperSettingsView: View {
    @ObservedObject var helperManager: HelperManager
    @Environment(\.dismiss) private var dismiss
    @State private var isWorking = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Privileged Helper Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("The privileged helper allows KeypathRecorder to launch Kanata automatically without requiring manual sudo commands.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Current Status
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Status")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(statusText)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                            
                            Text(statusDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Actions
                VStack(spacing: 12) {
                    if !helperManager.isHelperRegistered {
                        Button("Register Helper") {
                            registerHelper()
                        }
                        .controlSize(.large)
                        .disabled(isWorking)
                    } else {
                        Button("Unregister Helper") {
                            unregisterHelper()
                        }
                        .controlSize(.large)
                        .disabled(isWorking)
                    }
                    
                    if helperManager.status == .requiresApproval {
                        Button("Open System Settings") {
                            helperManager.openSystemSettings()
                        }
                        .controlSize(.large)
                    }
                    
                    Button("Refresh Status") {
                        helperManager.checkStatus()
                    }
                    .controlSize(.regular)
                    .disabled(isWorking)
                }
                
                // Error Display
                if let error = errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Text(error)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Help Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("About Privileged Helpers")
                        .font(.headline)
                    
                    Text("""
                    • Privileged helpers run with root privileges to perform system-level operations
                    • macOS requires user approval the first time a helper is registered
                    • You can enable/disable helpers in System Settings > General > Login Items
                    • Helpers are automatically managed by the system and only run when needed
                    """)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Helper Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
        .onAppear {
            helperManager.checkStatus()
        }
    }
    
    private var statusColor: Color {
        switch helperManager.status {
        case .enabled:
            return .green
        case .requiresApproval:
            return .orange
        case .notRegistered, .notFound:
            return .red
        @unknown default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch helperManager.status {
        case .notRegistered:
            return "Not Registered"
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Requires Approval"
        case .notFound:
            return "Not Found"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var statusDescription: String {
        switch helperManager.status {
        case .notRegistered:
            return "The helper is not registered with the system."
        case .enabled:
            return "The helper is registered and ready to use."
        case .requiresApproval:
            return "The helper is registered but requires user approval in System Settings."
        case .notFound:
            return "The helper could not be found in the app bundle."
        @unknown default:
            return "The helper status is unknown."
        }
    }
    
    private func registerHelper() {
        isWorking = true
        errorMessage = nil
        
        Task {
            do {
                try await helperManager.registerHelper()
                await MainActor.run {
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func unregisterHelper() {
        isWorking = true
        errorMessage = nil
        
        Task {
            do {
                try await helperManager.unregisterHelper()
                await MainActor.run {
                    isWorking = false
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}