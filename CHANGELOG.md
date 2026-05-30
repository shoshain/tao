# Changelog

All notable changes to the **Tolerance-Aware Oracle (TAO)** methodology are recorded here.
Format follows *Keep a Changelog*; the method is versioned per `CONTRIBUTING.md` (§Versioning).

## [0.1.0] — 2026-05-30
### Added
- Initial extraction of TAO from the AIP portfolio's Phase-2 LLM-ON measurement work.
- `METHODOLOGY.md`: the three pillars (answer-isolated proposal; product-as-oracle LLM-free scoring;
  type-stratified tolerance), the supporting honesty disciplines, and the per-product recipe.
- `templates/oracle/`: clone-ready oracle-crate skeleton (`oracle_score`, `gen_oracle_cases`,
  `normalize_oracle_proposals`, `baseline_proposals`, `reference`) + markdown templates
  (`metric`/`gate`/`propose_contract`/`STATE`) + answer-isolated `run_proposers.ps1` + proposer prompt.
- `docs/checklist.md` (actionable adoption recipe) and `docs/glossary.md` (terms + naming rationale).
- `examples/`: two validated worked examples.
- `scripts/new-oracle.ps1`: scaffolds an `oracle/` bundle into a target product.

### Validated
- **FMEDA-Copilot** (open-ended distribution drafting): LLM-ON **96.0%** (48/50), gate ≥80% PASS.
  Surfaced the round-2 catalogue discipline (50→86→96 on the SAME proposals, anti-p-hacked).
- **DataBook-Bridge** (closed-vocabulary classification + verbatim retrieval): LLM-ON **97.7%** (43/44)
  vs **50.0%** LLM-OFF keyword baseline, gate ≥90% PASS, on the first scored run (no round-2 needed).

### Notes
- Engine fixed by founder to **Claude Opus 4.8 at max** (never Haiku/Ollama); scorer is **LLM-free**.
