# Christofides Algorithm in Ada 2023

## Project Overview

The **Christofides algorithm** (also **Christofides–Serdyukov**) is a classical
**approximation algorithm** for the **metric travelling salesman problem
(TSP)**. A salesman must visit each city in a finite set exactly once and
return to the start; distances are **symmetric** and obey the **triangle
inequality**. Exact TSP is NP-hard. Christofides builds a tour whose length is
guaranteed to be at most $\tfrac{3}{2}$ times the optimum.

Nicos Christofides published the method in 1976; Anatoliy Serdyukov discovered
it independently around the same time. On general metric spaces it was the
best known polynomial-time guarantee for decades (sharper randomized ratios
appear in later work). The construction combines a **minimum spanning tree**,
a **minimum-weight perfect matching** on the odd-degree tree vertices, an
**Eulerian circuit** of their multigraph union, and **shortcutting** to a
Hamiltonian cycle.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed $1 .. N$, a complete undirected view of a
non-negative `Cost_Matrix`, `Approximate_Tour`, helpers
(`MST_Cost`, `Odd_Vertices`, `Matching_Cost`, `Tour_Cost`), and an exact
brute-force oracle for $N\le 10$. Exact matching uses subset DP capped at
$\mathrm{Max\_Matching\_Odd}=12$ odd vertices. Triangle inequality is
**assumed** for the $\tfrac{3}{2}$ proof and is not checked at runtime.

