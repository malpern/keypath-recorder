import Foundation
import Cocoa
import CoreGraphics

@Observable
class KeyboardCapture {
    var capturedKey: String = ""
    var capturedScanCode: UInt16 = 0
    var isCapturing = false
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init() {}
    
    deinit {
        stopCapture()
    }
    
    func startCapture() {
        // Check for accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("App not trusted for accessibility. Requesting permission...")
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options)
            return
        }
        
        // Create event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Get the capture instance from refcon
                let capture = Unmanaged<KeyboardCapture>.fromOpaque(refcon!).takeUnretainedValue()
                
                if type == .keyDown {
                    // Get scan code
                    let scanCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                    
                    // Get the key character
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    if let key = capture.keyCodeToString(keyCode: keyCode) {
                        DispatchQueue.main.async {
                            capture.capturedKey = key
                            capture.capturedScanCode = scanCode
                            capture.stopCapture()
                        }
                    }
                    
                    // Consume the event (don't pass it on)
                    return nil
                }
                
                return Unmanaged.passRetained(event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        
        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isCapturing = true
    }
    
    func stopCapture() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
        }
        isCapturing = false
    }
    
    internal func keyCodeToString(keyCode: Int64) -> String? {
        // Map common key codes to their string representations
        switch keyCode {
        case 0: return "a"
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 4: return "h"
        case 5: return "g"
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 16: return "y"
        case 17: return "t"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "o"
        case 32: return "u"
        case 33: return "["
        case 34: return "i"
        case 35: return "p"
        case 36: return "return"
        case 37: return "l"
        case 38: return "j"
        case 39: return "'"
        case 40: return "k"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "n"
        case 46: return "m"
        case 47: return "."
        case 48: return "tab"
        case 49: return "space"
        case 50: return "`"
        case 51: return "delete"
        case 53: return "escape"
        case 55: return "command"
        case 56: return "shift"
        case 57: return "capslock"
        case 58: return "option"
        case 59: return "control"
        case 60: return "rightshift"
        case 61: return "rightoption"
        case 62: return "rightcontrol"
        case 63: return "function"
        case 64: return "f17"
        case 65: return "keypaddecimal"
        case 67: return "keypadmultiply"
        case 69: return "keypadplus"
        case 71: return "keypadclear"
        case 72: return "volumeup"
        case 73: return "volumedown"
        case 74: return "mute"
        case 75: return "keypaddivide"
        case 76: return "keypadenter"
        case 78: return "keypadminus"
        case 79: return "f18"
        case 80: return "f19"
        case 81: return "keypadequals"
        case 82: return "keypad0"
        case 83: return "keypad1"
        case 84: return "keypad2"
        case 85: return "keypad3"
        case 86: return "keypad4"
        case 87: return "keypad5"
        case 88: return "keypad6"
        case 89: return "keypad7"
        case 90: return "f20"
        case 91: return "keypad8"
        case 92: return "keypad9"
        case 96: return "f5"
        case 97: return "f6"
        case 98: return "f7"
        case 99: return "f3"
        case 100: return "f8"
        case 101: return "f9"
        case 102: return "f11"
        case 103: return "f13"
        case 104: return "f16"
        case 105: return "f14"
        case 107: return "f10"
        case 109: return "f12"
        case 111: return "f15"
        case 113: return "help"
        case 114: return "home"
        case 115: return "pageup"
        case 116: return "forwarddelete"
        case 117: return "f4"
        case 118: return "end"
        case 119: return "f2"
        case 120: return "pagedown"
        case 121: return "f1"
        case 122: return "leftarrow"
        case 123: return "rightarrow"
        case 124: return "downarrow"
        case 125: return "uparrow"
        default: return "key\(keyCode)"
        }
    }
}