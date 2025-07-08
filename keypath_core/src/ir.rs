use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// The main IR structure representing a keyboard configuration
#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct IR {
    /// Optional metadata about the configuration
    #[serde(skip_serializing_if = "Option::is_none")]
    pub meta: Option<HashMap<String, serde_json::Value>>,

    /// Physical key mappings
    pub keys: HashMap<String, Key>,

    /// Named macro definitions
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub macros: HashMap<String, serde_json::Value>,

    /// Named condition definitions
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub conditions: HashMap<String, serde_json::Value>,

    /// Available layers
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub layers: Vec<String>,
}

/// Configuration for a physical key
#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct Key {
    /// Action when key is tapped
    pub tap: Action,

    /// Action when key is held
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hold: Option<Action>,

    /// Modifier keys that affect this mapping
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub mods: Vec<String>,

    /// Condition that must be met for this mapping
    #[serde(skip_serializing_if = "Option::is_none")]
    pub when: Option<String>,

    /// Macros associated with this key
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub macros: Vec<String>,
}

/// An action that can be performed
#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
#[serde(untagged)]
pub enum Action {
    /// Simple key output
    Key(String),
    /// Complex action
    Complex(ComplexAction),
}

/// Complex action with multiple possible behaviors
#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct ComplexAction {
    /// Switch to a layer
    #[serde(skip_serializing_if = "Option::is_none")]
    pub layer: Option<String>,

    /// Execute a macro
    #[serde(skip_serializing_if = "Option::is_none")]
    pub macro_name: Option<String>,
}

impl IR {
    /// Create a new empty IR
    pub fn new() -> Self {
        Self {
            meta: None,
            keys: HashMap::new(),
            macros: HashMap::new(),
            conditions: HashMap::new(),
            layers: Vec::new(),
        }
    }

    /// Add a simple key mapping
    pub fn add_key_mapping(&mut self, physical_key: &str, output_key: &str) {
        self.keys.insert(
            physical_key.to_string(),
            Key {
                tap: Action::Key(output_key.to_string()),
                hold: None,
                mods: Vec::new(),
                when: None,
                macros: Vec::new(),
            },
        );
    }
}

impl Default for IR {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_empty_ir() {
        let ir = IR::new();
        assert!(ir.keys.is_empty());
        assert!(ir.macros.is_empty());
        assert!(ir.conditions.is_empty());
        assert!(ir.layers.is_empty());
    }

    #[test]
    fn test_add_key_mapping() {
        let mut ir = IR::new();
        ir.add_key_mapping("a", "b");

        assert_eq!(ir.keys.len(), 1);
        let key = ir.keys.get("a").unwrap();
        match &key.tap {
            Action::Key(k) => assert_eq!(k, "b"),
            _ => panic!("Expected simple key action"),
        }
    }

    #[test]
    fn test_serialize_simple_ir() {
        let mut ir = IR::new();
        ir.add_key_mapping("a", "b");

        let json = serde_json::to_string(&ir).unwrap();
        assert!(json.contains("\"a\""));
        assert!(json.contains("\"b\""));
    }

    #[test]
    fn test_deserialize_simple_ir() {
        let json = r#"{"keys":{"a":{"tap":"b"}}}"#;
        let ir: IR = serde_json::from_str(json).unwrap();

        assert_eq!(ir.keys.len(), 1);
        let key = ir.keys.get("a").unwrap();
        match &key.tap {
            Action::Key(k) => assert_eq!(k, "b"),
            _ => panic!("Expected simple key action"),
        }
    }
}
