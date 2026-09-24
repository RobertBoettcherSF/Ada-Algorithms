# Timsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [Timsort](https://en.wikipedia.org/wiki/Timsort) (Tim Peters, 2002) — a hybrid stable sort derived from merge sort and insertion sort — on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it finds natural runs inside $\mathrm{Minrun}$-aligned windows, extends short ones with insertion, then merges bottom-up via a fixed temporary buffer of size $\mathrm{Max\_N}$ (prefer left on ties $L \le R$) — preserving equal-key order (**stable**), running in $O(n\log n)$ worst case, and using $\Theta(n)$ auxiliary memory for the temp buffer.

$$
O(n \log n)\ \text{worst},\quad \text{near-linear on sorted runs},\quad n \le \mathrm{Max\_N} = 64,\quad \mathrm{Minrun} = 8
$$

This is the SPARK Level 4 port of the companion package [Ada-Timsort](https://github.com/RobertBoettcherSF/Ada-Timsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a full Timsort run stack with classic $X/Y/Z$ merge invariants, power-of-two-related $\mathrm{minrun}\in[32,64]$, a larger `Max_N`, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), fixed $\mathrm{Minrun} = 8$ windows, `In_Bounds` / `Is_Sorted` contracts, a static `Temp (1 .. Max_N)`, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Merge-Sort) and [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Educational Timsort hybrid — natural runs + insertion extend + bottom-up stable merge via a fixed temp buffer.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **`Minrun`**: Classroom minimum run length ($8$) so initial runs stay Width-aligned for Level 4 merge proofs.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, stable merge invariants, and `Sorted_Runs` / ghost lemmas that doubling Width preserves run sortedness until $\mathrm{Width} \ge n$.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Prefer left when $L \le R$ so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **Fixed $\mathrm{Minrun} = 8$** windows instead of classic power-of-two-related $\mathrm{minrun}\in[32,64]$ (sibling): keeps prepared runs Width-aligned for bottom-up merge proofs.
* **Bottom-up merge** instead of the Timsort run-stack $X/Y/Z$ invariants (sibling): fixed `Temp (1 .. Max_N)`, `Merge_Pass` / recursive `Merge_From`, and ghost `Sorted_Runs` lemmas so Level 4 discharges sortedness without stack-invariant contracts.
* No galloping mode (also skipped in the non-SPARK educational sibling).
* After reversing a strictly descending natural run, the reversed slice is re-established sorted via insertion (avoids a delicate reverse-sortedness lemma at Level 4).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 239 assertions pass. Running `make prove` reports `Success: all checks proved (636 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia-style example, signed domain, $\mathrm{Minrun}$ boundaries, natural-run patterns (desc-then-asc, few runs, nearly sorted).
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Stability**: Tagged keys (`key×1000 + arrival_tag`) keep tag order for equal keys.
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
* `Prepare_Block` / `Insertion_Extend` establish $\mathrm{Minrun}$-aligned `Sorted_Slice`s; stable `Merge` uses `pragma Loop_Invariant` / `Loop_Variant`; bottom-up `Merge_From` / `Merge_Pass` plus ghost `Sorted_Runs` / `Lemma_Short_Tail` discharge Width doubling at Level 4.
* **GNATprove Level 4:** `Success: all checks proved (636 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
