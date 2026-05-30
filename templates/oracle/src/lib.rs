// <product>-oracle — TAO eval-infra library.
//
// LLM-FREE (C-DET-2): exposes only the product's reference VOCABULARY used by the
// case generator and the scorer. The scoring authority is the product's own
// deterministic kernel + verifier, not anything in this crate. No model call
// exists anywhere here.

pub mod reference;
