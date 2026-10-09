# Ada/SPARK Pearson Hashing

Pearson hashing (Pearson 1990): $h_0 = 0$, $h_i = T[h_{i-1} \oplus c_i]$, giving an 8-bit hash of up to `Max_Len` = 16 characters. $T$ is the same 256-entry permutation table as the plain-Ada twin `hashing/Ada/Pearson-Hashing`, so both versions return the same hash for the same input (checked by `tools/vv/difftest.py`).

Proved at SPARK Silver (`--level=2`): no run-time errors. The tests check values from the Ada twin.

Run `make test` and `make prove` (Level 2, cvc5, warnings as errors).

## Index convention

The input array may start at any index (First-relative): the precondition only
bounds its length. `tests.adb` checks that the same data stored at shifted
origins, including storage that ends at `Positive'Last`, gives the same result.
