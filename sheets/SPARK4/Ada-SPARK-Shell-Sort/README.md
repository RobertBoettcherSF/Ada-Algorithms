# Shellsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [Shellsort](https://en.wikipedia.org/wiki/Shellsort) (Donald Shell, 1959) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it generalizes insertion sort with a fixed decreasing **gap** sequence that ends at $1$: for each gap $h$, insertion-sort the $h$ interleaved subsequences (**$h$-sorting**). The final gap-$1$ pass is ordinary insertion sort and leaves the array fully sorted — **unstable**, **in-place**, and adaptive on nearly sorted input.

$$
\text{extra space } O(1);\quad \text{time depends on the gap sequence (Ciura-class empirically subquadratic)}
$$

This is the SPARK Level 4 port of the companion package [Ada-Shell-Sort](https://github.com/RobertBoettcherSF/Ada-Shell-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), arbitrary `A'First`, and a Ciura sequence extended with $\lfloor 2.25\,h\rfloor$ for $n > 701$; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and a **fixed** Ciura gap prefix that fits `Max_N` (no dynamic float gap generation). README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort), [Ada-SPARK-Heapsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Heapsort), and [Ada-SPARK-Quicksort](https://github.com/RobertBoettcherSF/Ada-SPARK-Quicksort).

## Features
* **`Sort (A)`**: Classic in-place ascending Shellsort (fixed Ciura gaps + final gap-$1$ insertion).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; gap-$1$ `Insert_Step` / `Sorted_Slice` invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (permutation is checked by tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Fixed gap table `57, 23, 10, 4, 1` (Ciura prefix for $n \le 64$); no $\lfloor 2.25\,h\rfloor$ extension (unnecessary under `Max_N`).
* Larger gaps prove only `In_Bounds` / RTE; the final gap-$1$ `Insertion_Pass` reuses the insertion-sort Level-4 argument for `Is_Sorted`.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return.
2. For each gap $h \in \{57, 23, 10, 4\}$ with $h < n$: **$h$-sort** $A$ (gapped insertion).
3. **Gap-$1$ pass**: ordinary insertion sort → fully sorted.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 228 assertions pass. Running `make prove` reports `Success: all checks proved (131 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia 12-element example, signed domain, lengths that engage each Ciura gap, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Unstable duplicates**: Tagged equal keys checked as a permutation only (not tag order).
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Gap-$1$ `Insert_Step` uses `pragma Loop_Invariant` and `Loop_Variant`; outer `Insertion_Pass` grows a sorted prefix; `Gap_Pass` discharges RTE for $h > 1$.
* **GNATprove Level 4:** `Success: all checks proved (131 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending in-place Shellsort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
