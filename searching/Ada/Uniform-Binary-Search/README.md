# Uniform Binary Search — Ada 2023

Educational, self-contained Ada 2023 package implementing
[**uniform binary search**](https://en.wikipedia.org/wiki/Uniform_binary_search)
(Donald Knuth, *The Art of Computer Programming* Vol. 3, Algorithm C;
idea credited to Ashok K. Chandra). Instead of recomputing the midpoint
$(lo+hi)/2$ on every step, the algorithm **precomputes a delta lookup
table** for array length $N$ and then searches with a **single index**
updated by table lookups.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

## Why uniform?

Classic binary search maintains two bounds and derives a mid index each
iteration. Uniform binary search is attractive when:

- a **table lookup** is cheaper than an addition plus a shift on the
  target architecture (historically Knuth’s MIX), and
- **many searches** run against the same array, or against several
  arrays of the **same length** (one table, many queries).

Search results match classic binary search on the same sorted ascending
array: if `Key` occurs, some valid index of an occurrence is returned
(not necessarily the leftmost when duplicates exist); if absent, the
sentinel `A'First - 1` is returned.

## Delta table

For length $N$, successive deltas follow the Wikipedia / Knuth formula

$$
\delta_i = \left\lfloor \frac{N + 2^i}{2^{i+1}} \right\rfloor,
\qquad i = 0,1,2,\ldots
$$

until a $0$ terminator is stored. Equivalently in imperative form
(`power` starts at $1$):

$$
\textit{half} \leftarrow \textit{power},\quad
\textit{power} \leftarrow 2\cdot\textit{power},\quad
\delta_i \leftarrow \left\lfloor (N + \textit{half}) / \textit{power} \right\rfloor.
$$

The table length is $O(\log N)$ (at most $\lfloor\log_2 N\rfloor + 2$
nonzero steps plus the final $0$). This package caps $N$ at
$\textit{Max\_N} = 100\,000$ and stores deltas in a fixed pool of
$\textit{Max\_Delta\_Entries} = 64$ slots.

### Example ($N = 10$)

Wikipedia’s sample array

$$
[1,3,5,6,7,9,14,15,17,19]
$$

yields

$$
\delta = [5, 3, 1, 1, 0].
$$

Search starts at 0-based index $\delta_0 - 1 = 4$ (value $7$) and then
adds or subtracts later $\delta$ values after each unequal comparison.

## Algorithm sketch

1. **Build** the delta table for $N = A'\textit{Length}$.
2. Set $\textit{index} \leftarrow A'\textit{First} + \delta_0 - 1$.
3. Loop:
   - if $\textit{index}$ is outside $A$'s range → miss (bounds guard;
     Knuth’s presentation uses a 1-based array with a sentinel at $0$);
   - if $A(\textit{index}) = \textit{Key}$ → hit;
   - if the current delta level is $0$ → miss;
   - else advance one table slot and set
     $\textit{index} \leftarrow \textit{index} \pm \delta$
     according to the comparison.

**Precondition:** `A` must be sorted in nondecreasing (ascending) order.
`Find` does not verify order; use `Is_Sorted_Ascending` in tests or
debug builds.

## Complexity

| Phase | Time | Space |
| --- | --- | --- |
| **Build_Table** | $O(\log N)$ | $O(\log N)$ deltas |
| **Find** (with table) | $O(\log N)$ comparisons | $O(1)$ extra |
| **Find** (no table) | $O(\log N)$ build + search | temporary table |
| **Classic_Binary_Search** | $O(\log N)$ | $O(1)$ |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Table** | `Build_Table (N, Table)` | Knuth deltas + trailing $0$ |
| **Search** | `Find (A, Key)` / `Find (A, Key, Table)` | Uniform index updates |
| **Oracle** | `Classic_Binary_Search` | Same result contract |
| **Sorted check** | `Is_Sorted_Ascending` | Optional / tests |
| **Capacity** | `Max_N` | Raises `Invalid_Argument` if exceeded |
| **Duplicates** | Any matching index | Not necessarily leftmost |
| **Empty array** | Immediate miss | Sentinel `A'First - 1` |
| **Indexing** | `Natural` bounds | 0-based or 1-based arrays |

## API

| Subprogram / type | Role |
| --- | --- |
| `Element_Array` | `array (Natural range <>) of Integer` |
| `Delta_Table` | Private delta lookup table |
| `Build_Table (N, Table)` | Precompute deltas for length $N$ |
| `Find (A, Key)` | Search; builds a fresh table |
| `Find (A, Key, Table)` | Search with a reused table for `A'Length` |
| `Classic_Binary_Search (A, Key)` | Reference binary search |
| `Is_Sorted_Ascending (A)` | Nondecreasing check |
| `Table_Length` / `Table_Entry_Count` / `Delta_At` | Table introspection |
| `Invalid_Argument` | $N > \textit{Max\_N}$, bad table, OOB `Delta_At` |
| `Max_N` / `Max_Delta_Entries` | Educational caps |

Return convention: a hit is an index in `A'Range`; a miss is the
integer sentinel `Integer (A'First) - 1` (so an empty or 0-based array
can use $-1$).

## Build / test

```bash
make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Puniform_binary_search.gpr`. Objects
go to `obj/`, the test binary to `bin/tests`. There is no `main.adb`;
`tests.adb` is the sole main.

```bash
make clean
```

## Repository

https://github.com/RobertBoettcherSF/Ada-Uniform-Binary-Search

## References

1. Knuth, Donald E. *The Art of Computer Programming*, Volume 3:
   *Sorting and Searching*. Algorithm C (uniform binary search).
2. [Uniform binary search — Wikipedia](https://en.wikipedia.org/wiki/Uniform_binary_search)
