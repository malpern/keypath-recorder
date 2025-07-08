#ifndef KEYPATH_BRIDGE_H
#define KEYPATH_BRIDGE_H

#include <stdint.h>

// FFI functions for Swift-Rust interop
extern const char* create_mapping_json(const char* input_key, const char* output_sequence);
extern const char* export_to_kanata(const char* ir_json);
extern const char* validate_ir_json(const char* ir_json);
extern void free_rust_string(char* ptr);

#endif // KEYPATH_BRIDGE_H