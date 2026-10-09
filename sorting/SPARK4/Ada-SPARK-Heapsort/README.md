# Heapsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [heapsort](https://en.wikipedia.org/wiki/Heapsort) on an `Integer` array (J. W. J. Williams, 1964; Floyd bottom-up `heapify`, 1964). Written in Ada 2022 and verified with SPARK (GNATprove Silver (level 2)), it builds a binary **max-heap**, then repeatedly **extracts the maximum** into a growing sorted suffix — **unstable**, **in-place**, and $O(n \log n)$ in the best, average, and worst cases.

$$
T(n) = O(n) + O(n \log n) = O(n \log n)
$$

This is the SPARK port of the companion package [Ada-Heapsort](https://github.com/RobertBoettcherSF/Ada-Heapsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_Length`, exceptions (`Invalid_Argument`), and a larger capacity; this port keeps the same First-relative child math for any `A'First` (= Lo): $\mathrm{Parent}(I)=Lo+\lfloor(I-Lo-1)/2\rfloor$, $\mathrm{Left}(I)=Lo+2(I-Lo)+1$, $\mathrm{Right}=\mathrm{Left}+1$, with `Has_Left` ($I-Lo \le (Hi-Lo-1)/2$) checked before `Left` is computed so nothing overflows near `Index'Last`; it adds a hard classroom bound (`Max_N = 64`) and `In_Bounds` / `Is_Sorted` contracts. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Quicksort](https://github.com/RobertBoettcherSF/Ada-SPARK-Quicksort), [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort), and [Ada-SPARK-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Merge-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending heapsort (Floyd `Heapify` + extract-max).
* **`Heapify` / `Sift_Down`**: Educational heap primitives (public; lighter Posts than the internal restore helper).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition of `Sort`.
* **Formal Verification**: Designed for GNATprove Silver (level 2) — absence of index errors, ghost parent-form heap predicates, and extract-max invariants that reassemble a sorted array.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (the result is a proved permutation of the input).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $\mathrm{Max\_Length}=100\,000$) so array / arithmetic / heap VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Any `A'First` (offset heap; Has_Left before Left) (sibling allows arbitrary `A'First` with First-relative 0-based child math).
* Offset heap on positions: $\mathrm{Left}=Lo+2(I-Lo)+1$ guarded by `Has_Left`; shifted-origin tests (origins 2, 7, 33 and flush to `Max_N`) check the result equals the 1-based sort.
* Public `Sift_Down` / `Heapify` keep lighter Posts (frame + bounds); Sort uses an internal `Sift_Down_Restore` with ghost `Heap_From` / `Heap_Leq_Suffix` so GNATprove can prove `Is_Sorted` without `Intentional` annotations.
* **SPARK proves sortedness and permutation** (`Post => Is_Sorted (A) and then Is_Perm (A, A'Old)`): every value occurs as often after the sort as before. A ghost count model (`Occ`, `Same_Occ`, swap lemmas) carries the property through sift-down and the extraction loop; `Is_Perm` is also evaluated at run time in the tests.

## Algorithm
1. **Build-heap (`Heapify`).** Sift down every non-leaf from $\lfloor n/2 \rfloor$ down to $1$ (Floyd). Cost $O(n)$.
2. **Extract-max.** For $\mathrm{Heap\_Last}$ from $n$ down to $2$: swap $A(1)$ with $A(\mathrm{Heap\_Last})$, shrink the heap, sift down the new root. Cost $O(n \log n)$.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 150 assertions pass. Running `make prove` reports `Success: all checks proved (529 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, classic numeric example, signed domain including `Integer'First` / `Integer'Last`, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Heap primitives**: `Heapify` builds a max-heap; `Sift_Down` repairs a damaged root; one extract-max step.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove Silver (level 2): 529 checks, all proved.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Ghost `Is_Heap` / `Heap_From` (parent-form), `Heap_Leq_Suffix`, and `Lemma_Root_Is_Max` support the extract-max sorted-suffix argument.
* **GNATprove Silver (level 2):** `Success: all checks proved (529 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'Length <= Max_N` (any origin) |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sift_Down` | Repair max-heap at `Root` within `1 .. Heap_Last` |
| `Heapify` | Floyd bottom-up build of a binary max-heap |
| `Sort` | Ascending in-place heapsort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
