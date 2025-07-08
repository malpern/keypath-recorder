use crate::{Result, IR};

/// Export IR to Kanata format
pub fn export_kanata(_ir: &IR) -> Result<String> {
    let mut output = String::new();

    // Basic Kanata structure
    output.push_str("(deflayer base\n");

    // For now, just export a simple base layer
    // TODO: Implement full Kanata export logic

    output.push_str(")\n");

    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_export_basic_kanata() {
        let ir = IR::new();
        let result = export_kanata(&ir).unwrap();

        assert!(result.contains("(deflayer base"));
        assert!(result.contains(")"));
    }
}
