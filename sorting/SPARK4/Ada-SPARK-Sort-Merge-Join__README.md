# Sort-Merge Join Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the
[sort-merge join](https://en.wikipedia.org/wiki/Sort-merge_join) algorithm:
an **inner join** of two relations already sorted by an integer join key,
emitting matching pairs (including many-to-many Cartesian expansion on equal
keys). Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it
uses **static storage only** — no `Ada.Containers`, no `Unbounded_String`,
no exceptions.

$$
O(n + m + |Out|)\ \text{after sort},\quad
n,m \le \mathrm{Max\_N} = 32,\quad
|Out| \le \mathrm{Max\_Out} = 256
$$

This is the SPARK Level 4 port of the companion package
[Ada-Sort-Merge-Join](https://github.com/RobertBoettcherSF/Ada-Sort-Merge-Join)
in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses
`Unbounded_String` payloads, `Ada.Containers.Vectors` for output,
`Auto_Sort` via `Generic_Array_Sort`, and raises
`Unsorted_Relation_Error` / `Non_Unique_Key_Error`. This port trades those
for classroom bounds, `Row (Key, Payload : Integer)`, a static
`Joined_Relation` buffer, and `Is_Sorted_By_Key` / `Keys_Unique` /
`Product_Fits` contracts so Level 4 can prove absence of run-time errors and
$\mathrm{Last} \le \mathrm{Max\_Out}$ with nondecreasing `Result` keys on
`Left.Key`. README links only — do not `with` sibling packages here.
Closest SPARK siblings that also merge sorted sequences:
[Ada-SPARK-K-Way-Merge](https://github.com/RobertBoettcherSF/Ada-SPARK-K-Way-Merge),
[Ada-SPARK-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Merge-Sort).

## Features
* **`Inner_Join`**: Classic many-to-many inner sort-merge join with
  equal-key run detection and Cartesian emission.
* **`Unique_Key_Join`**: Optimized variant when Left keys are strictly
  unique (`Keys_Unique`) — one-to-many / one-to-one without left-run nesting.
* **`Is_Sorted_By_Key` / `Keys_Unique` / `Product_Fits` /
  `Result_Keys_Nondecreasing`**: Expression-function guards.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of
  index / overflow errors; `Post => Last <= Max_Out` and nondecreasing
  `Left.Key` on `Result (1 .. Last)`.
* **Contract Discipline**: Preconditions replace exceptions; unsorted /
  oversized / non-unique inputs are `Pre` violations.
* **Static buffers only**: Fixed capacity `Max_Out` output array — no heap.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 32`, `Max_Out = 256` so array / arithmetic VCs stay within
  automated SMT reach.
* No exceptions: shape / sortedness / uniqueness / capacity are `Pre`
  contracts.
* No `Unbounded_String` / Vectors: `Row` uses `Integer` `Payload`; output
  is a static `Joined_Relation`.
* **Pre-sorted inputs only** (no `Auto_Sort`) — keeps Level 4 focused on
  the merge/join VCs; sorting is covered by sibling sort packages.
* **`Product_Fits`**: callers guarantee $|L| \cdot |R| \le \mathrm{Max\_Out}$
  (safe upper bound on join size, including a full Cartesian on one key).
  Tests use small data within the cap.
* **SPARK proves** $\mathrm{Last} \le \mathrm{Max\_Out}$ and nondecreasing
  `Result` keys on `Left.Key`. Full matching / multiset correctness is
  **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. Preconditions: both relations 1-based, length $\le \mathrm{Max\_N}$,
   sorted by `Key`, output buffer $\ge \mathrm{Max\_Out}$, and
   $|L|\cdot|R| \le \mathrm{Max\_Out}$.
2. Advance cursors $I$, $J$ over Left / Right:
   - if $\mathrm{Left}(I).\mathrm{Key} < \mathrm{Right}(J).\mathrm{Key}$
     then $I \leftarrow I+1$
   - elsif $\mathrm{Left}(I).\mathrm{Key} > \mathrm{Right}(J).\mathrm{Key}$
     then $J \leftarrow J+1$
   - else locate equal-key runs $[I_0..I_1]$, $[J_0..J_1]$ and emit the
     Cartesian product $\mathrm{Left}(I_0..I_1) \times
     \mathrm{Right}(J_0..J_1)$, then advance past both runs.
3. Loop invariant: `Result (1 .. OI)` is nondecreasing on `Left.Key` and
   $OI \le \mathrm{Max\_Out}$.

### Example
Left $[(1,a),(2,b)]$, Right $[(1,x),(1,y),(2,z)]$ yields

$$
(1,a\!\bowtie\!1,x),\ (1,a\!\bowtie\!1,y),\ (2,b\!\bowtie\!2,z)
$$

## Complexity

| Approach | Time (after sort) | Extra space | Notes |
| -------- | ----------------- | ----------- | ----- |
| Sort-merge join (this package) | $O(n + m + \|Out\|)$ | $O(\mathrm{Max\_Out})$ static | Educational; proves at L4 |
| Nested-loop join | $O(n \cdot m)$ | $O(1)$ cursors | No sort required |
| Hash join | $O(n + m)$ expected | $O(n)$ hash table | Preferred for unsorted large data |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all assertions pass (51 PASS, 0 FAIL).
Running `make prove` reports `Success: all checks proved (246 checks)`.

## Testing
* **Functional correctness**: Empty relations, one-to-one, one-to-many,
  many-to-one, many-to-many Cartesian, negatives, gaps between keys.
* **Unique-key variant**: One-to-many with strictly unique Left keys.
* **Contract helpers**: `Is_Sorted_By_Key`, `Keys_Unique`, `Product_Fits`.
* **Capacity**: Exact $|L|\cdot|R| = \mathrm{Max\_Out}$ boundary and full
  Cartesian within the cap.
* **Contract discipline**: Only valid call paths are exercised (no
  exception handlers).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`).
Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` /
  `Global => null`.
* Join loops use `pragma Loop_Invariant` / `Loop_Variant` tracking
  `Sorted_Left_Keys` and `OI <= Max_Out`.
* **GNATprove Level 4:** `Success: all checks proved (246 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)`
  suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Row` | `record Key, Payload : Integer` |
| `Relation` | `array (Positive range <>) of Row` |
| `Joined_Row` / `Joined_Relation` | Output pair / array |
| `Max_N` / `Max_Out` | Classroom bounds (`32` / `256`) |
| `Is_Sorted_By_Key` | Adjacent-nondecreasing on `Key` |
| `Keys_Unique` | Strictly increasing keys |
| `Product_Fits` | $\|L\|\cdot\|R\| \le \mathrm{Max\_Out}$ |
| `Inner_Join` | Many-to-many sort-merge join |
| `Unique_Key_Join` | Unique-Left optimized join |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
