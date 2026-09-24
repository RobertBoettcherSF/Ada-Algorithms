# Flashsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [flashsort](https://en.wikipedia.org/wiki/Flashsort) (Neubert, 1998) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it assigns each of $n$ keys to one of $m$ classes by linear interpolation, permutes the array so classes occupy contiguous segments (cycle-following), insertion-sorts each class, then finishes with a proved gap-$1$ bubble pass. For uniformly distributed keys the classes are balanced and the flashsort phase is expected $O(n)$; the worst case is $O(n^2)$ when insertion sort finishes unbalanced classes.

$$
m = \max\bigl(2,\ \lfloor n / 10 \rfloor\bigr),\quad n \le \mathrm{Max\_N} = 64,\quad \mathrm{Class\_Divisor} = 10
$$

This is the SPARK Level 4 port of the companion package [Ada-Flashsort](https://github.com/RobertBoettcherSF/Ada-Flashsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a larger `Max_N` ($100\,000$), exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a static `Border_Array (1 .. Max_N)`, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape and finish pattern: [Ada-SPARK-Bucket-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bucket-Sort), [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort).

## Features
* **`Sort (A)`**: Ascending educational flashsort (histogram / cycle-follow / per-class insertion), then a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; flashsort phase proves `In_Bounds` / RTE; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Static borders only**: `Border_Array (1 .. Max_N)` for class upper borders; `Class_Of` uses `Long_Long_Integer` like the sibling.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Static `Border_Array (1 .. Max_N)` sized for $m \le \mathrm{Max\_N}$ (sibling allocates length-$m$ locals).
* Cycle-follow permute uses iteration caps and index guards so Level-4 RTE discharges; flashsort phase posts only `In_Bounds` / RTE.
* The final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Strand / Comb / Odd_Even). Full class-order / permutation posts that would fight Level 4 are deferred to that finish and to tests.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
Given an array $A$ of length $n$:

1. If $n \le 1$, return.
2. **Min / max.** Scan $A$ for $A_{\min}$ and $A_{\max}$. If equal, return (already sorted).
3. **Number of classes.** Choose
   $$
   m = \max\bigl(2,\ \lfloor n / \mathrm{Class\_Divisor} \rfloor\bigr)
   $$
   with $\mathrm{Class\_Divisor} = 10$ (Neubert's $m \approx 0.1\,n$).
4. **Histogram and prefix sums.** Count items per class into a static vector $L$; prefix-sum so $L_k$ is the inclusive 1-based upper border of class $k$.
5. **Classification.** Map key $x$ by linear interpolation:
   $$
   K = 1 + \left\lfloor
     \frac{(m-1)\,(x - A_{\min})}{A_{\max} - A_{\min}}
   \right\rfloor.
   $$
   So $A_{\min} \mapsto 1$ and $A_{\max} \mapsto m$. Arithmetic uses `Long_Long_Integer`.
6. **In-place permutation (cycle-following).** Walk $i = 1..n$; if position $i$ is still unclassified, follow the cycle by swapping each item into slot $j = L_b$ and decrementing $L_b$ until the cycle returns to $i$.
7. **Per-class insertion sort** within each class segment.
8. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted (`Is_Sorted` proved).

Empty and singleton arrays are no-ops. Flashsort is **not stable**.

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Best / average (uniform keys, $m = \Theta(n)$) | $O(n)$ flashsort phase + $O(n^2)$ finish worst | $O(\mathrm{Max\_N})$ for $L$ |
| Worst (almost all items in a few classes) | $O(n^2)$ | $O(\mathrm{Max\_N})$ |
| All-equal | $O(n)$ min/max scan, then return | $O(1)$ |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 248 assertions pass. Running `make prove` reports `Success: all checks proved (350 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, duplicates / all-equal, signed domain, `Integer'First` / `Integer'Last` class-map cases, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Flashsort-specific**: Class-count thresholds ($n$ around $10,20,30,64$), clustered / gapped keys, uniform-ish random arrays.
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
* Flashsort loops use `pragma Loop_Invariant` / `Loop_Variant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (350 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Class_Divisor` | $m = \max(2, \lfloor n/10 \rfloor)$ (`10`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending flashsort + bubble finish (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
