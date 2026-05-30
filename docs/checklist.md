# TAO adoption checklist (per product)

The recipe from `../METHODOLOGY.md` §4, made tickable. Copy into your product's oracle work.

## 0. Prereqs
- [ ] The product has a **deterministic kernel** (recompute / retrieve / fit) and an **LLM-free verifier**.
- [ ] Both are callable from a sibling crate (intra-workspace path dependency).

## 1. Scaffold
- [ ] Copy `templates/oracle/` → `<product>/oracle/` (or run `scripts/new-oracle.ps1`).
- [ ] Add `"oracle"` to the workspace `members`; set `publish = false`; path-dep the product crates.
- [ ] Rename `*.tmpl` → real files; fill placeholders (`<PRODUCT>`, deps, types).

## 2. Define the layers (`reference.*`)
- [ ] **Deterministic:** identify the load-bearing exact value(s) — the no-fabrication target.
- [ ] **Standard:** enumerate the allowed/standard vocabulary; cite public clauses, never redistribute
      licensed text.
- [ ] Add the anti-gaming **`EXCLUDED`** set (e.g. an outcome posing as a mechanism).
- [ ] **Judgmental** (optional): a reference for a soft band — mark `signoff: pending-founder`.

## 3. Scorer (`oracle_score`)
- [ ] Wire the product's recompute/retrieve + `verify` as the authority. **No LLM.**
- [ ] `PASS = deterministic ∧ standard`. Judgmental is reported, **not** gated.
- [ ] Implement `--self-check`: correct→PASS; **fabricated number→FAIL (det)**; invented label→FAIL (std).
- [ ] Confirm re-score is **byte-identical** (fixed `--ran-at`; compare SHA-256).

## 4. Cases + data (`gen_oracle_cases`)
- [ ] Curate a held-out set spanning **easy / medium / hard**; expected answers defensible.
- [ ] Generate reference data; **SYNTHETIC + clearly marked** where the real source is licensed/private.
- [ ] `input.json` = inputs ONLY (answer-isolated). `expected.json` is never shown to the proposer.

## 5. Measure
- [ ] **LLM-OFF baseline:** score the product's own deterministic/keyword path.
- [ ] **LLM-ON:** `run_proposers.ps1` (Opus 4.8, inputs-only, scratch cwd, `--permission-mode plan`)
      → `normalize_oracle_proposals` → `oracle-score`.
- [ ] If the first score reveals a **metric gap** (not an AI error): exactly ONE anti-p-hacked round-2
      (`../CONTRIBUTING.md` §3).

## 6. Report + sign-off
- [ ] Record LLM-ON precision + **layer decomposition** NEXT TO the LLM-OFF number
      (`INSPECTION_BUNDLE.md` / `docs/SCOPE_AND_CLAIMS.md`).
- [ ] **Founder signs** the gate threshold and any borderline ground-truth calls.
- [ ] Honesty gate: only the measured number (with decomposition) may be cited — never a stub constant.

## Red flags (stop and fix)
- [ ] Scorer imports anything that can call a model → **STOP** (C-DET-2 violation).
- [ ] `--self-check` can't fail a wrong answer → the metric is a rubber stamp.
- [ ] The headline moved because you re-ran the AI, not because of a justified metric fix → **p-hacking**.
- [ ] A "N-sample test set" exists in a manifest but **not as files on disk** → the number was never measured.
