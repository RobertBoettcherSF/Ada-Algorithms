# Cocktail Shaker Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [cocktail shaker sort](https://en.wikipedia.org/wiki/Cocktail_shaker_sort) (bidirectional bubble sort / cocktail sort / shaker sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it alternates a **forward** pass (bubble the maximum to $\mathit{Hi}$) and a **backward** pass (bubble the minimum to $\mathit{Lo}$), shrinking the active $\mathit{Lo}..\mathit{Hi}$ window after each pass and stopping early on a swap-free pass — using only $O(1)$ auxiliary memory (**in-place**), adapting toward $O(n)$ on already-sorted input, and preserving equal-key order when the swap predicate is strict `>` (**stable**).

$$
\text{best } O(n),\quad \text{average/worst } O(n^2),\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Cocktail-Shaker-Sort](https://github.com/RobertBoettcherSF/Ada-Cocktail-Shaker-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`); this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a proof that the shaker passes themselves sort (sorted prefix and suffix grow around a shrinking window; no extra bubble sort at the end). README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort), [Ada-SPARK-Odd-Even-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Odd-Even-Sort), and [Ada-SPARK-Comb-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Comb-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending cocktail shaker (bidirectional bubble) sort with a shrinking $\mathit{Lo}..\mathit{Hi}$ window, and early exit on a clean pass.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; the forward/backward passes carry the `Sorted_Slice` / `Prefix_Leq_Suffix` window invariants that prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Strict `>` when swapping so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Any `A'First` in `1 .. Max_N` (index subtype `Live_Index`, at most `Max_N` elements); indices are First-relative. Tests sort shifted copies at origins 2, 7, `Max_N / 2 + 1` and slices flush to `Max_N`.
* Forward and backward passes carry the window invariant (`Sorted_Slice` / `Prefix_Leq_Suffix`: a sorted prefix <= the rest and a sorted suffix >= the rest), so `Sort` proves `Is_Sorted` from the cocktail passes alone; there is no extra bubble sort at the end.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return.
2. Set $\mathit{Lo} \leftarrow 1$, $\mathit{Hi} \leftarrow n$. While $\mathit{Lo} < \mathit{Hi}$ (stop early when a pass is swap-free):
   * **Forward:** for $i$ from $\mathit{Lo}$ to $\mathit{Hi}-1$, swap if $A(i) > A(i+1)$; then $\mathit{Hi} \leftarrow \mathit{Hi}-1$ (largest key in place).
   * **Backward:** for $i$ from $\mathit{Hi}$ down to $\mathit{Lo}+1$, swap if $A(i-1) > A(i)$; then $\mathit{Lo} \leftarrow \mathit{Lo}+1$ (smallest key in place).
3. When the window is empty (or a pass made no swap) the array is sorted: everything before $\mathit{Lo}$ and after $\mathit{Hi}$ is sorted and in place.

Empty and singleton arrays are no-ops.

A turtle (small key near the end) such as $(2,3,4,5,1)$ is placed in one cocktail round: forward yields $(2,3,4,1,5)$; backward yields $(1,2,3,4,5)$.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 303 assertions pass. Running `make prove` reports `Success: all checks proved (269 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia turtle $(2,3,4,5,1)$ and mixed cocktail demo, signed domain, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Stability**: Tagged keys (`key×1000 + arrival_tag`) keep tag order for equal keys.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Cocktail forward/backward loops use `pragma Loop_Invariant` / `Loop_Variant`; the outer `while Lo < Hi` loop has variant `Hi - Lo` (no iteration cap).
* **GNATprove Level 4:** `Success: all checks proved (269 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'Length <= Max_N`, `A'First in 1 .. Max_N`, `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending in-place cocktail shaker sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
