# Oracle — the Tolerance-Aware Oracle (TAO)

> A reusable **method + toolkit** for measuring the precision of *"AI proposes /
> deterministic-core verifies"* tools — by scoring the AI against the product's
> **own** deterministic truth, one ground-truth layer at a time.

This repository is the canonical, versioned, improvable home of the TAO method.
It was extracted on 2026-05-30 from the AIP portfolio's Phase-2 LLM-ON work after
the method was validated on two products with two different task shapes.

## Start here

| You want to… | Read |
|---|---|
| Understand the method | [`METHODOLOGY.md`](METHODOLOGY.md) |
| Adopt it in a product | [`docs/checklist.md`](docs/checklist.md) + [`templates/oracle/`](templates/oracle/) |
| Learn the vocabulary / why the name | [`docs/glossary.md`](docs/glossary.md) |
| See it work | [`examples/`](examples/) — FMEDA-Copilot **96%**, DataBook-Bridge **97.7%** |
| Improve the method | [`CONTRIBUTING.md`](CONTRIBUTING.md) + [`CHANGELOG.md`](CHANGELOG.md) |

## What's here

```
Oracle/
  METHODOLOGY.md            # the canonical TAO definition (the spec)
  README.md  LICENSE  CHANGELOG.md  CONTRIBUTING.md  .gitignore
  docs/
    checklist.md            # per-product adoption checklist (the recipe, actionable)
    glossary.md             # terms + the naming rationale
  templates/oracle/         # a clone-ready oracle/ bundle (copy into <product>/oracle/)
    Cargo.toml.tmpl  src/...  *.md.tmpl  proposer_system.txt.tmpl  run_proposers.ps1
  examples/
    fmeda-copilot.md         # worked example — open-ended distribution drafting
    databook-bridge.md       # worked example — closed-vocabulary classification
  scripts/
    new-oracle.ps1           # scaffold an oracle/ into a target product from the templates
```

## Quickstart — adopt TAO in a new product

1. **Scaffold:** `pwsh scripts/new-oracle.ps1 -Product <name> -Into <path-to-product-repo>`
   (or copy `templates/oracle/` to `<product>/oracle/` and rename the `*.tmpl` files).
2. **Wire the authority:** in `oracle_score`, replace the `// TODO(product)` hooks with the
   product's *own* deterministic kernel (recompute / retrieve / fit) and its LLM-free verifier.
   **No LLM in the scorer.**
3. **Define the layers:** fill `reference.*` with the product's standard/allowed vocabulary; keep the
   anti-gaming `EXCLUDED` set.
4. **Generate** a curated held-out set (`gen_oracle_cases`) + reference data (synthetic where the real
   source is licensed; mark it clearly).
5. **Prove it discriminates:** `oracle-score --self-check` (correct→PASS, fabricated/invalid→FAIL).
6. **Measure:** score the LLM-OFF baseline, then run answer-isolated Opus-4.8 proposers
   (`run_proposers.ps1`) → normalize → score LLM-ON. Report both numbers + the layer decomposition.
7. **Founder signs** the gate threshold and any borderline ground-truth calls.

The full rationale for every step is in [`METHODOLOGY.md`](METHODOLOGY.md); the actionable form is
[`docs/checklist.md`](docs/checklist.md).

## Status

**v0.1.0** — validated on two pilots (two task shapes); see [`CHANGELOG.md`](CHANGELOG.md). MIT-licensed.

## Reference implementations

The two pilots are the best living reference code (in the AIP monorepo):
`RELIABILITY/FMEDA-Copilot/oracle/` and `RELIABILITY/DataBook-Bridge/oracle/`. The `examples/` here
summarize each; clone the templates here for a fresh start.
