# Tree Sort in Ada 2023

## Project Overview

**Tree sort** builds a **binary search tree** (BST) from the elements to be
sorted and then **in-order** traverses the tree so the values come out in
sorted order. Its typical use is *online* sorting: after each insertion the
elements seen so far are available in order. As a one-time sort it is
equivalent in spirit to quicksort (both recursively partition around a
pivot — the root), but it needs extra memory for the tree and, without
balancing, has a worse degenerate case.

Adding one item to a BST is on average an $O(\log n)$ process. Adding $n$
items is therefore

$$
O(n \log n)
$$

on average, making tree sort a “fast sort”. Inserting into an *unbalanced*
tree is $O(n)$ in the worst case: when the tree degenerates to a linked
list. That yields

$$
O(n^2)
$$

total time. The worst case occurs on already-sorted, reverse-sorted, or
all-equal input (a pure right or left spine). Expected $O(n \log n)$ can
be restored by shuffling, but that does not help when keys are equal.
A self-balancing tree (AVL, red-black) would give $O(n \log n)$ worst-case
at extra overhead; this educational package keeps the classic unbalanced
BST so the algorithm stays visible.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** implementation for
`Integer` arrays with a modest length bound (`Max_N = 4096`). Nodes live
in a **fixed pool** of $\mathrm{Max\_N}$ records (no unbounded heap).
Equals are inserted on the **right**, so in-order traversal is stable.

Primary source: [Wikipedia — Tree sort](https://en.wikipedia.org/wiki/Tree_sort).

## Algorithm

Given an array $A$ of length $n$:

1. If $n \le 1$, return — already sorted.
2. Allocate a node pool of $\mathrm{Max\_N}$ BST nodes (index $0$ = null).
3. **Insert** each $A_i$ into an unbalanced BST:
   - if the key is **strictly smaller** than the node, go **left**;
   - otherwise (equal or larger) go **right**.
   - Tree invariant: $\text{left} < \text{node} \le \text{right}$.
4. **In-order** walk (left, node, right) writes the values back into $A$
   in nondecreasing order. The walk is iterative (explicit stack of size
   $n$) so a left-spine cannot overflow the call stack.

Empty and singleton arrays are no-ops. If $n > \mathrm{Max\_N}$, `Sort`
raises `Invalid_Argument`.

### BST convention and stability

Two consistent placements of equals are common:

| Convention | Insert equals | In-order vs insertion order |
| ---------- | ------------- | --------------------------- |
| $\text{left} < \text{node} \le \text{right}$ (**this package**) | right child | **stable** — earlier equals come out first |
| $\text{left} \le \text{node} < \text{right}$ | left child | unstable — later equals precede earlier ones |

Because later equals ride the right subtree, the in-order dump emits the
original node before those later copies.

### Example

Insert $A = \{5, 3, 7, 4, 6, 3\}$ (second $3$ goes right of the first):

```text
        5
       / \
      3   7
       \ /
       4 6
      /
     3
```

In-order: $3, 3, 4, 5, 6, 7$.

## Complexity

| Case | Time | When |
| ---- | ---- | ---- |
| Best / average | $O(n \log n)$ | Random-like keys, reasonably balanced tree |
| Worst | $O(n^2)$ | Sorted, reverse-sorted, or all equal (degenerate spine) |
| Auxiliary space | $\Theta(\mathrm{Max\_N})$ node pool + $O(n)$ in-order stack | Fixed pool, no unbounded heap |
| Stability | Yes | Equals inserted on the right |

Tree sort is a **comparison** sort. It is not in-place: the tree is extra
memory, unlike quicksort or heapsort. On most platforms a heap-allocated
tree is a noticeable cost; the fixed pool here keeps allocation off the
heap and the node bound obvious.

## Features

- **`Sort (A)`** — ascending tree sort on `Integer` arrays.
- **`Is_Sorted`** — nondecreasing predicate (empty/singleton count as sorted).
- **Stable equals** — `left < node <= right` (equals go right).
- **Fixed node pool** — $\mathrm{Max\_N}$ BST nodes, no unbounded heap.
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N` (default
  $4096$).
- **Arbitrary bounds** — works for any `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ptree_sort.gpr`.

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
- Already-sorted, reverse, and mixed small inputs
- Degenerate BST spines (sorted / reverse / all-equal)
- Negatives, duplicates, and tagged stability of equals
- Wikipedia-style insertion example
- Non-1 `A'First` index bounds
- Random arrays vs insertion-sort reference
- `Is_Sorted` true/false cases
- `Invalid_Argument` for oversize $n$
- Idempotence (sorting a sorted array again)

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Tree_Sort is
   Max_N : constant Positive := 4_096;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   procedure Sort (A : in out Element_Array);
   function Is_Sorted (A : Element_Array) return Boolean;
end Tree_Sort;
```

## License

Educational reference implementation. See repository `LICENSE` if present.
