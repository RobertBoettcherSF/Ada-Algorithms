# Breadth-First Search (BFS) in Ada 2023

## Project Overview

**Breadth-first search** (BFS) is a fundamental graph traversal: from a start
vertex it explores all neighbours at the current depth before moving on to
vertices at the next depth. Extra memory — typically a **FIFO queue** —
tracks the frontier of discovered but not yet expanded vertices; a visited
set ensures each vertex is enqueued once, so the search terminates on finite
graphs even when cycles are present.

Konrad Zuse described BFS-related ideas in 1945; Edward F. Moore (1959) and
C. Y. Lee (1961) developed shortest-path and wire-routing applications. In
modern algorithmics BFS underpins unweighted shortest paths, connected
components, bipartiteness testing, and many AI / puzzle searches. Relative
to depth-first search, BFS tends to produce shallow, bushy trees and
**level-order** visit sequences; on unit-cost graphs the first time a vertex
is discovered is along a **fewest-arcs** path from the start.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation on **directed unweighted** graphs: vertices indexed from
$1$, adjacency lists in fixed educational arrays (no dynamic heap beyond
queue-sized workspaces), documented $O(|V|+|E|)$ time, visit order,
single-source distances and predecessors, distance / reachability queries,
and path reconstruction. Undirected graphs are modelled by inserting both
directed edges.

Primary source:
[Wikipedia — Breadth-first search](https://en.wikipedia.org/wiki/Breadth-first_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Breadth-First-Search`) | Classic BFS: level order, unit-cost shortest paths |
| Depth-first search (sibling sheet) | DFS: discovery order, forest, timestamps |
| Iterative deepening DFS (sibling sheet) | IDDFS: DFS space + BFS shallowest-goal optimality |
| Dijkstra (sibling sheet) | Non-negative weighted single-source shortest paths |
| Lexicographic BFS (sibling sheet) | Partition-refinement Lex-BFS ordering |

README links only — **no** package `with` of siblings.

## Algorithm

### Queue view (Wikipedia)

```text
procedure BFS(G, root) is
    let Q be a queue
    label root as explored
    Q.enqueue(root)
    while Q is not empty do
        v := Q.dequeue()
        for all edges from v to w in G.adjacentEdges(v) do
            if w is not labeled as explored then
                label w as explored
                w.parent := v
                Q.enqueue(w)
```

### Implementation notes (this package)

1. Mark `Start` explored with distance $0$; enqueue it.
2. While the queue is nonempty: dequeue $v$; for each unexplored
   out-neighbour $w$, set $\mathrm{Dist}(w)=\mathrm{Dist}(v)+1$,
   $\mathrm{Prev}(w)=v$, mark explored, and enqueue $w$.
3. Vertices are marked **before enqueue** (Wikipedia), so each vertex
   enters the queue at most once.

Out-edges are stored by prepending, so the **most recently added** out-edge
of a vertex is expanded first among same-level neighbours.

### Outputs

- **`BFS`** — level-order discovery of the reachable set from `Start`.
- **`Shortest_Paths`** — for every vertex: unit-cost distance from `Start`
  (`Infinity` if unreachable) and a predecessor on some shortest path.
- **`Distance`** — fewest arcs `Start→Target`, or `Infinity`.
- **`Reconstruct_Path`** — walk `Prev` from `Target` back to `Start` and
  reverse into a vertex sequence of length $\mathrm{Dist}+1$.
- **`Reachable`** — membership of `Target` in the reachable set of `Start`
  (equivalent to $\mathrm{Distance}\neq\mathrm{Infinity}$).

### Example

Digraph on $\{1,2,3,4\}$ with arcs $1\to 2\to 3\to 4$ and shortcut $1\to 4$:

- $\mathrm{Distance}(1,4)=1$ via the shortcut;
- longer routes such as $(1,2,3,4)$ are never preferred for distances;
- BFS visit order from $1$ begins $(1,4,\ldots)$ when $1\to 4$ was the
  last out-edge added from $1$ (prepended head).

### Asymptotic cost

$$
O(|V| + |E|)
$$

time (each vertex and each edge is processed a constant number of times).
Auxiliary space is $O(|V|)$ for the queue and visited bitset, plus fixed
$O(|V|+|E|)$ graph storage.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(\|V\| + \|E\|)$ |
| Auxiliary space (search) | $O(\|V\|)$ queue + visited |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Unreachable distance | $\mathrm{Infinity} = \mathrm{Natural}'\mathrm{Last}$ |
| Shortest simple path | at most $N-1$ arcs when reachable |

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$
  (undirected = both directions).
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`BFS`** — level-order visit sequence from `Start`.
- **`Shortest_Paths`** — distances and predecessors from `Start`.
- **`Distance` / `Reachable`** — single-pair queries.
- **`Reconstruct_Path`** — recover a shortest vertex path from `Prev`.
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or insufficient array bounds.
- **Educational layout** — 1-based indices; FIFO queue BFS; no heap beyond
  fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbreadth_first_search.gpr`.

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
- Neighbour / prepend order; diamonds and shortcuts
- Disconnected components and unreachable vertices
- Cycles, complete digraphs, undirected modelling
- Stars, binary trees, grid DAGs, parallel edges, clear/rebuild
- Long chains ($N=30$, $N=50$), wide stars
- IDDFS-style depth-limited **oracle** distances on small digraphs
- Level-order monotonicity of distances; path/Prev consistency
- `Invalid_Argument` for capacity, range, and array bounds
- `Infinity` sentinel and max-$N$ smoke checks

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Breadth_First_Search is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;
   Infinity     : constant Natural := Natural'Last;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Order_Array is array (Positive range <>) of Vertex_Id;
   type Distance_Array is array (Vertex_Id range <>) of Natural;
   type Prev_Array is array (Vertex_Id range <>) of Natural;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure BFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array;
      Count : out Natural);

   procedure Shortest_Paths
     (G     : Graph;
      Start : Vertex_Id;
      Dist  : out Distance_Array;
      Prev  : out Prev_Array);

   function Distance
     (G : Graph; Start, Target : Vertex_Id) return Natural;

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Start  : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Order_Array;
      Length : out Natural) return Boolean;

   function Reachable
     (G : Graph; Start, Target : Vertex_Id) return Boolean;
end Breadth_First_Search;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Order'First /= 1` or `Order'Last < N`, distance /
predecessor arrays with `First /= 1` or `Last < N`, insufficient `Path`
bounds for `Reconstruct_Path`, or $N=0$ on `Distance` / `Reachable` /
`Shortest_Paths`.

Order convention: `Order(1 .. Count)` is BFS level order; `Count` is the
number of visited vertices. Distances use $0$ at the source and
$\mathrm{Infinity}$ for unreachable vertices. `Prev(v)=0` means $v$ is the
source or unreachable.

## License

Educational reference implementation. See repository `LICENSE` if present.
