# Cycle Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic write-optimal in-place [cycle sort](https://en.wikipedia.org/wiki/Cycle_sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it factors the permutation into **cycles** and rotates each cycle so every element is written **at most once** to its final position — **unstable** under duplicate skipping, **in-place** ($O(1)$ auxiliary memory), with typical $\Theta(n^2)$ comparisons.

$$
\text{comparisons } \Theta(n^2),\quad \text{writes } \le n,\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Cycle-Sort](https://github.com/RobertBoettcherSF/Ada-Cycle-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), arbitrary `A'First`, and a function `Sort_Counting_Writes`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort), [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort), and [Ada-SPARK-Heapsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Heapsort).

## Features
* **`Sort (A)`**: Classic in-place ascending cycle sort (write-optimal).
* **`Sort_Counting_Writes (A, Writes)`**: Same algorithm; returns the number of array writes in `Writes`.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, and loop invariants that a sorted / partitioned prefix grows by one cycle-start per outer step.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Duplicate skipping can reorder equal keys (permutation is checked by tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* `Sort_Counting_Writes` is a procedure with `Writes : out Natural` (SPARK functions cannot have `in out` arrays) and light contracts on the tally.
* Nested `Cycle_Step` plus `Dest_Index` / `Advance_Past_Equals` so Level 4 can prove `Is_Sorted` without claiming full cycle-placement postconditions.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality and exact write counts are **checked by tests**, not claimed as Level-4 postconditions. Zero `pragma Annotate (GNATprove, Intentional, …)`.

## Algorithm
For each cycle start $\mathit{CS}$ from $1$ through $n-1$:

1. Hold $\mathit{Item} = A(\mathit{CS})$.
2. Find destination $\mathit{Pos} = \mathit{CS} + |\{i > \mathit{CS} : A(i) < \mathit{Item}\}|$.
3. If $\mathit{Pos} = \mathit{CS}$, the item is already placed — continue.
4. Otherwise skip past equal duplicates, write $\mathit{Item}$ to $A(\mathit{Pos})$, and take the displaced value as the new $\mathit{Item}$.
5. Repeat until a write returns to $\mathit{CS}$, completing the cycle.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 248 assertions pass. Running `make prove` reports `Success: all checks proved (274 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia `bdeac` ordinals, signed domain, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Write counting**: Sorted / all-equal need $0$ writes; distinct reverse $n=5$ yields $4$ writes; bounds on tiny permutations.
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
* Outer loop grows a sorted prefix with the partition property vs. the remaining suffix; `Dest_Index` supplies the closing-write inequality that discharges `Is_Sorted`.
* **GNATprove Level 4:** `Success: all checks proved (274 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending in-place cycle sort (`Post => Is_Sorted`) |
| `Sort_Counting_Writes` | Same sort; `Writes` counts array stores |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
