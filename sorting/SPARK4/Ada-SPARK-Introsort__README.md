# Introsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Introsort](https://en.wikipedia.org/wiki/Introsort) (David Musser, 1997) — a hybrid of **quicksort**, **heapsort**, and **insertion sort** — on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it begins with **median-of-three Lomuto quicksort**, finishes partitions of size $\le 16$ with **insertion sort**, and switches to **heapsort** when the recursion depth exceeds $2\lfloor\log_2 n\rfloor$ — **unstable**, practically as fast as tuned quicksort, and $O(n\log n)$ in the worst case.

$$
\text{average } O(n \log n),\quad \text{worst } O(n \log n)\ \text{(heapsort fallback)},\quad n \le \mathrm{Max\_N} = 64
$$

This is the SPARK Level 4 port of the companion package [Ada-Introsort](https://github.com/RobertBoettcherSF/Ada-Introsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), Hoare partition, First-relative heap math, and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, Lomuto (so the pivot has a known final index), 1-based Floyd sift on a scratch copy of an exhausted partition, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Quicksort](https://github.com/RobertBoettcherSF/Ada-SPARK-Quicksort), [Ada-SPARK-Heapsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Heapsort), and [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Ascending Musser introsort — median-of-three Lomuto + heapsort depth cutoff + insertion for small partitions.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **`Insertion_Threshold`**: Classic Musser / SGI / libstdc++ small-partition cutoff ($16$).
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, a `Subprogram_Variant` on recursive `Intro_Sort_Rec`, insertion / heap / Lomuto invariants, and a glue lemma that reassembles a sorted slice at the pivot.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (permutation is checked by tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic / recursion VCs stay within automated SMT reach. For $n = 64$ the Musser depth budget is $2\lfloor\log_2 n\rfloor = 12$.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **Lomuto partition** (sibling uses Hoare), matching [Ada-SPARK-Quicksort](https://github.com/RobertBoettcherSF/Ada-SPARK-Quicksort): the pivot is swapped into a final slot $P$, so the recursive sides are $A(\mathrm{Lo} .. P-1)$ and $A(P+1 .. \mathrm{Hi})$.
* Median-of-three is kept (first / middle / last, median parked at `Hi`).
* **Heapsort fallback copies** the exhausted slice to a 1-based scratch array of length $m \le \mathrm{Max\_N}$ so Floyd sift uses $\mathrm{Parent}(I)=I/2$, $\mathrm{Left}(I)=2I$ (same contracts as [Ada-SPARK-Heapsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Heapsort)). The extra $\Theta(m)$ scratch is a classroom concession vs classic in-place First-relative heap math; `Sort` is still correct and `Is_Sorted` is proved.
* Insertion on a slice follows [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort) (`Insert_Step` + sorted-prefix invariants), generalized to $\mathrm{Lo} .. \mathrm{Hi}$.
* Bounded recursive `Intro_Sort_Rec` with `Subprogram_Variant => (Decreases => Hi - Lo)` rather than an explicit stack; $\lfloor\log_2 n\rfloor$ is a decision tree on $n \le 64$ (avoids a bit-loop VC).
* Ghost `All_Leq` / `All_Geq` value bounds are threaded through partition, insertion, heapsort, and recursion so the partition property survives the recursive permutations (full multiset equality is **not** a Level-4 postcondition).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
Given an array $A$ of length $n \le \mathrm{Max\_N}$ with $A'First = 1$:

1. **Depth budget.** Set

   $$
   \mathrm{maxdepth} \leftarrow 2 \lfloor \log_2 n \rfloor.
   $$

   The factor $2$ is the classic Musser / SGI / GNU libstdc++ choice.

2. **Introsort recursion** on a partition of length $m$:

   - If $m \le \mathrm{Insertion\_Threshold}$ (here $16$): finish with **insertion sort**.
   - Else if $\mathrm{maxdepth} = 0$: **heapsort** the partition (scratch copy, Floyd heapify + extract-max, copy back). This caps the worst case at $O(n \log n)$.
   - Else: **median-of-three** pivot, **Lomuto partition**, then recurse on both sides with $\mathrm{maxdepth}-1$.

3. Empty and singleton arrays are no-ops.

## Why the hybrid?

| Ingredient | Role |
| ---------- | ---- |
| Quicksort (median-of-3 + Lomuto) | Fast average case, good locality |
| Depth-limited heapsort | Prevents $O(n^2)$ on adversarial / killer sequences |
| Insertion sort ($m \le 16$) | Optimal for tiny partitions; fewer overheads |

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Best / average | $O(n \log n)$ | $O(\log n)$ stack |
| Worst | $O(n \log n)$ (heapsort fallback) | $O(\log n)$ stack + $\Theta(m)$ scratch on fallback |
| Tiny partition | $O(m^2)$ insertion, $m \le 16$ | $O(1)$ |

Unstable: equal keys may change relative order.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 297 assertions pass. Running `make prove` reports `Success: all checks proved (860 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, classic numeric example, signed domain including `Integer'First` / `Integer'Last`, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Hybrid paths**: sizes on both sides of `Insertion_Threshold` ($15$, $16$, $17$); all-equal $n=64$ (Lomuto returns $P=\mathrm{Hi}$ repeatedly so the depth budget hits $0$ and heapsort runs).
* **Pivot / depth stress**: Sorted, reverse, all-equal, sawtooth, organ-pipe, and random arrays up to `Max_N`.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$ (no combinatorial explosion).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Lomuto scan uses `pragma Loop_Invariant`; recursive `Intro_Sort_Rec` uses `Subprogram_Variant` and a ghost glue lemma to join the sorted sides at the pivot. Insertion and heapsort helpers prove `Sorted_Slice` on $\mathrm{Lo} .. \mathrm{Hi}$.
* **GNATprove Level 4:** `Success: all checks proved (860 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Insertion_Threshold` | Small-partition cutoff (`16`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending Musser introsort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
