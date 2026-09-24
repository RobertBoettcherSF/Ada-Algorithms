# Nearest Neighbour Algorithm in Ada 2023

## Project Overview

The **nearest neighbour algorithm** is a classical **constructive heuristic**
for the **travelling salesman problem (TSP)**. A salesman must visit each
city in a finite set exactly once and return to the start; the goal is a
tour of minimum total distance. Exact TSP is NP-hard. Nearest neighbour
gives a fast approximate tour: start at a chosen city, then repeatedly
walk to the **nearest unvisited** city, and finally return to the start.

The method was among the first practical TSP heuristics. It is easy to
implement and usually produces a short tour quickly, but it is **greedy**:
early cheap choices can force expensive finishing edges, so the result is
**not always optimal**. On arbitrary distance tables there is **no**
constant-factor approximation guarantee — for every ratio $r$ there exists
an instance where the nearest-neighbour tour is longer than $r$ times the
optimum. Running the heuristic from every start and keeping the best tour
improves practice (and dominates at least $N/2-1$ other tours in a
combinatorial sense) but still does not restore a fixed guarantee.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed $1 .. N$, a complete digraph given as a
non-negative `Cost_Matrix`, `Tour_From` / `Best_Tour`, an exact brute-force
oracle for $N\le 10$, asymmetric matrices allowed (default tests are
symmetric), and `Invalid_Argument` for bad shapes / negative distances /
$N=0$ / exact overflow.

