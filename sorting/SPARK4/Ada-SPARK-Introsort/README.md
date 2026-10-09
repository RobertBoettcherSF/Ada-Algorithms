# Introsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Introsort](https://en.wikipedia.org/wiki/Introsort) (David Musser, 1997) — a hybrid of **quicksort**, **heapsort**, and **insertion sort** — on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it begins with **median-of-three Lomuto quicksort**, finishes partitions of size $\le 16$ with **insertion sort**, and switches to **heapsort** when the recursion depth exceeds $2\lfloor\log_2 n\rfloor$ — **unstable**, practically as fast as tuned quicksort, and $O(n\log n)$ in the worst case.

$$
\text{average } O(n \log n),\quad \text{worst } O(n \log n)\ \text{(heapsort fallback)},\quad n \le \mathrm{Max\_N} = 64
$$

This is the SPARK Level 4 port of the companion package [Ada-Introsort](https://github.com/RobertBoettcherSF/Ada-Introsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), Hoare partition, First-relative heap math, and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, Lomuto (so the pivot has a known final index), an in-place First-relative Floyd sift on an exhausted partition, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Quicksort](https://github.com/RobertBoettcherSF/Ada-SPARK-Quicksort), [Ada-SPARK-Heapsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Heapsort), and [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Ascending Musser introsort — median-of-three Lomuto + heapsort depth cutoff + insertion for small partitions.
* **`Sort_Traced (A, Max_Depth, Heap_Fallbacks)`** / **`Depth_Budget (N)`**: the same sort with an explicit depth budget and a count of slices finished by the depth-0 heapsort fallback (`Sort (A)` uses `Depth_Budget (A'Length)` = $2\lfloor\log_2 n\rfloor$). Lets tests prove the fallback actually ran.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **`Insertion_Threshold`**: Classic Musser / SGI / libstdc++ small-partition cutoff ($16$).
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, a `Subprogram_Variant` on recursive `Intro_Sort_Rec`, insertion / heap / Lomuto invariants, and a glue lemma that reassembles a sorted slice at the pivot.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (permutation is proved and checked by tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic / recursion VCs stay within automated SMT reach. For $n = 64$ the Musser depth budget is $2\lfloor\log_2 n\rfloor = 12$.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Any `A'First` in `1 .. Max_N` (at most `Max_N` elements); the tests sort shifted copies at origins 2, 7, 33 and slices flush to `Max_N`.
* **Lomuto partition** (sibling uses Hoare), matching [Ada-SPARK-Quicksort](https://github.com/RobertBoettcherSF/Ada-SPARK-Quicksort): the pivot is swapped into a final slot $P$, so the recursive sides are $A(\mathrm{Lo} .. P-1)$ and $A(P+1 .. \mathrm{Hi})$.
* Median-of-three is kept (first / middle / last, median parked at `Hi`).
* **Heapsort fallback is in place** on the exhausted slice $Lo..Hi$ with offset heap math: $\mathrm{Parent}(I)=Lo+\lfloor(I-Lo-1)/2\rfloor$, `Has_Left` ($I-Lo \le \lfloor(Hi-Lo-1)/2\rfloor$) checked before $\mathrm{Left}(I)=Lo+2(I-Lo)+1$, so no child index is computed past `Hi` (same scheme as [Ada-SPARK-Heapsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Heapsort)). No scratch copy.
* Insertion on a slice follows [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort) (`Insert_Step` + sorted-prefix invariants), generalized to $\mathrm{Lo} .. \mathrm{Hi}$.
* Bounded recursive `Intro_Sort_Rec` with `Subprogram_Variant => (Decreases => Hi - Lo)` rather than an explicit stack; $\lfloor\log_2 n\rfloor$ is a decision tree on $n \le 64$ (avoids a bit-loop VC).
* Ghost `All_Leq` / `All_Geq` value bounds are threaded through partition, insertion, heapsort, and recursion so the partition property survives the recursive permutations (full multiset equality is **not** a Level-4 postcondition).
* **SPARK proves sortedness and permutation** (`Post => Is_Sorted (A) and then Is_Perm (A, A'Old)`): `Occ (A, V, Last)` counts V in `A (A'First .. Last)` and `Is_Perm` compares the counts of every value of either array. The proof carries the ghost `Same_Occ` (equal counts for every Integer) through the loops with swap / point-update lemmas (no Assume / Annotate). Loop invariants and the Posts of body-local subprograms are proved and not re-evaluated at run time (`Assertion_Policy` Ignore in the body: `Same_Occ` ranges over every Integer); the Post of `Sort`, including `Is_Perm`, is still checked by the tests. Before 2026-10-09 the Post said only `Is_Sorted`, which an all-zeros body also proves (tools/vv/contract_scan.csv).
* Tests check `Is_Perm` against an independent sorted-copy comparison on every pair of arrays of length 0 .. 4 over -1 .. 1 (14,762 pairs, origins 1 and 7).

## Algorithm
Given an array $A$ of length $n \le \mathrm{Max\_N}$ with any $A'First$:

1. **Depth budget.** Set

   $$
   \mathrm{maxdepth} \leftarrow 2 \lfloor \log_2 n \rfloor.
   $$

   The factor $2$ is the classic Musser / SGI / GNU libstdc++ choice.

2. **Introsort recursion** on a partition of length $m$:

   - If $m \le \mathrm{Insertion\_Threshold}$ (here $16$): finish with **insertion sort**.
   - Else if $\mathrm{maxdepth} = 0$: **heapsort** the partition in place (offset Floyd heapify + extract-max on $Lo..Hi$). This caps the worst case at $O(n \log n)$.
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
| Worst | $O(n \log n)$ (heapsort fallback) | $O(\log n)$ stack |
| Tiny partition | $O(m^2)$ insertion, $m \le 16$ | $O(1)$ |

Unstable: equal keys may change relative order.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 339 assertions pass. Running `make prove` reports `Success: all checks proved (981 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, classic numeric example, signed domain including `Integer'First` / `Integer'Last`, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Hybrid paths**: sizes on both sides of `Insertion_Threshold` ($15$, $16$, $17$); all-equal $n=64$ (Lomuto returns $P=\mathrm{Hi}$ repeatedly so the depth budget hits $0$ and heapsort runs).
* **Heapsort fallback is exercised (section 15)**: random inputs almost never exhaust the depth budget, so the tests use a median-of-3 killer and check `Heap_Fallbacks >= 1`. Musser's $K_{64}$ peels two elements per partition for a Hoare scheme with the median parked at `Lo`; this port parks the median at `Hi` and uses Lomuto, so $K_{64}$ is not a killer here (heap count 0, still checked sorted). `Killer_64` (and the $n=48$ shape at `A (17 .. 64)`) is the same peel-by-2 shape for this exact median-of-three + Lomuto, generated with McIlroy's adversary ("A Killer Adversary for Quicksort", 1999). `Max_Depth => 0` heapsorts the whole slice at origins 2, 7, 17, 33, 47 (flush to `Max_N`) with exactly one fallback.
* **Pivot / depth stress**: Sorted, reverse, all-equal, sawtooth, organ-pipe, and random arrays up to `Max_N`.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$ (no combinatorial explosion).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Lomuto scan uses `pragma Loop_Invariant`; recursive `Intro_Sort_Rec` uses `Subprogram_Variant` and a ghost glue lemma to join the sorted sides at the pivot. Insertion and heapsort helpers prove `Sorted_Slice` on $\mathrm{Lo} .. \mathrm{Hi}$.
* **GNATprove Level 4:** `Success: all checks proved (981 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Insertion_Threshold` | Small-partition cutoff (`16`) |
| `In_Bounds` | `A'Length <= Max_N`, `A'First in 1 .. Max_N`, `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending Musser introsort (`Post => Is_Sorted`) |
| `Depth_Limit` / `Depth_Budget` | Depth budget subtype (`0 .. 12`) / $2\lfloor\log_2 N\rfloor$ |
| `Sort_Traced` | `Sort` with explicit `Max_Depth` and `Heap_Fallbacks` count (`Post => Is_Sorted`, count $\le$ `A'Length`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
