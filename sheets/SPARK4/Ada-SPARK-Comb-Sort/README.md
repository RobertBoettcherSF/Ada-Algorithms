# Comb Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [comb sort](https://en.wikipedia.org/wiki/Comb_sort) (Włodzimierz Dobosiewicz; later popularized by Stephen Lacey and Richard Box) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it is bubble sort with a shrinking **gap** ($\approx 1.3$ via integer arithmetic $\mathrm{gap} := \lfloor\mathrm{gap}\cdot 10/13\rfloor$). Large early gaps move distant out-of-order keys (**turtles**); the final gap-$1$ phase is ordinary bubble sort — **unstable**, **in-place**, and typically much faster than plain bubble sort in practice.

$$
\text{extra space } O(1);\quad \text{time empirically near } O(n\log n)\text{ with shrink }\approx 1.3\text{ (worst still quadratic)}
$$

This is the SPARK Level 4 port of the companion package [Ada-Comb-Sort](https://github.com/RobertBoettcherSF/Ada-Comb-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), arbitrary `A'First`, and the classic until-gap-$1$-and-clean-pass loop; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a **capped** shrinking-gap phase for termination, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort), [Ada-SPARK-Shell-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Shell-Sort), and [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending comb sort (shrink $\approx 1.3$ + final gap-$1$ bubble).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; gap-$1$ `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (permutation is checked by tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Outer shrink loop capped at `Max_N` iterations so termination proves under Level 4.
* Gaps $> 1$ prove only `In_Bounds` / RTE; the final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Shell's gap-$1$ insertion).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return.
2. Set $\mathrm{gap} := n$. For up to `Max_N` shrink steps: $\mathrm{gap} := \max(1,\lfloor\mathrm{gap}\cdot 10/13\rfloor)$; if $\mathrm{gap} > 1$, one comb pass compares/swaps $A(i)$ with $A(i+\mathrm{gap})$.
3. **Gap-$1$ finish**: ordinary bubble sort with a shrinking unsorted suffix (and early exit) → fully sorted.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 228 assertions pass. Running `make prove` reports `Success: all checks proved (194 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia 10-element example, turtle cases, signed domain, power-of-two and odd lengths up to `Max_N`.
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
* Inner comb / bubble loops use `pragma Loop_Invariant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates; shrink loop is iteration-capped.
* **GNATprove Level 4:** `Success: all checks proved (194 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending in-place comb sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
