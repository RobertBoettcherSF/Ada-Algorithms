# Ada-SPARK-UTF-8-Validation

UTF-8 validation (RFC 3629): `Is_Valid` accepts exactly the well-formed byte sequences, rejecting truncated sequences, stray continuation bytes, overlong forms, surrogates (U+D800..U+DFFF) and code points above U+10FFFF. Any lower bound. The Post states validity locally (every byte starts a well-formed sequence or is a continuation inside one), proved at mode all, level 2.

`make test` compares against an independent decoder (bit patterns, code point accumulation, overlong/surrogate/range checks) on every 1-, 2- and 3-byte array, every 4-byte array over 27 boundary bytes, every lead F0..FF with every second byte (third/fourth byte 7F, 80, BF, C0), and 200,000 seeded random arrays (seed 20261009).

- `make test` builds and runs assertions.
- `make prove` runs level-2 CVC5 proofs with warnings and checks treated as errors.
