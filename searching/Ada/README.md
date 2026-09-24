# Beam Search in Ada 2023

## Project Overview

**Beam search** is a heuristic graph-search algorithm that explores a limited
set of the most promising partial solutions. It is a **memory-bounded
modification of best-first search**: instead of retaining every open state,
only a predetermined number $\beta$ (the **beam width**) of best partial
states are kept as candidates at each step. It is therefore a **greedy**
algorithm.

This package implements the classic **level-synchronous** (breadth-first
style) form from Wikipedia: the search tree is built **level by level**. At
each depth the algorithm expands every state in the current beam, generates
all successors, sorts them by increasing heuristic cost, and retains only
the $\beta$ best. Only those retained states are expanded at the next depth.

Ranking uses the caller-supplied heuristic alone:

$$
f(v) = H(v)
$$

(lower $H$ is better). This matches classic educational beam search that
scores states by heuristic estimate; an $f = g + h$ (path cost plus
heuristic) ranking is a related design and is **not** used here.

| Beam width $\beta$ | Behaviour |
| --- | --- |
| $\beta = 1$ | Hill-climbing-like: keep a single best child each depth |
| Small $\beta$ | Aggressive pruning; may miss an existing path (**incomplete**) |
| Large $\beta$ / $\beta \ge$ frontier size | Little or no pruning |
| $H(v)=0$ and large $\beta$ | Approximates **BFS reachability** on unit-cost digraphs |

**Not complete** in general: a goal path can be pruned when an intermediate
state (or even the Goal sibling) fails to rank into the top $\beta$.
**Not optimal**: even when a path is found, it need not be fewest-arcs.

Contrast:

| Method | Idea |
| --- | --- |
| **Beam search** (this package) | Level-wise; keep top $\beta$ by $H$ |
| Greedy best-first (sibling) | Priority queue on $h$; no width cap |
| Breadth-first search (sibling) | Full frontier; unit-cost fewest arcs |
| A\* (sibling, later) | $f=g+h$; admissible $h$ ⇒ optimal |

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation on **directed unweighted / unit-cost** graphs: vertices
indexed from $1$, adjacency lists in fixed educational arrays. Undirected
graphs are modelled by inserting both directed edges.

