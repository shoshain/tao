# Wiring the Opus 4.8 backend into a product's proposer (TAO v0.2.0)

> **Status:** validated on two surface shapes — MiniSat-Interlock (NL→CNF *enrichment*)
> and waiver-link (waiver→clause *classification*). This is the canonical recipe for
> de-stubbing a product's LLM path so the **shipped product** is genuinely AI-augmented,
> while keeping the scoring authority LLM-free (C-DET-2).
>
> **Caveat:** MiniSat-Interlock, waiver-link, and the file paths cited below (e.g.
> `check_no_llm_in_verifier.py`) live in a private external portfolio, not in this
> repository. They are not included here and are not verifiable standalone from Oracle —
> treat the citations as provenance for the recipe, not as inspectable code.

## The shape of the problem
Most AIP products shipped an "AI" path that was a **stub**: `Ok(vec![])`,
`enrich_sentence -> None`, `return baseline`, or a constant return. Their precision
headline was the **oracle-layer** answer-isolated proposer (a rich `proposer_system.txt`),
**not the product's own code path**. Wiring the real backend turns the shipped product
into a real proposer — and, as a side effect, reveals how good (or weak) the product's
*own* prompt actually is.

## The pattern (a `llm.rs` proposer module)
A single module, compiled out under the `llm_off` feature and OFF by default at runtime.
It shells to the founder's authenticated CLI — **NOT a new API key, NOT Ollama**:

```
claude -p --model opus --permission-mode plan [--output-format text]
```

with the prompt on stdin (or as the `-p` arg). Reference implementations:
`MiniSat-Interlock/shell/src/nl/llm.rs` and `EMBEDDED/waiver-link/shell/src/llm.rs`.

Required properties (all verified at the calibration gate):
1. **Real subprocess.** `std::process::Command::new(claude_bin)` … `.output()` /
   `.spawn()`. Never a canned/hardcoded return. Make the binary + model overridable via
   env (`*_CLAUDE_BIN`, `*_LLM_MODEL`) so the founder can pin a dated alias.
2. **Never fabricates.** Every failure path — CLI absent, non-zero exit, unparsable
   output, off-vocabulary / empty proposal — returns `None` / a below-floor `("",0.0)`,
   so a bad proposal is *dropped*, not mislinked. The model's job is to *propose*; the
   deterministic pipeline decides.
3. **Answer-isolated.** Build the prompt from the **inputs only** (and any closed
   vocabulary). The expected answer, the scorer, and the ground truth NEVER enter the
   module. Run in a throwaway scratch dir (no project context). **Pin this with a unit
   test** (`prompt_does_not_reveal_expected_verdict` / `prompt_is_answer_isolated…`).
4. **Opt-in, default OFF.** Gate behind the product's existing opt-in; keep the
   deterministic/local path as the default build (`#[cfg(not(feature="llm_off"))]` for
   the module; the `llm_off` build is the local-first default).
5. **Raw-output capture = audit proof.** When `*_LLM_CAPTURE_DIR` / `*_LLM_RAW_DIR` is
   set, persist each raw model response to disk. These files are how the orchestrator
   *proves the call was real* — they are load-bearing for the honesty claim.

## ⚠️ Reuse the oracle's PROVEN prompt — "wire the **good** AI"
**The single most important lesson from calibration.** waiver-link's product path scored
**50%** while its oracle-layer proposer scored **96.9%** — same model, same cases. The
only difference was the prompt: the product shipped a terse in-code prompt; the oracle
used a rich `oracle/proposer_system.txt`. **Port the oracle's proven prompt into the
product's `build_prompt`** (regime/domain guidance, the closed vocabulary, the reasoning
hints). Otherwise you will faithfully measure a weak prompt and the product's real
precision will trail its own oracle number. If you deliberately keep a leaner prompt,
SAY SO and report the gap as a finding — do not silently ship the weaker number.

## Honest precision_bench (the product's OWN path)
Add/replace `precision_bench` so it:
1. Runs the product's **own** end-to-end path with the opt-in LLM ON over a **real
   on-disk held-out set** — reuse the product's TAO `oracle/cases/` as that set.
2. **Captures the proposals to disk once** (a live LLM is NOT byte-identical across
   runs — capture once; re-running the model re-rolls).
3. Scores the captured proposals with the product's **own LLM-free verifier / recompute**
   (the unchanged `oracle_score`). The SCORER over fixed proposals stays byte-identical.
4. Reports the product-path **LLM-ON** number next to the **LLM-OFF** deterministic
   baseline. **RETRACT the phantom headline** in the manifests/docs (e.g. waiver-link's
   "82% / 41-of-50" → gone), and cite the real measured number with its gate status.

**LLM-ON may be N/A even after wiring.** MiniSat's eval set triggered the enrichment
path zero times (the rule engine matched all 100), so the LLM was genuinely never
called. The agent proved 0 raw files and reported LLM-ON as *not measurable on this set*
rather than inventing a number. **That is the correct behavior.** Honest-N/A > a faked %.

## C-DET-2: keep the verifier LLM-free, and PROVE it
The LLM lives in the proposer; the verifier/scorer must never call a model. Ship/keep a
real static guard (reference: `waiver-link/.spec/scripts/check_no_llm_in_verifier.py`):
scan every verifier source file for a FORBIDDEN token set — the proposer `llm` module,
`infer_clause`/`enrich_sentence`, `ollama`/`anthropic`/`openai`/`claude -p`,
`Command::new`/`std::process`, `reqwest`/`hyper`, `SystemTime::now`/`Instant::now`,
`rand::` — and **fail closed** (exit 1 on any hit, exit 2 if the verifier dir is missing,
exit 0 only when clean). A guard that can only ever pass is worthless; it must be able to
fail. Wire it into CI (`ci-shell.yml`).

## Orchestrator verification checklist (every wired product)
- [ ] `llm.rs` makes a real `claude -p --model opus` call; no canned return.
- [ ] Raw outputs on disk prove the path ran (or honest-N/A with 0 files + explanation).
- [ ] Answer-isolation unit test present and green.
- [ ] precision_bench measures the product's OWN path; the number is a real measurement
      (per-case report, not a constant), LLM-ON beside LLM-OFF.
- [ ] Phantom headline retracted in manifests/docs.
- [ ] C-DET-2 guard exists, is a real check, and exits 0.
- [ ] `cargo test --workspace` / `pytest` exits 0; clippy/fmt clean.
- [ ] If the product path trails its oracle-layer number, the gap is reported (prompt
      reuse considered), not hidden.
- [ ] Everything LOCAL/uncommitted (founder commits).
