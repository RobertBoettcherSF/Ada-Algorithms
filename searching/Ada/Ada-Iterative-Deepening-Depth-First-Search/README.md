# Iterative Deepening Depth-First Search (IDDFS) in Ada 2023

## Project Overview

**Iterative deepening depth-first search** (IDDFS / IDS) is a state-space
and graph search strategy that repeatedly runs a **depth-limited** DFS
with increasing depth limits until a goal is found. Because every node at
depth $d$ is examined before any node at depth $d+1$, the first success is
a **shallowest** goal — the same optimality guarantee as breadth-first
search on unit-cost (unweighted) graphs — while auxiliary memory stays
proportional to the depth of the search, as in depth-first search.

Richard Korf (1985) popularised iterative deepening for heuristic search;
the idea appears throughout AI textbooks (Russell & Norvig) and game-tree
engines. Relative to expanding the frontier at depth $d$, the cost of
re-expanding shallower levels is asymptotically small when the branching
factor $b > 1$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation on **directed unweighted** graphs: vertices indexed from
$1$, adjacency lists in fixed educational arrays (no dynamic heap beyond
stack-sized workspaces), documented $O(b^{d})$ time, and a BFS oracle for
tests.

Primary source:
[Wikipedia — Iterative deepening depth-first search](https://en.wikipedia.org/wiki/Iterative_deepening_depth-first_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Iterative-Deepening-Depth-First-Search`) | IDDFS: DFS space + BFS shallowest-goal optimality |
| Lexicographic BFS (sibling sheet) | Partition-refinement Lex-BFS ordering |
| Tarjan SCC (sibling sheet) | One-pass DFS + stack + low-link components |

README links only — **no** package `with` of siblings.

## Algorithm

### Depth-limited DFS (DLS)

Given a depth budget $L$ (maximum number of arcs on the explored path),
recursive DLS expands the **search-tree unfolding** of the digraph:

1. If $L = 0$: succeed when the current node is the goal; otherwise report
   a **cutoff** (remaining work may exist at greater depth).
2. If $L > 0$: recurse on each successor with budget $L-1$. Propagate
   success immediately; OR-combine cutoff flags from children.

No global closed set is kept (Wikipedia directed-graph presentation): the
depth budget truncates cyclic unfoldings. A finite simple shortest path,
when it exists, has at most $N-1$ arcs, so IDDFS need not deepen further.

### Iterative deepening

```text
for L ← 0, 1, 2, …, N−1 do
    if DLS(Start, L) finds Goal then
        return that path
return failure
```

The first successful $L$ equals the fewest arcs from Start to Goal.
`Start = Goal` succeeds at $L = 0$ with a one-vertex path.

### Example

Digraph on $\{1,2,3,4\}$ with arcs $1\to 2\to 3\to 4$ and shortcut $1\to 4$:

- DLS with $L=0$ fails (unless Start is Goal);
- DLS with $L=1$ returns path $(1,4)$ — shallowest;
- longer routes such as $(1,2,3,4)$ are never preferred.

### Asymptotic cost

In a tree with branching factor $b$ and goal depth $d$, nodes at depth $d$
are expanded once, those at $d-1$ twice, …, the root $d+1$ times:

$$
b^{d} + 2b^{d-1} + \cdots + (d+1) = O(b^{d})
$$

Space is $O(d)$ for the recursion / path stack (plus fixed $O(|V|+|E|)$
graph storage).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (tree / unit-cost) | $O(b^{d})$ |
| Auxiliary space (search) | $O(d)$ path / recursion |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Shortest-path depth | at most $N-1$ arcs when a simple path exists |

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Depth_Limited_Search`** — one DLS with explicit depth limit $L$.
- **`Search`** — full IDDFS returning a shallowest Start→Goal path.
- **`BFS_Shortest_Path`** — breadth-first oracle for optimality tests.
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or insufficient `Path` bounds.
- **Educational layout** — 1-based indices; no heap beyond fixed arrays
  sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Piterative_deepening_dfs.gpr`.

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

- Empty graph, single vertex, self-loops, Start = Goal
- Two-vertex arcs and 2-cycles; directed chains
- Shortcuts vs longer detours (shallowest-goal checks)
- Diamonds, stars, binary trees, grid DAGs
- Disconnected components and unreachable pairs
- Parallel edges, clear/rebuild, API counters
- Progressive DLS limits; long chains ($N=30$, $N=50$)
- Exhaustive IDDFS↔BFS agreement on small digraphs
- `Invalid_Argument` for capacity, range, path bounds, and oversized limits

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Iterative_Deepening_DFS is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Path_Array is array (Positive range <>) of Vertex_Id;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   function Depth_Limited_Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Limit  : Natural;
      Path   : out Path_Array;
      Length : out Natural) return Boolean;

   function Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean;

   function BFS_Shortest_Path
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean;
end Iterative_Deepening_DFS;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Path'First /= 1` or `Path'Last < N`, or
`Limit > \mathrm{Max\_Vertices}` in DLS.

Path convention: on success `Path(1) = Start`, `Path(Length) = Goal`, and
`Length` is the number of vertices (arc count $= Length - 1$).

## License

Educational reference implementation. See repository `LICENSE` if present.
