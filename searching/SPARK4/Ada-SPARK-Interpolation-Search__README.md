# Interpolation Search Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the classic [interpolation search](https://en.wikipedia.org/wiki/Interpolation_search) algorithm (also known as predictive search) on a sorted ascending `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it estimates the next probe by linear interpolation between the current bounds — the telephone-directory analogy — with the overflow-safe probe

$$
\textit{pos} = L + \left\lfloor\frac{(K - A(L))\cdot(H - L)}{A(H) - A(L)}\right\rfloor
$$

using `Long_Long_Integer` intermediates for the multiply. Average complexity is $O(\log\log n)$ probes on uniformly distributed keys; worst case is $O(n)$ (e.g. exponentially growing keys), so the search loop is bounded by `Max_N` iterations. The absent sentinel is always $0$ (live indices are $1 .. N$).

This is the SPARK Level 4 port of the companion package [Ada-Interpolation-Search](https://github.com/RobertBoettcherSF/Ada-Interpolation-Search) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), arbitrary `A'First`, and sentinel $A'\mathit{First}-1$; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK search sibling: [Ada-SPARK-Binary-Search](https://github.com/RobertBoettcherSF/Ada-SPARK-Binary-Search).

## Features
* **`Find`**: Classic interpolation / predictive search with equal-run handling when $A(H) = A(L)$.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards used in every entry-point `Pre`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, overflow in the interpolation probe, and non-termination of the bounded search loop.
* **Contract Discipline**: Preconditions replace exceptions; oversized / unsorted arrays are `Pre` violations rather than `Invalid_Argument`.
* **Sentinel $0$**: Absent keys return $0$; live indices stay in $1 .. N$.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length and sortedness are `Pre => In_Bounds (A) and then Is_Sorted (A)`.
* Indices fixed at `A'First = 1`; miss sentinel is $0$ (sibling allows arbitrary `A'First` and returns $A'\mathit{First}-1$).
* Search loop is a bounded `for` loop with `pragma Loop_Invariant` so termination is immediate for the prover (covers worst-case $O(n)$).
* Overflow-safe probe uses `Long_Long_Integer` for $(K - A(L))\cdot(H - L)$ before dividing by $A(H) - A(L)$.
* Posts prove “hit ⇒ correct index”; full “miss ⇒ key absent” completeness is exercised by tests rather than claimed as a Level-4 post without extra ghost lemmas.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 169 assertions pass. Running `make prove` reports `Success: all checks proved (62 checks).`

## Testing
* **Functional correctness**: Empty / singleton, uniform arithmetic (best case), Wikipedia-like arrays, clustered / exponential (near worst case), duplicates, signed domain, two-/three-element edges, capacity-bound $n = 64$, wide value spans.
* **Agreement**: `Find` vs linear reference at `Max_N`, including duplicate plateaus and random sorted queries.
* **Contract helpers**: `Is_Sorted` true/false cases; `In_Bounds` at capacity.
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
* **GNATprove Level 4:** `Success: all checks proved (62 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
