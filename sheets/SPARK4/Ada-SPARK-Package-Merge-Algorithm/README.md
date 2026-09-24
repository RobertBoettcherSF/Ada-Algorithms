# Package-Merge Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the [package-merge algorithm](https://en.wikipedia.org/wiki/Package-merge_algorithm) for **length-limited Huffman coding**. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it computes optimal code-word lengths for a positive integer frequency alphabet of size $n \le \mathrm{Max\_Symbols}$ subject to a hard maximum length $L \le \mathrm{Max\_L}$, using only fixed static node and list buffers (no unbounded heap, no `Float`).

$$
O(nL)\text{ time},\quad n \le 32,\quad L \le 16,\quad \sum_i 2^{-\ell_i} \le 1
$$

This is the SPARK Level 4 port of the companion package [Ada-Package-Merge-Algorithm](https://github.com/RobertBoettcherSF/Ada-Package-Merge-Algorithm) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses `Float` weights, four public variants (binary coin collector, Huffman-via-coins, space-efficient Huffman, alphabetic DP), and exceptions (`Invalid_Frequencies` / `Invalid_Target`). This port exports a single entry `Huffman_Length_Limited`, forces `Frequencies'First = 1`, uses `Freq_Value` / `Natural` weights, and proves length bounds via a final `Ensure_Length_Bounds` pass. README links only — do not `with` sibling packages here.

## Features
* **`Huffman_Length_Limited`**: Optimal length-limited Huffman lengths via space-efficient package-merge lists (active pruning to $2n-2$).
* **`In_Bounds` / `Can_Encode`**: Expression-function guards; `Can_Encode` encodes the Kraft feasibility $n \le 2^L$.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of run-time errors; proved postcondition that every code length lies in $1 .. L$.
* **Contract Discipline**: Preconditions replace exceptions; oversized alphabets or $n > 2^L$ are `Pre` violations.
* **Static buffers only**: Node pool and list arrays sized from `Max_Symbols` / `Max_L`.

## Deliberate simplifications vs non-SPARK sibling
* `Integer` / `Natural` frequencies only (`Freq_Value` capped at `Max_Freq`); no `Float`.
* `Max_Symbols = 32`, `Max_L = 16` (sibling is essentially unbounded aside from memory).
* One public entry (`Huffman_Length_Limited`); coin-collector packaging is private inside the body.
* `Lengths` is `in out` (not `out`) so Level-4 flow can track full array initialization; callers still treat it as a pure result buffer.
* No alphabetic / DP variant; no general `Coin_Collector` export.
* No exceptions: shape / capacity are `Pre => In_Bounds` / `Can_Encode`.
* Indices fixed at `Frequencies'First = 1`.
* Fixed node pool (`Max_Nodes`) and list capacity (`Max_List`); active list pruned to $2n-2$.
* **SPARK proves length bounds** (`Post => Lengths(I) in 1 .. Max_Length`) via `Ensure_Length_Bounds` (same proof role as Strand_Sort's `Bubble_Finish`). Kraft inequality and optimality on classroom cases are **checked by tests**, not claimed as Level-4 postconditions.
* Zero `pragma Annotate (GNATprove, Intentional, …)`.

## Algorithm
Given positive frequencies $p_1,\ldots,p_n$ and limit $L$ with $n \le 2^L$:

1. If $n = 1$, assign length $1$ and return.
2. Build leaf list $L_0$ sorted by increasing weight ($=\;p_i$).
3. For $\mathrm{Step} = 1 .. L-1$:
   * **Package:** pair adjacent items of $L_{\mathrm{curr}}$; each package weight is the sum of its children.
   * **Merge:** combine packages with $L_0$ by increasing weight.
   * **Prune:** keep the lightest $2n-2$ items as $L_{\mathrm{curr}}$.
4. Traverse the selected nodes; the number of times leaf $i$ appears is code length $\ell_i$.
5. `Ensure_Length_Bounds` clamps each $\ell_i$ into $1 .. L$ so Level 4 discharges the length postcondition (a correct package-merge run never clamps).

The construction is the educational space-efficient form of the coin-collector reduction described on Wikipedia.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see **34 PASS / 0 FAIL**. Running `make prove` reports `Success: all checks proved (196 checks).`

## Testing
* **Functional correctness**: $N=1$, $N=2$, equal frequencies, skewed, Fibonacci-like, length-limit binding cases, Wikipedia-style small alphabet, full `Max_Symbols`.
* **Kraft**: integer form $\sum_i 2^{L-\ell_i} \le 2^L$ on every case.
* **Contract helpers**: `In_Bounds`, `Can_Encode` true/false.
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
* Package / merge loops use `pragma Loop_Invariant`; length postcondition is discharged by `Ensure_Length_Bounds`.
* **GNATprove Level 4:** `Success: all checks proved (196 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Symbol_Frequencies` | `array (Symbol_Index range <>) of Freq_Value` |
| `Code_Lengths` | `array (Symbol_Index range <>) of Natural` |
| `Max_Symbols` / `Max_L` | Classroom capacity bounds (`32` / `16`) |
| `In_Bounds` | `F'First = 1` and `F'Last in 1 .. Max_Symbols` |
| `Can_Encode` | $n \le 2^L$ feasibility guard |
| `Huffman_Length_Limited` | Length-limited Huffman lengths (`in out`; `Post => lengths in 1..L`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
