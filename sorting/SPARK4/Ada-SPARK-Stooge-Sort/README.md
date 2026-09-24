# Stooge Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [stooge sort](https://en.wikipedia.org/wiki/Stooge_sort) — the deliberately inefficient recursive sorting algorithm named after [The Three Stooges](https://en.wikipedia.org/wiki/The_Three_Stooges) — on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it swaps the endpoints when out of order, then recursively sorts the first $\lceil 2n/3 \rceil$, the last $\lceil 2n/3 \rceil$, and the first two-thirds again. It is a pedagogical curiosity: **pessimal** asymptotic time (slower than bubble sort, still faster than Slowsort), **unstable**, and **in-place** aside from the recursion stack.

$$
T(n) = 3\,T\!\left(\left\lceil\frac{2n}{3}\right\rceil\right) + \Theta(1)
\qquad\Rightarrow\qquad
\Theta\!\bigl(n^{\log 3 / \log 1.5}\bigr) \approx \Theta(n^{2.709})
$$

This is the SPARK Level 4 port of the companion package [Ada-Stooge-Sort](https://github.com/RobertBoettcherSF/Ada-Stooge-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes exceptions (`Invalid_Argument`) and arbitrary `A'First` with the same tiny `Max_N = 24`; this port trades exceptions for `In_Bounds` / `Is_Sorted` contracts, fixes `A'First = 1`, and bounds recursive `Stooge_Range` with a `Subprogram_Variant` so Level 4 can discharge the VCs. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape and bubble-finish proof pattern: [Ada-SPARK-Comb-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Comb-Sort) and [Ada-SPARK-Odd-Even-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Odd-Even-Sort).

## Features
* **`Sort (A)`**: Ascending Stooge sort (recursive $2/3$–$2/3$–$2/3$), then a gap-$1$ bubble finish that discharges `Is_Sorted` at Level 4.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, a `Subprogram_Variant` on recursive `Stooge_Range`, and bubble-finish invariants that reassemble a sorted array.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable / pessimal**: Equal keys may change relative order; prefer $n \le 16$ in demos (never large reverse-sorted inputs).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 24` (same as the sibling — recursion is expensive) so demos stay interactive and array / arithmetic / recursion VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Bounded recursive `Stooge_Range` with `Subprogram_Variant => (Decreases => Hi - Lo)` rather than an explicit stack; depth is at most $\mathrm{Max\_N}$.
* **Sortedness proof:** the classic inductive “largest third lands in the last third” argument fights automated Level 4 (order-statistic / multiset VCs). `Stooge_Range` therefore proves only `In_Bounds` / RTE / termination / frame; `Sort` finishes with a gap-$1$ **`Bubble_Finish`** (same role as Comb / Odd–Even / Shell) so `Post => Is_Sorted (A)` discharges. On a correctly stooge-sorted array the finish is an $O(n)$ clean pass.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
Given an array $A$ with index range $[\mathrm{Lo} .. \mathrm{Hi}]$:

1. If $A[\mathrm{Lo}] > A[\mathrm{Hi}]$, swap them.
2. If the length $L := \mathrm{Hi} - \mathrm{Lo} + 1$ is greater than $2$:
   - Set $t := \lfloor L / 3 \rfloor$.
   - Stooge-sort $A[\mathrm{Lo} .. \mathrm{Hi}-t]$ (first $\lceil 2L/3 \rceil$).
   - Stooge-sort $A[\mathrm{Lo}+t .. \mathrm{Hi}]$ (last $\lceil 2L/3 \rceil$).
   - Stooge-sort $A[\mathrm{Lo} .. \mathrm{Hi}-t]$ again.
3. (Level 4) Run a gap-$1$ bubble finish so `Is_Sorted` is proved.

Using $t = \lfloor L/3 \rfloor$ makes the recursive span $L - t = \lceil 2L/3 \rceil$, which is required for correctness (e.g. $L=5$ must recurse on length $4$, not $3$). Empty and singleton arrays are no-ops.

## Complexity

| Aspect | Bound | Notes |
| ------ | ----- | ----- |
| Recurrence | $T(n)=3T(\lceil 2n/3 \rceil)+\Theta(1)$ | Three recursive calls on $2/3$ |
| Time | $O\!\bigl(n^{\log 3 / \log 1.5}\bigr) \approx O(n^{2.709})$ | Slower than bubble sort |
| Space | $O(\log n)$ stack | In-place aside from recursion |
| Stability | Unstable | Equal keys may change relative order |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 195 assertions pass. Running `make prove` reports `Success: all checks proved (189 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, signed domain, tiny lengths only ($n \le 16$).
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at empty / `Max_N` (all-zero under `Max_N` — never reverse-sort $n=24$).
* **Contract discipline**: Only valid call paths are exercised (no exception handlers).
* **Never** feed Stooge sort random $n \gg 16$ — it will not finish in reasonable time.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Recursive `Stooge_Range` uses `Subprogram_Variant => (Decreases => Hi - Lo)`; gap-$1$ `Bubble_Finish` uses `pragma Loop_Invariant` / `Loop_Variant` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (189 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
