# Quickselect Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Quickselect](https://en.wikipedia.org/wiki/Quickselect) (Tony Hoare's selection algorithm) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it finds the $k$-th order statistic by choosing a **median-of-three** pivot, **Lomuto-partitioning** so the pivot lands in a final slot, and iteratively shrinking **only one** side toward the target rank — **in-place** with $O(1)$ extra space for `Select_Kth`, average $O(n)$, worst $O(n^2)$.

$$
\text{average } O(n),\quad \text{worst } O(n^2),\quad \text{extra space } O(1)\ \text{(Select\_Kth)}
$$

This is the SPARK Level 4 port of the companion package [Ada-Quickselect](https://github.com/RobertBoettcherSF/Ada-Quickselect) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Kth_Partitioned` contracts, nonempty `A` for selection entry points, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK siblings that share the same array shape and Lomuto tooling: [Ada-SPARK-Quicksort](https://github.com/RobertBoettcherSF/Ada-SPARK-Quicksort) and [Ada-SPARK-Selection-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Selection-Sort).

## Features
* **`Select_Kth (A, K)`**: Classic in-place Quickselect (median-of-three + Lomuto, iterative).
* **`Select_Kth_Copy (A, K)` / `Median (A)`**: Non-mutating wrappers (copy then select; odd $n$ → rank $(n+1)/2$, even $n$ → lower middle $n/2$).
* **`Is_Kth_Partitioned` / `In_Bounds`**: Expression-function guards; the partition / order-statistic property is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, an outer loop bounded by `Max_N`, and loop invariants that the active window plus Lomuto split reassemble into `Is_Kth_Partitioned`.
* **Contract Discipline**: Preconditions replace exceptions; oversized / empty / bad-$K$ calls are `Pre` violations rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic / loop VCs stay within automated SMT reach.
* No exceptions: length / shape / $K$ are `Pre => In_Bounds (A) and then A'Length >= 1 and then K in 1 .. A'Length`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **Lomuto partition** with median-of-three parked at `Hi` (same pivot placement as Ada-SPARK-Quicksort): after the three-way order of $A(\mathrm{Lo})$, $A(\mathrm{Mid})$, $A(\mathrm{Hi})$, the median is swapped to `Hi` so Lomuto's return index is the pivot's final rank.
* Iterative one-sided shrink (no recursion); outer loop bounded by `Max_N` iterations with measure $\mathrm{Hi}-\mathrm{Lo}$.
* Ghost `Prefix_Leq_Window` / `Suffix_Geq_Window` plus Lomuto `All_Leq` / `All_Geq` glue lemmas discharge `Is_Kth_Partitioned`.
* **SPARK proves the partition property** (`Post => Is_Kth_Partitioned (A, K)`). Full multiset / permutation equality and agreement of the $k$-th value vs a sorted copy are **checked by tests**, not claimed as Level-4 postconditions beyond the partition predicate (which already implies the selected cell is a valid $k$-th order statistic under non-strict comparisons).

## Algorithm
Given nonempty $A$ with $A'\mathit{First}=1$ and rank $k\in[1,n]$:

1. $\mathit{target}\leftarrow k$, $L\leftarrow 1$, $R\leftarrow n$.
2. While $L < R$ (at most $\mathrm{Max\_N}$ steps):
   - If $R-L\ge 2$: median-of-three; park median at $R$.
   - Lomuto-partition $A[L..R]$; let $P$ be the pivot index.
   - If $P=\mathit{target}$, stop; if $P>\mathit{target}$ then $R\leftarrow P-1$; else $L\leftarrow P+1$.
3. Afterward $A(k)$ is the $k$-th smallest and
   $$
   \bigl(\forall i<k:\ A(i)\le A(k)\bigr)\ \land\ \bigl(\forall i>k:\ A(i)\ge A(k)\bigr).
   $$

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 690 assertions pass. Running `make prove` reports `Success: all checks proved (419 checks)`.

## Testing
* **Functional correctness**: Singleton / tiny, reverse / already-sorted / nearly sorted, Wikipedia-style example, signed domain including `Integer'First` / `Integer'Last`, all permutations of $\{1,2,3\}$ and $\{0,1,2,3\}$, random arrays up to `Max_N`.
* **Agreement**: `Select_Kth` / `Select_Kth_Copy` / `Median` vs an independent insertion-sort reference for the $k$-th value; `Is_Kth_Partitioned` after every `Select_Kth`.
* **Permutation**: Multiset equality of `Select_Kth` input vs output on every case.
* **Contract helpers**: `In_Bounds` at empty and `Max_N`; `Is_Kth_Partitioned` true/false.
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
* Lomuto scan uses `pragma Loop_Invariant`; outer `Select_Kth` loop is bounded by `Max_N` with window / measure invariants; ghost glue lemmas reassemble `Is_Kth_Partitioned`.
* **GNATprove Level 4:** `Success: all checks proved (419 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
