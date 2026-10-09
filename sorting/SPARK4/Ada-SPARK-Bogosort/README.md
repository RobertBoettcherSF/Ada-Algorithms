# Bogosort Algorithm in Ada/SPARK

## Project Overview
This folder holds a formally verified educational implementation of [bogosort](https://en.wikipedia.org/wiki/Bogosort) ("stupid sort") on an `Integer` array, in Ada 2022 and verified with SPARK (GNATprove Level 4). It is the real algorithm: shuffle the array at random (uniform Fisher–Yates) until it is sorted. Because plain bogosort has no upper bound on its running time, `Sort` stops after at most `Budget` shuffles and **returns an explicit outcome**: `Sorted`, or `Gave_Up` with the array still a permutation of the input. There is **no deterministic fallback**: a give-up is reported, not hidden behind a final bubble pass.

The random source is a 32-bit linear congruential generator whose state (`Seed`) belongs to the caller, so every run is reproducible.

## The give-up cap
For $n$ distinct values exactly one of the $n!$ orders is sorted, so one ideal uniform shuffle sorts with probability $1/n!$, and $K$ shuffles all miss with probability

$$
P(\text{Gave\_Up}) = \left(1 - \tfrac{1}{n!}\right)^K \le e^{-K/n!}.
$$

Requiring $P \le 10^{-9}$ gives $K \ge n! \cdot \ln(10^9) \approx 20.723 \cdot n!$. With duplicates more orders are sorted, and smaller $n$ have fewer orders, so the bound only improves. For the largest accepted $n = \mathrm{Max\_N} = 8$:

$$
K \ge 40\,320 \cdot 20.7232658 = 835\,562.08 \;\Rightarrow\; \mathrm{Max\_Shuffles} = 835\,563 .
$$

Run-time budget: a full give-up run at $n = 8$ is about 6.7 million swaps (tens of milliseconds); $n = 9$ would need $K = 7\,520\,094$ (about 68 million swaps), so `Max_N` stays 8. The bound is for an ideal uniform shuffle; the LCG (high 16 bits, reduced mod the range) only approximates one.

## Features
* **`Sort (A, Seed, Result, Shuffles, Budget)`**: shuffle until sorted or `Budget` (default `Max_Shuffles`) shuffles are spent.
  * `Result = Sorted` ⇒ `Is_Sorted (A)`.
  * `Result = Gave_Up` ⇒ `Shuffles = Budget` and `not Is_Sorted (A)`.
  * Both outcomes: `Is_Perm (A, A'Old)` (same values, same counts) and `Shuffles <= Budget`.
* An already sorted array takes 0 shuffles and leaves `Seed` unchanged.
* Any origin (`A'First`), `A'Length <= Max_N`.

## Algorithm
1. `Shuffles := 0`.
2. While `A` is not sorted and `Shuffles < Budget`: Fisher–Yates shuffle from the right (for `I` from `A'Last` down to `A'First + 1`, swap `A (I)` with `A (A'First + Draw (I - A'First + 1))`), then `Shuffles := Shuffles + 1`.
3. `Result := Sorted` if `A` is sorted, else `Gave_Up`.

Generator: `Seed := Seed * 1_664_525 + 1_013_904_223` (mod $2^{32}$); a draw in `0 .. Bound - 1` is `(Seed / 2**16) mod Bound`.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

## Testing
* Every case outside section 11 must end `Sorted` (empty, singleton, reverse, duplicates, negatives, `Max_N`, random arrays, any origin) and match an independent insertion-sort reference and a multiset check.
* Section 10 pins the **exact shuffle count and final seed** for fixed seeds (e.g. `[3, 1, 2]` with seed 1 takes 13 shuffles; rotated 8 with seed 42 takes 96,536).
* Section 11 tests the **`Gave_Up` path** with a small `Budget`: outcome, all shuffles used, not sorted, permutation kept, exact final array and seed.
* Expected values in sections 10 and 11 come from `tests/shuffle_counts.py`, an independent model written from the generator / shuffle description (see `tests/SOURCES.txt`).

## Proof Status
* SPARK proves the full contract of `Sort`: the permutation (ghost occurrence counts `Occ`, one swap lemma per exchange), `Is_Sorted` on `Sorted`, and `Shuffles = Budget` with `not Is_Sorted` on `Gave_Up`.
* Facts that quantify over every `Integer` (`Same_Occ`) sit in loop invariants / internal Posts that are proved but not executed (`Assertion_Policy ... => Ignore` in the body); the public Post, including `Is_Perm`, is checked at run time.
* **GNATprove:** `Success: all checks proved (138 checks).` No `pragma Assume` / `Annotate`.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Length bound (`8`) |
| `Max_Shuffles` | Give-up cap `ceil (8! * ln 1e9) = 835_563` |
| `Shuffle_Count` | `0 .. Max_Shuffles` (type of `Budget`) |
| `Seed_Type` | `mod 2**32` generator state |
| `Outcome` | `Sorted` / `Gave_Up` |
| `In_Bounds` | `A'Length <= Max_N` |
| `Is_Sorted`, `Occ`, `Is_Perm` | Contract helpers |
| `Sort` | Bounded bogosort with an explicit outcome |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
