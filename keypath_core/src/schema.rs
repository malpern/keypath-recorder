use crate::IR;
use schemars::schema_for;
use serde_json::Value;

/// Generate JSON schema for the IR
pub fn generate_schema() -> serde_json::Result<String> {
    let schema = schema_for!(IR);
    serde_json::to_string_pretty(&schema)
}

/// Validate JSON data against the IR schema
pub fn validate_json_schema(json_value: &Value, _schema: &Value) -> Result<(), String> {
    // For now, we'll implement basic validation
    // In a full implementation, you'd use a JSON schema validator like jsonschema

    // Check if it's an object
    if !json_value.is_object() {
        return Err("Root must be an object".to_string());
    }

    let obj = json_value.as_object().unwrap();

    // Check required fields
    if !obj.contains_key("keys") {
        return Err("Missing required field: keys".to_string());
    }

    // Check keys field is an object
    if !obj["keys"].is_object() {
        return Err("Field 'keys' must be an object".to_string());
    }

    // Basic validation of each key
    for (key_name, key_value) in obj["keys"].as_object().unwrap() {
        if !key_value.is_object() {
            return Err(format!("Key '{}' must be an object", key_name));
        }

        let key_obj = key_value.as_object().unwrap();

        // Check required tap field
        if !key_obj.contains_key("tap") {
            return Err(format!("Key '{}' missing required field: tap", key_name));
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_generate_schema() {
        let schema = generate_schema().unwrap();
        assert!(schema.contains("\"title\""));
        assert!(schema.contains("\"properties\""));
        assert!(schema.contains("\"keys\""));
    }

    #[test]
    fn test_validate_valid_json() {
        let json = json!({
            "keys": {
                "a": {"tap": "b"}
            }
        });
        let schema = json!({}); // Dummy schema for now

        let result = validate_json_schema(&json, &schema);
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_invalid_json() {
        let json = json!({
            "invalid": "structure"
        });
        let schema = json!({});

        let result = validate_json_schema(&json, &schema);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("Missing required field: keys"));
    }
}
