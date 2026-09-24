# Ternary Search Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [ternary search](https://en.wikipedia.org/wiki/Ternary_search) in Ada 2022 with SPARK (GNATprove Level 4). The **primary** form finds an index of a **maximum** in a **unimodal** discrete `Integer` array by repeatedly trisecting the index range with overflow-safe thirds-points

$$
m_1 = L + \left\lfloor\frac{H - L}{3}\right\rfloor,
\qquad
m_2 = H - \left\lfloor\frac{H - L}{3}\right\rfloor.
$$

A **secondary** API searches for a key in a sorted ascending array with the same two midpoints (binary search is usually preferable). Worst-case complexity for the unimodal peak search is $O(\log n)$ comparisons (base $3/2$ shrinkage) plus $O(1)$ for the final linear window. The absent-key sentinel for `Find` is always $0$ (live indices are $1 .. N$).

This is the SPARK Level 4 port of the companion package [Ada-Ternary-Search](https://github.com/RobertBoettcherSF/Ada-Ternary-Search) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), arbitrary `A'First`, and sentinel $A'\mathit{First}-1$; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Unimodal` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK search sibling: [Ada-SPARK-Binary-Search](https://github.com/RobertBoettcherSF/Ada-SPARK-Binary-Search).

## Features
* **`Find_Maximum_Index`**: Discrete unimodal peak finding via trisection, finishing with a linear scan of a tiny window (`Hi − Lo ≤ 2`).
* **`Find`**: Pedagogical ternary key search on a sorted ascending array (prefer binary search in production).
* **`Is_Unimodal` / `Is_Sorted` / `In_Bounds`**: Expression-function guards used in every entry-point `Pre`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, overflow in the thirds-point formulas, and non-termination of bounded search loops.
* **Contract Discipline**: Preconditions replace exceptions; oversized / non-unimodal / unsorted arrays are `Pre` violations rather than `Invalid_Argument`.
* **Sentinel $0$**: Absent keys from `Find` return $0$; live indices stay in $1 .. N$. `Find_Maximum_Index` always returns a live index under its `Pre` ($A'\mathit{Length} ≥ 1$).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length, unimodality, and sortedness are `Pre` contracts (`In_Bounds`, `Is_Unimodal`, `Is_Sorted`).
* Indices fixed at `A'First = 1`; `Find` miss sentinel is $0$ (sibling allows arbitrary `A'First` and returns $A'\mathit{First}-1$).
* Search loops are bounded `for` loops with `pragma Loop_Invariant` so termination is immediate for the prover.
* `Find_Maximum_Index` post proves “Result ∈ A'Range”; full “Result is a global max” completeness (and plateau uniqueness) is exercised by tests rather than claimed as a Level-4 post without extra ghost lemmas. `Find` posts prove “hit ⇒ correct index”; miss completeness is likewise test-backed.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 141 assertions pass. Running `make prove` reports `Success: all checks proved (99 checks).`

## Testing
* **Functional correctness**: Singleton / short unimodal, peak at start / middle / end, plateaus, generated peaks at every offset, capacity-bound shapes, signed / mixed domains.
* **Agreement**: `Find_Maximum_Index` vs brute-force max; `Find` vs linear reference at `Max_N`, including duplicates and signed keys.
* **Contract helpers**: `Is_Unimodal` / `Is_Sorted` true/false cases; `In_Bounds` at capacity; empty `Find` sentinel.
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
* Loops are bounded `for` loops with `pragma Loop_Invariant` so termination is immediate for the prover.
* **GNATprove Level 4:** `Success: all checks proved (99 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
