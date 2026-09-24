# Smoothsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [smoothsort](https://en.wikipedia.org/wiki/Smoothsort) ideas (Edsger W. Dijkstra, 1981) on an `Integer` array — a forest of **Leonardo heaps** ("stretches") with Dijkstra/Keith layout sift-down. Written in Ada 2022 and verified with SPARK (GNATprove Level 4). The classroom extract phase uses a linear prefix-max scan after one Leonardo-forest heapify (see simplifications below). **Unstable**, in-place aside from $O(\log n)$ stretch metadata on the stack.

$$
L(0)=L(1)=1,\quad L(k)=L(k-1)+L(k-2)+1,\quad n \le \mathrm{Max\_N}=64
$$

This is the SPARK Level 4 port of the companion package [Ada-Smoothsort](https://github.com/RobertBoettcherSF/Ada-Smoothsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_Length`, exceptions (`Invalid_Argument`), First-relative offsets, and the full bit-string $P$ / Up / Down / Trinkle / Semitrinkle Dijkstra pipeline with arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a precomputed Leonardo table, and 1-based indices. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Heapsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Heapsort) and [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Classroom Leonardo-forest heapsort — greedy stretch partition, Dijkstra/Keith-layout sift, then extract-max with a proved sorted-suffix argument.
* **`Leonardo (K)`**: Precomputed $L(0)..L(8)$ ($L(8)=67$ covers `Max_N`).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition of `Sort`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors and a selection-style extract-max proof of sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (permutation is checked by tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $\mathrm{Max\_Length}=100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Precomputed Leonardo table for orders $0..8$ only (`Max_Leonardo_Order = 8`; sibling table goes to $40$).
* **Classroom extract**: after one Leonardo-forest heapify of $1..n$, Sort proves `Is_Sorted` via a linear prefix-max scan and sorted-suffix invariants (same shape as selection / heapsort extract proofs). Full Dijkstra bit-string $P$, Trinkle / Semitrinkle, and Level-4 `Is_Leo_Heap` / forest-root-max lemmas were attempted and found intractable in reasonable time — documented honestly here rather than suppressed with `Intentional` annotations.
* Greedy largest-$L(k)$ stretch partition (educational cover of $n$) instead of the live bit-string grow loop.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. **Heapify (Leonardo forest).** Partition $1..n$ into greedy Leonardo stretches; for each stretch, recursively heapify the Keith/Dijkstra children ($\mathrm{Lt}_{k-1}$ then $\mathrm{Lt}_{k-2}$) and sift the root ($[\,\mathrm{Lt}_{k-1}\,][\,\mathrm{Lt}_{k-2}\,][\mathrm{root}\,]$).
2. **Extract-max.** For $\mathrm{Last}$ from $n$ down to $2$: find the maximum in $1..\mathrm{Last}$ by a linear scan, swap it to $A(\mathrm{Last})$, shrink. The sorted suffix grows; `Heap_Leq_Suffix` reassembles `Is_Sorted`.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 173 assertions pass. Running `make prove` reports `Success: all checks proved (205 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted, Leonardo-sized lengths ($L(2)..L(7)$), classic numeric example, signed domain including `Integer'First` / `Integer'Last`, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Leonardo table**: $L(0)..L(8)$ and the recurrence $L(k)=L(k-1)+L(k-2)+1$.
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
* Ghost `Sorted_Slice` / `Heap_Leq_Suffix` plus `Index_Of_Max` support the extract-max sorted-suffix argument after the educational Leonardo heapify.
* **GNATprove Level 4:** `Success: all checks proved (205 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Max_Leonardo_Order` | Highest table order (`8`; $L(8)=67$) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Leonardo` | Precomputed Leonardo number $L(K)$ |
| `Sort` | Ascending classroom Leonardo-forest heapsort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
