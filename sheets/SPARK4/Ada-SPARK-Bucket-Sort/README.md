# Bucket Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic [bucket sort](https://en.wikipedia.org/wiki/Bucket_sort) (also called **bin sort**) on a bounded-key `Element` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it **scatters** keys into $\mathrm{Max\_Buckets}$ uniform-width bins, **insertion-sorts** each bin, then **gathers** the bins in order. With roughly uniform keys it runs in **average linear time**; the worst case is $O(n^{2})$ when every key lands in one bin (insertion sort).

$$
k = \mathrm{Max\_Buckets} = 16,\quad n \le \mathrm{Max\_N} = 64,\quad \mathrm{Max\_Key} = 255,\quad \mathrm{Bucket\_Width} = 16
$$

This is the SPARK Level 4 port of the companion package [Ada-Bucket-Sort](https://github.com/RobertBoettcherSF/Ada-Bucket-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_Length` / `Max_Buckets`, exceptions (`Invalid_Argument`), arbitrary `Integer` keys with a dynamic min/max span, $k = \min(n, \mathrm{Max\_Buckets})$, and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), keys restricted to `0 .. Max_Key` (`Max_Key = 255`), a **fixed** `Max_Buckets = 16` static flat store, `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape and key cap: [Ada-SPARK-Counting-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Counting-Sort).

## Features
* **`Sort (A)`**: Ascending bucket sort (scatter → per-bucket insertion → gather).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; scatter / gather prove RTE; the final insertion pass (Shell gap-$1$ pattern) proves sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`. Element subtype enforces the key-domain cap.
* **Static flat store**: `Max_Buckets * Max_N` cells plus a count table — no heap / unbounded vectors.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* `Max_Key = 255` (sibling accepts the full `Integer` range with a dynamic min/max span) so bucket-index math is a single division $X / \mathrm{Bucket\_Width}$.
* Fixed `Max_Buckets = 16` (sibling uses $k = \min(n, 10\,000)$) so the store is a static flat array of size $16 \times 64$.
* No exceptions: length / shape are `Pre => In_Bounds (A)`; keys are the `Element` subtype `0 .. Max_Key`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Uniform-width bins over the closed domain $0..\mathrm{Max\_Key}$ instead of $\lfloor (k-1)\,(x-\min)/(\max-\min)\rfloor$ on a dynamic span.
* Scatter / per-bucket insertion / gather prove only `In_Bounds` / RTE. The final insertion pass reuses the insertion-sort Level-4 argument for `Is_Sorted` (same strategy as [Ada-SPARK-Shell-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Shell-Sort) gap-$1$).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
Given an array $A$ of length $n$ with keys in $0..\mathrm{Max\_Key}$:

1. If $n \le 1$, return.
2. **Scatter** each key $x$ into bucket
   $$
   \left\lfloor \frac{x}{\mathrm{Bucket\_Width}} \right\rfloor
   $$
   so $0$ maps to bucket $0$ and $\mathrm{Max\_Key}$ to bucket $\mathrm{Max\_Buckets}-1$.
3. **Sort** each non-empty bucket with insertion sort (stable, excellent for small bins).
4. **Gather** buckets $0..\mathrm{Max\_Buckets}-1$ back into $A$.
5. **Final insertion pass** (proof vehicle) — identity on a correctly gathered array.

Empty and singleton arrays are no-ops.

## Contrast with counting / pigeonhole sort

| Algorithm | Auxiliary structure | Best when |
| --------- | ------------------- | --------- |
| **Bucket sort** | $k$ buckets (here $k = 16$) + per-bucket sort | Keys roughly uniform; range may be larger than $k$ |
| **Counting sort** | Count table of size $\mathrm{Max\_Key}+1$ | Small key span; $O(n+k_{\mathrm{span}})$ worst case |
| **Pigeonhole** | One hole (list/segment) per key | Same small-span regime |

Bucket sort with bucket size $1$ degenerates toward counting sort. Two buckets behave like quicksort with a midpoint-of-range pivot.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 232 assertions pass. Running `make prove` reports `Success: all checks proved (177 checks).`

## Testing
* **Functional correctness**: Empty / singleton, Wikipedia-style integer example, reverse / already-sorted / almost-sorted, bin-edge clustering, power-of-two and odd lengths.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Tagged encodings**: Values such as `key×10 + tag` (kept in `0 .. Max_Key`) agree with the stable reference order.
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
* Scatter loop tracks `Counts (B) <= I-1`; per-bucket insertion and gather discharge RTE; `Insert_Step` / `Insertion_Pass` grow a sorted prefix.
* **GNATprove Level 4:** `Success: all checks proved (177 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Element` (`0 .. Max_Key`) |
| `Max_N` | Classroom capacity bound (`64`) |
| `Max_Key` | Inclusive key cap (`255`) |
| `Max_Buckets` | Fixed bin count (`16`) |
| `Bucket_Width` | Uniform bin width (`16`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending bucket sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
