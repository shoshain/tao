# The Tolerance-Aware Oracle (TAO) — v0.1.0

> **A method for measuring the precision of "AI-proposes / deterministic-core-verifies" tools —
> by scoring the AI against the product's _own_ deterministic truth, one ground-truth layer at a time.**

- **Canonical home:** this repository (`C:\Oracle`, `METHODOLOGY.md`). Versioned in `CHANGELOG.md`;
  improve it via `CONTRIBUTING.md`. Mirrored for portfolio convenience at
  `C:\AIP\TOLERANCE_AWARE_ORACLE_METHODOLOGY.md`.
- **Status:** validated on 2 pilots (FMEDA-Copilot, DataBook-Bridge), 2026-05-30.
- **Engine (founder decision, 2026-05-30):** the proposing AI is **Claude Opus 4.8 at max**, never
  Haiku/Ollama. The scorer contains **no model at all**.

---

## 0. Why a name, and why this one

The thing we kept building had no name, so it kept getting confused with two weaker things it is *not*:
LLM-as-judge grading, and "compare the output to one hardcoded golden value." Naming it fixes that.

**Tolerance-Aware Oracle (TAO):**
- **Oracle** — the scorer is an *oracle* in the testing sense: a trusted authority that decides
  pass/fail. Crucially, **the oracle is the product's own deterministic kernel + verifier**, not a model
  and not a constant. The product grades the AI.
- **Tolerance-Aware** — the distinctive move: a drafted answer is **not one thing with one right answer**.
  It is several layers, each with a *different kind* of ground truth. TAO scores each layer by its **own
  type and its own tolerance**, instead of demanding bit-exactness on an open-ended judgement (a
  meaningless 0%) or rubber-stamping everything (a meaningless 100%).

Short handle: **"product-as-oracle precision."**

---

## 1. The problem TAO solves

Three failure modes we observed, each of which TAO rules out:

1. **The hardcoded-constant stub.** A `precision_bench` that writes a fixed headline (e.g. `87.0` / `92.0`)
   to a report **without executing anything**. A precision number that is a string literal is not a
   measurement. (Found, independently, in two products.)
2. **The bit-exact trap.** Demanding the output be *bit-identical* to one reference. A perfectly defensible
   AI draft scores **0.0%** because the metric measures *memorisation of one table*, not quality, on a task
   that has many correct answers. Widening a band until 0% becomes flattering would be gaming.
