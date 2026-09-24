# Bead Sort in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [bead sort](https://en.wikipedia.org/wiki/Bead_sort) (also called **gravity sort**) on a `Natural` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it drops beads onto a static rod table $\mathrm{Rods}(1 .. \mathrm{Max\_Value})$, reconstructs ascending rows from rod heights, then finishes with a proved gap-$1$ bubble pass. The software simulation runs in

$$
O(n \cdot M),\quad M \le \mathrm{Max\_Value} = 64,\quad n \le \mathrm{Max\_N} = 64
$$

time for the bead phase (plus $O(n^2)$ worst-case for the bubble finish), using $O(\mathrm{Max\_Value})$ auxiliary rod counters.

Digital and analog **hardware** implementations can approach $O(n)$ (or abstract $O(1)$ if every bead moves in one step). In **software** there is no physical gravity: dropping beads costs work proportional to the sum of the inputs.

This is the SPARK Level 4 port of the companion package [Ada-Bead-Sort](https://github.com/RobertBoettcherSF/Ada-Bead-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses larger caps ($\mathrm{Max\_N} = \mathrm{Max\_Value} = 1\,024$), exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for classroom bounds (`Max_N = 64`, `Max_Value = 64`), `In_Bounds` / `Values_Ok` / `Is_Sorted` contracts, static `Rods (1 .. Max_Value)`, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings: [Ada-SPARK-Counting-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Counting-Sort) (related cumulative counts), [Ada-SPARK-Pigeonhole-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Pigeonhole-Sort) (same Bubble_Finish proof split), [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort).

## Features
* **`Sort (A)`**: Ascending educational bead sort (drop / reconstruct on static rods), then a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds` / `Values_Ok`**: Guards for shape, value domain, and sortedness; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; bead phase proves `In_Bounds` / RTE; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays or values are `Pre` violations rather than `Invalid_Argument`.
* **Static rods only**: `Rods (1 .. Max_Value)`; heights bounded by $n \le \mathrm{Max\_N}$.

## Choice: `Values_Ok` precondition
Callers must establish `Values_Ok (A)`: every live element satisfies $A(I) \le \mathrm{Max\_Value}$ so it fits the static rod table. An alternative design — `Element` subtype `0 .. Max_Key` as in counting sort — would also prove cleanly; this package keeps unconstrained `Natural` elements (matching the non-SPARK sibling) and an explicit `Values_Ok` contract so oversize values are rejected at the API boundary (matching the sibling's `Invalid_Argument`).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` and `Max_Value = 64` (sibling uses $1\,024$ / $1\,024$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape / values are `Pre => In_Bounds (A) and then Values_Ok (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Static `Rods (1 .. Max_Value)` (sibling allocates `1 .. Max_Val` for the live maximum).
* Bead phase posts only `In_Bounds` / RTE; rod increments and row counts use loop invariants so Level-4 RTE discharges without a full multiset lemma.
* The final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` on **Natural** arrays (same adjacent-swap pattern as Integer sorts; same proof split as Pigeonhole / Strand / Comb / Flashsort). Full gravity-order / permutation posts that would fight Level 4 are deferred to that finish and to tests.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.
* **Zero Intentional Annotate**: no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## Algorithm
Given an array $A$ of length $n$ with nonnegative values and $M = \max A \le \mathrm{Max\_Value}$:

1. If $n \le 1$, return.
2. Allocate static rod counters $\mathrm{Rods}[1 .. \mathrm{Max\_Value}]$, initially zero.
3. For each $a_i > 0$, increment $\mathrm{Rods}[1], \ldots, \mathrm{Rods}[a_i]$ (drop one bead on each of the first $a_i$ rods). Zero drops nothing.
4. Those counters already encode gravity: $\mathrm{Rods}[j]$ equals how many input values are $\ge j$ (settled height on rod $j$).
5. Reconstruct **ascending** order: for height $H = n$ downto $1$, the value at that row is the number of rods with $\mathrm{Rods}[j] \ge H$. Top rows have few beads (small values); the bottom row holds the largest.
6. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted (`Is_Sorted` proved).

Empty and singleton arrays are no-ops. If all values are zero, the bead phase returns immediately.

### Example
For $A = [3, 2, 4, 2]$ the rod heights become $\mathrm{Rods} = [4, 4, 2, 1]$. Reading rows $H = 4 .. 1$ yields bead counts $2, 2, 3, 4$ — sorted ascending.

### Relation to counting sort
$\mathrm{Rods}[j]$ is exactly the number of elements with value $\ge j$, the same information a counting-sort histogram carries in cumulative form. Bead sort presents that fact through the abacus metaphor; counting sort uses an explicit count table and prefix sums.

## Complexity (hardware vs software)

| Model | Time | Space | Notes |
| ----- | ---- | ----- | ----- |
| Abstract simultaneous fall | $O(1)$ | $O(n \cdot M)$ grid | Not realizable as written |
| Physical gravity | $O(\sqrt{n})$ | physical rods | Fall time $\propto \sqrt{\text{height}}$ |
| Digital / analog hardware | $O(n)$ | rods / circuits | Row-by-row bead motion |
| **This software + bubble finish** | $O(n \cdot M) + O(n^2)$ worst | $O(\mathrm{Max\_Value})$ counters | Each bead dropped individually |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 238 assertions pass ($0$ FAIL). Running `make prove` reports `Success: all checks proved (249 checks)`.

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia-style $[3,2,4,2]$, zeros / duplicates / all-equal, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Bead-specific**: Exact `Max_Value`, wiki reconstruction check, all-zero early exit, random arrays with values $\le 64$.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Values_Ok` true at exact `Max_Value` and false when any value $> \mathrm{Max\_Value}$.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$ and values $\le 64$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Bead loops use `pragma Loop_Invariant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (249 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Natural` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Max_Value` | Max element / rod count (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Values_Ok` | Every live element $\le \mathrm{Max\_Value}$ |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending bead sort + bubble finish (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
