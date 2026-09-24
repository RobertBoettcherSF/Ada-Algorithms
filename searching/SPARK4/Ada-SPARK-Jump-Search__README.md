# Jump Search Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the classic [jump search algorithm](https://en.wikipedia.org/wiki/Jump_search) (also known as block search) on a sorted ascending `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it advances by fixed-size jumps of length

$$
m = \left\lfloor\sqrt{n}\right\rfloor
$$

(or an explicit `Step`), then finishes with a short linear scan of the candidate block. Worst-case complexity is $O(\sqrt{n})$ comparisons — better than linear search, worse than binary search, with only one backward jump. The absent sentinel is always $0$ (live indices are $1 .. N$).

This is the SPARK Level 4 port of the companion package [Ada-Jump-Search](https://github.com/RobertBoettcherSF/Ada-Jump-Search) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), arbitrary `A'First`, and sentinel $A'\mathit{First}-1$; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK search sibling: [Ada-SPARK-Binary-Search](https://github.com/RobertBoettcherSF/Ada-SPARK-Binary-Search).

## Features
* **`Find` / `Find (…, Step)`**: Classic jump / block search with optimal $m = \lfloor\sqrt{n}\rfloor$ or an explicit positive block size.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards used in every entry-point `Pre`.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, overflow in jump advances / $\lfloor\sqrt{n}\rfloor$, and non-termination of bounded search loops.
* **Contract Discipline**: Preconditions replace exceptions; oversized / unsorted arrays are `Pre` violations rather than `Invalid_Argument`. `Step` is `Positive` (zero is not representable).
* **Sentinel $0$**: Absent keys return $0$; live indices stay in $1 .. N$.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length and sortedness are `Pre => In_Bounds (A) and then Is_Sorted (A)`; `Step = 0` is impossible (`Positive`).
* Indices fixed at `A'First = 1`; miss sentinel is $0$ (sibling allows arbitrary `A'First` and returns $A'\mathit{First}-1$).
* Jump and linear phases use bounded `for` loops with `pragma Loop_Invariant` so termination is immediate for the prover.
* Overflow-safe jump advance caps at `Max_N + 1`; $\lfloor\sqrt{n}\rfloor$ is a descending search over $0 .. 8$ ($8^2 = 64$).
* Posts prove “hit ⇒ correct index”; full “miss ⇒ key absent” completeness is exercised by tests rather than claimed as a Level-4 post without extra ghost lemmas.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 231 assertions pass. Running `make prove` reports `Success: all checks proved (88 checks).`

## Testing
* **Functional correctness**: Empty / singleton, small sorted arrays, non-square and perfect-square lengths (including $n = 64$), explicit `Step` overload, duplicates, signed domain, two-/three-element edges, endpoint keys.
* **Agreement**: `Find` / `Find (…, Step)` vs linear reference at `Max_N`, including duplicate plateaus and random sorted queries.
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
* **GNATprove Level 4:** `Success: all checks proved (88 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
