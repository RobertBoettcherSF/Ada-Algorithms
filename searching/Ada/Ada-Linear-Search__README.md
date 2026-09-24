# Linear Search (Sequential Search) in Ada 2023

## Project Overview

**Linear search** (also known as **sequential search**) finds an element
in a list by checking each element from left to right until a match is
found or the whole list has been examined. It needs **no sortedness**
precondition and is usually the simplest search to implement.

A linear search runs in linear time in the worst case — at most $n$
comparisons for a list of length $n$. If every element is equally likely
to be the target, the average number of comparisons is about
$(n+1)/2$. Best case is $O(1)$ when the key sits at the first position.
For all but short lists, faster schemes such as binary search (on sorted
data) or hash tables are preferable; linear search remains practical for
tiny arrays, single searches on unordered data, and as a building block
inside other algorithms (for example the final block scan of jump search).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of the classic **iterative** left-to-right scan on
`Integer` arrays, returning the **first** matching index.

Primary source:
[Wikipedia — Linear search](https://en.wikipedia.org/wiki/Linear_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with search siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Linear-Search`) | Left-to-right scan; unordered OK |
| **[Ada-Jump-Search](https://github.com/RobertBoettcherSF/Ada-Jump-Search)** | Fixed jumps then a short linear block scan (sorted) |
| **[Ada-Binary-Search](https://github.com/RobertBoettcherSF/Ada-Binary-Search)** | Classic iterative binary chop (sorted) |

README links only — **no** package `with` of siblings.

## Algorithm

Given an array $A$ of length $n$ and target $T$ (Ada indices
$A'\mathit{First} \ldots A'\mathit{Last}$):

1. If $n = 0$, return the sentinel $A'\mathit{First}-1$.
2. For each index $i$ from $A'\mathit{First}$ to $A'\mathit{Last}$:
   - If $A(i) = T$, return $i$ (first occurrence).
3. Return the sentinel $A'\mathit{First}-1$ (absent).

If $n > \mathrm{Max\_N}$, every entry point raises `Invalid_Argument`.

### Classic Find pseudocode

$$
\begin{align*}
&\mathbf{function}\ \mathrm{Find}(A,T): \\
&\quad \mathbf{for}\ i \leftarrow A'\mathit{First}\ \mathbf{to}\ A'\mathit{Last}: \\
&\quad\quad \mathbf{if}\ A(i) = T:\ \mathbf{return}\ i \\
&\quad \mathbf{return}\ A'\mathit{First}-1
\end{align*}
$$

`Find_From` is the same loop starting at a caller-supplied `Start`
instead of $A'\mathit{First}$ (useful for locating later duplicates).
`Contains` is the Boolean membership form of `Find`.

### Sentinel variant (README only)

Wikipedia also describes a **sentinel** optimization: append a copy of
$T$ past the end so the loop need not test the index bound each step.
This package deliberately uses the plain two-comparison form (value check
plus range iteration) for clarity; Ada's `for I in A'Range` already
expresses the bound cleanly. The API does **not** require a sentinel slot
in the array.

### Ordered-table early exit (not implemented)

If $A$ is known sorted ascending, the scan can stop early once $A(i) > T$.
That variant is documented on Wikipedia but is **not** part of this
package — use binary or jump search when the data are sorted and $n$ is
large.

### Example

Array $\{40, 10, 30, 20, 50, 0\}$ (1-based), target $30$:

- `Find` returns index $3$.
- Target $15$ → sentinel $0$ when $A'\mathit{First}=1$.
- Duplicates $\{1,2,2,2,3\}$: `Find(..., 2)` returns the **first** index
  $2$; `Find_From(..., 2, Start => 3)` returns $3`.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (worst) | $O(n)$ — key absent or only at the end |
| Time (average) | $O(n)$ — about $(n+1)/2$ comparisons if the key occurs once and all orderings are equally likely |
| Time (best) | $O(1)$ — key at $A'\mathit{First}$ |
| Auxiliary space | $O(1)$ — iterative |
| Requires sorted input | **No** |

When the key occurs $k$ times and all orderings are equally likely, the
expected number of comparisons is $n$ if $k = 0$, and
$(n+1)/(k+1)$ if $1 \le k \le n$ (Wikipedia). Asymptotically both the
worst-case and expected costs remain $O(n)$.

## Features

- **`Find`** — classic left-to-right scan; **first** matching index.
- **`Find_From`** — same scan from an explicit `Start` index.
- **`Contains`** — Boolean membership.
- **Sentinel** — $A'\mathit{First}-1$ when the key is absent (works for
  arbitrary `A'First`, including $0$).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $100\,000$); `Find_From` also rejects `Start` outside
  `A'Range` on non-empty arrays.
- **Arbitrary bounds** — works for any `Natural` `A'First`.
- **Negatives and duplicates** — full `Integer` domain; first occurrence.
- **Unordered OK** — no sortedness precondition.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Plinear_search.gpr`.

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

(Exact `NN` is the current suite size; it is at least 80.)

## Testing

The test suite in `tests.adb` covers:

- Empty / singleton edge cases (including 0-based indices)
- First / middle / last hits and systematic misses
- Duplicate keys (first occurrence; `Find_From` for later hits)
- Negatives, zero, and `Integer'First` / `Integer'Last`
- Non-1 `A'First` index bounds
- Two-element and unordered permutations
- Larger $n$ ($500$) spot checks vs an arithmetic reference
- Random unordered arrays vs a linear first-occurrence oracle
- `Invalid_Argument` for oversized $n$ and out-of-range `Start`
- `Contains` equivalence with `Find`

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Linear_Search is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   function Find (A : Element_Array; Key : Integer) return Integer;
   function Find_From
     (A : Element_Array; Key : Integer; Start : Natural) return Integer;
   function Contains (A : Element_Array; Key : Integer) return Boolean;
end Linear_Search;
```

Sentinel when absent: `A'First - 1`. Raises `Invalid_Argument` if
`A'Length > Max_N`, or if `Find_From` is given a `Start` outside
`A'Range` on a non-empty array. No sortedness precondition.

## License

Educational reference implementation. See repository `LICENSE` if present.
