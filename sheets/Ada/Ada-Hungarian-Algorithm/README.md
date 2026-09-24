# Hungarian Algorithm in Ada 2023

## Project Overview

The **Hungarian algorithm** (also **Hungarian method**, **Kuhn–Munkres**, or
**Munkres assignment algorithm**) is a combinatorial optimization procedure
that solves the **assignment problem** in polynomial time. Given an
$n\times n$ cost matrix $C$, find a permutation $\pi$ of
$\{1,\ldots,n\}$ minimizing (or maximizing) the assignment cost

$$
\sum_{i=1}^{n} C_{i,\pi(i)}.
$$

Equivalently, seek a minimum-cost (or maximum-cost) **perfect matching** in
the complete bipartite graph of $n$ workers and $n$ jobs. Harold Kuhn
published the method in 1955 and named it “Hungarian” after combinatorial
lemmas of Dénes Kőnig and Jenő Egerváry; James Munkres (1957) observed that
it is strongly polynomial. In 2006 it was recognized that Carl Gustav Jacobi
had already solved the assignment problem in the 19th century (Latin
publication, 1890). The original presentation was $O(n^{4})$; Edmonds–Karp
and independently Tomizawa obtained an $O(n^{3})$ refinement.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: square matrices of order $n\le\mathrm{Max\_N}=64$,
1-based indices, signed integer costs, `Clear` / `Set_Cost` /
`Load_Matrix`, `Solve_Minimize` / `Solve_Maximize`, an optional
brute-force oracle for $n\le 8$, fixed arrays (no dynamic heap), and
`Invalid_Argument` for bad dimensions.