Primary source:
[Wikipedia — Beam search](https://en.wikipedia.org/wiki/Beam_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Beam-Search`) | Level-synchronous beam; width $\beta$; rank by $H$ |
| Best-first search (sibling sheet) | Greedy BeFS: $f=h$; uncapped open set |
| Breadth-first search (sibling sheet) | Level order; no heuristic; complete on finite graphs |
| A\* (sibling sheet, later) | Best-first with $f=g+h$ |
| Dijkstra (sibling sheet) | Non-negative weighted SSSP; $f=g$ |

README links only — **no** package `with` of siblings.

## Algorithm

### Level-synchronous beam (Wikipedia sketch)

```text
beam ← {start}
mark start visited
while beam is not empty do
  if goal ∈ beam then
    return reconstruct(path)
  candidates ← ∅
  for each u in beam do
    for each unvisited out-neighbour w of u do
      mark w visited; Prev(w) ← u
      add w to candidates
  if candidates = ∅ then
    return failure
  sort candidates by ascending H (FIFO among ties)
  beam ← first β candidates   -- beam width
return failure
```

### Implementation notes (this package)

1. Special-case `Start = Goal` → path of length $1$.
2. Initialise the beam with `Start` (visited-on-enqueue).
3. At each depth: if `Goal` is in the beam, reconstruct and succeed.
4. Expand **all** beam nodes; collect unvisited out-neighbours as
   candidates keyed by $H(w)$ (insertion sequence breaks ties).
5. Sort candidates ascending by $H$; retain at most `Beam_Width` (= $\beta$).
6. A Goal generated as a child must **rank into** the next beam — a
   high-$H$ Goal among many better-scoring siblings can be pruned
   (Wikipedia incompleteness).
7. Visited-before-enqueue prevents re-expansion loops on cyclic digraphs.

Out-edges are stored by **prepending**, so the most recently added out-edge
of a vertex is scanned first among that vertex’s neighbours (affects FIFO
tie order when $H$ values are equal).

### Outputs

- **`Search`** — beam path `Start→…→Goal`, or failure (unreachable /
  pruned).
- **`Search` (with `Expansions`)** — same, plus the number of vertices
  expanded (out-neighbours scanned) across all beam levels.
- **`Search_With_Order`** — also records the expansion order.

### Example (narrow beam prunes; wide beam finds)

Digraph on $\{1,2,3,4,5\}$ with arcs $1\to 2$, $1\to 3$, $1\to 4$,
$2\to 5$, and

$$
H(1)=10,\ H(2)=50,\ H(3)=0,\ H(4)=1,\ H(5)=0.
$$

The only path to Goal $5$ is $1\to 2\to 5$. With $\beta = 2$, depth-1
candidates sort as $3,4,2$ — the beam keeps $\{3,4\}$ and **prunes** $2$,
so search fails. With $\beta = 3$ (or larger), $2$ survives and the path
$(1,2,5)$ is found.

With $H(v)=0$ for all $v$ and $\beta$ at least as large as the BFS frontier
at every depth, every discovered successor is retained and reachability
matches BFS on the unit digraph.

### Asymptotic cost

Per depth, ranking up to $F$ candidates costs $O(F\log F)$ with an
educational sort (here insertion sort, fine for $F \le |V|$). Over depth
bound $D$ with branching $B$ and width $\beta$:

$$
O\bigl(D \cdot (\beta \cdot B)\log (\beta \cdot B)\bigr)
$$

in the worst educational bound. Live beam memory is $O(\beta)$; auxiliary
visited / predecessor storage is $O(|V|)$, plus fixed $O(|V|+|E|)$ graph
storage. The beam width **bounds** the frontier retained each depth.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (educational) | $O(D\cdot F\log F)$ per run with $F\le\min(\|V\|,\beta\cdot B)$ |
| Live beam memory | $O(\beta)$ |
| Auxiliary space (search) | $O(\|V\|)$ visited + Prev + candidate pool |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Ranking key | $f(v)=H(v)$ (not $g+h$) |
| Completeness | **Not** guaranteed when $\beta$ is small |
| Optimality | **Not** guaranteed |

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$
  (undirected = both directions).
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Search`** — level-synchronous beam Start→Goal via caller $H$ and $\beta$.
- **`Search` + `Expansions`** — expansion count for educational comparisons.
- **`Search_With_Order`** — expansion order across beam levels.
- **Beam width $\beta$** — retain at most $\beta$ best children by $H$
  each depth.
- **Closed set** — visited-on-enqueue; finite termination on cycles.
- **Capacity / range guards** — `Invalid_Argument` for bad ids, overflow,
  `Beam_Width = 0`, insufficient `Path` / `Order` / `H` bounds, or $N=0$.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbeam_search.gpr`.

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

(Exact `NN` is the current suite size; it is at least 100.)

## Testing

The test suite in `tests.adb` covers:

- Single vertex (`Start = Goal`); self-loops
- Two-vertex arcs and 2-cycles; directed chains
- Wide beam finds a path that a narrow beam prunes
- Goal pruned among high-$H$ siblings when $\beta$ is small
- $H=0$ + large $\beta$ ≈ BFS reachability on unit graphs
- $\beta=1$ hill-climbing along decreasing $H$
- Unreachable goals; disconnected components
- Cycles, diamonds, grids, stars, undirected modelling
- Parallel edges; clear/rebuild; long chains
- Expansion-count comparisons: wide vs narrow beam
- `Invalid_Argument` for capacity, range, `Beam_Width=0`, `H` / `Path` bounds
- Max-$N$ smoke checks

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Beam_Search is
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
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
      Path       : out Path_Array;
      Length     : out Natural) return Boolean;

   function Search
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
      Path       : out Path_Array;
      Length     : out Natural;
      Expansions : out Natural) return Boolean;

   function Search_With_Order
     (G          : Graph;
      Start      : Vertex_Id;
      Goal       : Vertex_Id;
      H          : Heuristic_Array;
      Beam_Width : Natural;
      Path       : out Path_Array;
      Length     : out Natural;
      Order      : out Order_Array;
      Count      : out Natural;
      Expansions : out Natural) return Boolean;
end Beam_Search;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, $N=0$ on `Search`, `Beam_Width = 0`, `H'First > 1` or
`H'Last < N`, `Path'First /= 1` or `Path'Last < N`, or the same bounds on
`Order` for `Search_With_Order`.

Path convention: `Path(1)=Start`, `Path(Length)=Goal` when found; `Length=0`
on failure. Heuristic $H(v)$ estimates remaining cost to the goal (lower is
ranked first into the beam). Beam width $\beta$ caps how many states survive
each depth; small $\beta$ trades completeness for bounded memory.

## License

Educational reference implementation. See repository `LICENSE` if present.
