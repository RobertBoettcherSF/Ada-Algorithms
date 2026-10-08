# Strand Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [strand sort](https://en.wikipedia.org/wiki/Strand_sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it repeatedly extracts a nondecreasing *strand* from the remaining input and merges it into a sorted output using only fixed static buffers of size $\mathrm{Max\_N}$ (no unbounded lists). Best case $O(n)$ when already sorted; worst $O(n^2)$ when reverse-sorted; average often cited around $O(n \log n)$.

$$
\text{best } O(n),\quad \text{average } O(n\log n),\quad \text{worst } O(n^2),\quad n \le \mathrm{Max\_N} = 64
$$

This is the SPARK Level 4 port of the companion package [Ada-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-Strand-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a larger `Max_N` ($4096$), exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, fixed `Input` / `Strand` / `Output` / `Remaining` buffers, and a strand phase that is proved to sort on its own. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape and merge-buffer spirit: [Ada-SPARK-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Merge-Sort).

## Features
* **`Sort (A)`**: Ascending strand sort via static buffers; the strand phase alone is proved to sort.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; strand extract / merge loop invariants (`Sorted_Slice` on `Strand`, `Output` and the merge scratch) prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Static buffers only**: No unbounded lists; all work arrays are `1 .. Max_N`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $4096$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Fixed `Input` / `Strand` / `Output` / `Remaining` buffers of size `Max_N` (sibling uses length-exact locals).
* Outer strand loop capped at `Max_N` iterations so termination proves under Level 4 (each iteration removes $\ge 1$ element).
* **Sortedness proof:** each extracted strand is nondecreasing (it only takes elements $\ge$ the last taken), the two-way merge keeps `Output` nondecreasing (the last written element is $\le$ both merge heads), and the invariant `Input_Len + Iter - 1 <= N` shows `Input` is empty after the capped outer loop, so all $n$ elements are in `Output`. There is no fallback pass.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return.
2. Copy $A$ into a fixed `Input` buffer (`Input_Len = n`, `Output_Len = 0`).
3. While `Input_Len > 0` (capped at `Max_N` outer iterations):
   * **Extract strand:** take `Input(1)`, then greedily append every subsequent element $\ge$ last taken; leftovers go to `Remaining`.
   * **Merge:** stable two-way merge of `Strand` into `Output` (prefer left when $L \le R$), scratch in `Remaining`.
   * Replace `Input` with `Remaining`.
4. Copy `Output` back into $A$ (already sorted).

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 226 assertions pass. Running `make prove` reports `Success: all checks proved (254 checks).` (also at `--mode=silver --level=2`).

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia-style example, strand-friendly interleaved runs, signed domain, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
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
* Strand / merge loops use `pragma Loop_Invariant` / `Loop_Variant` with `Sorted_Slice` on the strand, the output and the merge scratch; the strand outer loop is iteration-capped at `Max_N` and its invariant `Input_Len + Iter - 1 <= N` proves every element is merged.
* **GNATprove Level 4:** `Success: all checks proved (254 checks).` (also at `--mode=silver --level=2`).
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending strand sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
