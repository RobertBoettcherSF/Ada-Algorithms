# Travelling Salesman Problem in Ada 2023

## Project Overview

The **travelling salesman problem (TSP)** asks: given a list of cities and
the distances between each pair, what is the **shortest possible route** that
visits each city **exactly once** and returns to the origin? It is an
**NP-hard** problem in combinatorial optimization, central to theoretical
computer science and operations research. The decision version (is there a
tour of length at most $L$?) is **NP-complete**.

TSP was formulated mathematically in the 1930s (notably by Karl Menger) and
has been studied intensively ever since. Exact methods (integer programming,
branch-and-cut, Held–Karp DP) solve modest instances optimally; heuristics and
approximation algorithms produce good tours for large $N$. Related problems
include the **vehicle routing problem (VRP)** and the travelling purchaser
problem.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational **survey**:
vertices indexed $1 .. N$, a complete digraph as a non-negative
`Cost_Matrix`, **exact** solvers (Held–Karp bitmask DP for
$N\le\mathrm{Max\_Held\_Karp\_Vertices}=16$, brute force for
$N\le 10$), and **in-package educational copies** of classical heuristics —
nearest neighbour (one start / best over all starts), optional **2-opt**,
and the MST **double-tree** $2$-approximation for metric instances.
Asymmetric matrices are allowed; metric demos default to symmetric Euclidean
tables. Caps raise `Invalid_Argument` on overflow. Full **Christofides**
($\tfrac{3}{2}$) lives in a sibling sheet — this package prefers the lighter
double-tree $2$-approx and documents Christofides as a sibling.

