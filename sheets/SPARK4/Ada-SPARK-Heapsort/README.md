# Heapsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [heapsort](https://en.wikipedia.org/wiki/Heapsort) on an `Integer` array (J. W. J. Williams, 1964; Floyd bottom-up `heapify`, 1964). Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it builds a binary **max-heap**, then repeatedly **extracts the maximum** into a growing sorted suffix — **unstable**, **in-place**, and $O(n \log n)$ in the best, average, and worst cases.

$$
T(n) = O(n) + O(n \log n) = O(n \log n)
$$

This is the SPARK Level 4 port of the companion package [Ada-Heapsort](https://github.com/RobertBoettcherSF/Ada-Heapsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_Length`, exceptions (`Invalid_Argument`), and First-relative child math for arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and 1-based indices so $\mathrm{Parent}(I)=I/2$, $\mathrm{Left}(I)=2I$, $\mathrm{Right}(I)=2I+1$. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Quicksort](https://github.com/RobertBoettcherSF/Ada-SPARK-Quicksort), [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort), and [Ada-SPARK-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Merge-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending heapsort (Floyd `Heapify` + extract-max).
* **`Heapify` / `Sift_Down`**: Educational heap primitives (public; lighter Posts than the internal restore helper).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition of `Sort`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, ghost parent-form heap predicates, and extract-max invariants that reassemble a sorted array.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (permutation is checked by tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $\mathrm{Max\_Length}=100\,000$) so array / arithmetic / heap VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First` with First-relative 0-based child math).
* 1-based child formulas: $\mathrm{Parent}=I/2$, $\mathrm{Left}=2I$, $\mathrm{Right}=2I+1$.
* Public `Sift_Down` / `Heapify` keep lighter Posts (frame + bounds); Sort uses an internal `Sift_Down_Restore` with ghost `Heap_From` / `Heap_Leq_Suffix` so Level 4 can prove `Is_Sorted` without `Intentional` annotations.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. **Build-heap (`Heapify`).** Sift down every non-leaf from $\lfloor n/2 \rfloor$ down to $1$ (Floyd). Cost $O(n)$.
2. **Extract-max.** For $\mathrm{Heap\_Last}$ from $n$ down to $2$: swap $A(1)$ with $A(\mathrm{Heap\_Last})$, shrink the heap, sift down the new root. Cost $O(n \log n)$.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 140 assertions pass. Running `make prove` reports `Success: all checks proved (340 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, classic numeric example, signed domain including `Integer'First` / `Integer'Last`, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Heap primitives**: `Heapify` builds a max-heap; `Sift_Down` repairs a damaged root; one extract-max step.
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
* Ghost `Is_Heap` / `Heap_From` (parent-form), `Heap_Leq_Suffix`, and `Lemma_Root_Is_Max` support the extract-max sorted-suffix argument.
* **GNATprove Level 4:** `Success: all checks proved (340 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sift_Down` | Repair max-heap at `Root` within `1 .. Heap_Last` |
| `Heapify` | Floyd bottom-up build of a binary max-heap |
| `Sort` | Ascending in-place heapsort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
