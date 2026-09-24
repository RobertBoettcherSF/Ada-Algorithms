# Ada/SPARK FNV-1a Hash

A bounded Fowler-Noll-Vo 32-bit FNV-1a hash over Ada characters. The modular hash
type makes wraparound explicit and avoids unchecked integer overflow.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).
