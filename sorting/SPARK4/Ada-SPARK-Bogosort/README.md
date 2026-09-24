# Bogosort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [bogosort](https://en.wikipedia.org/wiki/Bogosort) (also *permutation sort*, *stupid sort*) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it uses the **deterministic** generate-and-test variant: advance the array with **next-permutation** (lexicographic multiset order, wrapping last → first) until sorted — **not** a random Fisher–Yates shuffle. Because of factorial growth, $\mathrm{Max\_N}$ is only $8$ (tests keep reverse cases $\le 7$).

$$
\text{deterministic worst } O(n \cdot n!),\quad \text{best } O(n),\quad n \le \mathrm{Max\_N} = 8,\quad 8! = 40\,320
$$

This is the SPARK Level 4 port of the companion package [Ada-Bogosort](https://github.com/RobertBoettcherSF/Ada-Bogosort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a slightly larger `Max_N` ($10$), exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 8`), `In_Bounds` / `Is_Sorted` contracts, an iteration-capped next-permutation loop (`Max_Perm_Steps = \mathrm{Max\_N}! + 1`), and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape and Bubble_Finish proof split: [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort), [Ada-SPARK-Patience-Sorting](https://github.com/RobertBoettcherSF/Ada-SPARK-Patience-Sorting), [Ada-SPARK-Stooge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Stooge-Sort).

## Features
* **`Sort (A)`**: Ascending deterministic bogosort via next-permutation, then a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; next-permutation / reverse prove `In_Bounds` / RTE; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Deterministic only**: No RNG / Fisher–Yates; reproducible for unit tests.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 8` (sibling uses $10$) so $n!$ stays feasible in tests and Level-4 VCs.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Next-permutation loop capped at `Max_Perm_Steps = \mathrm{Max\_N}! + 1` so termination proves under Level 4; prefer `exit when Is_Sorted`.
* Next-permutation / reverse prove only `In_Bounds` / RTE; the final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Comb / Odd_Even / Shell / Strand / Patience / Stooge). Proving that the permutation walk alone always exits sorted would fight automated Level 4 without `Annotate`.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return.
2. **Bogo phase** (at most $\mathrm{Max\_N}! + 1$ steps):
   * If `Is_Sorted (A)`, exit the phase.
   * Else advance $A$ to the next lexicographic multiset permutation (rightmost ascent, swap in rightmost successor, reverse suffix; wrap last → first by full reverse).
3. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted. If the bogo phase already left $A$ sorted, the first bubble pass reports no swaps and returns at once.

Empty and singleton arrays are no-ops.

### Example
For $A = [3, 1, 2]$:

| Step | State | Sorted? |
| ---- | ----- | ------- |
| start | $[3,1,2]$ | no |
| next | $[3,2,1]$ | no |
| next (wrap) | $[1,2,3]$ | yes → bogo exits; bubble finish is a no-op |

## Why `Max_N` is tiny
Even the deterministic enumerator may walk nearly $n!$ permutations. With $8! = 40\,320$ already a classroom limit, `Max_N = 8` and tests prefer reverse / already-sorted / few-key patterns for larger tiny $n$. **Never** feed bogosort random $n \gg 8$ — factorial cost dominates.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 180 assertions pass. Running `make prove` reports `Success: all checks proved (231 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse ($\le 7$) / already-sorted / almost-sorted, Wikipedia-style tiny examples, signed domain, lengths up to `Max_N` (all-equal / already-sorted only at $n=8$).
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 8$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Next-permutation / reverse / bogo loops use `pragma Loop_Invariant` / `Loop_Variant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates; bogo outer loop is iteration-capped at `Max_Perm_Steps`.
* **GNATprove Level 4:** `Success: all checks proved (231 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`8`) |
| `Max_Perm_Steps` | Next-permutation iteration cap (`40321` $= 8!+1$) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending deterministic bogosort + bubble finish (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
