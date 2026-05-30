# Example — DataBook-Bridge (closed-vocabulary *classification + verbatim retrieval*)

**Task shape.** The AI classifies a free-text part description into a taxonomy
class; a deterministic retriever copies the λ **verbatim** from the databook; five
verifiers enforce no-fabrication. The AI never emits a number.

**Layer mapping.**
- **Deterministic** — the proposed class, fed to the product's `retrieve_verbatim`,
  returns the **bit-identical** expected `row_id` + λ; `verify()` accepts (the λ
  exists verbatim in the source — `lambda_not_in_source` / `fabricated_row_id`).
- **Standard** — class ∈ the taxonomy vocabulary (+ the `unclassified` sentinel).
- **Judgmental** — *family match* (right component family, wrong granularity) —
  diagnostic.

**Result (Opus 4.8, N=44).** LLM-ON **`97.7%`** (43/44) vs LLM-OFF keyword baseline
**`50.0%`** (22/44), same scorer. det 43/44, std **44/44** (zero invented labels),
family-match **44/44**. Gate ≥90% **PASS on the first scored run — no round-2
needed**.

**Lessons.**
- A **closed-vocabulary classification** task has no open-ended-naming gap → the
  round-2 catalogue step that FMEDA needed does not arise. The method adapts to the
  task shape.
- The 1 miss (`case-04` metal-foil resistor → `resistor-general` vs expected
  `resistor-thin-film`) is a **defensible granularity call** (family-correct),
  flagged for founder re-filing — not noise.
- The strongest discrimination probe is the **no-fabrication self-check**: a
  hand-built citation whose λ is not in the databook is **rejected by the real
  `verify()`**.
- Reference implementation: AIP `RELIABILITY/DataBook-Bridge/oracle/`.
