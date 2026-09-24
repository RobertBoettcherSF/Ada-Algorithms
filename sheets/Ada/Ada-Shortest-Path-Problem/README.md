# Shortest Path Problem in Ada 2023

## Project Overview

The **shortest path problem** asks for a path between two vertices in an
edge-weighted graph whose **total weight is minimized**. Road maps,
routing protocols, puzzle state graphs, and many operations-research
models reduce to this question (or to its single-source / all-pairs
variants).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
**survey**: one shared directed-graph API with signed weights, plus
self-contained re-implementations of the classical methods (do **not**
`with` the sibling packages):

| Method | Applies when | Role |
| --- | --- | --- |
| **BFS_Shortest** | unit / unweighted (every edge length $1$) | hop-count SSSP, $O(V+E)$ |
| **Dijkstra** (dense) | all weights $\ge 0$ | weighted SSSP, $O(V^{2}+E)$ |
| **Bellman_Ford** | weights may be negative | SSSP + negative-cycle status, $O(VE)$ |
| **Floyd_Warshall** | dense APSP; negatives OK | all-pairs DP, $O(V^{3})$ |

Vertices are indexed from $1$. Storage uses fixed educational arrays up
to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$ (no dynamic heap).
A shared `Infinity` sentinel marks unreachable vertices; `Prev` trees /
matrices support `Reconstruct_Path`.

