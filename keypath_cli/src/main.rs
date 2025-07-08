use clap::{Parser, Subcommand};
use keypath_core::{export_kanata, generate_schema, parse_ir, to_pretty_json};
use std::fs;
use std::path::PathBuf;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Validate a keypath IR file
    Validate {
        /// Path to the IR file
        file: PathBuf,
    },
    /// Pretty-print a keypath IR file
    Pretty {
        /// Path to the IR file
        file: PathBuf,
    },
    /// Export IR to Kanata format
    Export {
        /// Path to the IR file
        file: PathBuf,
        /// Output path for .kbd file
        #[arg(short, long)]
        output: Option<PathBuf>,
    },
    /// Generate JSON schema for IR format
    Schema {
        /// Output path for schema file
        #[arg(short, long)]
        output: Option<PathBuf>,
    },
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();

    match args.command {
        Commands::Validate { file } => {
            let content = fs::read_to_string(&file)?;
            match parse_ir(&content) {
                Ok(_) => {
                    println!("✅ {} is valid", file.display());
                    Ok(())
                }
                Err(e) => {
                    eprintln!("❌ {} is invalid: {}", file.display(), e);
                    std::process::exit(1);
                }
            }
        }
        Commands::Pretty { file } => {
            let content = fs::read_to_string(&file)?;
            let ir = parse_ir(&content)?;
            let pretty = to_pretty_json(&ir)?;
            fs::write(&file, pretty)?;
            println!("✅ {} formatted", file.display());
            Ok(())
        }
        Commands::Export { file, output } => {
            let content = fs::read_to_string(&file)?;
            let ir = parse_ir(&content)?;
            let kanata = export_kanata(&ir)?;

            let output_path = output.unwrap_or_else(|| file.with_extension("kbd"));

            fs::write(&output_path, kanata)?;
            println!("✅ Exported to {}", output_path.display());
            Ok(())
        }
        Commands::Schema { output } => {
            let schema = generate_schema()?;

            let output_path = output.unwrap_or_else(|| PathBuf::from("ir_schema.json"));

            fs::write(&output_path, schema)?;
            println!("✅ Schema generated: {}", output_path.display());
            Ok(())
        }
    }
}
