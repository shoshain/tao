# Glossary + naming rationale

## Why "Tolerance-Aware Oracle"?

Two weaker things this method is constantly confused with — and rejected in favour of:

- **LLM-as-judge.** A second model grades the first. Rejected: non-deterministic, non-reproducible, and
  it puts an LLM in the scoring path (forbidden by **C-DET-2**); indefensible for functional safety.
- **Golden-value / bit-exact match.** Compare the output to one hardcoded "correct" answer. Rejected: on
  open-ended tasks (a failure-mode distribution, a classification) there are many correct answers, so this
  measures *memorisation of one table* and reads a meaningless 0%.

TAO keeps the good half of each — a **trusted, deterministic oracle** (like golden-value) that is **tolerant
of legitimate variation** (unlike golden-value) — by making the **product's own kernel** the oracle and
scoring **each layer by its own ground-truth type**. Hence *Tolerance-Aware* (the layered tolerance) +
*Oracle* (the product-as-authority scorer). Short handle: **"product-as-oracle precision."**

## Terms

- **Oracle** — the trusted pass/fail authority. In TAO it is the product's own deterministic kernel +
  LLM-free verifier, never a model or a constant.
- **Answer isolation** — the proposing AI sees only the inputs a user supplies; never the expected answer,
  the reference, the allowed-value catalogue, or the scorer. Enforced by a fresh `claude -p` process in a
  throwaway scratch dir under `--permission-mode plan`.
- **Deterministic layer** — the exact, load-bearing value(s) (e.g. a carried-through λ, a retrieved row).
  Scored bit-identically; the no-fabrication guarantee lives here.
- **Standard-derived layer** — the standard/allowed vocabulary (modes, categories, taxonomy classes).
  Scored by **set-membership** (normalised), not by one exact string.
- **Judgmental layer** — an open-ended judgement (a distribution shape → SFF/DC) compared to a soft band.
  **Reported, never gated**, because its reference is unsigned (`signoff: pending-founder`).
- **PASS** — `deterministic ∧ standard`. **Precision** — the pass rate over the held-out set.
- **Gate** — the precision threshold a release must meet. *Proposed* by the agent, **signed by the founder**.
- **LLM-OFF baseline** — the product's own deterministic/keyword path, scored by the same oracle, reported
  beside the LLM-ON number.
- **Discrimination self-check** — `--self-check`: proves the scorer can fail a deliberately-wrong answer
  before any measurement is trusted.
- **`EXCLUDED` set** — anti-gaming list: values that look valid but aren't (an outcome posing as a
  mechanism). Must keep failing after legitimate catalogue growth.
- **Round-2 / anti-p-hacking re-score** — fixing a *metric* gap by adding only justified same-meaning
  entries, keeping `EXCLUDED`, re-scoring the **same** proposals (no re-roll), and reporting before/after.
- **C-DET-2** — the portfolio constitution clause forbidding any LLM in the verification/scoring path.
- **Honesty gate** — only the measured number, with its layer decomposition, may be cited; never a stub
  constant or a bare headline.
