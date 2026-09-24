# Best-First Search (Greedy) in Ada 2023

## Project Overview

**Best-first search** is a family of graph search algorithms that expand the
**most promising** open node according to an evaluation function $f$. Judea
Pearl described $f(n)$ as estimating the promise of node $n$ from the node
description, the goal, search history, and domain knowledge. When authors
specialise “best-first” to a heuristic that estimates remaining distance to
the goal, the resulting method is **greedy best-first search** (also called
**pure heuristic search**): expand the open vertex with smallest
$h(n)$ first.

This package implements that greedy form:

$$
f(n) = h(n)
$$

with a **binary-heap priority queue** open set (minimum $h$ first; FIFO among
equal keys) and a **visited/closed** set marked on enqueue so cyclic graphs
terminate. The caller supplies a heuristic array $H(v)$ — estimated remaining
cost from $v$ to the goal. The search returns a Start→Goal vertex path when
one is found.

**Not optimal in general.** A misleadingly low $h$ on a long detour can beat
a higher-$h$ short path. Contrast:

| Method | Evaluation |
| --- | --- |
| **Greedy best-first** (this package) | $f(n)=h(n)$ |
| Breadth-first search | fewest arcs (unit cost); no heuristic |
| Dijkstra | $f(n)=g(n)$ (path cost from start) |
| **A\*** (sibling sheet later) | $f(n)=g(n)+h(n)$ — best-first variant, not greedy |

Neither A\* nor B\* is greedy best-first: both incorporate distance from the
start as well as estimated distance to the goal.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation on **directed unweighted / unit-cost** graphs: vertices
indexed from $1$, adjacency lists in fixed educational arrays, documented
$O((|V|+|E|)\log |V|)$ time with a heap open set. Undirected graphs are
modelled by inserting both directed edges.

