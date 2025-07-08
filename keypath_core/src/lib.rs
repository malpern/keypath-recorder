pub mod bridge;
pub mod export;
pub mod ir;
pub mod schema;
pub mod validation;

#[cfg(test)]
mod integration_tests;

pub use export::export_kanata;
pub use ir::{Action, Key, IR};
pub use schema::{generate_schema, validate_json_schema};
pub use validation::{parse_ir, to_pretty_json};

pub type Result<T> = anyhow::Result<T>;

#[derive(Debug, thiserror::Error)]
pub enum KeypathError {
    #[error("Invalid IR format: {0}")]
    InvalidIR(String),

    #[error("Schema validation failed: {0}")]
    SchemaValidation(String),

    #[error("Export failed: {0}")]
    ExportFailed(String),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
}
