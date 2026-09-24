# Library Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [library sort](https://en.wikipedia.org/wiki/Library_sort) (also called *gapped insertion sort*) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it maintains a static working buffer of capacity $(1+\varepsilon)\,n$ with $\varepsilon = 1$ so

$$
\mathrm{Cap}(n) = (1+\varepsilon)\,n = 2n,\qquad n \le \mathrm{Max\_N} = 64,\qquad \mathrm{Max\_Cap} = 2\cdot\mathrm{Max\_N} = 128.
$$

Binary-search insert plus local shifts into gaps; rebalance/spread on doubling rounds and congestion; pack the dense result back into $A$. Average $O(n \log n)$ with high probability for suitable $\varepsilon$ (Bender–Farach-Colton–Mosteiro); auxiliary $\Theta((1+\varepsilon)n)$ space.

This is the SPARK Level 4 port of the companion package [Ada-Library-Sort](https://github.com/RobertBoettcherSF/Ada-Library-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a larger `Max_N` ($8192$), exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a fixed `Working` buffer of size `Max_Cap`, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape and Bubble_Finish proof split: [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort), [Ada-SPARK-Bitonic-Sorter](https://github.com/RobertBoettcherSF/Ada-SPARK-Bitonic-Sorter), [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

### Librarian shelf analogy
Imagine a librarian shelving books A–Z with **no** empty slots: inserting a new B may require shifting every book from mid-B through Z. If the librarian leaves a blank after every letter, a new B usually needs only a few books moved until the next blank — the idea behind library sort.

## Features
* **`Sort (A)`**: Ascending library sort ($\varepsilon = 1$, $\mathrm{Cap} = 2n$) via a static Working buffer, then a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; library Gather / Spread / Rebalance / insert prove `In_Bounds` / RTE; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Static buffer only**: Working array is `1 .. Max_Cap`; no unbounded allocation.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $8192$) so array / arithmetic VCs stay within automated SMT reach; `Max_Cap = 128`.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Fixed Working buffer of size `Max_Cap` (sibling allocates length-exact `Cap = 2n`).
* Library insert / rebalance prove only `In_Bounds` / RTE; the final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Strand / Bitonic / Comb / Odd_Even). Full gapped-structure sortedness posts that would fight Level 4 are intentionally deferred to that finish.
* Outer insert loop capped at `Max_N` iterations so termination proves under Level 4.
* Rebalance / insert loops keep the educational $\varepsilon = 1$ Cap $= 2n$ structure but are written for automated RTE discharge (fallback gather+append+spread on congestion).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.
* Zero `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## Algorithm
1. If $n \le 1$, return.
2. $\mathrm{Cap} := 2n$. Clear static Working $W[1..\mathrm{Max\_Cap}]$; use $W[1..\mathrm{Cap}]$.
3. Place $A(1)$; then for each remaining $x$ (capped at $\mathrm{Max\_N}$ outer steps):
   * On **doubling rounds** (after $1, 2, 4, \ldots$ insertions), **rebalance**: gather occupied values and **spread** them evenly across $\mathrm{Cap}$.
   * **Binary-search** $W$ for an insertion index (gap at Mid → scan right then left).
   * **Insert** $x$ into a gap, or shift until a gap; on congestion, rebalance and retry (fallback: gather + append + spread).
4. **Pack** occupied slots of $W$ left-to-right back into $A$.
5. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted.

### Rebalance (spread)
After gathering $k$ occupied values into a dense buffer, place element $j$ (1-based) near index

$$
1 + (j-1)\left\lfloor\frac{\mathrm{Cap}}{k}\right\rfloor
$$

(walking forward on rare collisions). For $\varepsilon = 1$ and $k \approx n$, this is roughly every other slot.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 233 assertions pass. Running `make prove` reports `Success: all checks proved (360 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Cap=$2n$ README example, signed domain, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Max_Cap = 2·Max_N`.
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
* Library Gather / Spread / insert / rebalance loops use `pragma Loop_Invariant` / `Loop_Variant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates; library outer loop is iteration-capped at `Max_N`.
* **GNATprove Level 4:** `Success: all checks proved (360 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Max_Cap` | Working-buffer size (`128` = $2\cdot\mathrm{Max\_N}$) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending library sort + bubble finish (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
