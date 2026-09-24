# Sorted List ADT in Ada 2023

## Project Overview

A **sorted list** (ordered list) is an abstract data type that stores
elements in **nondecreasing** order under insertion and deletion. Unlike a
plain dynamic array that is sorted only after an explicit sort pass, the
sorted-list ADT **maintains** the order invariant on every mutating
operation.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of a **bounded, array-backed sorted multiset** of
`Integer` values. Membership and insertion-point location use **inline
binary search** (no dependency on a sibling `Binary_Search` package).
Insert and delete then shift a contiguous array tail.

Primary source:
[Wikipedia — Sorted list](https://en.wikipedia.org/wiki/Sorted_list)
(the encyclopedia page may redirect toward sorting articles; this package
implements the **sorted-list ADT**, not a standalone sorting algorithm).

Part of the **RobertBoettcherSF** Ada algorithm / ADT series.

## Representation invariant

For a list $L$ of length $n = \mathrm{Length}(L)$:

$$
\forall\, i \in \{1,\ldots,n-1\}:\quad
\mathrm{Element}(L,i) \le \mathrm{Element}(L,i+1)
$$

Duplicates are allowed (multiset). Capacity is the compile-time constant
$\mathrm{Max\_N}$ (here $1024$).

## Algorithm sketch

**Search / Contains / Find.** Inline binary search (lower-bound style)
over the occupied prefix $[1..n]$:

$$
\begin{align*}
&\mathit{lo} \leftarrow 1,\quad \mathit{hi} \leftarrow n+1 \\
&\mathbf{while}\ \mathit{lo} < \mathit{hi}: \\
&\quad m \leftarrow \mathit{lo} + \lfloor(\mathit{hi}-\mathit{lo})/2\rfloor \\
&\quad \mathbf{if}\ L[m] < x:\ \mathit{lo} \leftarrow m+1 \\
&\quad \mathbf{else}:\ \mathit{hi} \leftarrow m \\
&\mathbf{return}\ \mathit{lo}
\end{align*}
$$

The midpoint form $m = \mathit{lo} + \lfloor(\mathit{hi}-\mathit{lo})/2\rfloor$
avoids overflow of $(\mathit{lo}+\mathit{hi})/2$.

**Insert.** Locate the lower bound of $x$, shift the right tail one slot
toward the end, write $x$, increment length. Raises `Overflow` when
$n = \mathrm{Max\_N}$.

**Delete / Delete_First.** Locate the leftmost equal key, shift the right
tail one slot left, decrement length. Raises `Invalid_Argument` if $x$ is
absent.

**Min / Max.** Read $L[1]$ / $L[n]$ in $O(1)$. Raise `Invalid_Argument`
when empty.

## Complexity

Let $n$ be the current length.

| Operation | Time | Notes |
| --- | --- | --- |
| `Empty` / `Clear` / `Length` / `Is_Empty` / `Is_Full` | $O(1)$ | |
| `Contains` / `Find` | $O(\log n)$ | Inline binary search |
| `Insert` | $O(n)$ | Binary search + shift |
| `Delete` / `Delete_First` | $O(n)$ | Binary search + shift |
| `Min` / `Max` | $O(1)$ | Ends of the array |
| `Element` | $O(1)$ | 1-based index into sorted content |

Space is $O(\mathrm{Max\_N})$ for the backing store (fixed capacity).

## API (`Sorted_List`)

| Entity | Role |
| --- | --- |
| `Max_N` | Capacity ($1024$) |
| `List` | Private opaque sorted multiset |
| `Overflow` | Raised by `Insert` when full |
| `Invalid_Argument` | Empty `Min`/`Max`, bad `Element`, absent `Delete` |
| `Empty` | Fresh empty list |
| `Length` / `Is_Empty` / `Is_Full` / `Clear` | Size / state |
| `Insert` | Ordered insert (multiset) |
| `Contains` / `Find` | Membership; `Find` returns 1-based index or $0$ |
| `Delete` / `Delete_First` | Remove first occurrence of a key |
| `Min` / `Max` | Extremes |
| `Element (L, Index)` | 1-based access into sorted content |

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Psorted_list.gpr → bin/tests
make test   # run bin/tests; expect "Results: N PASS, 0 FAIL"
make clean
```

Requires GNAT with Ada 2022/2023 support. Object files go under `obj/`,
the test executable under `bin/`. There is no `main.adb` — `tests.adb` is
the project main.

## Related ideas

Binary search, selection, balanced search trees, skip lists, and explicit
sorting algorithms (heapsort, mergesort, …) are natural companions. This
package stays self-contained: binary search is inlined in the body.

## License

Educational use within the RobertBoettcherSF Ada series.
