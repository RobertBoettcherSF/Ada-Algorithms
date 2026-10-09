# Bloom-Filter (SPARK)

A 64-bit Bloom filter over `Natural` keys with two hash functions,
`H1 (K) = K mod 64` and `H2 (K) = (K / 7) mod 64`. `Insert` sets both
bits; `Might_Contain` is True when both bits are set. An inserted key is
always reported (no false negatives); other keys can be reported too
(false positives, e.g. 490 after inserting 42). The full Ada version with
sizing formulas is `hashing/Ada/Bloom-Filter`.

## Verification

```text
make test    # -gnatwa -gnat2022 -gnata
make prove   # Level 2, cvc5
```

Own checks: `own_checks.adb`, sources in `tests/SOURCES.txt`.
