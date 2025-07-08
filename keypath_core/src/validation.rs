use crate::{generate_schema, validate_json_schema, KeypathError, Result, IR};

/// Parse and validate an IR from JSON string
pub fn parse_ir(json: &str) -> Result<IR> {
    // First parse as raw JSON to validate against schema
    let json_value: serde_json::Value = serde_json::from_str(json)
        .map_err(|e| KeypathError::InvalidIR(format!("JSON parse error: {}", e)))?;

    // Generate schema for validation
    let schema_str = generate_schema()
        .map_err(|e| KeypathError::SchemaValidation(format!("Schema generation error: {}", e)))?;
    let schema: serde_json::Value = serde_json::from_str(&schema_str)
        .map_err(|e| KeypathError::SchemaValidation(format!("Schema parse error: {}", e)))?;

    // Validate against schema
    validate_json_schema(&json_value, &schema).map_err(KeypathError::SchemaValidation)?;

    // If validation passes, parse into IR struct
    let ir: IR = serde_json::from_value(json_value)
        .map_err(|e| KeypathError::InvalidIR(format!("IR deserialization error: {}", e)))?;

    Ok(ir)
}

/// Convert IR to pretty-printed JSON with deterministic field order
pub fn to_pretty_json(ir: &IR) -> Result<String> {
    let json = serde_json::to_string_pretty(ir)?;
    Ok(json)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_valid_ir() {
        let json = r#"{"keys":{"a":{"tap":"b"}}}"#;
        let ir = parse_ir(json).unwrap();

        assert_eq!(ir.keys.len(), 1);
        assert!(ir.keys.contains_key("a"));
    }

    #[test]
    fn test_parse_invalid_ir() {
        let json = r#"{"invalid": "json"#;
        let result = parse_ir(json);

        assert!(result.is_err());
    }

    #[test]
    fn test_to_pretty_json() {
        let mut ir = IR::new();
        ir.add_key_mapping("a", "b");

        let json = to_pretty_json(&ir).unwrap();
        assert!(json.contains("\"a\""));
        assert!(json.contains("\"b\""));
        assert!(json.contains("  ")); // Should be pretty-printed
    }
}
