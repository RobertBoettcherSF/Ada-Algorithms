# Samplesort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [samplesort](https://en.wikipedia.org/wiki/Samplesort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it chooses $\mathrm{Num\_Buckets}-1$ pivots from equally spaced samples, cuts the array in place into $\mathrm{Num\_Buckets}$ buckets (one partition of the remaining suffix per pivot) and insertion-sorts each bucket where it lies. The proof shows that these steps sort; there is no fallback pass. With $p$ fixed at 8 the bucketing costs $O(p\,n)$ and the bucket sorts about $O(n^{2}/p)$ on balanced buckets; the worst case is $O(n^{2})$ when most keys land in one bucket.

$$
p = \mathrm{Num\_Buckets} = 8,\quad n \le \mathrm{Max\_N} = 64,\quad \text{pivots} = p-1 = 7
$$

This is the SPARK Level 4 port of the companion package [Ada-Samplesort](https://github.com/RobertBoettcherSF/Ada-Samplesort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes `Sequential_Sample_Sort` / `Parallel_Sample_Sort` (Ada tasks) / `Oversampling_Sample_Sort`, a parameterised `Num_Buckets`, `Quick_Sort` buckets, exceptions (`Invalid_Bucket_Count` / `Invalid_Oversample_Factor`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), fixed `Num_Buckets = 8`, a single `Sort` procedure, `In_Bounds` / `Is_Sorted` contracts, in-place buckets (no work array), and a proof that the samplesort steps themselves sort. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Flashsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Flashsort), [Ada-SPARK-Bucket-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bucket-Sort).

## Features
* **`Sort (A)`**: Ascending educational samplesort (sample and sort pivots / cut buckets in place / insertion-sort each bucket).
* **`Is_Sorted` / `In_Bounds` / `Occ` / `Is_Perm`**: Expression-function guards and value counts; `Is_Sorted (A) and then Is_Perm (A, A'Old)` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; the bucket partition and the bucket insertion sort carry the invariants (`Sorted_Slice`, `All_In` value bounds) that prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than raised exceptions.
* **In place**: buckets are cut out of the array itself by partitioning — no work array, no heap / unbounded vectors, no Ada tasks.

## Deliberate simplifications vs non-SPARK sibling (Ada-Samplesort)
* `Max_N = 64` so array / arithmetic VCs stay within automated SMT reach.
* Fixed `Num_Buckets = 8` (sibling takes `Num_Buckets` as a parameter).
* **No Parallel variant** — SPARK Level 4 classroom package has no Ada tasks.
* **No Oversampling API** — single deterministic stride sample; no oversample factor.
* Single `Sort` procedure (sibling: Sequential / Parallel / Oversampling + exposed `Quick_Sort`).
* `Integer` `Element_Array` with `A'First = 1` (sibling: `Data_Element` / arbitrary `A'First`).
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Buckets are formed in place, one pivot at a time, by partitioning the not yet placed suffix (sibling allocates `Temp` of length $n$, distributes into it, and uses task workers).
* Per-bucket **insertion** sort (sibling uses `Quick_Sort` on buckets).
* One invariant carries the proof across buckets: the placed prefix is sorted, `Floor` is its last element, and every element still to place is $\ge$ `Floor`. A bucket holds values in `Floor` .. pivot and the rest stays above the pivot, so each sorted bucket extends the sorted prefix.
* **SPARK proves sortedness and permutation** (`Post => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old)`; before 2026-10-10 the Post said only `Is_Sorted`, which a constant-fill body also proves: tools/vv/contract_scan.csv). Every move on `A` is an exchange: `Swap` proves `Same_Occ` (the count of every value) with `Lemma_Swap`, `Partition` swaps, and `Insert_Step` moves the key down by exchanges with the larger neighbour (the same comparisons as the earlier shifting version); the pivots live in their own array. `Sort_Bucket`, `Partition` and `Sort` chain `Same_Occ`. It ranges over every `Integer` value, so the body's contracts, invariants and assertions are proved and not checked at run time (`Assertion_Policy` in the body, `tools/vv/proof_escapes.csv` runtime_only); the spec Post of `Sort` still runs in the tests.

## Algorithm
Given an array $A$ of length $n$:

1. If $n \le 1$, return.
2. If $n < \mathrm{Num\_Buckets}$, there are no pivots: the whole array is one bucket (step 6).
3. **Sample.** Choose $p-1$ pivots at equally spaced indices
   $$
   A\bigl[i \cdot \lfloor n / p \rfloor\bigr],\quad i = 1..p-1
   $$
   (deterministic stride; no RNG; the largest index is at most $n$, no clamp).
4. **Sort pivots** with the same insertion sort used for the buckets.
5. **Cut buckets in place.** For $k = 1..p-1$: partition the not yet placed suffix $A[\mathit{Lo}..n]$ so that the keys $\le \mathrm{pivot}_k$ come first; that block is bucket $k$. Insertion-sort it where it lies and move $\mathit{Lo}$ past it.
6. **Last bucket:** insertion-sort $A[\mathit{Lo}..n]$ (every key above the largest pivot, or the whole array when $n < p$) $\to$ fully sorted (`Is_Sorted` proved).

Empty and singleton arrays are no-ops. Samplesort is **not** required to be stable in this educational port.

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Best / average (balanced buckets) | $O(p\,n + n^{2}/p)$ with $p = 8$ | $O(p)$ for the pivots |
| Worst (almost all items in one bucket) | $O(n^{2})$ | $O(p)$ |
| $n < \mathrm{Num\_Buckets}$ | $O(n^{2})$ insertion sort (one bucket) | $O(1)$ beyond locals |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 398 assertions pass. `make prove` (level 4) and `gnatprove --mode=silver --level=2 --steps=1000000` report `Success: all checks proved (418 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, duplicates / all-equal, signed domain, `Integer'First` / `Integer'Last`, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Samplesort-specific**: Thresholds around `Num_Buckets` ($n = 7,8,9,16,24$), clustered / gapped keys, uniform-ish random arrays.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Num_Buckets = 8`.
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
* Partition, insertion and bucket loops use `pragma Loop_Invariant` / `Loop_Variant`; the bucket loop keeps the sorted prefix / `Floor` invariant described above.
* **GNATprove (level 4, and silver level 2):** `Success: all checks proved (418 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Num_Buckets` | Fixed bucket count (`8`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending samplesort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
