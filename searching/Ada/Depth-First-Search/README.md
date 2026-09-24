# Depth-First Search (DFS) in Ada 2023

## Project Overview

**Depth-first search** (DFS) is a fundamental graph traversal: from a start
vertex it explores as far as possible along each branch before
**backtracking**. Extra memory — typically an explicit stack or the call
stack — tracks the current path; a visited set ensures each vertex is
discovered once, so the search terminates on finite graphs even when cycles
are present.

Charles Pierre Trémaux studied a DFS-like maze strategy in the nineteenth
century. In modern algorithmics DFS underpins topological sorting, strongly
connected components (Tarjan / Kosaraju), biconnectivity, planarity testing,
and many AI / puzzle searches. Relative to breadth-first search, DFS tends
to produce deep, skinny trees and different vertex orderings (preorder /
postorder) rather than level order.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation on **directed unweighted** graphs: vertices indexed from
$1$, adjacency lists in fixed educational arrays (no dynamic heap beyond
stack-sized workspaces), documented $O(|V|+|E|)$ time, discovery order,
full forests, reachability, and discover/finish timestamps.

Primary source:
[Wikipedia — Depth-first search](https://en.wikipedia.org/wiki/Depth-first_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Depth-First-Search`) | Classic DFS: discovery order, forest, timestamps |
| Iterative deepening DFS (sibling sheet) | IDDFS: DFS space + BFS shallowest-goal optimality |
| Dijkstra (sibling sheet) | Non-negative weighted single-source shortest paths |
| Lexicographic BFS / Tarjan SCC (sibling sheets) | Ordering / strong components built on DFS ideas |

README links only — **no** package `with` of siblings.

## Algorithm

### Recursive view (Wikipedia)

```text
procedure DFS(G, v):
    label v as discovered
    for each edge v → w in G.adjacentEdges(v) do
        if w is not discovered then
            DFS(G, w)
    -- finish v
```

### Iterative implementation (this package)

An explicit stack of **adjacency iterators** yields the same discovery and
finish order as recursion, without depending on a deep call stack (safe up
to $\mathrm{Max\_Vertices}$):

1. Mark Start discovered; push an iterator over its out-edges.
2. While the stack is nonempty: advance the top iterator; on a fresh
   neighbour, discover it and push; when the iterator is exhausted, **finish**
   the vertex and pop.

Out-edges are stored by prepending, so the **most recently added** out-edge
of a vertex is explored first.

### Outputs

- **`DFS`** — preorder (discovery) of the reachable set from `Start`.
- **`DFS_Forest`** — for $v = 1 .. N$ in order, start a tree at every still
  undiscovered vertex; every vertex appears once.
- **`Reachable`** — membership of `Target` in the reachable set of `Start`.
- **`DFS_Timestamps`** — forest with a global clock: discover and finish
  times in $1 .. 2N$. Intervals nest or are disjoint (**parenthesization**).
  On a DAG, sorting vertices by **decreasing finish time** is a topological
  order.

### Example

Digraph on $\{1,2,3\}$ with arcs $1\to 2$ then $1\to 3$ (head explores $3$
first): discovery order from $1$ is $(1,3,2)$. Finish times satisfy
$\mathrm{Finish}(3) < \mathrm{Finish}(1)$ and
$\mathrm{Finish}(2) < \mathrm{Finish}(1)$.

### Asymptotic cost

$$
O(|V| + |E|)
$$

time to build a forest over the whole graph (each vertex and each edge is
processed a constant number of times). Auxiliary space is $O(|V|)$ for the
iterator stack and visited bitset, plus fixed $O(|V|+|E|)$ graph storage.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(\|V\| + \|E\|)$ |
| Auxiliary space (search) | $O(\|V\|)$ stack + visited |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Timestamp range | $1 .. 2N$ after a full forest |

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`DFS`** — discovery order of vertices reachable from `Start`.
- **`DFS_Forest`** — full forest over all vertices.
- **`Reachable`** — directed reachability query.
- **`DFS_Timestamps`** — discover/finish times (parenthesization / DAG topo).
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or insufficient `Order` / time-array bounds.
- **Educational layout** — 1-based indices; iterator-stack DFS; no heap
  beyond fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pdepth_first_search.gpr`.

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
- Neighbour / prepend order; diamonds and stars
- Disconnected components and DFS forests
- Cycles, complete digraphs, DAGs and reverse-finish topo checks
- Binary trees, grid DAGs, parallel edges, clear/rebuild
- Long chains ($N=30$, $N=50$), wide stars
- Parenthesization of discover/finish intervals; clock permutation
- Reachability matrices on small digraphs
- `Invalid_Argument` for capacity, range, and array bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Depth_First_Search is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Order_Array is array (Positive range <>) of Vertex_Id;
   type Time_Array is array (Vertex_Id range <>) of Natural;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure DFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array;
      Count : out Natural);

   procedure DFS_Forest
     (G     : Graph;
      Order : out Order_Array;
      Count : out Natural);

   function Reachable
     (G : Graph; Start, Target : Vertex_Id) return Boolean;

   procedure DFS_Timestamps
     (G        : Graph;
      Discover : out Time_Array;
      Finish   : out Time_Array);
end Depth_First_Search;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Order'First /= 1` or `Order'Last < N`, time arrays with
`First /= 1` or `Last < N`, or $N=0$ on `Reachable` / `DFS_Timestamps`.

Order convention: `Order(1 .. Count)` is discovery preorder; `Count` is the
number of visited vertices. Timestamps lie in $1 .. 2N$ with
$\mathrm{Discover}(v) < \mathrm{Finish}(v)$ for every $v$.

## License

Educational reference implementation. See repository `LICENSE` if present.