Primary source:
[Wikipedia — Shortest path problem](https://en.wikipedia.org/wiki/Shortest_path_problem).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Shortest-Path-Problem`) | Survey: BFS + Dijkstra + Bellman–Ford + Floyd–Warshall |
| Dijkstra (sibling sheet) | Dedicated non-negative dense SSSP |
| Bellman–Ford (sibling sheet) | Dedicated SSSP with negatives + affected-set helpers |
| Floyd–Warshall (sibling sheet) | Dedicated dense APSP with Next/Prev matrices |
| Johnson (sibling sheet) | Sparse-leaning APSP: BF potentials + $V$ Dijkstras |

README links only — **no** package `with` of siblings. Johnson is
omitted from this survey body to keep the sheet focused; see the sibling
for the potentials + Dijkstra pipeline.

## When to use which method

$$
\begin{align*}
\text{unweighted / unit} &\Rightarrow \textbf{BFS} \\
\text{non-negative weights, one source} &\Rightarrow \textbf{Dijkstra} \\
\text{negative weights, one source} &\Rightarrow \textbf{Bellman–Ford} \\
\text{all pairs, dense} &\Rightarrow \textbf{Floyd–Warshall} \\
\text{all pairs, sparse, no neg.\ cycles} &\Rightarrow \textbf{Johnson (sibling)}
\end{align*}
$$

`Has_Negative_Edge` helps choose between Dijkstra and Bellman–Ford /
Floyd–Warshall. Dijkstra **raises** `Invalid_Argument` if any stored
edge weight is negative.

## Algorithm sketches

### BFS (unit length)

Treat every edge as cost $1$. A FIFO queue expands vertices in order of
increasing hop distance; the first time a vertex is reached, that hop
count is final.

### Dense Dijkstra (non-negative)

$$
\mathrm{dist}(s)\leftarrow 0,\quad
\mathrm{dist}(v)\leftarrow\infty\ (v\neq s)
$$

Repeatedly settle the unsettled vertex $u$ of minimum tentative
distance and relax its outgoing edges. Correct when $c(u,w)\ge 0$.

### Bellman–Ford

Relax every edge $|V|-1$ times; one extra pass detects a negative-weight
cycle reachable from the source:

$$
\mathrm{dist}(v)\leftarrow\min\bigl(\mathrm{dist}(v),\,
\mathrm{dist}(u)+w(u,v)\bigr)
$$

### Floyd–Warshall (APSP)

$$
d_{ij}^{(k)}=\min\bigl(d_{ij}^{(k-1)},\,
d_{ik}^{(k-1)}+d_{kj}^{(k-1)}\bigr)
$$

with $d_{ij}^{(0)}$ the direct-edge estimate. A negative diagonal entry
$d_{vv}<0$ signals a negative cycle. Correct nest order is **K–I–J**.

### Example

Vertices $\{1,2,3,4\}$ with edges
$1\xrightarrow{1}2$, $1\xrightarrow{4}3$, $2\xrightarrow{1}3$,
$2\xrightarrow{5}4$, $3\xrightarrow{1}4$:

- $\mathrm{dist}(1)=0$, $\mathrm{dist}(2)=1$, $\mathrm{dist}(3)=2$,
  $\mathrm{dist}(4)=3$
- Shortest $1\to 4$ path $(1,2,3,4)$ (Dijkstra / Bellman–Ford /
  Floyd–Warshall agree on non-negative instances)
- BFS hop-count $1\to 4$ is $2$ via $1\to 2\to 4$ (ignores weights)

## Complexity

| Measure | Bound |
| ------- | ----- |
| BFS | $O(V+E)$ |
| Dense Dijkstra | $O(V^{2}+E)$ |
| Bellman–Ford | $O(VE)$ |
| Floyd–Warshall | $O(V^{3})$ time, $O(V^{2})$ Dist matrix |
| Graph storage | $O(\|V\|+\|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Weights | Integers in `Weight_Type` (may be signed) |
| Unreachable | $\mathrm{dist}=\mathrm{Infinity}$ |

## Features

- **`Clear` / `Add_Edge`** — shared weighted digraph on vertices $1 .. N$
  (signed weights).
- **`Vertex_Count` / `Edge_Count` / `Has_Negative_Edge`** — size and
  weight-class queries.
- **`BFS_Shortest` / `Distance_BFS`** — unit / unweighted SSSP.
- **`Dijkstra` / `Distance_Dijkstra`** — dense non-negative SSSP.
- **`Bellman_Ford` / `Distance_Bellman_Ford` / `Has_Negative_Cycle`** —
  SSSP with negatives and cycle status (raising overload available).
- **`Floyd_Warshall` / `Distance_Floyd_Warshall` /
  `Has_Negative_Cycle_APSP`** — dense APSP with optional `Prev` matrix.
- **`Reconstruct_Path`** — recover Source→Target walks from `Prev_Array`
  or APSP `Prev_Matrix`.
- **`Infinity` / `Run_Status` / `Invalid_Argument` /
  `Negative_Cycle_Error`** — unified sentinels and guards.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pshortest_path_problem.gpr`.

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

=== 1. Empty / Clear / counters ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 180.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph / Clear / capacity guards
- Single vertex; zero and negative self-loops
- Two-vertex arcs; unreachable `Infinity`
- Unit graphs: BFS ≡ Dijkstra ≡ Bellman–Ford
- Classic non-negative diamonds: Dijkstra ≡ Bellman–Ford
- Floyd–Warshall vs repeated Dijkstra on non-negative instances
- Negative edges without a cycle; reachable negative cycles
- Cycle not reachable from the chosen source
- Parallel edges; zero weights; positive cycles
- Path reconstruction (trivial and multi-hop; APSP Prev)
- Chains, stars, grids, small complete digraphs
- BFS hop-count vs weighted shortcuts
- `Invalid_Argument` for bounds, weight range, Dijkstra-on-negatives
- `Max_Vertices` smoke; Distance_* agreement; taxonomy checks

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Shortest_Path_Problem is
   Max_Vertices : constant Positive := 256;
   Max_Edges    : constant Positive := 50_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range -(2**30) .. 2**30 - 1;
   type Distance_Value is range -(2**62) .. 2**62 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;
   type Dist_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Distance_Value;
   type Prev_Array is array (Vertex_Id range <>) of Natural;
   type Prev_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;

   type Run_Status is (Success, Negative_Cycle);
   type Graph is limited private;

   Invalid_Argument     : exception;
   Negative_Cycle_Error : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;
   function Has_Negative_Edge (G : Graph) return Boolean;

   procedure BFS_Shortest
     (G : Graph; Source : Vertex_Id;
      Dist : out Distance_Array; Prev : out Prev_Array);
   function Distance_BFS
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value;

   procedure Dijkstra
     (G : Graph; Source : Vertex_Id;
      Dist : out Distance_Array; Prev : out Prev_Array);
   function Distance_Dijkstra
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value;

   procedure Bellman_Ford
     (G : Graph; Source : Vertex_Id;
      Dist : out Distance_Array; Prev : out Prev_Array;
      Status : out Run_Status);
   procedure Bellman_Ford
     (G : Graph; Source : Vertex_Id;
      Dist : out Distance_Array; Prev : out Prev_Array);
   function Has_Negative_Cycle
     (G : Graph; Source : Vertex_Id) return Boolean;
   function Distance_Bellman_Ford
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value;

   procedure Floyd_Warshall
     (G : Graph; Dist : out Dist_Matrix; Status : out Run_Status);
   procedure Floyd_Warshall
     (G : Graph; Dist : out Dist_Matrix; Prev : out Prev_Matrix;
      Status : out Run_Status);
   procedure Floyd_Warshall
     (G : Graph; Dist : out Dist_Matrix; Prev : out Prev_Matrix);
   function Has_Negative_Cycle_APSP (G : Graph) return Boolean;
   function Distance_Floyd_Warshall
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value;

   function Reconstruct_Path
     (Prev : Prev_Array; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural) return Boolean;
   function Reconstruct_Path
     (Prev : Prev_Matrix; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural) return Boolean;
end Shortest_Path_Problem;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Weight` outside `Weight_Type`, $N=0$ on search APIs,
insufficient `Dist`/`Prev`/`Path` bounds, or Dijkstra when a negative
edge is present.

On a negative-weight cycle, Bellman–Ford / Floyd–Warshall status
overloads return `Negative_Cycle`; raising overloads and the
corresponding `Distance_*` helpers raise `Negative_Cycle_Error`.

Path convention: on success `Path(1) = Source`, `Path(Length) = Target`,
and `Length` is the number of vertices (arc count $= Length - 1$).
`Prev(Source) = 0`; unreachable targets leave `Dist = Infinity`.

## License

Educational reference implementation. See repository `LICENSE` if present.
