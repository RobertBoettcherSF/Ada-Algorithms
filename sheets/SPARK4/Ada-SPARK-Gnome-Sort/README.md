# Gnome Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [gnome sort](https://en.wikipedia.org/wiki/Gnome_sort) (also nicknamed **stupid sort**) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it is the garden-gnome adjacent compare / swap / step: for each new key, swap left while out of order (strict `<` — never $\le$ / $\ge$ when deciding to swap) so equals keep relative order (**stable-ish**), using only $O(1)$ auxiliary memory (**in-place**), and adapting toward $O(n)$ on already-sorted input. Equivalent in spirit to insertion sort, but moves elements by **adjacent swaps** rather than shifting a gap.

$$
\text{best } O(n),\quad \text{average/worst } O(n^2),\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Gnome-Sort](https://github.com/RobertBoettcherSF/Ada-Gnome-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape and insertion-style prefix proof: [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending gnome (stupid) sort via adjacent swaps.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, and loop invariants that the sorted prefix grows by one element per outer step.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Strict `<` when swapping so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Nested `Gnome_Step` (adjacent-swap bubble of $A(I)$ into the sorted prefix) plus `pragma Loop_Invariant` / `Loop_Variant` so the swap loop and outer prefix growth are discharged at Level 4 — same proof shape as insertion sort, but with swaps instead of a shift hole.
* Single-`Pos` while-loop of the sibling is expressed as a **bounded outer** `for I in 2 .. A'Last` plus an inner decreasing-`Pos` swap loop (equivalent insertion-via-swaps form of gnome sort).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition (a simple ghost permutation lemma is not required here).

## Algorithm
1. If $n \le 1$, return — already sorted.
2. For each index $I$ from $2$ through $A'\mathit{Last}$:
   - Set $\mathit{pos} \leftarrow I$.
   - While $\mathit{pos} > 1$ and $A(\mathit{pos}) < A(\mathit{pos}-1)$: swap adjacent pots and $\mathit{pos} \leftarrow \mathit{pos}-1$.
   - Otherwise the prefix $A(1 .. I)$ is ordered (advance on $\ge$).
3. After the last outer step, $A$ is fully sorted.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 242 assertions pass. Running `make prove` reports `Success: all checks proved (101 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, readme walk-through, gnome wiki-style tiny, organ-pipe, signed domain, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Stability**: Tagged keys (`key×1000 + arrival_tag`) keep tag order for equal keys.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
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
* Inner adjacent-swap loop uses `pragma Loop_Invariant` and `Loop_Variant`; outer loop grows a sorted prefix via `Gnome_Step`.
* **GNATprove Level 4:** `Success: all checks proved (101 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending in-place gnome sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
