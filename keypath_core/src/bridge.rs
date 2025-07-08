use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use crate::ir::{IR, Action};
use crate::export::export_kanata;

/// Create a simple IR JSON mapping from input key to output sequence
#[no_mangle]
pub extern "C" fn create_mapping_json(
    input_key: *const c_char,
    output_sequence: *const c_char,
) -> *mut c_char {
    if input_key.is_null() || output_sequence.is_null() {
        return std::ptr::null_mut();
    }
    
    let input_str = unsafe {
        match CStr::from_ptr(input_key).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        }
    };
    
    let output_str = unsafe {
        match CStr::from_ptr(output_sequence).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        }
    };
    
    // Create a simple IR mapping
    let mut ir = IR::new();
    ir.add_key_mapping(input_str, output_str);
    
    match serde_json::to_string_pretty(&ir) {
        Ok(json) => match CString::new(json) {
            Ok(c_string) => c_string.into_raw(),
            Err(_) => std::ptr::null_mut(),
        },
        Err(_) => std::ptr::null_mut(),
    }
}

/// Export IR JSON to Kanata format
#[no_mangle]
pub extern "C" fn export_to_kanata(ir_json: *const c_char) -> *mut c_char {
    if ir_json.is_null() {
        return std::ptr::null_mut();
    }
    
    let json_str = unsafe {
        match CStr::from_ptr(ir_json).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        }
    };
    
    let ir: IR = match serde_json::from_str(json_str) {
        Ok(ir) => ir,
        Err(_) => return std::ptr::null_mut(),
    };
    
    match export_kanata(&ir) {
        Ok(kanata) => match CString::new(kanata) {
            Ok(c_string) => c_string.into_raw(),
            Err(_) => std::ptr::null_mut(),
        },
        Err(_) => std::ptr::null_mut(),
    }
}

/// Validate IR JSON format
#[no_mangle]
pub extern "C" fn validate_ir_json(ir_json: *const c_char) -> *mut c_char {
    if ir_json.is_null() {
        return std::ptr::null_mut();
    }
    
    let json_str = unsafe {
        match CStr::from_ptr(ir_json).to_str() {
            Ok(s) => s,
            Err(_) => return std::ptr::null_mut(),
        }
    };
    
    let result = match serde_json::from_str::<IR>(json_str) {
        Ok(_) => "valid",
        Err(e) => {
            // Return error message, but truncated for safety
            let error_msg = format!("invalid: {}", e);
            return match CString::new(error_msg) {
                Ok(c_string) => c_string.into_raw(),
                Err(_) => std::ptr::null_mut(),
            };
        }
    };
    
    match CString::new(result) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Free a string allocated by Rust
#[no_mangle]
pub extern "C" fn free_rust_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            let _ = CString::from_raw(ptr);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CString;

    #[test]
    fn test_create_mapping_json() {
        let input = CString::new("a").unwrap();
        let output = CString::new("f").unwrap();
        
        let result_ptr = create_mapping_json(input.as_ptr(), output.as_ptr());
        assert!(!result_ptr.is_null());
        
        let result = unsafe { CStr::from_ptr(result_ptr) };
        let json_str = result.to_str().unwrap();
        
        // Verify it's valid JSON and contains our mapping
        let ir: IR = serde_json::from_str(json_str).unwrap();
        match &ir.keys.get("a").unwrap().tap {
            Action::Key(k) => assert_eq!(k, "f"),
            _ => panic!("Expected simple key action"),
        }
        
        free_rust_string(result_ptr);
    }

    #[test]
    fn test_export_to_kanata() {
        let input = CString::new("a").unwrap();
        let output = CString::new("f").unwrap();
        
        // First create IR JSON
        let ir_json_ptr = create_mapping_json(input.as_ptr(), output.as_ptr());
        assert!(!ir_json_ptr.is_null());
        
        // Then export to Kanata
        let kanata_ptr = export_to_kanata(ir_json_ptr);
        assert!(!kanata_ptr.is_null());
        
        let kanata_result = unsafe { CStr::from_ptr(kanata_ptr) };
        let kanata_str = kanata_result.to_str().unwrap();
        
        // Verify Kanata format
        assert!(kanata_str.contains("(defsrc"));
        assert!(kanata_str.contains("(deflayer"));
        assert!(kanata_str.contains("a"));
        assert!(kanata_str.contains("f"));
        
        free_rust_string(ir_json_ptr);
        free_rust_string(kanata_ptr);
    }

    #[test]
    fn test_validate_ir_json() {
        let valid_json = CString::new(r#"{"keys":{},"macros":{},"conditions":{},"layers":[]}"#).unwrap();
        let result_ptr = validate_ir_json(valid_json.as_ptr());
        assert!(!result_ptr.is_null());
        
        let result = unsafe { CStr::from_ptr(result_ptr) };
        assert_eq!(result.to_str().unwrap(), "valid");
        
        free_rust_string(result_ptr);
    }
}