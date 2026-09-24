# Bellman–Ford Algorithm in Ada 2023

## Project Overview

The **Bellman–Ford algorithm** computes **single-source shortest paths** in a
**directed graph that may contain negative edge weights**. From a chosen
source it produces, for every vertex, the minimum total weight of a path
from the source (or reports that the vertex is unreachable). Unlike
Dijkstra's algorithm, it does **not** require non-negative weights. A
final extra pass detects a **negative-weight cycle** reachable from the
source — distances of vertices affected by such a cycle are undefined in
the extended reals ($-\infty$).

Richard Bellman and Lester Ford, Jr. (among others) developed the method
in the late 1950s; it remains a standard building block for routing
ideas, **arbitrage detection**, **difference-constraint** systems, and as
the potential-finding step inside **Johnson's** all-pairs algorithm.

The classic formulation **relaxes every edge** $|V|-1$ times. A simple
shortest path has at most $|V|-1$ edges, so after that many rounds every
finite shortest-path distance is final. One more full pass asks whether
any edge can still improve a distance; if so, a negative cycle is
reachable from the source. Time is $O(VE)$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, weighted adjacency lists in
fixed arrays (no dynamic heap beyond stack-sized workspaces), an
`Infinity` sentinel for unreachable nodes, path reconstruction via a
predecessor tree, `Run_Status` / `Negative_Cycle_Error` for cycle
reporting, and optional marking of vertices **affected** by a negative
cycle.

