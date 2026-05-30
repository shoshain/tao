# Example — FMEDA-Copilot (open-ended *distribution drafting*)

**Task shape.** The AI drafts each component's failure-mode distribution
(`{mode, fraction, category, diagnostic_coverage}`) from a BOM. A deterministic
Kahan-summed recompute + a 5-class verifier are the authority.

**Layer mapping.**
- **Deterministic** — every component λ carried through **bit-identical** (no
  fabrication) + `recompute(lambda_total)` bit-identical (within the product's own
  Kahan order-stability bound) + the 5-verifier chain accepts.
- **Standard** — every `mode_id` ∈ `allowed_modes(class)`; every category ∈ the
  IEC 61508-2 four-set; fractions sum to 1.0 ± 1e-6.
- **Judgmental** — `|SFF/DC − reference|` band — **diagnostic only** (reference
  distribution `pending-founder`).

**Result (Opus 4.8, N=50).** `50.0%` (round-1 catalogue) → `86.0%` (added justified
mode synonyms, **same proposals re-scored**) → **`96.0%`** (founder ratified the
borderline `watchdog-safe-reset`). det 50/50, std 48/50. Residual 2 = genuine
`safe-benign-failure` mislabels (a category posing as a mode — **correctly
rejected**).

**Lessons.**
- Open-ended **naming** needs a round-2 catalogue pass (legitimate same-mechanism
  synonyms) — done under strict anti-p-hacking (justify each, keep `EXCLUDED`,
  re-score the same proposals, report before/after).
- The `EXCLUDED` guard (`safe-benign-failure`) keeps real mislabels failing → the
  layer still discriminates after the fix.
- Reference implementation: AIP `RELIABILITY/FMEDA-Copilot/oracle/`.