Primary source:
[Wikipedia — Nearest neighbour algorithm](https://en.wikipedia.org/wiki/Nearest_neighbour_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with routing / TSP siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Nearest-Neighbor-Algorithm`) | Greedy TSP tour from a cost matrix; all-starts + tiny exact oracle |
| Christofides (sibling sheet) | Metric TSP $\tfrac{3}{2}$-approximation via MST + matching |
| Vehicle routing / CVRP (sibling sheet) | Multi-vehicle capacitated routes from a depot (generalises TSP) |
| Ant colony / ACO (sibling sheet) | Population metaheuristic for TSP tours |
| Dijkstra (sibling sheet) | Non-negative weighted SSSP — build $c_{ij}$ from a road graph |

README links only — **no** package `with` of siblings.

## Algorithm

### Nearest neighbour (constructive)

Input: a complete digraph on vertices $\{1,\ldots,N\}$ with costs
$c(u,v)\ge 0$, and a start $s$.

1. Mark every vertex unvisited.
2. Set the current vertex $u\leftarrow s$; mark $s$ visited; append $s$ to
   the tour.
3. While unvisited vertices remain: choose an unvisited $v$ minimising
   $c(u,v)$ (ties: **smallest vertex index**); append $v$; mark $v$
   visited; set $u\leftarrow v$.
4. Close the tour by returning to $s$. The tour cost is the sum of the
   $N$ edge weights along the cycle.

The sequence of visited vertices is the output. Asymmetry is allowed:
$c(u,v)$ need not equal $c(v,u)$. Diagonal entries are ignored except for
the trivial $N=1$ tour, whose cost is $c(1,1)$.

### Best over all starts

$$
\mathrm{Best}(c)=\arg\min_{s\in\{1,\ldots,N\}}
\mathrm{cost}\bigl(\mathrm{NN}(c,s)\bigr)
$$

(ties: smaller $s$). This is still a heuristic, but it removes dependence
on a single unlucky seed.

### Exact oracle ($N\le 10$)

Enumerate all directed Hamiltonian cycles by fixing the first city to $1$
and permuting the rest — $(N-1)!$ candidates — and keep the minimum closed
tour cost. Used in tests as a ground-truth optimum so learners can see
when NN agrees or disagrees with OPT.

### Example (path of three)

Symmetric costs $c_{12}=c_{23}=1$, $c_{13}=100$. Nearest neighbour from $1$
builds $1{-}2{-}3$ with cost $1+1+100=102$, which is optimal on this
instance. An asymmetric bait can make NN from $1$ worse than OPT while
`Best_Tour` (or another start) recovers the optimum — see the test suite.

### Approximation nature

Unlike **Christofides’ algorithm** on **metric** TSP (triangle inequality),
classical nearest neighbour has **no** fixed worst-case ratio on general
instances. A practical sanity check from the literature: if the last few
edges of the NN tour are much longer than the first few, a better tour
likely exists. Prefer metric methods (Christofides, LKH, Concorde, …) when
optimality gap matters; use NN for teaching, warm starts, or huge $N$
where a linear scan per step is acceptable.

### Asymptotic cost

With a dense $N\times N$ matrix and a scan for the nearest unvisited city
at each step:

$$
O(N^{2})
$$

time and $O(N^{2})$ storage for the matrix (capped at
$\mathrm{Max\_Vertices}=128$). Exact enumeration is $O((N-1)!\,N)$ and
restricted to $N\le 10$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Tour_From`) | $O(N^{2})$ |
| Time (`Best_Tour`) | $O(N^{3})$ ($N$ starts) |
| Time (`Exact_Tour`) | $O((N-1)!\,N)$ for $N\le 10$ |
| Matrix storage | $O(N^{2})$ up to $\mathrm{Max\_Vertices}$ |
| Vertex indices | $1 .. N$ with $N \le 128$ |
| Costs | Non-negative integers; negatives raise `Invalid_Argument` |
| Exact cap | $\mathrm{Max\_Exact\_Vertices}=10$ |

## Features

- **`Cost_Matrix` / `Tour` / `Cost_Value`** — complete digraph + closed tour.
- **`Put_Distance` / `Put_Symmetric`** — fill entries with negativity checks.
- **`Tour_From`** — classical NN from a chosen start (index tie-break).
- **`Best_Tour`** — try every start; keep the cheapest tour.
- **`Exact_Tour`** — brute-force optimal directed tour for $N\le 10$.
- **`Closed_Tour_Cost` / `Tour_Cost` / `Is_Valid_Tour`** — cost and
  permutation helpers.
- **`Rounded_Euclidean`** — build metric demos from integer coordinates.
- **Asymmetric OK** — matrix need not be symmetric; demos default to
  symmetric metric tables.
- **Guards** — `Invalid_Argument` for bad dimensions, $N=0$, bad starts,
  negatives, exact overflow.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pnearest_neighbor_algorithm.gpr`.

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

=== 1. N=1 trivial tour ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- $N=1,2,3$ hand-checked tours and costs
- Lines of cities (metric) with known optima
- Metric vs non-metric matrices; asymmetric bait instances
- `Best_Tour` vs every start; agreement with `Exact_Tour` on tiny $N$
- Disagreement cases where a single NN start is worse than Exact /
  Best
- `Invalid_Argument` for shape, negatives, bad starts, $N>10$ exact,
  cost mismatches
- Tie-breaking to the smallest vertex index
- Capacity smoke at $N=\mathrm{Max\_Vertices}$
- `Rounded_Euclidean`, `Is_Valid_Tour`, API counters

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Nearest_Neighbor_Algorithm is
   Max_Vertices       : constant Positive := 128;
   Max_Exact_Vertices : constant Positive := 10;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Cost_Value is range 0 .. 2**63 - 1;
   type Cost_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Cost;
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
     (Distances : Cost_Matrix; From, To : Vertex_Id) return Cost;
   function Rounded_Euclidean
     (X1, Y1, X2, Y2 : Integer) return Cost;

   function Closed_Tour_Cost
     (Distances : Cost_Matrix;
      Cities    : City_Seq;
      N         : Natural) return Cost;
   function Is_Valid_Tour (T : Tour) return Boolean;
   function Tour_Cost
     (Distances : Cost_Matrix; T : Tour) return Cost;

   function Tour_From
     (Distances : Cost_Matrix; Start : Vertex_Id) return Tour;
   function Best_Tour (Distances : Cost_Matrix) return Tour;
   function Exact_Tour (Distances : Cost_Matrix) return Tour;
end Nearest_Neighbor_Algorithm;
```

Raises `Invalid_Argument` when the matrix is not square and 1-based, when
$N=0$ on tour APIs, when `Start` or indices lie outside $1 .. N$, when a
written distance is negative, when `Exact_Tour` is called with
$N>10$, or when `Tour_Cost` / `Closed_Tour_Cost` see a size mismatch.

Tour convention: `Cities(1 .. N)` is a permutation of $1 .. N$; `Cost` is
the sum of the $N$ edges of the cycle including the return edge
$\mathrm{Cities}(N)\to\mathrm{Cities}(1)$.

## License

Educational reference implementation. See repository `LICENSE` if present.