Primary source:
[Wikipedia — Hungarian algorithm](https://en.wikipedia.org/wiki/Hungarian_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with matching siblings

| Package / method | Problem | Notes |
| --- | --- | --- |
| **This package** (`Ada-Hungarian-Algorithm`) | Weighted bipartite assignment | Dual $O(n^{3})$ Kuhn–Munkres |
| Hopcroft–Karp (sibling sheet) | **Cardinality** bipartite matching | Unweighted max matching; $O(E\sqrt{V})$ |
| Blossom / Edmonds (sibling sheet) | Matching in **general** graphs | Handles odd cycles (blossoms); not bipartite-only |

README links only — **no** package `with` of siblings. Hopcroft–Karp
maximizes the *number* of edges in a bipartite matching; this sheet
optimizes *edge weights* under a perfect-matching constraint. Blossom
algorithms extend matching beyond bipartite graphs.

## Assignment problem

Workers $S=\{1,\ldots,n\}$ and jobs $T=\{1,\ldots,n\}$ with costs
$c(i,j)$. Seek a bijection $\pi:S\to T$ of minimum total cost. In matrix
form this is

$$
\min_{P}\operatorname{Tr}(PC),
$$

where $P$ ranges over permutation matrices. Maximization is the same
problem on $-C$.

A feasible dual **potential** $y$ on $S\cup T$ satisfies
$y(i)+y(j)\le c(i,j)$ for every edge. The value of $y$ is
$\sum_{v} y(v)$. Every perfect matching costs at least the value of every
potential; equality holds for a matching of **tight** edges
($y(i)+y(j)=c(i,j)$). The Hungarian method maintains a potential and grows
a matching of tight edges until it is perfect — at which point matching
cost equals potential value and both are optimal.

### Example (Wikipedia Alice / Bob / Carol)

| Worker \ Job | Clean bathroom | Sweep floors | Wash windows |
| --- | ---: | ---: | ---: |
| Alice | $8$ | $4$ | $7$ |
| Bob | $5$ | $2$ | $3$ |
| Carol | $9$ | $4$ | $8$ |

Minimum cost $15$: Alice cleans the bathroom, Carol sweeps the floors,
Bob washes the windows ($8+4+3$).

## Algorithm

### Dual $O(n^{3})$ Kuhn–Munkres

Maintain row potentials $U(i)$ and column potentials $V(j)$ with reduced
costs

$$
\overline{c}(i,j)=C_{i j}-U(i)-V(j)\ge 0.
$$

Grow a matching of tight edges ($\overline{c}=0$) by $n$ successive
augmentations. Each augmentation is an $O(n^{2})$ Dijkstra-like scan that
adjusts potentials by a minimum slack $\delta$ and updates an alternating
tree until a free column is reached, then flips the matching along the
recovering path. Total time:

$$
O(n^{3}).
$$

`Solve_Maximize` negates the matrix, calls `Solve_Minimize`, and restores
the objective sign.

### Classical matrix view (equivalent)

An equivalent matrix formulation proceeds by row (and optional column)
reduction, starring independent zeros, covering columns of starred zeros,
priming uncovered zeros, and adjusting covers until $n$ independent zeros
are starred. The dual presentation used here is algorithmically equivalent
and clearer for an $O(n^{3})$ implementation.

### Brute-force oracle ($n\le 8$)

Enumerate all $n!$ permutations and retain a minimum (or maximum) cost
assignment. Used only as a teaching / test oracle; raises
`Invalid_Argument` when $n>\mathrm{Max\_Brute\_N}$.

### Pseudocode

```text
function Solve_Minimize(C):          -- n×n cost matrix
    U[*] := 0; V[*] := 0; match[*] := 0
    for each free row i:
        grow alternating tree on reduced costs
        while no free column reached:
            δ := min slack of unused columns
            update U, V by ±δ; shrink slacks
        augment matching along Way[*]
    return (match, Σ C(i, match(i)))
```

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Solve_Minimize` / `Solve_Maximize`) | $O(n^{3})$ |
| Time (`Solve_Brute_*`) | $O(n!\cdot n)$ for $n\le 8$ |
| Auxiliary space | $O(n^{2})$ fixed cost store |
| Matrix order | $n\le\mathrm{Max\_N}=64$ |
| Indices | $1 .. n$ |
| Costs | Signed integers (`Cost_Value`) |
| Empty $n=0$ | Feasible; total cost $0$ |

## Features

- **`Clear` / `Set_Cost` / `Load_Matrix`** — build a square $n\times n$
  instance ($n=0$ allowed).
- **`Size` / `Get_Cost`** — inspectors.
- **`Solve_Minimize` / `Solve_Maximize`** — Kuhn–Munkres assignment.
- **`Solve_Brute_Minimize` / `Solve_Brute_Maximize`** — $n!$ oracle for
  $n\le 8$.
- **`Is_Permutation` / `Assignment_Cost`** — validation helpers.
- **Capacity / dimension guards** — `Invalid_Argument` for $n>\mathrm{Max\_N}$,
  non-square `Load_Matrix`, `First/=1`, out-of-range indices, or brute
  $n>8$.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_N}$.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Phungarian_algorithm.gpr`.

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

=== 1. Empty N=0 ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty $n=0$; trivial $1\times 1$ (positive and negative)
- Diagonal / identity preference; all-equal and zero matrices
- Wikipedia Alice/Bob/Carol instance (min cost $15$)
- Classic $4\times 4$ Munkres textbook matrix (min cost $275$)
- Hand $2\times 2$, $3\times 3$, $4\times 4$ batches with expected totals
- Signed costs; maximize via $-C$ identity
- Brute-force agreement for all $n\le 8$ on generated grids
- Cycle / path sparse preferences; $n=16,32,\mathrm{Max\_N}$ identity
- `Invalid_Argument` for overflow, rectangular load, bad indices,
  duplicate assignments, and brute $n>8$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Hungarian_Algorithm is
   Max_N       : constant Positive := 64;
   Max_Brute_N : constant Positive := 8;

   type Index is range 1 .. Max_N;
   type Cost_Value is range -(2**62) .. 2**62 - 1;
   Large_Cost : constant Cost_Value := Cost_Value'Last / 8;

   type Cost_Matrix is array (Positive range <>, Positive range <>)
     of Cost_Value;
   type Assignment_Array is array (Positive range <>) of Natural;

   type Solution is record
      N          : Natural := 0;
      Total_Cost : Cost_Value := 0;
      Assignment : Assignment_Array (1 .. Max_N);
   end record;

   type Problem is limited private;
   Invalid_Argument : exception;

   procedure Clear (P : in out Problem; Size : Natural);
   procedure Set_Cost
     (P : in out Problem; Row, Col : Index; Cost : Integer);
   procedure Load_Matrix (P : in out Problem; Costs : Cost_Matrix);
   function Size (P : Problem) return Natural;
   function Get_Cost
     (P : Problem; Row, Col : Index) return Cost_Value;

   procedure Solve_Minimize (P : Problem; Result : out Solution);
   procedure Solve_Maximize (P : Problem; Result : out Solution);
   procedure Solve_Brute_Minimize (P : Problem; Result : out Solution);
   procedure Solve_Brute_Maximize (P : Problem; Result : out Solution);

   function Is_Permutation
     (A : Assignment_Array; N : Natural) return Boolean;
   function Assignment_Cost
     (P : Problem; A : Assignment_Array) return Cost_Value;
end Hungarian_Algorithm;
```

Raises `Invalid_Argument` for $n>\mathrm{Max\_N}$, non-square or
non-1-based `Load_Matrix`, row/column indices outside $1 .. n$,
`Solve_Brute_*` when $n>8$, or `Assignment_Cost` when the mapping is not
a permutation of $1 .. n$.

`Assignment(I)=J` means row $I$ is matched to column $J$. Empty $n=0$ is
feasible with total cost $0$. Costs may be negative; maximization is
implemented by negating the matrix.

## License

Educational reference implementation. See repository `LICENSE` if present.
