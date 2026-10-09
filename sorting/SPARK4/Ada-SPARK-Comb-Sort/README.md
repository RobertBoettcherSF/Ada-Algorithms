# Comb Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [comb sort](https://en.wikipedia.org/wiki/Comb_sort) (Włodzimierz Dobosiewicz; later popularized by Stephen Lacey and Richard Box) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it is bubble sort with a shrinking **gap** ($\approx 1.3$ via integer arithmetic $\mathrm{gap} := \lfloor\mathrm{gap}\cdot 10/13\rfloor$). Large early gaps move distant out-of-order keys (**turtles**); the final gap-$1$ phase is ordinary bubble sort — **unstable**, **in-place**, and typically much faster than plain bubble sort in practice.

$$
\text{extra space } O(1);\quad \text{time empirically near } O(n\log n)\text{ with shrink }\approx 1.3\text{ (worst still quadratic)}
$$

This is the SPARK Level 4 port of the companion package [Ada-Comb-Sort](https://github.com/RobertBoettcherSF/Ada-Comb-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), and the classic until-gap-$1$-and-clean-pass loop; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and a single comb loop whose termination is proved by the loop variant (gap, bound) and whose gap-$1$ passes prove sortedness. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort), [Ada-SPARK-Shell-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Shell-Sort), and [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending comb sort (shrink $\approx 1.3$, then gap-$1$ passes until one makes no swap).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; gap-$1$ `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (the permutation is proved; tag order is not).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Any `A'First` in `1 .. Max_N` (index subtype `Live_Index`, at most `Max_N` elements); indices are First-relative. Tests sort shifted copies at origins 2, 7, `Max_N / 2 + 1` and slices flush to `Max_N`.
* No iteration cap: one loop runs the shrinking-gap passes and then the gap-$1$ passes, with loop variant (gap, bound). From gap $\ge 2$ the shrink $\lfloor\mathrm{gap}\cdot 10/13\rfloor$ is at least $1$, so no $\max(1, \cdot)$ clamp is needed.
* Gaps $> 1$ prove only `In_Bounds` / RTE; the gap-$1$ passes (`Bubble_Pass`, inside the comb loop) carry the bubble-sort Level-4 argument for `Is_Sorted`.
* **SPARK proves sortedness and permutation** (`Post => Is_Sorted (A) and then Is_Perm (A, A'Old)`): A holds the values of A'Old, each equally often (counted with `Occ`); every element move is a swap, proved to keep all counts (`Lemma_Swap`). The body's internal contracts and invariants are proved but not executed at run time (they quantify over every Integer value); the Post of `Sort` is checked on every call.

## Algorithm
1. If $n \le 1$, return.
2. Set $\mathrm{gap} := n$. Repeat: if $\mathrm{gap} > 1$, $\mathrm{gap} := \lfloor\mathrm{gap}\cdot 10/13\rfloor$ (at least $1$); if still $\mathrm{gap} > 1$, one comb pass compares/swaps $A(i)$ with $A(i+\mathrm{gap})$.
3. **Gap $1$** (same loop): gap-$1$ passes until one makes no swap; each stops one element earlier, since a gap-$1$ pass leaves the maximum at the end → fully sorted.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 250 assertions pass. Running `make prove` reports `Success: all checks proved (187 checks).` (gnatprove 16.1)

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia 10-element example, turtle cases, signed domain, power-of-two and odd lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Unstable duplicates**: Tagged equal keys checked as a permutation only (not tag order).
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
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
* Inner comb / bubble loops use `pragma Loop_Invariant`; gap-$1$ passes shrink the unsorted suffix via `Bubble_Pass` with partition predicates; the single comb loop has loop variant (gap, bound).
* **GNATprove Level 4:** `Success: all checks proved (187 checks)` (gnatprove 16.1).
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'Length <= Max_N`, `A'First in 1 .. Max_N`, `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending in-place comb sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
