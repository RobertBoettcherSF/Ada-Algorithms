# Samplesort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [samplesort](https://en.wikipedia.org/wiki/Samplesort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it chooses $\mathrm{Num\_Buckets}-1$ pivots from equally spaced samples, distributes keys into $\mathrm{Num\_Buckets}$ static buckets, insertion-sorts each bucket, concatenates, then finishes with a proved gap-$1$ bubble pass. With balanced buckets the samplesort phase is near $O(n\log n)$; the worst case is $O(n^{2})$ when insertion / bubble finish unbalanced partitions.

$$
p = \mathrm{Num\_Buckets} = 8,\quad n \le \mathrm{Max\_N} = 64,\quad \text{pivots} = p-1 = 7
$$

This is the SPARK Level 4 port of the companion package [Ada-Samplesort](https://github.com/RobertBoettcherSF/Ada-Samplesort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes `Sequential_Sample_Sort` / `Parallel_Sample_Sort` (Ada tasks) / `Oversampling_Sample_Sort`, a parameterised `Num_Buckets`, `Quick_Sort` buckets, exceptions (`Invalid_Bucket_Count` / `Invalid_Oversample_Factor`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), fixed `Num_Buckets = 8`, a single `Sort` procedure, `In_Bounds` / `Is_Sorted` contracts, static `Work (1 .. Max_N)` + Counts / Borders, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape and finish pattern: [Ada-SPARK-Flashsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Flashsort), [Ada-SPARK-Bucket-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bucket-Sort).

## Features
* **`Sort (A)`**: Ascending educational samplesort (sample / distribute / per-bucket insertion / concatenate), then a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; samplesort phase proves `In_Bounds` / RTE; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than raised exceptions.
* **Static work only**: `Work (1 .. Max_N)` plus Counts / Starts borders — no heap / unbounded vectors, no Ada tasks.

## Deliberate simplifications vs non-SPARK sibling (Ada-Samplesort)
* `Max_N = 64` so array / arithmetic VCs stay within automated SMT reach.
* Fixed `Num_Buckets = 8` (sibling takes `Num_Buckets` as a parameter).
* **No Parallel variant** — SPARK Level 4 classroom package has no Ada tasks.
* **No Oversampling API** — single deterministic stride sample; no oversample factor.
* Single `Sort` procedure (sibling: Sequential / Parallel / Oversampling + exposed `Quick_Sort`).
* `Integer` `Element_Array` with `A'First = 1` (sibling: `Data_Element` / arbitrary `A'First`).
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Static `Work (1 .. Max_N)` + Counts / Borders (sibling allocates `Temp` of length $n$ and task workers).
* Per-bucket **insertion** sort (sibling uses `Quick_Sort` on buckets).
* Samplesort phase posts only `In_Bounds` / RTE. The final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Flashsort / Strand / Comb / Odd_Even).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
Given an array $A$ of length $n$:

1. If $n \le 1$, return.
2. If $n < \mathrm{Num\_Buckets}$, skip sampling (leave ordering to the bubble finish).
3. **Sample.** Choose $p-1$ pivots at equally spaced indices
   $$
   A\bigl[i \cdot \lfloor n / p \rfloor\bigr],\quad i = 1..p-1
   $$
   (deterministic stride; no RNG). Clamp the sample index into $1..n$.
4. **Sort pivots** with insertion sort on the length-$(p-1)$ vector.
5. **Count / distribute.** Map each key $x$ to bucket
   $$
   b = \min\{k : x \le \mathrm{pivot}_k\}
   $$
   or $b = p$ if $x$ exceeds every pivot; write into static `Work` via prefix Starts / Counts.
6. **Sort each bucket** in `Work` with insertion sort.
7. **Concatenate** `Work` back into $A$.
8. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted (`Is_Sorted` proved).

Empty and singleton arrays are no-ops. Samplesort is **not** required to be stable in this educational port.

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Best / average (balanced buckets) | near $O(n\log n)$ samplesort phase + $O(n^{2})$ finish worst | $O(\mathrm{Max\_N})$ for `Work` |
| Worst (almost all items in a few buckets) | $O(n^{2})$ | $O(\mathrm{Max\_N})$ |
| $n < \mathrm{Num\_Buckets}$ | $O(n^{2})$ bubble finish | $O(1)$ beyond locals |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 233 assertions pass. Running `make prove` reports `Success: all checks proved (287 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, duplicates / all-equal, signed domain, `Integer'First` / `Integer'Last`, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Samplesort-specific**: Thresholds around `Num_Buckets` ($n = 7,8,9,16,24$), clustered / gapped keys, uniform-ish random arrays.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Num_Buckets = 8`.
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
* Samplesort loops use `pragma Loop_Invariant` / `Loop_Variant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (287 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Num_Buckets` | Fixed bucket count (`8`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending samplesort + bubble finish (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
