# Bidirectional Search in Ada 2023

## Project Overview

**Bidirectional search** runs two simultaneous searches: one **forward** from
the start vertex and one **backward** from the goal, aiming to **meet in the
middle**. For unweighted graphs the natural engine on each side is
breadth-first search (BFS). Because each frontier only needs to grow about
halfway to the goal, the number of expansions is often far smaller than a
one-sided BFS of the same depth.

Intuitively, if the effective branching factor is $b$ and the shortest-path
depth is $d$, one-sided BFS expands on the order of $O(b^{d})$ vertices,
while balanced bidirectional BFS expands on the order of

$$
O(b^{d/2})
$$

on each side (roughly $O(b^{d/2})$ total when the two cones meet). The
asymptotic worst case on arbitrary digraphs remains $O(|V|+|E|)$; the
$O(b^{d/2})$ figure is the classic AI / puzzle-search intuition that
motivates the algorithm.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation on **directed unweighted** graphs: vertices indexed from
$1$, dual adjacency lists (forward out-edges plus automatically recorded
**reverse** edges for the backward frontier) in fixed educational arrays,
unit-cost `Shortest_Path` via meeting-in-the-middle bidirectional BFS,
`Distance` / `Reachable` queries, and a unidirectional `BFS_Distance`
oracle so tests can prove agreement with ordinary BFS. Undirected graphs
are modelled by inserting both directed edges.

