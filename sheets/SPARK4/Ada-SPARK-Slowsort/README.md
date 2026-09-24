# Slowsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Slowsort](https://en.wikipedia.org/wiki/Slowsort) — the humorous **multiply and surrender** sorting algorithm (a parody of divide-and-conquer) published by Andrei Broder and Jorge Stolfi in *Pessimal Algorithms and Simplexity Analysis* (1984) — on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it recursively sorts both halves, places the larger of the two half-maxima at the end, then re-sorts almost the entire prefix. It is a pedagogical curiosity: **pessimal** asymptotic time (not even polynomial), **unstable**, and **in-place** aside from the recursion stack.

$$
T(n) = 2\,T\!\left(\frac{n}{2}\right) + T(n-1) + \Theta(1)
\qquad\Rightarrow\qquad
\Omega\!\bigl(n^{\log_2 n/(2+\epsilon)}\bigr)
\quad(\epsilon > 0)
$$

This is the SPARK Level 4 port of the companion package [Ada-Slowsort](https://github.com/RobertBoettcherSF/Ada-Slowsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes exceptions (`Invalid_Argument`) and arbitrary `A'First` with `Max_N = 24`; this port trades exceptions for `In_Bounds` / `Is_Sorted` contracts, fixes `A'First = 1`, uses `Max_N = 16`, and bounds recursive `Slowsort_Range` with a `Subprogram_Variant` so Level 4 can discharge the VCs. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same recursive multiply-and-surrender spirit and bubble-finish proof pattern: [Ada-SPARK-Stooge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Stooge-Sort) and [Ada-SPARK-Bogosort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bogosort).

## Features
* **`Sort (A)`**: Ascending Slowsort (recursive multiply-and-surrender), then a gap-$1$ bubble finish that discharges `Is_Sorted` at Level 4.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, a `Subprogram_Variant` on recursive `Slowsort_Range`, and bubble-finish invariants that reassemble a sorted array.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable / pessimal**: Equal keys may change relative order; prefer $n \le 12$ in demos (never large reverse-sorted inputs beyond `Max_N`).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 16` (sibling uses $24$) so demos stay interactive and array / arithmetic / recursion VCs stay within automated SMT reach. The recurrence is **not polynomial**; keep tests tiny.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Bounded recursive `Slowsort_Range` with `Subprogram_Variant => (Decreases => J - I)` rather than an explicit stack; midpoint uses $I + (J-I)/2$ (overflow-safe equivalent of $\lfloor(I+J)/2\rfloor$).
* **Sortedness proof:** the classic inductive “half-maxima then surrender” argument fights automated Level 4 (order-statistic / multiset VCs). `Slowsort_Range` therefore proves only `In_Bounds` / RTE / termination / frame; `Sort` finishes with a gap-$1$ **`Bubble_Finish`** (same role as Stooge / Comb / Odd–Even / Strand) so `Post => Is_Sorted (A)` discharges. On a correctly slowsorted array the finish is an $O(n)$ clean pass.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
Given an array $A$ with index range $[I .. J]$:

1. If $I \ge J$, return (trivial range).
2. Set $M := I + \lfloor(J-I)/2\rfloor$ (same as $\lfloor(I+J)/2\rfloor$).
3. **Multiply:** Slowsort $A[I .. M]$.
4. **Multiply:** Slowsort $A[M+1 .. J]$.
5. If $A[M] > A[J]$, swap them (the larger of the two half-maxima moves to $J$).
6. **Surrender:** Slowsort $A[I .. J-1]$ (re-sort everything except the new maximum).
7. (Level 4) Run a gap-$1$ bubble finish so `Is_Sorted` is proved.

Empty and singleton arrays are no-ops.

## Complexity

| Aspect | Bound | Notes |
| ------ | ----- | ----- |
| Recurrence | $T(n)=2T(n/2)+T(n-1)+\Theta(1)$ | Two half-sorts plus surrender |
| Lower bound | $\Omega\!\bigl(n^{\log_2 n/(2+\epsilon)}\bigr)$ | Not polynomial |
| Space | $O(\log n)$ stack | In-place aside from recursion |
| Stability | Unstable | Equal keys may change relative order |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 192 assertions pass. Running `make prove` reports `Success: all checks proved (187 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, signed domain, tiny lengths only ($n \le 16$).
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at empty / `Max_N` (all-zero under `Max_N`).
* **Contract discipline**: Only valid call paths are exercised (no exception handlers).
* **Never** feed Slowsort random $n \gg 16$ — it will not finish in reasonable time.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Recursive `Slowsort_Range` uses `Subprogram_Variant => (Decreases => J - I)`; gap-$1$ `Bubble_Finish` uses `pragma Loop_Invariant` / `Loop_Variant` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (187 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