Primary source:
[Wikipedia — Bellman–Ford algorithm](https://en.wikipedia.org/wiki/Bellman%E2%80%93Ford_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Bellman-Ford-Algorithm`) | Weighted SSSP with negatives; $O(VE)$; cycle detection |
| Dijkstra (sibling sheet) | Non-negative weighted SSSP; dense $O(V^{2})$ selection |
| Floyd–Warshall (sibling sheet) | Dense APSP $O(V^{3})$ DP; negatives OK; diagonal cycle probe |
| Johnson (sibling sheet) | Sparse-leaning APSP: one Bellman–Ford (potentials) + $V$ Dijkstras |

README links only — **no** package `with` of siblings.

When is Bellman–Ford preferable? Whenever **negative weights** matter and
you need **one source** (or a few). For non-negative weights, **Dijkstra**
is asymptotically and practically faster. For **all-pairs** on dense
graphs, **Floyd–Warshall** is simpler; on sparse graphs without negative
cycles, **Johnson** reuses Bellman–Ford once for potentials then runs
Dijkstra from every vertex.

## Algorithm

### Initialisation

Given digraph $G=(V,E)$ with weight $w$ and source $s$:

$$
\mathrm{dist}(v)\leftarrow\infty,\qquad
\mathrm{prev}(v)\leftarrow\text{undefined},\qquad
\mathrm{dist}(s)\leftarrow 0
$$

### Relaxation rounds

For $i=1 .. |V|-1$, for each edge $(u,v)\in E$:

$$
\mathrm{dist}(v)\leftarrow\min\bigl(\mathrm{dist}(v),\,
\mathrm{dist}(u)+w(u,v)\bigr)
$$

(only when $\mathrm{dist}(u)$ is finite), updating $\mathrm{prev}(v)$ on
improvement. Early exit when a round makes no changes is optional.

### Negative-cycle check ($|V|$-th pass)

If any edge can still improve a finite $\mathrm{dist}(u)$, report
**Negative_Cycle**. Vertices whose distance can improve on this pass, and
all vertices reachable from them, have undefined ($-\infty$) distance;
`Affected_By_Negative_Cycle` marks exactly that set.

### Path reconstruction

Walk $\mathrm{prev}$ from a target $t$ back to $s$ and reverse the walk.
If the chain never reaches $s$, $t$ is unreachable (or the tree is
inconsistent after a cycle report).

### Example

Vertices $\{1,2,3,4\}$ with edges
$1\xrightarrow{4}2$, $1\xrightarrow{5}3$, $2\xrightarrow{-3}3$,
$3\xrightarrow{2}4$:

- $\mathrm{dist}(1)=0$, $\mathrm{dist}(2)=4$, $\mathrm{dist}(3)=1$,
  $\mathrm{dist}(4)=3$
- Shortest $1\to 4$ path is $(1,2,3,4)$ with total weight $3$

With an extra edge $3\xrightarrow{-2}2$, the $2\leftrightarrow 3$ pair
forms a negative cycle reachable from $1$; status becomes
`Negative_Cycle`.

### Asymptotic cost

$$
O(VE)\quad\text{time},\qquad O(V)\quad\text{auxiliary space for Dist/Prev}
$$

Graph storage is $O(V+E)$ in fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (classic Bellman–Ford) | $O(VE)$ |
| Auxiliary space (search) | $O(V)$ for `Dist` / `Prev` / flags |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Weights | Integers in `Weight_Type` (may be negative) |
| Unreachable | $\mathrm{dist}(v)=\mathrm{Infinity}$ |
| Negative cycle | Extra pass improvement → `Negative_Cycle` / `Negative_Cycle_Error` |

## Features

- **`Clear` / `Add_Edge`** — build a weighted digraph on vertices $1 .. N$
  (weights may be negative).
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Shortest_Paths`** — full source tree: `Dist` + `Prev` + `Run_Status`
  (raising overload available).
- **`Has_Negative_Cycle`** — Boolean probe from a given source.
- **`Affected_By_Negative_Cycle`** — mark vertices on / reachable from a
  negative cycle reachable from the source.
- **`Distance`** — single Source→Target distance (or `Infinity`).
- **`Reconstruct_Path`** — recover a Source→Target vertex sequence from `Prev`.
- **`Infinity`** — sentinel distance for unreachable vertices.
- **Capacity / weight guards** — `Invalid_Argument` for bad ids, overflow,
  weight range, or insufficient `Dist` / `Prev` / `Path` / `Flag` bounds.
- **Educational layout** — 1-based indices; classic $|V|-1$ relaxations;
  fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbellman_ford_algorithm.gpr`.

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

=== 1. Empty / single / self ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph guards; single vertex; positive / zero / negative self-loops
- Two-vertex arcs; unreachable `Infinity`; disconnected components
- Negative edges without a cycle; classic reachable negative cycles
- Cycle not reachable from the chosen source
- Dijkstra-compatible non-negative diamonds and layered DAGs
- Parallel edges; zero-weight and positive cycles (not reported as negative)
- Path reconstruction and trivial one-vertex paths
- `Affected_By_Negative_Cycle` seeding and propagation
- Currency-style arbitrage triangles; Wikipedia-style worked example
- Status vs raising overloads; Distance vs `Shortest_Paths` agreement
- Larger sparse chains; `Max_Vertices` smoke; edge-capacity parallels
- `Invalid_Argument` for capacity, range, weight bounds, array bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Bellman_Ford_Algorithm is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range -(2**30) .. 2**30 - 1;
   type Distance_Value is range -(2**62) .. 2**62 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;
   type Prev_Array is array (Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;
   type Flag_Array is array (Vertex_Id range <>) of Boolean;

   type Run_Status is (Success, Negative_Cycle);
   type Graph is limited private;

   Invalid_Argument     : exception;
   Negative_Cycle_Error : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status);

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array);
   --  raises Negative_Cycle_Error

   function Has_Negative_Cycle
     (G : Graph; Source : Vertex_Id) return Boolean;

   procedure Affected_By_Negative_Cycle
     (G        : Graph;
      Source   : Vertex_Id;
      Affected : out Flag_Array;
      Found    : out Boolean);

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value;

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean;
end Bellman_Ford_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Weight` outside `Weight_Type`, $N=0$ on search APIs, or
`Dist`/`Prev`/`Path`/`Flag` with `First /= 1` or `Last < N`.

On a negative-weight cycle reachable from the source, status overloads
return `Negative_Cycle`; raising overloads and `Distance` raise
`Negative_Cycle_Error`.

Path convention: on success `Path(1) = Source`, `Path(Length) = Target`,
and `Length` is the number of vertices (arc count $= Length - 1$).
`Prev(Source) = 0`; unreachable targets leave `Dist = Infinity`.

## License

Educational reference implementation. See repository `LICENSE` if present.
