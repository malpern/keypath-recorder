import Foundation
import os.log

/// Entry point for the privileged Kanata helper daemon
/// This daemon runs with root privileges and manages Kanata processes via XPC

let logger = os.Logger(subsystem: "com.keypath.KeypathRecorder", category: "KanataHelper")

func main() {
    logger.info("Kanata helper daemon starting...")
    
    let listener = NSXPCListener(machServiceName: "com.keypath.kanata.xpc")
    let delegate = KanataHelperDelegate()
    listener.delegate = delegate
    
    listener.resume()
    
    logger.info("Kanata helper daemon listening for XPC connections")
    
    // Keep the daemon running
    RunLoop.current.run()
}

main()