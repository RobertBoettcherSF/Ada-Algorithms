# Bitonic Sorter Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Batcher's bitonic sorter](https://en.wikipedia.org/wiki/Bitonic_sorter) — a fixed **sorting network** built from *bitonic* subsequences — on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it sequentially simulates recursive `Bitonic_Sort` / `Bitonic_Merge` with an ascending / descending direction flag. A sequence is **bitonic** when it rises then falls (or is a cyclic shift of that shape): there exists an index $m$ such that

$$
x_0 \le \cdots \le x_m \ge \cdots \ge x_{n-1}.
$$

Recursively sorting the two halves of an arbitrary input into opposite directions produces a bitonic whole; a bitonic merge then finishes the sort. With $n = 2^{k}$ (after padding) the network uses

$$
\mathcal{O}\bigl(n(\log n)^{2}\bigr)
$$

comparators and has parallel depth

$$
\mathcal{O}\bigl((\log n)^{2}\bigr).
$$

This is the SPARK Level 4 port of the companion package [Ada-Bitonic-Sorter](https://github.com/RobertBoettcherSF/Ada-Bitonic-Sorter) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a larger `Max_Length` ($10\,000$), exceptions (`Invalid_Argument`), arbitrary `A'First`, a $0$-based work buffer, and public `Compare_Swap` / `Next_Power_Of_Two`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a fixed $1$-based `Work` buffer, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape and bubble-finish proof pattern: [Ada-SPARK-Odd-Even-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Odd-Even-Sort) and [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort).

## Features
* **`Sort (A)`**: Ascending bitonic mergesort network via a static `Work` buffer (sentinel pad to the next power of two), then a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; `Bitonic_Sort` / `Bitonic_Merge` / `Compare_Swap` prove `In_Bounds` / RTE with `Subprogram_Variant`; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Static Work buffer**: `Work : Element_Array (1 .. Max_N)`; no heap / unbounded allocation.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses `Max_Length = 10_000`) so array / arithmetic / recursion VCs stay within automated SMT reach; `Max_N` itself is a power of two so padded work length stays $\le \mathrm{Max\_N}$.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First` and a $0$-based work buffer).
* Fixed static `Work (1 .. Max_N)` rather than a length-exact local; pad with `Integer'Last` sentinels to the next power of two, run the network, copy the live prefix back.
* `Compare_Swap` / `Is_Power_Of_Two` / `Next_Power_Of_Two` stay **private** (sibling exposes them); the educational wire still appears in the body.
* Network correctness posts (full bitonic / merge lemmas) fight automated Level 4, so `Bitonic_Sort` / `Bitonic_Merge` prove only `In_Bounds` / RTE / termination; `Sort` finishes with a gap-$1$ **`Bubble_Finish`** (same role as Comb / Odd–Even / Strand / Stooge) so `Post => Is_Sorted (A)` discharges. On a correctly network-sorted prefix the finish is an $O(n)$ clean pass.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.
* Zero `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## Algorithm
1. If $n \le 1$, return.
2. Copy $A$ into static `Work (1 .. Max_N)`; let $P$ be the next power of two $\ge n$ ($P \le \mathrm{Max\_N}$); pad `Work(n+1 .. P)` with `Integer'Last`.
3. **`Bitonic_Sort(Work, low=1, count=P, dir=Ascending)`** — if $count > 1$, let $k = count/2$; recursively sort $[low .. low+k)$ ascending and $[low+k .. low+count)$ descending; then `Bitonic_Merge(Work, low, count, dir)`.
4. **`Bitonic_Merge`** — pairwise `Compare_Swap` of $W(i)$ with $W(i+k)$ for $i \in [low .. low+k)$; recurse on both halves with the same direction. `Subprogram_Variant` decreases `Count`.
5. Copy `Work(1 .. n)` back into $A$ (sentinels discarded).
6. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted (`Is_Sorted` proved).

Empty and singleton arrays are no-ops. Sentinel padding matches the mitigation noted on Wikipedia when $n$ is not a power of two; live `Integer'Last` data is still correct because the first $n$ elements of the sorted padded multiset equal the original multiset.

## Complexity

| Aspect | Bound | Notes |
| ------ | ----- | ----- |
| Comparators | $\mathcal{O}(n(\log n)^{2})$ | On padded length $n = 2^{k}$ |
| Parallel depth | $\mathcal{O}((\log n)^{2})$ | $k(k+1)/2$ layers |
| Sequential time | $\Theta(\text{comparators})$ | This package runs wires one-by-one |
| Extra space | $\Theta(\mathrm{Max\_N})$ | Static `Work` buffer |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 236 assertions pass. Running `make prove` reports `Success: all checks proved (294 checks).`

## Testing
* **Functional correctness**: Empty / singleton, powers of two, padded non-powers-of-two, reverse / already-sorted / duplicates, signed domain, lengths up to `Max_N`, `Integer'Last` data mixed with sentinel padding.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Recursive `Bitonic_Sort` / `Bitonic_Merge` use `Subprogram_Variant => (Decreases => Count)`; gap-$1$ `Bubble_Finish` uses `pragma Loop_Invariant` / `Loop_Variant` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (294 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`, power of two) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending bitonic network + bubble finish (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
