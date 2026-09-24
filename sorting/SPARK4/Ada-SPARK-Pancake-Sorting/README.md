# Pancake Sorting Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic [pancake sorting](https://en.wikipedia.org/wiki/Pancake_sorting) on an `Integer` array: sorting by *prefix reversals* (“pancake flips”). Written in Ada 2022 and verified with SPARK (GNATprove Level 4), the selection-style algorithm brings a maximum of the unsorted prefix to the front, then flips it into place — using at most $2n-3$ flips for $n \ge 2$, with $O(1)$ auxiliary memory beyond a fixed flip-recording buffer.

$$
P(n) \le 2n-3 \qquad (n \ge 2),\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Pancake-Sorting](https://github.com/RobertBoettcherSF/Ada-Pancake-Sorting) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_Length`, exceptions (`Invalid_Argument`), unconstrained `Flip_Sequence`, and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), fixed `Flip_Sequence (1 .. Max_Flips)`, `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape and selection-style suffix placement: [Ada-SPARK-Selection-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Selection-Sort).

## Features
* **`Flip (A, K)`**: Prefix reversal of $A(1..K)$ ($K=0$ or $1$ is a no-op).
* **`Apply_Flips (A, Flips, Count)`**: Replay `Flips (1 .. Count)`.
* **`Sort (A)`**: Classic ascending pancake sort ($\le 2n-3$ flips).
* **`Sort (A, Flips, Count)`**: Same, recording prefix lengths into a fixed buffer.
* **`Is_Sorted` / `In_Bounds` / `Classic_Flip_Bound`**: Expression-function guards; sortedness is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, and loop invariants that the sorted suffix grows by one element per outer step with the partition property vs. the remaining prefix.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays / bad $K$ are `Pre` violations rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape / prefix length are `Pre => In_Bounds (A)` and `K <= A'Last`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* `Flip_Sequence` is a fixed array `1 .. Max_Flips` with `Max_Flips = 2\cdot Max_N` (sibling uses an unconstrained array).
* Nested `Place_Max` plus `pragma Loop_Invariant` so the scan, flips, and outer suffix growth are discharged at Level 4.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition (a simple ghost permutation lemma is not required here).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 183 assertions pass. Running `make prove` reports `Success: all checks proved (391 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, OEIS $(1,3,2)$, signed domain, duplicates.
* **Agreement**: `Sort` vs independent insertion-sort reference; multiset / permutation equality on every case.
* **Flip / replay**: `Flip` primitive; recorded sequences replay via `Apply_Flips`; `Count <= Classic_Flip_Bound (N)`.
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
* `Flip` uses two-pointer loop invariants establishing the full prefix reverse; outer loops grow a sorted suffix via `Place_Max` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (391 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
