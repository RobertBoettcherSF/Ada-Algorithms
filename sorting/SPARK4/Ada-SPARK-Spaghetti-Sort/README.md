# Spaghetti Sort in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [spaghetti sort](https://en.wikipedia.org/wiki/Spaghetti_sort) — A. K. Dewdney's analog sorting idea from *Scientific American* — on an `Integer` array with nonnegative keys. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it tallies rod lengths into a static height-bin table $\mathrm{Counts}(0 .. \mathrm{Max\_Key})$, emits ascending order by reading bins short$\to$tall; the height-bin phase itself is proved to sort (no finishing pass). The software simulation runs in

$$
O(n + U),\quad U = \mathrm{Max\_Key} + 1 = 65,\quad n \le \mathrm{Max\_N} = 64
$$

time, using $O(\mathrm{Max\_Key})$ auxiliary counters.

True spaghetti sort is $O(n)$ with parallel / analog hardware: cut uncooked rods to key lengths, stand them upright, and repeatedly lower a hand to extract the current longest rod in $O(1)$ parallel time. This package is an **honest sequential software simulation** of that classroom metaphor — not a claim of $O(n)$ wall-clock time on a single-threaded CPU.

This is the SPARK Level 4 port of the companion package [Ada-Spaghetti-Sort](https://github.com/RobertBoettcherSF/Ada-Spaghetti-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses larger caps ($\mathrm{Max\_Length} = \mathrm{Max\_Key} = 10\,000$), exceptions (`Invalid_Argument`), and also exports `Sort_Extraction` for general Integers; this port trades those for classroom bounds (`Max_N = 64`, `Max_Key = 64`), `In_Bounds` / `Keys_Ok` / `Is_Sorted` contracts, static `Counts (0 .. Max_Key)`, **height-bin `Sort` only**, and a proof that the height-bin phase sorts. README links only — do not `with` sibling packages here. Closest SPARK sort siblings: [Ada-SPARK-Counting-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Counting-Sort) (related fixed-domain emit), [Ada-SPARK-Pigeonhole-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Pigeonhole-Sort) / [Ada-SPARK-Bead-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bead-Sort).

## Features
* **`Sort (A)`**: Ascending educational height-bin spaghetti sort (tally / emit on static bins).
* **`Is_Sorted` / `In_Bounds` / `Keys_Ok`**: Guards for shape, key domain $0 .. \mathrm{Max\_Key}$, and sortedness; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; the height-bin phase proves sortedness itself: a ghost `Sum_Below` with three induction lemmas shows the bins hold exactly `N` rods, so the emit cursor ends at `N + 1`, and each emitted rod is no shorter than the one before.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays or out-of-range keys are `Pre` violations rather than `Invalid_Argument`.
* **Static bins only**: `Counts (0 .. Max_Key)`; heights bounded by $n \le \mathrm{Max\_N}$.

## Choice: `Keys_Ok` precondition
Callers must establish `Keys_Ok (A)`: every live element satisfies $A(I) \in 0 .. \mathrm{Max\_Key}$ so it fits the static height-bin table (rod lengths). An alternative design — `Element` subtype `0 .. Max_Key` as in counting sort — would also prove cleanly; this package keeps unconstrained `Integer` elements (matching the non-SPARK sibling) and an explicit `Keys_Ok` contract so out-of-range keys are rejected at the API boundary (matching the sibling's `Invalid_Argument`).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` and `Max_Key = 64` (sibling uses $10\,000$ / $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape / keys are `Pre => In_Bounds (A) and then Keys_Ok (A)`.
* Any `A'First` in `1 .. Max_N` (index subtype `Live_Index`, at most `Max_N` elements); indices are First-relative. Tests sort shifted copies at origins 2, 7, `Max_N / 2 + 1` and slices flush to `Max_N`.
* Static `Counts (0 .. Max_Key)` (sibling allocates the same shape at larger $U$).
* **Export only height-bin `Sort`** for Level-4 simplicity; the sibling's `Sort_Extraction` ($O(n^2)$ max-pull for general Integers, including negatives) remains a non-SPARK companion feature — mentioned here, not reimplemented.
* Height-bin phase posts only `In_Bounds` / RTE; tally / emit use loop invariants and write-cursor caps so Level-4 RTE discharges without a full cardinality / multiset lemma.
* There is no finishing pass: `Is_Sorted` is proved for the height-bin phase itself. Permutation (same multiset) is checked by the tests, not claimed as a postcondition.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.
* **Zero Intentional Annotate**: no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## Algorithm
Given an array $A$ of length $n$ with keys in $0 .. \mathrm{Max\_Key}$:

1. If $n \le 1$, return.
2. Allocate static height bins $\mathrm{Counts}[0 .. \mathrm{Max\_Key}]$, initially zero.
3. **Tally (prepare the rods):** for each $A(i)$, increment $\mathrm{Counts}[A(i)]$ — one bin per rod length.
4. **Emit ascending (short$\to$tall):** for height $H = 0 .. \mathrm{Max\_Key}$, write $\mathrm{Counts}[H]$ copies of $H$ into $A$ left-to-right. Analog spaghetti extracts tallest-first / descending; this port emits ascending so `Sort` matches the documented API contract.
5. **Why it is sorted:** the bins hold exactly $n$ rods, so the emit cursor ends at $n+1$; every rod is written after all shorter ones (`Is_Sorted` proved, no finishing pass).

Empty and singleton arrays are no-ops. Software cost is $O(n+U)$, not the analog $O(n)$.

### Example
For $A = [3, 2, 4, 2]$ the height bins become $\mathrm{Counts}[2]=2$, $\mathrm{Counts}[3]=1$, $\mathrm{Counts}[4]=1$. Reading short$\to$tall yields $[2, 2, 3, 4]$ — sorted ascending.

### Relation to counting sort and bead sort
Height-bin spaghetti sort is educationally the same reconstruction as classic counting sort when the key *is* the element: histogram then emit each key $\mathrm{Hist}(K)$ times. Bead sort encodes the dual cumulative view ($\mathrm{Rods}[j] = \#\{a_i \ge j\}$). Dewdney's metaphor motivates the bins as physical rod lengths rather than an abstract count table.

## Complexity (analog vs software)

| Model | Time | Space | Notes |
| ----- | ---- | ----- | ----- |
| Analog / parallel (Dewdney) | $O(n)$ | $O(n)$ rods | Hand finds max in $O(1)$ parallel |
| Sibling `Sort_Extraction` | $O(n^2)$ | $O(n)$ | Sequential max-pull; general Integers |
| **This software** | $O(n+U)$ | $O(\mathrm{Max\_Key})$ bins | Height-bin tally / emit, proved to sort |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 272 assertions pass ($0$ FAIL). Running `make prove` reports `Success: all checks proved (147 checks)`.

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia-style height-bin $[3,2,4,2]$, zeros / duplicates / all-equal, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Height-bin-specific**: Exact `Max_Key`, dense bin cover, all-zero early patterns, random arrays with keys $\le 64$.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Keys_Ok` true at exact `Max_Key` and false when any key $< 0$ or $> \mathrm{Max\_Key}$.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$ and keys in $0 .. 64$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Height-bin loops use `pragma Loop_Invariant`: the tally keeps the bin total equal to the rods seen, the emit loop keeps the written prefix sorted and bounded by the current bin.
* **GNATprove Level 4:** `Success: all checks proved (147 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Max_Key` | Max rod length / bin index (`64`) |
| `In_Bounds` | `A'Length <= Max_N`, `A'First in 1 .. Max_N`, `A'Last in 0 .. Max_N` |
| `Keys_Ok` | Every live element $\in 0 .. \mathrm{Max\_Key}$ |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending height-bin (`Post => Is_Sorted`, proved for the phase itself) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
