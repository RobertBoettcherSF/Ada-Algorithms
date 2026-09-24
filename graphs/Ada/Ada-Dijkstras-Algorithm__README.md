# Dijkstra's Algorithm in Ada 2023

## Project Overview

**Dijkstra's algorithm** computes **single-source shortest paths** in a
**directed graph with non-negative edge weights**. From a chosen source it
produces, for every vertex, the minimum total weight of a path from the
source (or reports that the vertex is unreachable). Edsger W. Dijkstra
designed the method in 1956 and published it in 1959; it remains a
standard building block for routing (e.g. OSPF, IS-IS), map navigation,
and as a subroutine inside algorithms such as Johnson's all-pairs method.

The classic formulation repeatedly **settles** the unsettled vertex whose
tentative distance is smallest, then **relaxes** its outgoing edges. With
non-negative weights, a settled distance is final. This package uses the
original **dense** selection — scan all unsettled vertices for the
minimum — giving $O(V^{2}+E)$ time. Heap-based variants achieve
$O((V+E)\log V)$ (binary heap) or $O(E+V\log V)$ (Fibonacci heap); the
dense scan matches Dijkstra's 1959 presentation and keeps the educational
code free of priority-queue machinery.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, weighted adjacency lists in
fixed arrays (no dynamic heap beyond stack-sized workspaces), an
`Infinity` sentinel for unreachable nodes, path reconstruction via a
predecessor tree, and rejection of negative edge weights.

Primary source:
[Wikipedia — Dijkstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Dijkstras-Algorithm`) | Non-negative weighted SSSP; dense $O(V^{2})$ Dijkstra |
| Iterative Deepening DFS (sibling sheet) | Unweighted shallowest path; DFS space + BFS optimality |
| Tarjan SCC (sibling sheet) | One-pass DFS + stack + low-link components |

README links only — **no** package `with` of siblings.

## Algorithm

### Dense Dijkstra

Given a digraph $G=(V,E)$ with $c(u,w)\ge 0$ and source $s$:

1. Set $\mathrm{dist}(v)\leftarrow\infty$ and $\mathrm{prev}(v)\leftarrow$ undefined for all $v$; set $\mathrm{dist}(s)\leftarrow 0$.
2. Let $S$ be the set of unsettled vertices (initially all of $V$).
3. While $S$ is nonempty:
   - Choose $u\in S$ with minimum $\mathrm{dist}(u)$; remove $u$ from $S$.
   - If $\mathrm{dist}(u)=\infty$, stop (remaining vertices are unreachable).
   - For each edge $u\to w$ with weight $c$: let
     $\mathrm{alt}=\mathrm{dist}(u)+c$; if $\mathrm{alt}<\mathrm{dist}(w)$ then
     update $\mathrm{dist}(w)$ and set $\mathrm{prev}(w)\leftarrow u$.

When $u$ is settled, $\mathrm{dist}(u)$ is the true shortest-path distance
from $s$. Negative weights are forbidden: they can invalidate the
settling argument (use Bellman–Ford instead).

### Path reconstruction

Walk $\mathrm{prev}$ from a target $t$ back to $s$ and reverse the walk.
If the chain never reaches $s$, $t$ is unreachable.

### Example

Vertices $\{1,2,3,4\}$ with edges
$1\xrightarrow{1}2$, $1\xrightarrow{4}3$, $2\xrightarrow{1}3$,
$2\xrightarrow{5}4$, $3\xrightarrow{1}4$:

- $\mathrm{dist}(1)=0$, $\mathrm{dist}(2)=1$, $\mathrm{dist}(3)=2$, $\mathrm{dist}(4)=3$
- One shortest $1\to 4$ path is $(1,2,3,4)$ with total weight $3$
  (not the direct $1\to 2\to 4$ of weight $6$).

### Asymptotic cost

With array scan for the unsettled minimum:

$$
O(V^{2} + E)
$$

Graph storage is $O(V+E)$ in fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (dense Dijkstra) | $O(V^{2} + E)$ |
| Time (binary-heap variant, not used here) | $O((V+E)\log V)$ |
| Auxiliary space (search) | $O(V)$ settled / scratch |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Weights | Non-negative integers; negatives raise `Invalid_Argument` |
| Unreachable | $\mathrm{dist}(v)=\mathrm{Infinity}$ |

## Features

- **`Clear` / `Add_Edge`** — build a weighted digraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Shortest_Paths`** — full source tree: `Dist` + `Prev`.
- **`Distance`** — single Source→Target distance (or `Infinity`).
- **`Reconstruct_Path`** — recover a Source→Target vertex sequence from `Prev`.
- **`Infinity`** — sentinel distance for unreachable vertices.
- **Capacity / weight guards** — `Invalid_Argument` for bad ids, overflow,
  negative weights, or insufficient `Dist` / `Prev` / `Path` bounds.
- **Educational layout** — 1-based indices; dense $O(V^{2})$ selection;
  fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pdijkstras_algorithm.gpr`.

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

(Exact `NN` is the current suite size; it is at least 120.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph guards; single vertex; Source = Target
- Two-vertex arcs, reverse arcs, zero-weight edges
- Directed chains and diamonds with known distances
- Shortcuts vs longer detours; parallel edges (min via relaxation)
- Unreachable vertices (`Infinity`); disconnected components
- Self-loops; clear/rebuild; API counters
- Path reconstruction and trivial one-vertex paths
- Larger grids / stars / random-ish handcrafted digraphs
- `Invalid_Argument` for capacity, range, negative weights, array bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Dijkstras_Algorithm is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range 0 .. 2**31 - 1;
   type Distance_Value is range 0 .. 2**63 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;
   type Prev_Array is array (Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array);

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value;

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean;
end Dijkstras_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, negative `Weight`, $N=0$ on search APIs, or
`Dist`/`Prev`/`Path` with `First /= 1` or `Last < N`.

Path convention: on success `Path(1) = Source`, `Path(Length) = Target`,
and `Length` is the number of vertices (arc count $= Length - 1$).
`Prev(Source) = 0`; unreachable targets leave `Dist = Infinity`.

## License

Educational reference implementation. See repository `LICENSE` if present.
