# Ada-SPARK-Fisher-Yates-Shuffle

Fisher-Yates shuffle in Durstenfeld's in-place form, with the random choices supplied by the caller. For I = 6 down to 1, `Shuffle` swaps `Data (I)` with `Data (Choices (I))`.

- `Swap_Array` has a type predicate `Choices (I) <= I`, so a choice vector picks one of positions 1 .. I at each step. There are 6! = 720 valid vectors, and each one gives a different permutation. Uniform random choices therefore give a uniform random shuffle. The package itself has no random number generator.
- The postcondition is proved (level 2 CVC5, 30 checks): `Data` is a permutation of its old value, meaning every value occurs equally often (ghost `Occ`, `Is_Perm`).

`make test` builds and runs `tests.adb`. `make prove` runs the proof.

The first version accepted any index as a choice, so it allowed 6 ** 6 vectors and was not Fisher-Yates. It also had no postcondition.
