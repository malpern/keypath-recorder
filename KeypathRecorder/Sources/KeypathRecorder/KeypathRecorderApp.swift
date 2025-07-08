import SwiftUI

@main
struct KeypathRecorderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, idealWidth: 500, minHeight: 300, idealHeight: 400)
        }
        .windowResizability(.contentSize)
        .commands {
            // Remove unwanted menu items
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
        }
    }
}