Primary source:
[Wikipedia — Bidirectional search](https://en.wikipedia.org/wiki/Bidirectional_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| Breadth-first search (sibling sheet) | One-sided BFS: level order, unit-cost shortest paths |
| **This package** (`Ada-Bidirectional-Search`) | Two BFS frontiers meeting in the middle |
| Depth-first search (sibling sheet) | DFS: discovery order, forest, timestamps |
| Iterative deepening DFS (sibling sheet) | IDDFS: DFS space + BFS shallowest-goal optimality |
| Dijkstra (sibling sheet) | Non-negative weighted single-source shortest paths |

README links only — **no** package `with` of siblings.

## Algorithm

### Dual-frontier view (Wikipedia)

```text
procedure Bidirectional_BFS(G, start, goal) is
    F ← queue; B ← queue
    mark start explored_forward; F.enqueue(start)
    mark goal  explored_backward; B.enqueue(goal)
    best ← ∞; meet ← none
    while F ≠ ∅ or B ≠ ∅ do
        expand the smaller frontier one vertex:
          for each unused adjacent edge (forward out / reverse in) do
            if neighbour not explored on this side then
                set parent/distance; enqueue
            if neighbour explored on the other side then
                candidate ← Dist_F + Dist_B
                if candidate < best then best ← candidate; meet ← neighbour
    reconstruct start → … → meet → … → goal
```

### Implementation notes (this package)

1. `Add_Edge(From, To)` stores `From → To` in the **forward** adjacency list
   and `To ← From` in the **reverse** list used by the backward frontier.
2. Mark `Start` / `Goal` explored on their respective sides with distance
   $0$; enqueue both.
3. While either queue is nonempty, expand **one** vertex from the **smaller**
   frontier (balanced bidirectional BFS).
4. Whenever a vertex is known to both sides, keep the minimum
   $\mathrm{Dist}_F(v)+\mathrm{Dist}_B(v)$ meeting vertex.
5. Reconstruct by walking `Prev_F` from the meet back to `Start` (then
   reverse) and `Prev_B` from the meet forward to `Goal`.

Vertices are marked **before enqueue** on each side, so each vertex enters
each frontier at most once. Distances match unidirectional BFS on every
reachable pair (`BFS_Distance` oracle).

### Outputs

- **`Shortest_Path`** — bidirectional BFS path `Start … Goal` (or failure).
- **`Distance`** — fewest arcs `Start→Goal`, or `Infinity`.
- **`BFS_Distance`** — one-sided forward BFS distance (test oracle).
- **`Reachable`** — membership of `Goal` in the reachable set of `Start`
  (equivalent to $\mathrm{Distance}\neq\mathrm{Infinity}$).

### Example

Digraph on $\{1,2,3,4,5\}$ with chain $1\to 2\to 3\to 4\to 5$:

- $\mathrm{Distance}(1,5)=4$;
- forward frontier grows $\{1\},\{2\},\{3\},\ldots$ while backward grows
  $\{5\},\{4\},\{3\},\ldots$ and they meet near the middle (vertex $3$);
- path $(1,2,3,4,5)$ has length $5$ vertices / $4$ arcs;
- unidirectional `BFS_Distance(1,5)` agrees.

With a shortcut $1\to 5$, both sides meet immediately at distance $1$.

### Expansion savings (intuition)

$$
O(b^{d}) \quad\text{(one-sided BFS)}
\quad\text{vs}\quad
O(b^{d/2}) \quad\text{(bidirectional BFS, each side)}
$$

On bushy state spaces (puzzles, grids with large open frontiers) the
reduction is dramatic; on long directed chains both sides still walk
$\Theta(d)$ vertices and the asymptotic gain disappears — correctness is
unchanged.

### Asymptotic cost

$$
O(|V| + |E|)
$$

time in the worst case (each vertex and each directed edge is processed a
constant number of times per side). Auxiliary space is $O(|V|)$ for both
queues / visited bitsets / parent arrays, plus fixed $O(|V|+|E|)$ graph
storage for forward and reverse adjacency.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (worst case) | $O(\|V\| + \|E\|)$ |
| Expansions (branching intuition) | $O(b^{d/2})$ per side vs $O(b^{d})$ one-sided |
| Auxiliary space (search) | $O(\|V\|)$ dual queues + visited + parents |
| Graph storage | $O(\|V\| + \|E\|)$ forward and reverse arrays |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Unreachable distance | $\mathrm{Infinity} = \mathrm{Natural}'\mathrm{Last}$ |
| Shortest simple path | at most $N-1$ arcs when reachable |

## Features

- **`Clear` / `Add_Edge`** — digraph on vertices $1 .. N$; reverse edges
  recorded automatically for the backward frontier (undirected = both
  directions).
- **`Vertex_Count` / `Edge_Count`** — size queries (`Edge_Count` counts
  directed edges once).
- **`Shortest_Path`** — meeting-in-the-middle bidirectional BFS path.
- **`Distance` / `Reachable`** — single-pair queries.
- **`BFS_Distance`** — unidirectional BFS oracle for tests.
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or insufficient `Path` bounds.
- **Educational layout** — 1-based indices; dual FIFO BFS; no heap beyond
  fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbidirectional_search.gpr`.

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

- Empty graph, single vertex, self-loops
- Two-vertex arcs and 2-cycles; directed chains
- Diamonds, shortcuts, and meeting-in-the-middle paths
- Disconnected components and unreachable goals
- Cycles, complete digraphs, undirected modelling
- Stars, binary trees, grid DAGs, parallel edges, clear/rebuild
- Long chains ($N=30$, $N=50$), wide stars
- **`BFS_Distance` oracle** agreement on all small digraph pairs
- Path endpoint / length / consecutive-edge consistency
- `Invalid_Argument` for capacity, range, and array bounds
- `Infinity` sentinel and max-$N$ smoke checks
- Bidirectional vs one-sided distance matrices

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Bidirectional_Search is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;
   Infinity     : constant Natural := Natural'Last;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Order_Array is array (Positive range <>) of Vertex_Id;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   function Shortest_Path
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Order_Array;
      Length : out Natural) return Boolean;

   function Distance
     (G : Graph; Start, Goal : Vertex_Id) return Natural;

   function BFS_Distance
     (G : Graph; Start, Goal : Vertex_Id) return Natural;

   function Reachable
     (G : Graph; Start, Goal : Vertex_Id) return Boolean;
end Bidirectional_Search;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Path'First /= 1` or `Path'Last < N`, or $N=0$ on
`Distance` / `Reachable` / `Shortest_Path` / `BFS_Distance`.

Path convention: `Path(1 .. Length)` runs from `Start` to `Goal` with
$\mathrm{Length}=\mathrm{Dist}+1$. Distances use $0$ when
$\mathrm{Start}=\mathrm{Goal}$ and $\mathrm{Infinity}$ when unreachable.
`Add_Edge` always records the reverse adjacency entry used by the
backward frontier; undirected educational graphs still insert both
directed edges explicitly.

## License

Educational reference implementation. See repository `LICENSE` if present.
