# Patience Sorting in Ada 2023

## Project Overview

**Patience sorting** is a comparison sorting algorithm inspired by the
card game *patience* (solitaire). Cards (array elements) are dealt one by
one into a sequence of piles according to a simple greedy rule; when the
deck is exhausted, the sorted sequence is recovered by repeatedly taking
the minimum among the visible pile tops — a $k$-way merge of the piles.

The same deal phase is famous for another reason: under the classic
placement rule, the **number of piles equals the length of a longest
increasing subsequence (LIS)** of the input. That makes patience sorting
both a practical educational sort and a bridge to the LIS problem.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for `Integer` arrays with a modest length bound
(`Max_N = 8192`). Pile stacks live in a **fixed node pool** of
$\mathrm{Max\_N}$ linked-list nodes (no unbounded heap).

Primary source:
[Wikipedia — Patience sorting](https://en.wikipedia.org/wiki/Patience_sorting).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. **Deal.** Initially there are no piles. For each element $X$ in
   left-to-right order:
   - Place $X$ on the **leftmost** existing pile whose **top** value is
     $\ge X$; or
   - if no such pile exists, start a **new** pile to the right of all
     others.
3. **Merge.** While any pile remains, pop the pile whose top is the
   global minimum among tops and write that value back into $A$ (a
   $k$-way merge). Discard empty piles.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### Placement rule ($\ge$ vs $>$)

| Rule | Place when | LIS interpretation |
| ---- | ---------- | ------------------ |
| **top $\ge X$ (this package)** | Wikipedia overview / Aldous–Diaconis | pile count $=$ length of a longest *strictly increasing* subsequence |
| top $> X$ | some pseudocode listings | variant for nondecreasing / weakly increasing formulations |

By construction the pile tops form a **strictly increasing** sequence left
to right, so the target pile can be found with **binary search** in
$O(\log k)$ comparisons for $k$ piles. Within each pile, each new top is
$\le$ the previous top, so reading a pile from top to bottom yields a
**nondecreasing** run — hence the merge is correct.

### Example

Deal $A = [4, 3, 9, 1, 8]$ with the $\ge$ rule:

```text
  4 → pile 1: [4]
  3 → pile 1: [3, 4]     (3 ≤ 4)
  9 → pile 2: [9]        (9 > 3)
  1 → pile 1: [1, 3, 4]
  8 → pile 2: [8, 9]     (8 ≤ 9; leftmost eligible)
```

Tops are $1, 8$. Merge pops $1, 3, 4, 8, 9$ → sorted.
Two piles ⇒ an LIS of length $2$ (e.g. $4, 9$ or $3, 8$ or $3, 9$).

## Complexity

| Measure | Bound | Notes |
| ------- | ----- | ----- |
| Deal (binary search) | $O(n \log n)$ worst | at most $n$ piles; tops searchable |
| Merge (scan min top) | $O(n \cdot k)$ | $k =$ #piles; $O(n^2)$ worst; $O(n\log n)$ with a heap |
| Time (already sorted) | $O(n^2)$ here | $n$ singleton piles; deal is $O(n\log n)$, merge $O(n^2)$ with linear min |
| Time (reverse sorted) | $O(n)$ | single decreasing-from-bottom pile |
| Average ($k \sim \sqrt{n}$) | $O(n \log n)$ class | expected $O(\sqrt{n})$ piles on random input |
| Auxiliary space | $\Theta(\mathrm{Max\_N})$ | fixed node pool + pile-top array |
| Stability | **No** | equal keys may reorder across piles |

A priority queue of tops would bring the merge to $O(n \log k)$; this
educational body keeps a linear scan of tops so the algorithm stays
transparent.

## Relation to longest increasing subsequence

After the deal phase, the number of piles equals the length of a longest
strictly increasing subsequence. Following back-pointers from each newly
placed card to the previous pile recovers one such subsequence in linear
extra work. This package focuses on **`Sort`**; the LIS length is an
immediate by-product of the deal (`Num_Piles`) but is not exported.

## Features

- **`Sort (A)`** — ascending patience sort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as
  sorted).
- **Classic $\ge$ placement** — leftmost pile with top $\ge X$.
- **Fixed node pool** — $\mathrm{Max\_N}$ stack nodes, no unbounded heap.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $8192$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain (not stable).
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ppatience_sorting.gpr`.

## Usage

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected Output

```text
Running tests...

=== 1. Empty and singleton ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

## Testing

The test suite in `tests.adb` covers:

- Empty / singleton edge cases
- Already-sorted / reverse / almost-sorted / alternating patterns
- Negatives mixed with positives; large-magnitude integers
- Duplicate keys vs an insertion-sort reference
- Non-1 `A'First` index bounds
- Random arrays vs reference
- Power-of-two and odd lengths; deal/merge smoke examples
- Idempotence (sorting twice)
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversized $n$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Patience_Sorting is
   Max_N : constant Positive := 8_192;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Patience_Sorting;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