3. **The LLM judge.** Using a second model to grade the first: non-deterministic, non-reproducible, and
   un-defensible in a functional-safety context (it puts an LLM in the scoring path — forbidden by the
   portfolio constitution's **C-DET-2**).

---

## 2. The three pillars

### Pillar I — Answer-Isolated Proposal
The proposing AI runs in a **fresh process with zero shared context** (`claude -p --model opus
--permission-mode plan` in a throwaway scratch dir) and is given **only the inputs** a user would supply —
never the expected answer, the reference distribution, the allowed-value catalogue, or the scorer source.
It physically *cannot* read the answer off disk. Proposals are produced in batches; raw output is kept for
audit, then normalized into per-case files.

### Pillar II — Product-as-Oracle Scoring (LLM-free)
The scorer reuses the **product's own deterministic authority** as the source of truth — and **nothing
else**. No model is invoked anywhere in scoring (**C-DET-2**). The scorer is deterministic and **re-scores
byte-identically** (verify by SHA-256). The same kernel the product ships to the customer is the kernel
that grades the AI, so the measurement is exactly as trustworthy as the product itself.

### Pillar III — Type-Stratified Tolerance
The answer is decomposed into layers, and **each layer is scored by its own ground-truth type**:

| Layer | Ground-truth type | Tolerance | Gated? | Authority (example) |
|---|---|---|---|---|
| **Deterministic** | exact | bit-identical (`f64::to_bits`), plus a documented order-stability bound only where the product itself claims one; the verifier must accept | **YES** | the product's recompute / retrieve kernel + its verifier |
| **Standard-derived** | set-membership | the value is *in* the standard/allowed set (case/separator-normalised) — not one exact string | **YES** | published-clause catalogues / the product's taxonomy |
| **Judgmental** | banded / soft | within a documented band of a reference | **NO — reported only** | an agent-seeded reference, `signoff: pending-founder` |

**Per-case PASS = (Deterministic ∧ Standard)** — the layers with genuine product/standard authority. The
judgmental layer is **reported, never gated**: gating on an unsigned reference would be arbitrary.

```
precision_pct = 100 × (#cases PASS) / (#cases scored)
```

The headline is **never** read without its layer decomposition.

---

## 3. The supporting disciplines (what keeps the number honest)

- **Discrimination self-check.** Before any measurement is trusted, `--self-check` proves the scorer
  *bites*: a canonical/correct answer PASSes; a **fabricated number** FAILs (deterministic); an
  **off-catalogue / invented label** FAILs (standard). If the scorer can't fail a deliberately-wrong
  answer, its passes are worthless.
- **Anti-gaming exclusions.** The standard catalogues carry an explicit `EXCLUDED` set (e.g. an *outcome*
  posing as a *mechanism*). Real mislabels must keep failing even after legitimate catalogue growth.
- **Anti-p-hacking re-scoring.** When a *metric/data gap* is found (the catalogue was too narrow for a
  legitimate synonym), you (a) add **only** independently-justified, same-meaning entries, (b) keep the
  exclusions, (c) **re-score the SAME proposals — never re-roll the AI**, and (d) **report both the before
  and after numbers**. Genuine errors must still fail after the fix (proof the layer still discriminates).
- **Reproducibility.** Re-scoring the same proposals yields a byte-identical report (fixed timestamp).
- **LLM-OFF baseline beside LLM-ON.** The product's deterministic/keyword path is scored by the *same*
  oracle, so every LLM-ON number is reported next to a like-for-like LLM-OFF number.
- **Founder ratifies the bar, not the agent.** The agent surfaces borderline ground-truth calls and a
  *proposed* gate; the **founder signs** the gate threshold and rules on borderline cases. The agent never
  grades itself into a release number.
- **Honesty gate.** Sales/inspection may cite **only the measured number with its decomposition** — never
  a bare headline, never a stub constant.

---

## 4. The repeatable recipe (per product)

```
1. Map the product's deterministic authority (its recompute/retrieve/fit kernel + its LLM-free verifier).
2. Build an `oracle/` crate that reuses that authority as the scorer (publish=false; path deps).
3. Define the type-stratified layers + a discrimination --self-check; prove it discriminates.
4. Generate a curated held-out set (deterministic, idempotent) + reference data.
   - Use SYNTHETIC reference data where the real source is licensed/private; mark it clearly.
5. Score the LLM-OFF baseline (the product's own deterministic path).
6. Run answer-isolated Opus-4.8 proposers (inputs-only) -> normalize -> score LLM-ON.
7. If the first score reveals a *metric* gap (not an AI error): one justified, anti-p-hacked re-score.
8. Record LLM-ON precision + full layer decomposition NEXT TO the LLM-OFF number; founder signs the gate.
```

The actionable checklist form is [`docs/checklist.md`](docs/checklist.md); the clone-ready code +
doc templates are in [`templates/oracle/`](templates/oracle/).

---

## 5. Evidence — two pilots, two task shapes, both pass

| Pilot | Task shape | LLM-ON (Opus 4.8) | LLM-OFF baseline | Gate | Round-2 needed? |
|---|---|---|---|---|---|
| **FMEDA-Copilot** | open-ended **distribution drafting** | **96.0%** (48/50) | 87% fixture (was a stub) | ≥80% ✅ | yes — justified mode-synonym catalogue growth (50→86→96) |
| **DataBook-Bridge** | closed-vocabulary **classification + verbatim retrieval** | **97.7%** (43/44) | 50.0% (keyword classifier) | ≥90% ✅ | **no** — gate cleared on the first scored run |

The second pilot proved what the first could not: **TAO generalises across task shapes.** It also showed the
method adapts *to the task* — the "catalogue round-2" step is only needed for open-ended naming (FMEDA), not
for closed-vocabulary classification (DataBook). In both pilots the residual failures were **either genuine
errors the oracle correctly caught, or a single defensible borderline call** flagged for founder sign-off —
never noise. Details: [`examples/`](examples/).

---

## 6. What TAO does and does NOT claim

- **Does measure:** does an answer-isolated draft (a) never fabricate/alter a load-bearing number and stay
  internally consistent (deterministic), and (b) stay within the standard/allowed vocabulary (standard)?
  I.e. **drafting hygiene + non-fabrication.**
- **Does NOT claim:** that the draft is *certified accurate*, or that the reference data is itself correct.
  A high TAO precision means **"non-fabricating and standard-correct,"** not "certified."
- **Out of scope (still human/founder):** tool qualification (IEC 61508-3 §7.4.4 / ISO 26262-8 §11),
  signing the judgmental reference, swapping synthetic reference data for the real source, and setting the
  gate threshold.

---

## 7. One-paragraph definition (for reuse)

> **The Tolerance-Aware Oracle (TAO)** is a precision-measurement method for tools where an AI *proposes*
> and a deterministic core *verifies*. A fresh, answer-isolated LLM (Opus 4.8) produces proposals from
> inputs only; the product's **own** deterministic kernel and LLM-free verifier — never a model, never a
> hardcoded constant — score each proposal. Ground truth is **stratified by type**: a *deterministic* layer
> scored bit-exactly (no fabrication), a *standard* layer scored by set-membership (in-vocabulary), and a
> *judgmental* layer scored against a soft, documented band that is **reported but not gated** because its
> reference is unsigned. A case passes iff the deterministic and standard layers pass; precision is the pass
> rate, always reported with its layer decomposition, beside an LLM-OFF baseline, reproducibly, after a
> self-check proves the scorer can fail a wrong answer — and the founder, not the agent, signs the gate.
