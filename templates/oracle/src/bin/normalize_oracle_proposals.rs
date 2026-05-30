// normalize_oracle_proposals — convert raw LLM batch responses
// (_batch-N-raw.txt) into clean per-case proposal files. Generic; the only
// product-specific part is the scored field name + its accepted aliases.

use anyhow::Result;
use clap::Parser;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Parser, Debug)]
struct Cli {
    #[arg(long, default_value = "oracle/proposals")]
    proposals: PathBuf,
}

#[derive(Deserialize)]
struct RawBatch {
    proposals: Vec<RawProposal>,
}
#[derive(Deserialize)]
struct RawProposal {
    case_id: String,
    // TODO(product): the scored field + the aliases the model might emit.
    #[serde(default, alias = "class", alias = "taxonomy_class", alias = "predicted")]
    value: String,
}
#[derive(Serialize)]
struct Out {
    value: String,
}

fn extract_json(raw: &str) -> Option<&str> {
    let start = raw.find('{')?;
    let end = raw.rfind('}')?;
    if end > start {
        Some(&raw[start..=end])
    } else {
        None
    }
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    let mut batches: Vec<PathBuf> = fs::read_dir(&cli.proposals)?
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|p| {
            p.file_name()
                .and_then(|n| n.to_str())
                .map(|n| n.starts_with("_batch-") && n.ends_with("-raw.txt"))
                .unwrap_or(false)
        })
        .collect();
    batches.sort();
    anyhow::ensure!(!batches.is_empty(), "no _batch-*-raw.txt in {}", cli.proposals.display());

    let mut written = 0usize;
    for bf in &batches {
        let raw = fs::read_to_string(bf)?;
        let Some(j) = extract_json(&raw) else {
            eprintln!("WARN: no JSON object in {}", bf.display());
            continue;
        };
        let batch: RawBatch = match serde_json::from_str(j) {
            Ok(b) => b,
            Err(e) => {
                eprintln!("WARN: parsing {}: {e}", bf.display());
                continue;
            }
        };
        for p in batch.proposals {
            fs::write(
                cli.proposals.join(format!("{}.json", p.case_id)),
                serde_json::to_string_pretty(&Out { value: p.value })? + "\n",
            )?;
            written += 1;
        }
    }
    println!("Normalized {written} proposals.");
    Ok(())
}
