# Quantum Sort Educational Models in Ada/SPARK

## Project Overview
This repository contains a formally verified **educational** Ada/SPARK package of **classical stand-ins** for [quantum sorting](https://en.wikipedia.org/wiki/Quantum_sort) notions on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it exposes four `Sort_*` procedures that model comparison, parallel-network, frequency/distribution, and space-bounded ideas with ordinary classical sorts — **not** a quantum simulator and **not** a claim of asymptotic quantum advantage.

Comparison-based quantum sorting is known to need $\Omega(n \log n)$ steps in the worst case (already achieved classically), so quantum computers offer no asymptotic time win for unrestricted comparison sorting. In **space-bounded** settings, quantum time–space tradeoffs can improve on the classical $TS = \Theta(n^2)$ bound (e.g. toward $TS = \Omega(n^{3/2})$). This package uses classical algorithms as classroom proxies for those research themes:

| Quantum notion (educational) | Classical stand-in | SPARK proof path |
| --- | --- | --- |
| Comparison sort | Insertion sort | `Insert_Step` → `Is_Sorted` |
| Parallel sorting network | Shellsort (fixed Ciura gaps) | `Gap_Pass` + `Insertion_Pass` |
| Frequency / distribution | Selection sort | `Select_Min_Step` + partition |
| Space-bounded sort | Cocktail shaker sort | capped cocktail + `Bubble_Finish` |

$$
\text{classroom } n \le \mathit{Max\_N}=64,\quad \text{extra space } O(1),\quad \text{proved postcondition: } \mathit{Is\_Sorted}
$$

This is the SPARK Level 4 port of the companion package [Ada-Quantum-Sort](https://github.com/RobertBoettcherSF/Ada-Quantum-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a modest `Element_Value` subtype, exceptions (`Invalid_Input_Size`), and the same four classical mappings; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, `Integer` elements, and proved sortedness. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that supply the proof patterns reused here: [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort), [Ada-SPARK-Shell-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Shell-Sort), [Ada-SPARK-Selection-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Selection-Sort), and [Ada-SPARK-Cocktail-Shaker-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Cocktail-Shaker-Sort).

## Features
* **`Sort_Comparison (A)`**: Quantum comparison model via classic stable in-place insertion sort.
* **`Sort_Parallel_Network (A)`**: Parallel-network model via Shellsort with a fixed Ciura gap table $(57,23,10,4,1)$ sized for `Max_N`, finished by a gap-$1$ insertion pass.
* **`Sort_Frequency (A)`**: Frequency / distribution model via in-place selection sort (min of suffix → prefix).
* **`Sort_Space_Bounded (A)`**: Space-bounded model via cocktail shaker (capped $\mathit{Lo}..\mathit{Hi}$ rounds) plus a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition on every `Sort_*`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; educational phases prove `In_Bounds` / RTE where needed; finishes prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Input_Size`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows a dedicated `Index_Type`).
* Element type widened to `Integer` (sibling uses `Element_Value` range $-10\,000 .. 10\,000$).
* Shell model uses a **fixed** Ciura gap prefix that fits `Max_N` (no dynamic $\lfloor 2.25\cdot h\rfloor$ extension).
* Cocktail outer rounds capped at `Max_N` so termination proves under Level 4; cocktail forward/backward phases prove only `In_Bounds` / RTE; the final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Shell / Comb / Odd–Even).
* **SPARK proves sortedness** (`Post => In_Bounds (A) and Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.
* Zero `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## Algorithm sketches
1. **Comparison (insertion):** if $n \le 1$, return; for $i = 2 .. n$, insert $A(i)$ into the sorted prefix $A(1 .. i-1)$ with strict `>` shifts (stable).
2. **Parallel network (Shell):** for each gap $h \in \{57,23,10,4\}$ with $1 < h < n$, $h$-sort; then gap-$1$ insertion → fully sorted.
3. **Frequency (selection):** for $i = 1 .. n-1$, swap $A(i)$ with $\arg\min A(i .. n)$.
4. **Space-bounded (cocktail):** maintain $[\mathit{Lo}..\mathit{Hi}]$; up to `Max_N` rounds of forward (max to $\mathit{Hi}$) then backward (min to $\mathit{Lo}$) with early exit; then gap-$1$ bubble finish → fully sorted.

Empty and singleton arrays are no-ops for every entry point.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 932 assertions pass (`0 FAIL`). Running `make prove` reports `Success: all checks proved (441 checks)` with **zero** Intentional Annotate.

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, cocktail turtle $(2,3,4,5,1)$, Shell Wikipedia-style $12$-element demo, signed domain, lengths up to `Max_N`.
* **Agreement**: Each `Sort_*` vs an independent insertion-sort reference; multiset / permutation equality on every case; cross-variant agreement on the sorted multiset.
* **Stability**: Tagged keys (`key×1000 + arrival_tag`) keep tag order for `Sort_Comparison` and `Sort_Space_Bounded` (strict `>`); Shell / Selection only checked as permutations.
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
* Insertion / selection loops use `pragma Loop_Invariant` / `Loop_Variant`; Shell gap passes prove `In_Bounds` / RTE; cocktail-round loop is iteration-capped at `Max_N`; bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (441 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort_Comparison` | Insertion-sort model (`Post => Is_Sorted`) |
| `Sort_Parallel_Network` | Shellsort model (`Post => Is_Sorted`) |
| `Sort_Frequency` | Selection-sort model (`Post => Is_Sorted`) |
| `Sort_Space_Bounded` | Cocktail-shaker model (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
