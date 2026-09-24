# Binary Search Algorithm in Ada 2023

## Project Overview

**Binary search** (also known as **half-interval search**, **logarithmic
search**, or **binary chop**) finds the position of a target value within a
**sorted** array. It compares the target to the middle element; if they
differ, the half that cannot contain the target is discarded and the search
continues on the remaining half until the value is found or the interval is
empty.

Binary search runs in logarithmic time in the worst case —
$O(\log n)$ comparisons — and is faster than linear search except for small
arrays. The array must already be sorted. Specialized structures such as
hash tables can be faster for exact membership, but binary search also
supports rank / predecessor / successor style queries and duplicate-key
bounds.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of classic **iterative** binary search on ascending
`Integer` arrays, with overflow-safe midpoints and leftmost / rightmost
variants for duplicate keys.

Primary source:
[Wikipedia — Binary search algorithm](https://en.wikipedia.org/wiki/Binary_search_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with search siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Binary-Search`) | Classic iterative binary chop on a sorted array |
| **[Ada-Uniform-Binary-Search](https://github.com/RobertBoettcherSF/Ada-Uniform-Binary-Search)** | Uniform binary search (precomputed mid deltas) |
| **[Ada-Fibonacci-Search](https://github.com/RobertBoettcherSF/Ada-Fibonacci-Search)** | Fibonacci search (division-free splits) |

README links only — **no** package `with` of siblings.

## Algorithm

Given a sorted ascending array $A$ of length $n$ and target $T$:

1. If $n = 0$, return the sentinel $A'\mathit{First}-1$.
2. Set $L \leftarrow A'\mathit{First}$, $R \leftarrow A'\mathit{Last}$.
3. While $L \le R$:
   - Midpoint (overflow-safe):
     $$m = L + \left\lfloor\frac{R-L}{2}\right\rfloor$$
     (never $(L+R)/2$, which can overflow fixed-width indices — the
     famous Bentley / Java library bug).
   - If $A(m) < T$, set $L \leftarrow m+1$.
   - Else if $A(m) > T$, set $R \leftarrow m-1$.
   - Else return $m$ (any matching index is correct).
4. Return the sentinel $A'\mathit{First}-1$ (absent).

If $n > \mathrm{Max\_N}$, every entry point raises `Invalid_Argument`.

### Duplicate keys — leftmost / rightmost

Classic `Find` may return **any** index equal to $T$. When duplicates
matter, use half-open bound searches (Wikipedia):

**Find_First** (leftmost / lower-bound style) on $[L,R) = [A'\mathit{First},\,A'\mathit{Last}+1)$:

$$
\begin{align*}
&\mathbf{while}\ L < R: \\
&\quad m \leftarrow L + \lfloor(R-L)/2\rfloor \\
&\quad \mathbf{if}\ A(m) < T:\ L \leftarrow m+1 \\
&\quad \mathbf{else}:\ R \leftarrow m \\
&\mathbf{return}\ L\ \text{if in range and }A(L)=T\text{, else sentinel}
\end{align*}
$$

**Find_Last** (rightmost / upper-bound $-1$):

$$
\begin{align*}
&\mathbf{while}\ L < R: \\
&\quad m \leftarrow L + \lfloor(R-L)/2\rfloor \\
&\quad \mathbf{if}\ A(m) > T:\ R \leftarrow m \\
&\quad \mathbf{else}:\ L \leftarrow m+1 \\
&\mathbf{return}\ R-1\ \text{if in range and }A(R-1)=T\text{, else sentinel}
\end{align*}
$$

### Classic Find pseudocode

$$
\begin{align*}
&\mathbf{function}\ \mathrm{Find}(A,T): \\
&\quad L \leftarrow A'\mathit{First};\ R \leftarrow A'\mathit{Last} \\
&\quad \mathbf{while}\ L \le R: \\
&\quad\quad m \leftarrow L + \lfloor(R-L)/2\rfloor \\
&\quad\quad \mathbf{if}\ A(m) < T:\ L \leftarrow m+1 \\
&\quad\quad \mathbf{elsif}\ A(m) > T:\ R \leftarrow m-1 \\
&\quad\quad \mathbf{else}:\ \mathbf{return}\ m \\
&\quad \mathbf{return}\ A'\mathit{First}-1
\end{align*}
$$

### Example

Sorted array $\{1,2,3,4,4,5,6,7\}$ (1-based), target $4$:

- `Find` may return index $4$ or $5$ (Wikipedia classic returns $4$).
- `Find_First` returns $4$ (leftmost $4$).
- `Find_Last` returns $5$ (rightmost $4$).
- Target $0$ or $8$ → sentinel $0$ when $A'\mathit{First}=1$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (worst) | $O(\log n)$ comparisons |
| Time (average) | $O(\log n)$ |
| Time (best) | $O(1)$ — middle element is the key |
| Auxiliary space | $O(1)$ — iterative |
| Requires sorted input | Yes — ascending / nondecreasing |

Each iteration discards half of the remaining interval, so after
$k$ steps at most $\lceil n/2^k\rceil$ candidates remain; thus
$k = O(\log n)$.

## Features

- **`Find`** — classic iterative binary search; any matching index.
- **`Find_First` / `Find_Last`** — leftmost / rightmost equal key.
- **Overflow-safe midpoint** — $L + \lfloor(R-L)/2\rfloor$.
- **Sentinel** — $A'\mathit{First}-1$ when the key is absent (works for
  arbitrary `A'First`, including $0$).
- **Capacity guard** — `Invalid_Argument` when `A'Length > Max_N`
  (default $100\,000$).
- **Arbitrary bounds** — works for any `Natural` `A'First`.
- **Negatives and duplicates** — full `Integer` domain.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbinary_search.gpr`.

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

(Exact `NN` is the current suite size; it is at least 70.)

## Testing

The test suite in `tests.adb` covers:

- Empty / singleton edge cases (including 0-based indices)
- Small sorted hits and misses
- Duplicate keys (`Find_First` / `Find_Last` vs Wikipedia examples)
- Negatives, zero, and mixed signed keys
- Non-1 `A'First` index bounds
- Power-of-two and odd lengths
- Large $n$ ($5\,000$) vs a linear-scan reference
- Duplicate plateaus on large $n$ vs linear first/last
- Random sorted arrays with random queries
- `Invalid_Argument` for oversized $n$
- Two-element boundary cases

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Binary_Search is
   Max_N : constant Positive := 100_000;
   type Element_Array is array (Natural range <>) of Integer;
   Invalid_Argument : exception;
   function Find (A : Element_Array; Key : Integer) return Integer;
   function Find_First (A : Element_Array; Key : Integer) return Integer;
   function Find_Last (A : Element_Array; Key : Integer) return Integer;
end Binary_Search;
```

Sentinel when absent: `A'First - 1`. Raises `Invalid_Argument` if
`A'Length > Max_N`. Precondition (unchecked): `A` is sorted nondecreasing.

## License

Educational reference implementation. See repository `LICENSE` if present.