Primary source:
[Wikipedia — Christofides algorithm](https://en.wikipedia.org/wiki/Christofides_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with routing / TSP siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Christofides-Algorithm`) | Metric TSP $\tfrac{3}{2}$-approximation via MST + matching + Euler shortcut |
| Nearest neighbour (sibling sheet) | Greedy TSP tour; fast, **no** constant-factor guarantee |
| Vehicle routing / CVRP (sibling sheet) | Multi-vehicle capacitated routes from a depot (generalises TSP) |
| Dijkstra (sibling sheet) | Non-negative weighted SSSP — build $c_{ij}$ from a road graph |

README links only — **no** package `with` of siblings. Prefer the nearest-neighbour
sheet for classical NN rather than duplicating that heuristic here.

## Algorithm

### Input assumptions

Input: a complete graph on vertices $\{1,\ldots,N\}$ with $N\ge 2$ and weights
$c(u,v)\ge 0$. For the approximation proof, $c$ must be **symmetric**
($c(u,v)=c(v,u)$) and satisfy the **triangle inequality**
$c(u,w)\le c(u,v)+c(v,w)$. This implementation stores a (possibly asymmetric)
matrix but MST / matching use the undirected weight
$\min(c(u,v),c(v,u))$. Triangle inequality is not validated; the algorithm may
still run on non-metric tables without the $\tfrac{3}{2}$ guarantee.

### Christofides–Serdyukov steps

1. **MST.** Compute a minimum spanning tree $T$ of $G$ (Prim on the dense
   matrix; ties prefer the smaller vertex index).
2. **Odd set.** Let $O$ be the set of vertices of odd degree in $T$. By the
   handshaking lemma, $|O|$ is even.
3. **Matching.** Compute a minimum-weight perfect matching $M$ in the complete
   subgraph induced by $O$ (subset DP for $|O|\le\mathrm{Max\_Matching\_Odd}$).
4. **Multigraph.** Form $H=(V,E(T)\cup E(M))$. Every vertex has even degree in
   $H$, and $H$ is connected.
5. **Euler tour.** Find an Eulerian circuit of $H$ (Hierholzer).
6. **Shortcut.** Convert the circuit into a Hamiltonian cycle by skipping
   repeated vertices. Triangle inequality ensures shortcutting does not
   increase cost.

### The $\tfrac{3}{2}$ guarantee

Let $C^\star$ be an optimal tour. Removing any edge of $C^\star$ yields a
spanning tree, so

$$
w(T)\le w(C^\star).
$$

Number the odd vertices of $T$ in cyclic order around $C^\star$ and split the
tour into two perfect matchings of $O$ (odd- and even-indexed path endpoints).
One of those matchings has weight at most half of $w(C^\star)$; the minimum
perfect matching is no heavier:

$$
w(M)\le \tfrac{1}{2}\,w(C^\star).
$$

The Euler tour of $T\cup M$ therefore costs at most
$\tfrac{3}{2}\,w(C^\star)$. Shortcutting does not increase the weight under the
triangle inequality, so the output tour $C$ satisfies

$$
w(C)\le \tfrac{3}{2}\,w(C^\star).
$$

The ratio is tight up to arbitrarily small additives on some families of
metric instances (path plus near-shortcut edges).

### Exact oracle ($N\le 10$)

Enumerate all directed Hamiltonian cycles by fixing the first city to $1$ and
permuting the rest — $(N-1)!$ candidates — and keep the minimum closed-tour
cost. On symmetric matrices this is the undirected optimum. Used in tests so
learners can check $w(C)\le \tfrac{3}{2}\,w(C^\star)$ on tiny Euclidean
instances.

### Example ($N=3$ path metric)

Symmetric costs $c_{12}=c_{23}=1$, $c_{13}=2$. The MST is the path $1{-}2{-}3$
of weight $2$; odd vertices are $\{1,3\}$; the matching is the single edge
$1{-}3$ of weight $2$; the Euler circuit is already the cycle
$1{-}2{-}3{-}1$ of cost $4$, which equals OPT.

### Asymptotic cost

With a dense $N\times N$ matrix:

$$
O(N^{2})
$$

for Prim, plus $O(2^{k}k^{2})$ for matching on $k=|O|\le 12$ odd vertices, plus
$O(N)$ for Hierholzer and shortcutting. Storage is $O(N^{2})$ capped at
$\mathrm{Max\_Vertices}=24$. Exact enumeration is $O((N-1)!\,N)$ and restricted
to $N\le 10$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (Prim MST) | $O(N^{2})$ |
| Time (matching DP) | $O(2^{k}k^{2})$ for $k=\|O\|\le 12$ |
| Time (Euler + shortcut) | $O(N)$ |
| Time (`Exact_Tour`) | $O((N-1)!\,N)$ for $N\le 10$ |
| Matrix storage | $O(N^{2})$ up to $\mathrm{Max\_Vertices}$ |
| Vertex indices | $1 .. N$ with $N \le 24$ |
| Costs | Non-negative integers; negatives raise `Invalid_Argument` |
| Matching cap | $\mathrm{Max\_Matching\_Odd}=12$ |
| Exact cap | $\mathrm{Max\_Exact\_Vertices}=10$ |

## Features

- **`Cost_Matrix` / `Tour` / `Vertex_List` / `Cost_Value`** — complete graph +
  closed tour + odd-set list.
- **`Put_Distance` / `Put_Symmetric`** — fill entries with negativity checks.
- **`Approximate_Tour`** — full Christofides–Serdyukov pipeline.
- **`MST_Cost` / `Odd_Vertices` / `Matching_Cost`** — inspect intermediate
  steps (handshaking, MWPM).
- **`Exact_Tour`** — brute-force optimal directed tour for $N\le 10`.
- **`Closed_Tour_Cost` / `Tour_Cost` / `Is_Valid_Tour`** — cost and
  permutation helpers.
- **`Undirected_Weight` / `Rounded_Euclidean`** — undirected view and metric
  demos from integer coordinates.
- **Guards** — `Invalid_Argument` for bad dimensions, $N<2$, negatives,
  matching overflow, exact overflow.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pchristofides_algorithm.gpr`.

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

=== 1. Matrix builders and queries ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- $N=2,3,4$ hand-checked tours, MST weights, and matching costs
- Line / Euclidean instances with `Exact_Tour` and the $\le\tfrac{3}{2}$ check
- MST properties ($w(T)=N-1$ on unit lines; tour $\ge$ MST)
- Even cardinality of odd MST vertices (handshaking)
- `Invalid_Argument` for shape, negatives, $N=1$, exact overflow, matching
  overflow / odd $|O|$, cost mismatches
- Empty matching cost $0$; explicit MWPM preference for cheap pairs
- Capacity smoke at $N=\mathrm{Max\_Vertices}$ on a line (only two odd vertices)
- Tour rotation so `Cities(1)=1`

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Christofides_Algorithm is
   Max_Vertices       : constant Positive := 24;
   Max_Matching_Odd   : constant Positive := 12;
   Max_Exact_Vertices : constant Positive := 10;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Cost_Value is range 0 .. 2**63 - 1;
   type Cost_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Cost_Value;
   type City_Seq is array (1 .. Max_Vertices) of Vertex_Id;

   type Tour is record
      N      : Natural := 0;
      Cities : City_Seq;  -- permutation in Cities(1 .. N)
      Cost   : Cost_Value := 0; -- closed tour length
   end record;

   type Vertex_List is record
      Count    : Natural := 0;
      Vertices : City_Seq;
   end record;

   Invalid_Argument : exception;

   procedure Put_Distance
     (Distances : in out Cost_Matrix;
      From, To  : Vertex_Id;
      Value     : Integer);
   procedure Put_Symmetric
     (Distances : in out Cost_Matrix;
      A, B      : Vertex_Id;
      Value     : Integer);

   function Matrix_Order (Distances : Cost_Matrix) return Natural;
   function Distance
     (Distances : Cost_Matrix; From, To : Vertex_Id) return Cost_Value;
   function Rounded_Euclidean
     (X1, Y1, X2, Y2 : Integer) return Cost_Value;
   function Undirected_Weight
     (Distances : Cost_Matrix; A, B : Vertex_Id) return Cost_Value;

   function MST_Cost (Distances : Cost_Matrix) return Cost_Value;
   function Odd_Vertices (Distances : Cost_Matrix) return Vertex_List;
   function Matching_Cost
     (Distances : Cost_Matrix; Odds : Vertex_List) return Cost_Value;

   function Closed_Tour_Cost
     (Distances : Cost_Matrix;
      Cities    : City_Seq;
      N         : Natural) return Cost_Value;
   function Is_Valid_Tour (T : Tour) return Boolean;
   function Tour_Cost
     (Distances : Cost_Matrix; T : Tour) return Cost_Value;

   function Approximate_Tour (Distances : Cost_Matrix) return Tour;
   function Exact_Tour (Distances : Cost_Matrix) return Tour;
end Christofides_Algorithm;
```

Raises `Invalid_Argument` when the matrix is not square and 1-based, when
$N<2$ on MST / tour APIs, when indices lie outside $1 .. N$, when a written
distance is negative, when `Exact_Tour` is called with $N>10$, when
`Matching_Cost` / `Approximate_Tour` see an odd set larger than
$\mathrm{Max\_Matching\_Odd}$ (or of odd cardinality), or when
`Tour_Cost` / `Closed_Tour_Cost` see a size mismatch.

Tour convention: `Cities(1 .. N)` is a permutation of $1 .. N$ starting at
vertex $1$ after shortcutting; `Cost` is the sum of the $N$ edges of the cycle
including the return edge $\mathrm{Cities}(N)\to\mathrm{Cities}(1)$.

Matching limit: trees may have up to $N$ odd vertices (e.g. a star when $N$ is
even). Instances with $|O|>12$ must be avoided or the cap raised; line metrics
always have $|O|=2$ and are safe up to $\mathrm{Max\_Vertices}$.

## License

Educational reference implementation. See repository `LICENSE` if present.
