# Cocktail Shaker Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [cocktail shaker sort](https://en.wikipedia.org/wiki/Cocktail_shaker_sort) (bidirectional bubble sort / cocktail sort / shaker sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it alternates a **forward** pass (bubble the maximum to $\mathit{Hi}$) and a **backward** pass (bubble the minimum to $\mathit{Lo}$), shrinking the active $\mathit{Lo}..\mathit{Hi}$ window after each pass and stopping early on a swap-free pass — then finishes with a gap-$1$ bubble pass — using only $O(1)$ auxiliary memory (**in-place**), adapting toward $O(n)$ on already-sorted input, and preserving equal-key order when the swap predicate is strict `>` (**stable**).

$$
\text{best } O(n),\quad \text{average/worst } O(n^2),\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Cocktail-Shaker-Sort](https://github.com/RobertBoettcherSF/Ada-Cocktail-Shaker-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, capped outer cocktail rounds for termination, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape and bubble-finish proof pattern: [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort), [Ada-SPARK-Odd-Even-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Odd-Even-Sort), and [Ada-SPARK-Comb-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Comb-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending cocktail shaker (bidirectional bubble) sort with a shrinking $\mathit{Lo}..\mathit{Hi}$ window, early exit on a clean pass, and a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; cocktail forward/backward passes prove `In_Bounds` / RTE; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Strict `>` when swapping so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Outer cocktail-round loop capped at `Max_N` iterations so termination proves under Level 4 (early exit on a clean pass or collapsed window is kept).
* Cocktail forward/backward phases prove only `In_Bounds` / RTE; the final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Comb / Odd–Even). Full bidirectional partition invariants on the $\mathit{Lo}..\mathit{Hi}$ window are omitted as a classroom simplification.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return.
2. Set $\mathit{Lo} \leftarrow 1$, $\mathit{Hi} \leftarrow n$. For up to `Max_N` rounds (early exit when $\mathit{Lo} \ge \mathit{Hi}$ or a pass is swap-free):
   * **Forward:** for $i$ from $\mathit{Lo}$ to $\mathit{Hi}-1$, swap if $A(i) > A(i+1)$; then $\mathit{Hi} \leftarrow \mathit{Hi}-1$ (largest key in place).
   * **Backward:** for $i$ from $\mathit{Hi}$ down to $\mathit{Lo}+1$, swap if $A(i-1) > A(i)$; then $\mathit{Lo} \leftarrow \mathit{Lo}+1$ (smallest key in place).
3. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted.

Empty and singleton arrays are no-ops.

A turtle (small key near the end) such as $(2,3,4,5,1)$ is placed in one cocktail round: forward yields $(2,3,4,1,5)$; backward yields $(1,2,3,4,5)$.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 281 assertions pass. Running `make prove` reports `Success: all checks proved (204 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia turtle $(2,3,4,5,1)$ and mixed cocktail demo, signed domain, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Stability**: Tagged keys (`key×1000 + arrival_tag`) keep tag order for equal keys.
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
* Cocktail forward/backward loops use `pragma Loop_Invariant` / `Loop_Variant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates; cocktail-round loop is iteration-capped at `Max_N`.
* **GNATprove Level 4:** `Success: all checks proved (204 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending in-place cocktail shaker sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