Primary source:
[Wikipedia — Best-first search](https://en.wikipedia.org/wiki/Best-first_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Best-First-Search`) | Greedy BeFS: $f=h$; priority queue + closed set |
| Breadth-first search (sibling sheet) | Level order; unit-cost fewest arcs |
| Dijkstra (sibling sheet) | Non-negative weighted SSSP; $f=g$ |
| A\* (sibling sheet, later) | Best-first with $f=g+h$; admissible $h$ ⇒ optimal |
| Bidirectional search (sibling sheet) | Two-frontier BFS meeting in the middle |

README links only — **no** package `with` of siblings.

## Algorithm

### Greedy BeFS (Wikipedia sketch)

```text
procedure GBS(start, target) is
  mark start as visited
  add start to queue          -- priority queue by heuristic
  while queue is not empty do
    current ← vertex with min heuristic distance to target
    remove current from queue
    foreach neighbour n of current do
      if n not in visited then
        if n is target then
          return n
        else
          mark n as visited
          add n to queue
  return failure
```

### Implementation notes (this package)

1. Special-case `Start = Goal` → path of length $1$.
2. Mark `Start` visited; push onto a binary min-heap keyed by $H(v)$
   (insertion sequence breaks ties → FIFO among equal $h$).
3. While the heap is nonempty: pop $u$; if $u=\mathrm{Goal}$, reconstruct.
4. For each unvisited out-neighbour $w$: set $\mathrm{Prev}(w)=u$, mark
   visited; if $w=\mathrm{Goal}$, reconstruct and succeed; else push $w$.
5. Visited-before-enqueue prevents re-expansion loops on cyclic digraphs.

Out-edges are stored by **prepending**, so the most recently added out-edge
of a vertex is scanned first among that vertex’s neighbours.

### Outputs

- **`Search`** — greedy BeFS path `Start→…→Goal`, or failure.
- **`Search` (with `Expansions`)** — same, plus the number of vertices
  popped from the open set (educational: guiding $h$ often expands fewer
  nodes than a flat zero heuristic).
- **`Search_With_Order`** — also records the pop / discovery order.

### Example (heuristic guides; greedy is not optimal)

Digraph on $\{1,2,3,4\}$ with arcs $1\to 2\to 4$ and $1\to 3\to 4$, and

$$
H(1)=3,\ H(2)=100,\ H(3)=1,\ H(4)=0.
$$

Greedy expands $1$, then prefers $3$ over $2$, then reaches $4$ along
$(1,3,4)$. If instead $H(2)=0$ and $H(3)=50$ while the short path is still
$1\to 3\to 4$ of two arcs and $1\to 2\to \cdots$ is longer, greedy may take
the low-$h$ detour — illustrating **non-optimality**.

With $H(v)=0$ for all $v$, all keys tie and FIFO among ties yields
BFS-like discovery order (still not a correctness claim for optimality of
path *cost* under arbitrary graphs — here edges are unit, and visited-on-
enqueue already yields a simple path).

### Asymptotic cost

$$
O((|V| + |E|) \log |V|)
$$

time with a binary-heap open set (each vertex pushed/popped at most once;
each edge scanned once). Auxiliary space is $O(|V|)$ for the heap, visited
bitset, and predecessor array, plus fixed $O(|V|+|E|)$ graph storage.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (heap open set) | $O((\|V\| + \|E\|)\log \|V\|)$ |
| Auxiliary space (search) | $O(\|V\|)$ heap + visited + Prev |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Heuristic | $H(v)\in\mathbb{N}$; need not be admissible |
| Optimality | **Not** guaranteed (unlike BFS / Dijkstra / A\* with admissible $h$) |

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$
  (undirected = both directions).
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Search`** — greedy best-first Start→Goal path via caller $H$.
- **`Search` + `Expansions`** — expansion count for educational comparisons.
- **`Search_With_Order`** — expansion / discovery order.
- **Priority queue** — binary min-heap on $H(v)$ with FIFO tie-break.
- **Closed set** — visited-on-enqueue; finite termination on cycles.
- **Capacity / range guards** — `Invalid_Argument` for bad ids, overflow,
  insufficient `Path` / `Order` / `H` bounds, or $N=0$.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbest_first_search.gpr`.

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

- Single vertex (`Start = Goal`); self-loops
- Two-vertex arcs and 2-cycles; directed chains
- Heuristic guiding toward the goal (prefer low-$h$ branch)
- Zero heuristic degeneration (FIFO among ties)
- Non-optimality examples (greedy takes a longer low-$h$ detour)
- Unreachable goals; disconnected components
- Cycles, diamonds, grids, stars, undirected modelling
- Parallel edges; clear/rebuild; long chains
- Expansion-count comparisons: guiding $h$ vs flat $H=0$
- `Invalid_Argument` for capacity, range, `H` bounds, and `Path` bounds
- Max-$N$ smoke checks

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Best_First_Search is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Heuristic_Array is array (Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;
   type Order_Array is array (Positive range <>) of Vertex_Id;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   function Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      H      : Heuristic_Array;
      Path   : out Path_Array;
      Length : out Natural) return Boolean;

   function Search
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Path       : out Path_Array;
      Length     : out Natural;
      Expansions : out Natural) return Boolean;

   function Search_With_Order
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Path       : out Path_Array;
      Length     : out Natural;
      Order      : out Order_Array;
      Count      : out Natural;
      Expansions : out Natural) return Boolean;
end Best_First_Search;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, $N=0$ on `Search`, `H'First > 1` or `H'Last < N`,
`Path'First /= 1` or `Path'Last < N`, or the same bounds on `Order` for
`Search_With_Order`.

Path convention: `Path(1)=Start`, `Path(Length)=Goal` when found; `Length=0`
on failure. Heuristic $H(v)$ is an estimate of remaining cost to the goal
(lower is expanded first). Greedy best-first uses $f(n)=h(n)$ only; A\*
($f=g+h$) is a related best-first variant documented for a later sibling
sheet and is **not** implemented here.

## License

Educational reference implementation. See repository `LICENSE` if present.
