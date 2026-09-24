# Tree Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic unbalanced [tree sort](https://en.wikipedia.org/wiki/Tree_sort) on an `Integer` array: **insert** every element into a **binary search tree** (fixed node pool), then **write back** in sorted order. Written in Ada 2022 and verified with SPARK (GNATprove Level 4). Average $O(n \log n)$; worst $O(n^2)$ when the tree degenerates to a spine (already-sorted, reverse-sorted, or all-equal input). No AVL / red-black balancing — the classic educational insert stays visible. Equals ride the **right** spine ($\text{left} < \text{node} \le \text{right}$), so equal-key order stays **stable**. Nodes live in a **fixed pool** of $\mathrm{Max\_N}$ records (no heap allocators).

$$
\text{average } O(n \log n),\quad \text{worst } O(n^2),\quad \text{extra space } \Theta(\mathrm{Max\_N})
$$

This is the SPARK Level 4 port of the companion package [Ada-Tree-Sort](https://github.com/RobertBoettcherSF/Ada-Tree-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N` ($4096$), exceptions (`Invalid_Argument`), arbitrary `A'First`, and an explicit-stack in-order walk; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and `A'First = 1`. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape and contract style: [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Ascending unbalanced tree sort (BST insert + sorted write-back).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, ghost live-count / `All_Live_GE` helpers, and extract-min invariants that reassemble a sorted array.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Equals go right on insert; write-back keeps earlier equals first (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $4096$) so array / pool VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **Write-back:** successive **minimum extraction** from the live node pool (same multiset / order as BST in-order). Full recursive in-order BST invariants fight automated Level 4; this lighter helper keeps the insert educational and still proves `Is_Sorted`.
* Ghost `Live_Count` / `All_Live_GE` / `Struct_OK` so Level 4 can prove sortedness without `Intentional` annotations.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return — already sorted.
2. Allocate a fixed node pool of $\mathrm{Max\_N}$ BST nodes (index $0$ = null).
3. **Insert** each $A_i$ into an unbalanced BST: strictly smaller keys go **left**; equal or larger keys go **right**.
4. **Write-back:** repeatedly extract the minimum live pool value into $A$ (order-identical to in-order on the BST).

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 228 assertions pass. Running `make prove` reports `Success: all checks proved (294 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, worked BST example, signed domain, degenerate spines up to `Max_N`.
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
* Ghost `Live_Count` / `All_Live_GE` / `Struct_OK` and extract-min loop invariants support the sortedness argument.
* **GNATprove Level 4:** `Success: all checks proved (294 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
