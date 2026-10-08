# Postman Sort in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [postman sort](https://en.wikipedia.org/wiki/Postman_sort) (also listed under [bucket sort](https://en.wikipedia.org/wiki/Bucket_sort) as *Postman's sort*): MSD (most-significant-digit) postal / pigeonhole distribution on a nonnegative `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it finds the highest decimal power $\mathit{Exp} = 10^{p}$, stably scatters keys into $10$ digit pigeonholes, recurses on each bucket at $\mathit{Exp}/10$, gathers, then finishes with a proved gap-$1$ bubble pass.

$$
O\bigl(d\,(n + k)\bigr),\quad k = \mathrm{Base} = 10,\quad n \le \mathrm{Max\_N} = 64,\quad d \le 10
$$

This is the SPARK Level 4 port of the companion package [Ada-Postman-Sort](https://github.com/RobertBoettcherSF/Ada-Postman-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses larger caps ($\mathrm{Max\_Length} = 100\,000$, $\mathrm{Max\_Base} = 256$), exceptions (`Invalid_Argument`), optional `Sort_Base`, and arbitrary `A'First`; this port trades those for classroom bounds (`Max_N = 64`, fixed `Base = 10`), `In_Bounds` / `Keys_Ok` / `Is_Sorted` contracts, static `Count (0 .. 9)` and `Work (1 .. Max_N)`, recursion bounded by `Subprogram_Variant` on $\mathit{Exp}$, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings: [Ada-SPARK-Radix-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Radix-Sort) (LSD, one counting pass), [Ada-SPARK-Bucket-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bucket-Sort), [Ada-SPARK-Pigeonhole-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Pigeonhole-Sort) (same `Bubble_Finish` proof split).

## Post-office analogy

| Postal step | Algorithm step |
| ----------- | -------------- |
| Sort domestic vs international | Bucket by MSD |
| Within country, sort by state/province | Recurse on next digit |
| Sort by local office / route | Deeper recursion |
| Stack trays in ZIP order | Concatenate buckets $0 \ldots k-1$ |

Because keys are not compared pairwise in the distribution phase, sorting time is $O(c\,n)$ where $c$ depends on key length (digit depth) and the number of buckets — the same family as top-down radix sort.

## Features
* **`Sort (A)`**: Ascending educational MSD postman sort (base $10$ scatter / recurse / gather). The distribution alone proves `Is_Sorted`; there is no fallback pass.
* **`Is_Sorted` / `In_Bounds` / `Keys_Ok`**: Guards for shape, nonnegative keys, and sortedness; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors and sortedness of the MSD distribution itself (exact bucket starts, scatter coverage, digit-ordered buckets, shared digit prefix inside a bucket).
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays or negative keys are `Pre` violations rather than `Invalid_Argument`.
* **Static tables only**: `Count (0 .. Base−1)` and `Work (1 .. Max_N)`; recursion decreases $\mathit{Exp}$.

## Choice: `Keys_Ok` precondition
Callers must establish `Keys_Ok (A)`: every live element is $\ge 0$. Digit extraction $(x / 10^{p}) \bmod 10$ is defined here for **nonnegative** keys only ($0 \ldots \texttt{Integer'Last}$). Empty arrays are vacuously accepted. An alternative (not implemented) would XOR/flip the sign bit so signed Integers order as unsigned bit patterns. This package prefers the explicit `Keys_Ok` contract so negatives are rejected at the API boundary (matching the sibling's `Invalid_Argument` for signed keys).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* Fixed `Base = 10` only — no `Sort_Base`, no radix $2..256$ (sibling `Max_Base = 256`). Digit tables are static $0..9$.
* No exceptions: length / shape / signs are `Pre => In_Bounds (A) and then Keys_Ok (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Static `Count` and `Work` (sibling allocates locals sized to the live span / `A'Range`).
* **Sortedness proof:** `MSD_Range (Lo, Hi, P)` is called on a slice whose keys share the prefix $\lfloor x / 10^{P+1} \rfloor$. Ghost `Cnt` counts the keys of each digit and ghost `Sum_To` gives exact bucket starts (the counts sum to the slice length, so no caps are needed); the scatter invariant says each digit's region holds exactly keys of that digit with the slice's prefix, so the regions tile the slice. A bucket shares its prefix one digit lower (`Lemma_Div_Div`), so the recursive call applies; at $P = 0$ a bucket holds equal keys. Adjacent buckets are ordered because a smaller digit under the same prefix means a smaller key (`Lemma_Order`). The earlier gap-$1$ `Bubble_Finish` fallback and the digit / prefix-sum / scatter clamps were removed. Recursion is bounded by `Subprogram_Variant => (Decreases => P)`.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
Given an array $A$ of $n$ nonnegative keys and radix $k = 10$:

1. If $n \le 1$, return. Let $M = \max A$; if $M = 0$, return.
2. Let $\mathit{Exp} = k^{p}$ be the highest power with $\mathit{Exp} \le M$ ($p \le 9$).
3. **Scatter** (stable): for each key $x$ in index order, place $x$ into
   bucket $d(x) = \lfloor x / \mathit{Exp} \rfloor \bmod k$.
4. **Gather**: write buckets $0, 1, \ldots, k-1$ contiguously back into $A$.
5. If $\mathit{Exp} > 1$, **recurse** on each bucket with more than one
   element using $\mathit{Exp}/k$ (`Subprogram_Variant` decreases $p$); otherwise stop.

Empty and singleton arrays are no-ops. The MSD scatter is **stable**.

### MSD vs LSD (sibling radix sort)

| Variant | Digit order | Style | This package |
| ------- | ----------- | ----- | ------------ |
| **MSD / Postman** | Most → least significant | Recursive pigeonholes | **Yes** |
| **LSD radix** | Least → most significant | Flat counting-sort passes | Sibling package only |

For nonnegative integers treated with **leading-zero padding**, MSD and LSD produce the same numeric order. MSD is the natural model for variable-length strings and hierarchical keys (postal codes, file paths).

### Relation to bucket and pigeonhole sorts
- **Bucket sort** scatters into bins, sorts each bin, then concatenates. Postman's sort is the hierarchical / multi-attribute form of that idea.
- **Pigeonhole sort** is the extreme of one distinct key per hole; Postman allows many keys per digit bucket and recurses on the next digit.
- **Top-down radix sort** is MSD with a power-of-two (or fixed) digit radix; Postman sort is the same distribution pattern described through the postal metaphor.

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Typical (balanced digits) | $O(d\,(n+k))$ | $O(\mathrm{Max\_N} + k)$ per level |
| All-zero | $O(n)$ (maximum scan only) | static tables |
| All-equal nonzero | $O(d\,(n+k))$ (one bucket per level) | static tables |

Worst case of the MSD phase degrades when many keys share long common prefixes (deep recursion on large buckets), analogous to unbalanced bucket sort.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 279 assertions pass ($0$ FAIL). Running `make prove` reports `Success: all checks proved (507 checks)` (the same at `--mode=silver --level=2`).

## Testing
* **Functional correctness**: Empty / singleton, classic multi-digit MSD example, reverse / already-sorted / almost-sorted, duplicates / all-equal / all-zero, mixed digit lengths, near `Integer'Last`, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Postman-specific**: Postal-prefix keys, shared MSD then diverge, powers-of-ten lengths, encoded (key, tag) pairs vs the stable reference.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Keys_Ok` true on nonnegative keys and false when any element is negative.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$ and keys $\ge 0$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* MSD loops use `pragma Loop_Invariant`; recursion uses `Subprogram_Variant => (Decreases => P)`; ghost lemmas (`Lemma_Sum_Inc`, `Lemma_Cnt_Mono`, `Lemma_Bucket_Pre` / `Lemma_Bucket_Post`, `Lemma_Tile`, `Lemma_Order`) carry the distribution argument.
* **GNATprove Level 4:** `Success: all checks proved (507 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Base` | Fixed educational radix (`10`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Keys_Ok` | Every live element $\ge 0$ (nonnegative keys) |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending MSD postman sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
