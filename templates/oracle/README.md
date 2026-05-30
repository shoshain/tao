# templates/oracle/ — clone-ready TAO oracle bundle

Copy this whole folder to `<product>/oracle/`, then:

1. Rename every `*.tmpl` to drop the suffix.
2. Replace placeholders: `<PRODUCT>` (display name), `<product>` (crate-prefix, kebab),
   `<product_kernel>` / `<product_shell>` (the product's crates).
3. Fill each `// TODO(product):` hook in `src/bin/oracle_score.rs` with the product's **deterministic
   kernel** (recompute / retrieve / fit) and its **LLM-free verifier**. **No LLM in the scorer.**
4. Fill `src/reference.rs` with the product's standard vocabulary + the anti-gaming `EXCLUDED` set.
5. Curate the held-out cases in `src/bin/gen_oracle_cases.rs`.

| File | Role |
|---|---|
| `Cargo.toml.tmpl` | crate manifest (`publish=false`; path-dep the product crates) |
| `src/lib.rs` | exposes the `reference` module |
| `src/reference.rs.tmpl` | the LLM-free vocabulary + `EXCLUDED` + helpers |
| `src/bin/oracle_score.rs.tmpl` | **the core** — 3-layer scorer + `--self-check`; wire the authority here |
| `src/bin/gen_oracle_cases.rs.tmpl` | deterministic held-out case generator |
| `src/bin/normalize_oracle_proposals.rs` | raw batch → per-case (generic; rarely edited) |
| `src/bin/baseline_proposals.rs.tmpl` | LLM-OFF baseline via the product's own deterministic path |
| `proposer_system.txt.tmpl` | the answer-isolated proposer system prompt |
| `run_proposers.ps1` | answer-isolated Opus-4.8 batch runner (generic; works as-is) |
| `metric.md.tmpl` `gate.md.tmpl` `propose_contract.md.tmpl` `STATE.md.tmpl` | the per-product docs |

Rationale for every choice: `../../METHODOLOGY.md`. Actionable steps: `../../docs/checklist.md`.
The two validated reference implementations are the AIP `FMEDA-Copilot/oracle/` (distribution drafting)
and `DataBook-Bridge/oracle/` (classification) — see `../../examples/`.
