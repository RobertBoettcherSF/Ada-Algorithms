# Introselect Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Introselect](https://en.wikipedia.org/wiki/Introselect) (David Musser's introspective selection, 1997) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it finds the $k$-th order statistic by starting with **Quickselect** (median-of-three + Lomuto, iterative one-sided shrink) under a depth budget

$$
\mathrm{maxdepth} = 2\lfloor\log_2 n\rfloor
$$

and falling back to an educational **Blum–Floyd–Pratt–Rivest–Tarjan median-of-medians** (BFPRT, groups of 5) pivot when that budget is exhausted. Practical average $\sim O(n)$; worst-case $O(n)$ intent via MoM pivots; $O(1)$ extra space for `Select_Kth` aside from $O(\log n)$ MoM recursion.

This is the SPARK Level 4 port of the companion package [Ada-Introselect](https://github.com/RobertBoettcherSF/Ada-Introselect) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Kth_Partitioned` contracts, nonempty $A$ for selection entry points, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK siblings that share the same array shape and Lomuto tooling: [Ada-SPARK-Quickselect](https://github.com/RobertBoettcherSF/Ada-SPARK-Quickselect) and [Ada-SPARK-Introsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Introsort).

## Features
* **`Select_Kth (A, K)`**: In-place introselect (median-of-three Quickselect + depth budget + MoM fallback).
* **`Select_Kth_Copy (A, K)` / `Median (A)`**: Non-mutating wrappers (copy then select; odd $n$ → rank $(n+1)/2$, even $n$ → lower middle $n/2$).
* **`Is_Kth_Partitioned` / `In_Bounds`**: Expression-function guards; the partition / order-statistic property is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, an outer loop bounded by `Max_N`, MoM recursion with `Subprogram_Variant`, and loop invariants that the active window plus Lomuto split reassemble into `Is_Kth_Partitioned`.
* **Contract Discipline**: Preconditions replace exceptions; oversized / empty / bad-$K$ calls are `Pre` violations rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic / loop VCs stay within automated SMT reach.
* No exceptions: length / shape / $K$ are `Pre => In_Bounds (A) and then A'Length >= 1 and then K in 1 .. A'Length`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **Lomuto partition** with median-of-three or MoM parked at `Hi` (same pivot placement as Ada-SPARK-Quickselect).
* Iterative one-sided shrink (no Quickselect recursion); outer loop bounded by `Max_N` with measure $\mathrm{Hi}-\mathrm{Lo}$.
* Depth budget $2\lfloor\log_2 n\rfloor$ restored after each MoM fallback on the remaining subproblem.
* Educational BFPRT MoM (groups of 5 + recursive median of medians via selection-sort of each group). Level 4 proves termination and window / partition safety; the classic constant-fraction “good pivot” progress argument is **not** claimed as a SPARK postcondition (any pivot preserves `Is_Kth_Partitioned` after Lomuto).
* Ghost `Prefix_Leq_Window` / `Suffix_Geq_Window` plus Lomuto `All_Leq` / `All_Geq` glue lemmas discharge `Is_Kth_Partitioned`.
* **SPARK proves the partition property** (`Post => Is_Kth_Partitioned (A, K)`). Full multiset / permutation equality and agreement of the $k$-th value vs a sorted copy are **checked by tests**, not claimed as Level-4 postconditions beyond the partition predicate.

## Algorithm
Given nonempty $A$ with $A'\mathit{First}=1$ and rank $k\in[1,n]$:

1. $\mathit{target}\leftarrow k$, $L\leftarrow 1$, $R\leftarrow n$, $\mathrm{depth}\leftarrow 2\lfloor\log_2 n\rfloor$.
2. While $L < R$ (at most $\mathrm{Max\_N}$ steps):
   - If $\mathrm{depth}=0$: BFPRT MoM index on $A[L..R]$; swap that element to $R$; mark fallback.
   - Else: if $R-L\ge 2$, median-of-three; park median at $R$; $\mathrm{depth}\leftarrow\mathrm{depth}-1$.
   - Lomuto-partition $A[L..R]$; let $P$ be the pivot index.
   - If $P=\mathit{target}$, stop; if $P>\mathit{target}$ then $R\leftarrow P-1$; else $L\leftarrow P+1$.
   - After MoM fallback, restore $\mathrm{depth}\leftarrow 2\lfloor\log_2(R-L+1)\rfloor$.
3. Afterward $A(k)$ is the $k$-th smallest and
   $$
   \bigl(\forall i<k:\ A(i)\le A(k)\bigr)\ \land\ \bigl(\forall i>k:\ A(i)\ge A(k)\bigr).
   $$

### Pseudocode

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{Select\_Kth}(A,k): \\
&\quad \mathit{target}\leftarrow k;\ L\leftarrow 1;\ R\leftarrow n \\
&\quad \mathrm{depth}\leftarrow 2\lfloor\log_2 n\rfloor \\
&\quad \mathbf{while}\ L < R: \\
&\quad\quad \mathbf{if}\ \mathrm{depth}=0: \\
&\quad\quad\quad \mathrm{Swap}(A,\ \mathrm{MoMIndex}(A,L,R),\ R);\ \mathit{fallback}\leftarrow\mathbf{true} \\
&\quad\quad \mathbf{else}: \\
&\quad\quad\quad \mathrm{MedianOfThreeToHi}(A,L,R);\ \mathrm{depth}\leftarrow\mathrm{depth}-1;\ \mathit{fallback}\leftarrow\mathbf{false} \\
&\quad\quad P\leftarrow\mathrm{PartitionLomuto}(A,L,R) \\
&\quad\quad \mathbf{if}\ P=\mathit{target}:\ \mathbf{return} \\
&\quad\quad \mathbf{elsif}\ P>\mathit{target}:\ R\leftarrow P-1 \\
&\quad\quad \mathbf{else}:\ L\leftarrow P+1 \\
&\quad\quad \mathbf{if}\ \mathit{fallback}\ \mathbf{and}\ L<R: \\
&\quad\quad\quad \mathrm{depth}\leftarrow 2\lfloor\log_2(R-L+1)\rfloor
\end{align*}
$$

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all assertions pass with `0 FAIL`. Running `make prove` reports `Success: all checks proved (584 checks)`.

## Testing
* **Functional correctness**: Singleton / tiny, reverse / already-sorted / nearly sorted, Wikipedia-style example, signed domain including `Integer'First` / `Integer'Last`, all permutations of $\{1,2,3\}$ and $\{0,1,2,3\}$, random arrays up to `Max_N`, depth-budget / MoM-capable sizes ($n=31,63,64$).
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
* Lomuto scan uses `pragma Loop_Invariant`; outer `Select_Kth` loop is bounded by `Max_N` with window / measure invariants; MoM uses `Subprogram_Variant => (Decreases => Hi - Lo)`; ghost glue lemmas reassemble `Is_Kth_Partitioned`.
* **GNATprove Level 4:** `Success: all checks proved (584 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
