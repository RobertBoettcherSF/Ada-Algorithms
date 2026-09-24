# Linear Search Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the classic iterative [linear search algorithm](https://en.wikipedia.org/wiki/Linear_search) (also known as sequential search) on an unordered `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it scans left-to-right until the first matching key and offers `Find_From` / `Contains` siblings. Worst-case complexity is $O(n)$ comparisons; best case is $O(1)$ when the key sits at $A'\mathit{First}$. The absent sentinel is always $0$ (live indices are $1 .. N$). **No sortedness precondition** — unlike binary / jump search.

This is the SPARK Level 4 port of the companion package [Ada-Linear-Search](https://github.com/RobertBoettcherSF/Ada-Linear-Search) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), arbitrary `A'First`, and sentinel $A'\mathit{First}-1$; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK search sibling: [Ada-SPARK-Binary-Search](https://github.com/RobertBoettcherSF/Ada-SPARK-Binary-Search).

## Features
* **`Find` / `Find_From` / `Contains`**: Classic left-to-right scan, scan-from-`Start`, and Boolean membership.
* **`In_Bounds`**: Expression-function shape guard used in every entry-point `Pre` (no `Is_Sorted`).
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors and non-termination of range loops; posts prove first-occurrence correctness and miss completeness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Sentinel $0$**: Absent keys return $0$; live indices stay in $1 .. N$.
* **Unordered OK**: input need not be sorted.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`; `Find_From` additionally requires `Start in A'Range` when the array is non-empty.
* Indices fixed at `A'First = 1`; miss sentinel is $0$ (sibling allows arbitrary `A'First` and returns $A'\mathit{First}-1$).
* Search uses Ada `for` loops over the live range with `pragma Loop_Invariant` so first-occurrence / miss posts discharge at Level 4.
* Unlike [Ada-SPARK-Binary-Search](https://github.com/RobertBoettcherSF/Ada-SPARK-Binary-Search), there is **no** `Is_Sorted` precondition.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 203 assertions pass. Running `make prove` reports `Success: all checks proved (31 checks).`

## Testing
* **Functional correctness**: Empty / singleton, small arrays, duplicates (first occurrence), `Find_From` later hits, signed domain, unordered permutations, `Integer'First` / `Integer'Last`.
* **Agreement**: first-occurrence oracle on random unordered arrays at `Max_N`; arithmetic spot checks.
* **Contract helpers**: `In_Bounds` at capacity; `Contains` mirrors `Find`.
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
* Loops are Ada `for` loops with `pragma Loop_Invariant` so termination and first-occurrence posts are immediate for the prover.
* **GNATprove Level 4:** `Success: all checks proved (31 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
