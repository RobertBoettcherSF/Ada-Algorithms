# Patience Sorting Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [patience sorting](https://en.wikipedia.org/wiki/Patience_sorting) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it deals each element onto piles (leftmost pile whose top $\ge$ the element, else a new pile) and recovers sorted order by a $k$-way merge of pile tops, using only a fixed static node pool of size $\mathrm{Max\_N}$ (no unbounded heap). Under the classic $\ge$ placement rule, the number of piles equals the length of a longest *strictly increasing* subsequence. Worst-case merge is $O(n^2)$ when there are $\Theta(n)$ piles.

$$
\text{deal } O(n\log n),\quad \text{merge worst } O(n^2),\quad n \le \mathrm{Max\_N} = 64
$$

This is the SPARK Level 4 port of the companion package [Ada-Patience-Sorting](https://github.com/RobertBoettcherSF/Ada-Patience-Sorting) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a larger `Max_N` ($8192$), exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a fixed node pool / `Top_Array` of size `Max_N`, and sortedness proved directly from the deal and merge (pile order plus a popped-node invariant). README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort), [Ada-SPARK-Comb-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Comb-Sort).

## Features
* **`Sort (A)`**: Ascending patience sort via static node-pool piles + $k$-way merge.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; the deal and merge loop invariants (pile order, popped-node prefix, ghost count of unpopped nodes) prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Static buffers only**: Fixed pool of `Max_N` stack nodes and `Top_Array` of size `Max_N`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $8192$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First` / `Natural` index).
* Same educational node-pool + binary-search deal + linear min-top merge structure, scaled to `Max_N`.
* The deal and merge prove `Is_Sorted` themselves: inside a pile every older node is $\ge$ every newer one, the unpopped nodes of a pile are its oldest ones (the top is the newest of them), so the smallest top is $\le$ every unpopped node; a ghost count of unpopped nodes shows the merge stops only after $n$ outputs. There is no bubble-sort fallback.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return.
2. **Deal:** for each element $X$ in order, place it on the leftmost pile whose top is $\ge X$ (binary search on strictly increasing tops); if none, start a new pile to the right. Storage is a fixed pool of linked stack nodes.
3. **Merge:** while any pile remains, pop the pile with the smallest top into the output; if that pile empties, discard it by swapping with the last active pile.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 238 assertions pass, then the own property checks (9,849 sort calls, see `tests/SOURCES.txt`). Running `make prove` reports `Success: all checks proved (274 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, patience/LIS-friendly patterns (sorted → few piles, reverse → many piles), signed domain, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Deal / merge loops use `pragma Loop_Invariant` / `Loop_Variant`; ghost state `Pile_Of` / `Alive` / `Slot_Of` plus count lemmas carry the pile-order and popped-node invariants.
* **GNATprove Level 4:** `Success: all checks proved (274 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending patience sort: deal + $k$-way merge (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
