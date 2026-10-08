# Library Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [library sort](https://en.wikipedia.org/wiki/Library_sort) (also called *gapped insertion sort*) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it keeps the values in a static working array of capacity $(1+\varepsilon)\,n$ with $\varepsilon = 1$ so

$$
\mathrm{Cap}(n) = (1+\varepsilon)\,n = 2n,\qquad n \le \mathrm{Max\_N} = 64,\qquad \mathrm{Max\_Cap} = 2\cdot\mathrm{Max\_N} = 128.
$$

Binary-search insert plus a local shift to the nearest free slot; spread the values out again after $1, 2, 4, \ldots$ insertions; pack the occupied slots back into $A$. Average $O(n \log n)$ with high probability for suitable $\varepsilon$ (Bender–Farach-Colton–Mosteiro); auxiliary $\Theta((1+\varepsilon)n)$ space.

This is the SPARK Level 4 port of the companion package [Ada-Library-Sort](https://github.com/RobertBoettcherSF/Ada-Library-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a larger `Max_N` ($8192$), exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and a fixed working array of size `Max_Cap`; sortedness is proved for the library phase itself, with no final fallback sort. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort), [Ada-SPARK-Bitonic-Sorter](https://github.com/RobertBoettcherSF/Ada-SPARK-Bitonic-Sorter), [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

### Librarian shelf analogy
Imagine a librarian shelving books A–Z with **no** empty slots: inserting a new B may require shifting every book from mid-B through Z. If the librarian leaves a blank after every letter, a new B usually needs only a few books moved until the next blank — the idea behind library sort.

## Features
* **`Sort (A)`**: Ascending library sort ($\varepsilon = 1$, $\mathrm{Cap} = 2n$) in a static working array; nothing else sorts the array.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: GNATprove proves absence of runtime errors and `Is_Sorted` for the library phase: the occupied slots of the working array stay nondecreasing through every search, shift and spread (`Sorted_W`), and a ghost count of occupied slots (`Occ_In`) shows the final pack writes exactly $n$ values.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Static buffer only**: the working array is `1 .. Max_Cap`; no unbounded allocation.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $8192$) so array / arithmetic VCs stay within automated SMT reach; `Max_Cap = 128`.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Fixed working array of size `Max_Cap` (sibling allocates length-exact `Cap = 2n`).
* A rebalance places the values at slots $1, 3, 5, \ldots$ (one free slot after each), not evenly over all of $\mathrm{Cap}$; with rebalances after $1, 2, 4, \ldots$ insertions this keeps the last slot free, so the shift always goes right to the nearest free slot (the proof shows the slots from $\mathrm{Count} + \mathrm{Next\_Goal}/2$ on stay free).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.
* Zero `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## Algorithm
1. If $n \le 1$, return.
2. $\mathrm{Cap} := 2n$. The working array $W$ has slots (occupied flag + value); use $W[1..\mathrm{Cap}]$. Place $A(1)$ in slot 1.
3. For each remaining $x = A(2), \ldots, A(n)$:
   * After $1, 2, 4, \ldots$ insertions, **rebalance**: gather the occupied values in slot order and **spread** them to slots $1, 3, 5, \ldots$.
   * **Binary-search** $W$ for the first slot whose value is greater than $x$; a free slot at the midpoint is skipped by looking for the nearest occupied slot (right, then left).
   * **Insert**: if that slot is free, put $x$ there; otherwise move the values up to the nearest free slot on the right one place to the right and put $x$ in the opened slot.
4. **Pack** the occupied slots of $W$ left-to-right back into $A$.

### Why it is sorted
The occupied slots of $W$ hold nondecreasing values at every step: the search result separates values $\le x$ from values $> x$, a shift moves a block of neighbouring values by one slot, and a spread keeps the gathered order. A ghost count of occupied slots goes up by one per insertion, so the final pack writes exactly $n$ values, in order.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 233 assertions pass, then the property checks (`PASS own checks: ...`). Running `make prove` reports `Success: all checks proved (275 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Cap=$2n$ README example, signed domain, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Max_Cap = 2·Max_N`.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Search / insert / gather / spread loops use `pragma Loop_Invariant` / `Loop_Variant`; recursive ghost lemmas (`Lemma_Occ_In_*`, `Lemma_Spread_Count`, with `Subprogram_Variant`) carry the occupied-slot count.
* **GNATprove Level 4:** `Success: all checks proved (275 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Max_Cap` | Working-buffer size (`128` = $2\cdot\mathrm{Max\_N}$) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending library sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