Primary source:
[Wikipedia — Travelling salesman problem](https://en.wikipedia.org/wiki/Travelling_salesman_problem).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with routing / TSP siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Travelling-Salesman-Problem`) | TSP survey: Held–Karp + brute exact, NN, 2-opt, double-tree $2$-approx |
| Nearest neighbour (sibling sheet) | Dedicated greedy NN package (same heuristic, deeper focus) |
| Christofides (sibling sheet) | Metric TSP $\tfrac{3}{2}$-approximation via MST + matching |
| Vehicle routing / CVRP (sibling sheet) | Multi-vehicle capacitated routes from a depot (generalises TSP) |

README links only — **no** package `with` of siblings. Heuristics here are
educational copies for a self-contained survey API (exact vs approximate).

## Problem statement

Input: a complete digraph on vertices $\{1,\ldots,N\}$ with costs
$c(u,v)\ge 0$. A **tour** is a cyclic permutation $\pi$ of the cities; its
cost is

$$
\sum_{i=1}^{N-1} c\bigl(\pi(i),\pi(i+1)\bigr) + c\bigl(\pi(N),\pi(1)\bigr).
$$

**Symmetric TSP:** $c(u,v)=c(v,u)$. **Asymmetric TSP:** directions may differ.
**Metric TSP:** $c$ is symmetric and obeys the triangle inequality
$c(u,w)\le c(u,v)+c(v,w)$. Exact TSP is NP-hard; even Euclidean planar TSP is
NP-hard.

### Edge cases ($N=1,2,3$)

- $N=1$: trivial tour $[1]$ with cost $c(1,1)$ (often $0$).
- $N=2$: unique directed cycle $1{-}2{-}1$ with cost $c(1,2)+c(2,1)$.
- $N=3$: $(3-1)! = 2$ directed cycles with fixed start; easy to enumerate.

Double-tree requires $N\ge 2$ (MST). Exact / NN / 2-opt accept $N\ge 1$.

## Exact algorithms

### Held–Karp bitmask DP — $O(n^{2} 2^{n})$

Fix start city $s=1$ (every directed cycle has a unique rotation with
$\pi(1)=1$). Let $S\subseteq\{1,\ldots,N\}$ with $1\in S$, and let
$\mathrm{dp}[S][j]$ be the minimum cost of a path that starts at $1$, visits
exactly the cities in $S$, and ends at $j\in S$:

$$
\mathrm{dp}[\{1\}][1]=0,\qquad
\mathrm{dp}[S][j]=\min_{i\in S\setminus\{j\}}
\bigl(\mathrm{dp}[S\setminus\{j\}][i]+c(i,j)\bigr).
$$

Then

$$
\mathrm{OPT}=\min_{j\neq 1}
\bigl(\mathrm{dp}[\{1,\ldots,N\}][j]+c(j,1)\bigr).
$$

Time and memory are $O(N^{2} 2^{N})$ and $O(N 2^{N})$. This sheet caps
$N\le 16$ for educational comfort. `Exact_Tour` is an alias of
`Held_Karp_Tour`.

### Brute force — $O((n-1)!\,n)$

Fix $\mathrm{Cities}(1)=1$ and permute $2 .. N$; keep the minimum closed-tour
cost. Restricted to $N\le 10$. Agrees with Held–Karp on every shared instance.

## Approximate / heuristic methods

### Nearest neighbour

From start $s$, repeatedly append the **nearest unvisited** city (ties:
smallest index), then return to $s$. `Best_Nearest_Neighbor` tries every
start. Fast ($O(N^{2})$ / $O(N^{3})$ for all starts) but **no** constant-factor
guarantee on general instances.

### 2-opt local search

`Improve_Two_Opt` repeatedly reverses a contiguous city segment when the
directed $2$-opt move decreases tour cost (best improvement per pass). No
approximation guarantee; often improves NN seeds.

### Double-tree $2$-approximation (metric)

1. Compute an MST $T$ of the undirected view $\min(c(u,v),c(v,u))$ (Prim).
2. Double every tree edge → Eulerian multigraph $H$.
3. Find an Euler tour of $H$ (Hierholzer).
4. Shortcut repeated vertices → Hamiltonian cycle (rotated to start at $1$).

Under the triangle inequality, shortcutting does not increase cost, and
$w(T)\le\mathrm{OPT}$, so the tour costs at most $2\cdot\mathrm{OPT}$. Full
**Christofides–Serdyukov** improves this to $\tfrac{3}{2}$ by matching odd MST
vertices instead of doubling all edges — see the Christofides sibling sheet.

### Exact vs approximate (intuition)

| Method | Role | Guarantee |
| --- | --- | --- |
| Held–Karp / brute | Exact OPT | Optimal (small $N$) |
| Nearest neighbour | Constructive heuristic | None (general) |
| 2-opt | Local search | None |
| Double-tree | Metric approximation | $\le 2\cdot\mathrm{OPT}$ |
| Christofides (sibling) | Metric approximation | $\le \tfrac{3}{2}\cdot\mathrm{OPT}$ |

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Held_Karp_Tour` / `Exact_Tour`) | $O(N^{2} 2^{N})$ for $N\le 16$ |
| Time (`Brute_Force_Tour`) | $O((N-1)!\,N)$ for $N\le 10$ |
| Time (`Nearest_Neighbor_From`) | $O(N^{2})$ |
| Time (`Best_Nearest_Neighbor`) | $O(N^{3})$ |
| Time (`Improve_Two_Opt`) | $O(N^{2})$ per improving pass |
| Time (`Double_Tree_Tour`) | $O(N^{2})$ Prim + Euler + shortcut |
| Matrix storage | $O(N^{2})$ up to $\mathrm{Max\_Vertices}=64$ |
| Held–Karp storage | $O(N 2^{N})$ (heap) |

## Features

- **`Cost_Matrix` / `Tour` / `Cost_Value`** — complete digraph + closed tour.
- **`Put_Distance` / `Put_Symmetric`** — fill entries with negativity checks.
- **`Held_Karp_Tour` / `Exact_Tour`** — optimal bitmask DP for $N\le 16$.
- **`Brute_Force_Tour`** — $(N-1)!$ oracle for $N\le 10$.
- **`Nearest_Neighbor_From` / `Best_Nearest_Neighbor`** — classical NN.
- **`Improve_Two_Opt`** — best-improvement $2$-opt local search.
- **`Double_Tree_Tour`** — metric MST double-tree $2$-approx.
- **`Closed_Tour_Cost` / `Tour_Cost` / `Is_Valid_Tour`** — helpers.
- **`Rounded_Euclidean` / `Undirected_Weight`** — metric builders / MST view.
- **Asymmetric OK** — exact and NN use directed entries; double-tree MST uses
  undirected weights.
- **Guards** — `Invalid_Argument` for bad dimensions, $N=0$, bad starts,
  negatives, exact / brute overflow, double-tree $N<2$.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Ptravelling_salesman_problem.gpr`.

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

=== 1. Caps and API constants ===
  PASS: ...
...
Results:  231 PASS, 0 FAIL
```

(Exact pass count is the current suite size; it is at least 180.)

## Testing

The test suite in `tests.adb` covers:

- $N=1,2,3$ hand-checked tours and costs
- Path-metric instances with known OPT $=2(N-1)$
- Euclidean metric clouds and the unit square
- Exact Held–Karp vs brute force agreement
- NN / Best NN / 2-opt / double-tree vs Exact on small $N$
- Asymmetric bait instances; Invalid_Argument guards
- Capacity smoke for heuristics at $N=20$; Held–Karp at $N=12$
- Tour validity, cost consistency, rotation of double-tree to start $1$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Travelling_Salesman_Problem is
   Max_Vertices             : constant Positive := 64;
   Max_Brute_Force_Vertices : constant Positive := 10;
   Max_Held_Karp_Vertices   : constant Positive := 16;

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

   function Closed_Tour_Cost
     (Distances : Cost_Matrix;
      Cities    : City_Seq;
      N         : Natural) return Cost_Value;
   function Is_Valid_Tour (T : Tour) return Boolean;
   function Tour_Cost
     (Distances : Cost_Matrix; T : Tour) return Cost_Value;

   function Brute_Force_Tour (Distances : Cost_Matrix) return Tour;
   function Held_Karp_Tour (Distances : Cost_Matrix) return Tour;
   function Exact_Tour (Distances : Cost_Matrix) return Tour;

   function Nearest_Neighbor_From
     (Distances : Cost_Matrix; Start : Vertex_Id) return Tour;
   function Best_Nearest_Neighbor (Distances : Cost_Matrix) return Tour;
   function Improve_Two_Opt
     (Distances : Cost_Matrix; Seed : Tour) return Tour;
   function Double_Tree_Tour (Distances : Cost_Matrix) return Tour;
end Travelling_Salesman_Problem;
```

Raises `Invalid_Argument` when the matrix is not square and 1-based, when
$N=0$ on tour APIs (or $N<2$ for double-tree), when `Start` or indices lie
outside $1 .. N$, when a written distance is negative, when
`Brute_Force_Tour` is called with $N>10$, when `Held_Karp_Tour` /
`Exact_Tour` is called with $N>16$, or when `Tour_Cost` /
`Closed_Tour_Cost` / `Improve_Two_Opt` see a size mismatch or invalid seed.

Tour convention: `Cities(1 .. N)` is a permutation of $1 .. N$; `Cost` is
the sum of the $N$ edges of the cycle including the return edge
$\mathrm{Cities}(N)\to\mathrm{Cities}(1)$.

## License

Educational reference implementation. See repository `LICENSE` if present.
