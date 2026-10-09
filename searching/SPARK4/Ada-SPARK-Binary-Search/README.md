# Binary Search Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the classic iterative [binary search algorithm](https://en.wikipedia.org/wiki/Binary_search_algorithm) (also known as half-interval search, logarithmic search, or binary chop) on a sorted ascending `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it also offers leftmost / rightmost variants for duplicate keys, with the overflow-safe midpoint

$$
m = L + \left\lfloor\frac{R - L}{2}\right\rfloor
$$

Worst-case complexity is $O(\log n)$ comparisons. The absent sentinel is always $0$ (`A` may start at any origin in `1 .. Max_N`, so $0$ is never a live index).

This is the SPARK Level 4 port of the companion package [Ada-Binary-Search](https://github.com/RobertBoettcherSF/Ada-Binary-Search) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), and sentinel $A'\mathit{First}-1$; this port keeps arbitrary `A'First` but trades the rest for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Related search siblings: [Ada-Uniform-Binary-Search](https://github.com/RobertBoettcherSF/Ada-Uniform-Binary-Search), [Ada-Fibonacci-Search](https://github.com/RobertBoettcherSF/Ada-Fibonacci-Search).

## Features
* **`Find` / `Find_First` / `Find_Last`**: Classic iterative chop plus Wikipedia leftmost / rightmost bound searches.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards used in every entry-point `Pre`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, overflow in the midpoint formula, and non-termination of bounded search loops.
* **Contract Discipline**: Preconditions replace exceptions; oversized / unsorted arrays are `Pre` violations rather than `Invalid_Argument`.
* **Sentinel $0$**: Absent keys return $0$; live indices are `A'First .. A'Last` within `1 .. Max_N`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length and sortedness are `Pre => In_Bounds (A) and then Is_Sorted (A)`.
* First-relative: any `A'First` (`Element_Array` is indexed by `Live_Index`); `In_Bounds` only bounds `A'Length <= Max_N`. Miss sentinel is $0$ (sibling returns $A'\mathit{First}-1$). Section 11 of `tests.adb` checks `Find`, `Find_First` and `Find_Last` at `A'First` = 1, 5, 17, 33, flush to `Max_N`, a single cell at `Max_N`, `2 .. Max_N`, and an empty array at origin 10.
* Search loops are bounded `for` loops with `pragma Loop_Invariant` so termination is immediate for the prover.
* Posts prove “hit ⇒ correct index” (and leftmost / rightmost when found); full “miss ⇒ key absent” completeness is exercised by tests rather than claimed as a Level-4 post without extra ghost lemmas.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 618 assertions pass. Running `make prove` reports `Success: all checks proved (106 checks).`

## Testing
* **Functional correctness**: Empty / singleton, small sorted arrays, Wikipedia duplicate plates, signed domain, power-of-two and odd lengths, two-element boundaries.
* **Agreement**: `Find` / `Find_First` / `Find_Last` vs linear reference at `Max_N`, including duplicate plateaus and random sorted queries.
* **Contract helpers**: `Is_Sorted` true/false cases; `In_Bounds` at capacity.
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
* Loops are bounded `for` loops with `pragma Loop_Invariant` so termination is immediate for the prover.
* **GNATprove Level 4:** `Success: all checks proved (106 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
