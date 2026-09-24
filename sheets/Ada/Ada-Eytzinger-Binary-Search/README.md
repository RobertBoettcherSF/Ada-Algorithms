# Eytzinger Binary Search — Ada 2023

Educational, self-contained Ada 2023 package implementing
[**Eytzinger binary search**](https://en.wikipedia.org/wiki/Eytzinger_binary_search)
(also known as **multiplicative binary search**). A sorted ascending
sequence is rearranged into **complete-binary-tree level order** (BFS /
heap layout); search then walks child indices $2i+1$ (left) and $2i+2$
(right) instead of recomputing $(lo+hi)/2$.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

## Why Eytzinger?

Classic binary search keeps two bounds and a midpoint. The Eytzinger
layout stores the implicit BST in **array heap order**:

- root at offset $0$;
- left child of offset $i$ at $2i+1$;
- right child at $2i+2$.

In-order traversal of that tree recovers the sorted sequence. Search
updates a **single index** by doubling (multiplicative steps), which is
often more **cache- and branch-friendly** on modern CPUs than bouncing
across distant midpoints of a dense sorted array.

## Layout

For a sorted array of length $n$, `Build` fills the heap shape by an
**inorder walk**:

$$
\texttt{Fill}(i):\quad
\texttt{Fill}(2i+1);\ \
L[i] \leftarrow \textit{next sorted};\ \
\texttt{Fill}(2i+2)
$$

starting at $i = 0$, skipping $i \ge n$. Equivalently, for a perfect
tree ($n = 2^k - 1$), one may recursively place the median of each
sorted subrange into successive BFS slots; the inorder-fill form is used
here so the complete shape is correct for every $n$.

### Example ($n = 7$)

Sorted

$$
[1,2,3,4,5,6,7]
$$

becomes layout

$$
[4, 2, 6, 1, 3, 5, 7].
$$

### Example ($n = 5$)

Sorted $[10,20,30,40,50]$ becomes $[40, 20, 50, 10, 30]$.

## Search

1. Start at offset $0$ (root).
2. While the offset is in range, compare $\textit{Key}$ with $L[i]$:
   - equal → hit (return the **layout** absolute index);
   - smaller → $i \leftarrow 2i+1$;
   - larger → $i \leftarrow 2i+2$.
3. Falling off the tree → miss (sentinel $L'\textit{First} - 1$).

**Precondition:** the input to `Build` must be sorted ascending.
`Find` assumes its argument is an Eytzinger layout from `Build`.

## Index mapping

`Find` returns an index into the **layout** array (not the original
sorted positions). Helper `Sorted_Index (Layout_Index, Length, First)`
maps a layout absolute index back to the corresponding absolute index in
the sorted array by computing the node’s **inorder rank**:

$$
\textit{sorted index} = \textit{First} + \textit{rank}_{\mathrm{inorder}}(i).
$$

Presence checks (hit vs miss) match classic binary search on the sorted
source; the concrete indices differ because the arrays are permuted.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| **Build** | $O(n)$ | $O(\log n)$ recursion |
| **Find** | $O(\log n)$ comparisons | $O(1)$ extra |
| **Sorted_Index** | $O(n)$ walk (educational) | $O(\log n)$ recursion |
| **Classic_Binary_Search** | $O(\log n)$ | $O(1)$ |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Build** | Inorder → heap fill | Complete BST in an array |
| **Search** | $2i+1$ / $2i+2$ | Multiplicative index updates |
| **Return** | Layout index or sentinel | `Layout'First - 1` on miss |
| **Map back** | `Sorted_Index` | Inorder rank → sorted index |
| **Oracle** | `Classic_Binary_Search` | Same presence contract |
| **Capacity** | `Max_N = 100\,000` | Fixed educational bound |
| **Errors** | `Invalid_Argument` | Length mismatch / oversize / OOB |
| **Empty** | No-op build; immediate miss | Sentinel still `First - 1` |

## API

| Subprogram / type | Role |
| --- | --- |
| `Element_Array` | `array (Natural range <>) of Integer` |
| `Build (Sorted, Layout)` | Sorted ascending → Eytzinger layout |
| `Find (Layout, Key)` | Search; layout index or sentinel |
| `Sorted_Index (...)` | Layout index → sorted index |
| `Classic_Binary_Search` | Reference binary search on sorted data |
| `Is_Sorted_Ascending` | Nondecreasing check |
| `Invalid_Argument` | Length mismatch, `> Max_N`, bad `Sorted_Index` |
| `Max_N` | Educational length cap ($100\,000$) |

Return convention: a hit from `Find` is an index in `Layout'Range`; a
miss is the integer sentinel `Integer (Layout'First) - 1`.

## Build / test

```bash
make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Peytzinger_binary_search.gpr`. Objects
go to `obj/`, the test binary to `bin/tests`. There is no `main.adb`;
`tests.adb` is the sole main.

```bash
make clean
```

## Repository

https://github.com/RobertBoettcherSF/Ada-Eytzinger-Binary-Search

## References

1. [Eytzinger binary search — Wikipedia](https://en.wikipedia.org/wiki/Eytzinger_binary_search)
   (related title: *Multiplicative binary search*).
2. Eytzinger, Michael. Level-order (BFS) layout of a binary search tree
   in a contiguous array; search by multiplicative child indexing.
