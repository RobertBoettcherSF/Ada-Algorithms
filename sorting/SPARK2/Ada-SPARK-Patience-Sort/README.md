# Ada-SPARK-Patience-Sort

Patience sort of an `Input_Array` of eight values in `0 .. 31` (D. Aldous and P. Diaconis, "Longest increasing subsequences: from patience sorting to the Baik-Deift-Johansson theorem", Bull. AMS 36 (1999), section 1). Deal: each key in input order goes onto the leftmost pile whose top is `>=` the key, or onto a new pile on the right, so every pile is nonincreasing from bottom to top. Output: repeatedly remove the smallest pile top (the leftmost pile on ties). The piles live side by side in the array itself (pile `Q` occupies `Ends (Q - 1) + 1 .. Ends (Q)`, top at `Ends (Q)`); putting a key on a pile, or moving a pile top to the end of the output, is a rotation by adjacent exchanges that shifts the piles in between by one slot. `Sort_Traced` also returns the pile of every key dealt, the pile of every removal and the number of piles.

Proof (SPARK, `make prove`, level 2, cvc5 + z3, timeout 10 s, 231 checks): no run-time error and the full Post: the result is sorted and a permutation of the input (`Is_Perm`, value counts, swap lemmas). Ghost invariants: every pile is nonincreasing (`Pile_Ok`, every pair), the pile ends are nondecreasing, and every output key is `<=` every key still on a pile; the smallest top is the smallest remaining key because every remaining slot lies in some pile (`Lemma_In_Pile`).

Tests: `tests.adb` (original) and `own_checks.adb`: the deal piles, the removal piles, the pile count and the result equal an own model with real piles (stacks) on every 0/1 input, edge shapes, 3,000 random inputs (seed 20261008), 3,000 random inputs (seed 20261009), all 3**8 inputs over `0 .. 2` and all 8! permutations of `1 .. 8`; every result is sorted, a permutation of the input and equal to an own insertion sort.

```sh
make test
make prove
```
