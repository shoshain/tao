# Contributing to / improving the Tolerance-Aware Oracle (TAO)

TAO is a *measurement method*. Its value is entirely in being **trustworthy**, so the bar for changes is
not "does it make the code nicer" but "**does it preserve the integrity properties**." Read this before
changing `METHODOLOGY.md`, the templates, or a product's scorer.

## Prime directive — the four invariants a change must NOT break

1. **LLM-free scoring (C-DET-2).** No model may enter the scoring path, ever. The oracle's authority is the
   product's own deterministic kernel + verifier. A change that adds a model to scoring is rejected.
2. **The scorer must discriminate.** `--self-check` must still fail a fabricated number (deterministic) and
   an off-catalogue / invented value (standard). If a change makes a wrong answer pass, it is a bug.
3. **No p-hacking.** A metric/data change (e.g. widening a catalogue) is legitimate ONLY if every added
   entry is independently justified as *the same meaning under a different form*, the anti-gaming `EXCLUDED`
   set still rejects real mislabels, you **re-score the SAME proposals (never re-roll)**, and you **report
   the before and after numbers**. Tuning until the headline is flattering is forbidden.
4. **The founder signs the gate, not the agent/contributor.** Proposals may *recommend* a gate threshold or
   a borderline ground-truth ruling; only the founder ratifies it into a release number.

A change that improves any of (1)–(4) — e.g. a stronger discrimination self-check, a new anti-gaming
exclusion, a tighter reproducibility check — is always welcome.

## Versioning (the method, in `CHANGELOG.md`)

- **MAJOR** — changes the definition of PASS, the pillars, or what may be cited (semantic break).
- **MINOR** — adds support for a new task shape, a new template, or an *additive* layer/diagnostic.
- **PATCH** — clarifications, doc fixes, template ergonomics, non-semantic refactors.

Every change updates `CHANGELOG.md`. Keep the portfolio mirror
(`C:\AIP\TOLERANCE_AWARE_ORACLE_METHODOLOGY.md`) pointing at this canonical copy; don't let them drift on
substance.

## How to add a new worked example (recommended way to grow confidence)

The strongest contribution is a **new task shape** validated end-to-end. Add `examples/<product>.md` with:
the task shape, how the three layers were mapped, the LLM-OFF and LLM-ON numbers, whether a round-2 was
needed and why, and the residual-failure analysis (genuine error vs defensible borderline). Two shapes are
validated so far (distribution-drafting, classification+retrieval); good next shapes to prove: **numeric
model fit** (e.g. RGCanary) and **structured extraction**.

## How to evolve the templates

`templates/oracle/` is a *skeleton*, not a framework. Keep it small and copy-friendly. Every product-specific
hook is marked `TODO(product)`; keep those markers obvious. Prefer adding a worked example over adding
template abstraction.

## Repo hygiene

- MIT-licensed; keep `LICENSE` intact and set the copyright holder to suit.
- `git` history should read as method evolution: one logical change per commit, CHANGELOG updated.
- The `*.tmpl` files are intentionally not compiled here — they compile once copied into a product and the
  `TODO(product)` hooks are filled.
