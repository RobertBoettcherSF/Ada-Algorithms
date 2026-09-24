# A* Search in Ada 2023

## Project Overview

**A\*** (pronounced “A-star”) is a graph traversal and pathfinding algorithm
that finds a **least-cost path** from a source to a designated goal on a
**weighted digraph**. Peter Hart, Nils Nilsson, and Bertram Raphael published
it in 1968 (Stanford Research Institute / Shakey project). It extends
Dijkstra’s algorithm by guiding expansion with a **heuristic** estimate of
remaining cost to the goal.

At each step A\* expands the open vertex $n$ that minimises

$$
f(n) = g(n) + h(n)
$$

where $g(n)$ is the cost of the best path found so far from the source to $n$,
and $h(n)$ is a problem-specific estimate of the cheapest path from $n$ to the
goal. When $h$ is **admissible** (never overestimates), the first time the goal
is selected from the open set its $g$-score is optimal. When $h$ is
**consistent** (monotone), each vertex is settled at most once.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, weighted adjacency lists in fixed
arrays, dense $O(V)$ open-set selection (no heap machinery — matching the
Dijkstra sibling sheet), an `Infinity` sentinel for unreachable goals, path
reconstruction via a predecessor tree, and rejection of negative edge weights
and negative heuristic values. A heuristic that is **identically zero** makes
selection depend on $g$ alone, so A\* reduces to dense Dijkstra on the same
graph.

Primary source:
[Wikipedia — A\* search algorithm](https://en.wikipedia.org/wiki/A*_search_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Evaluation | Notes |
| --- | --- | --- |
| **This package** (`Ada-A-Star`) | $f(n)=g(n)+h(n)$ | Admissible $h$ ⇒ optimal path cost; dense open scan |
| Dijkstra (sibling sheet) | $f(n)=g(n)$ | Non-negative weighted SSSP; A\* with $h\equiv 0$ |
| Uniform-cost search (UCS) | $f(n)=g(n)$ | Same idea as Dijkstra for point-to-point |
| Greedy best-first (sibling sheet) | $f(n)=h(n)$ | Not optimal in general |
| BFS / IDDFS (sibling sheets) | fewest arcs | Unweighted / unit-cost shallowest path |

README links only — **no** package `with` of siblings.

## Algorithm

### Dense A\* (this sheet)

Given digraph $G=(V,E)$ with $c(u,w)\ge 0$, source $s$, goal $t$, and
heuristic $H$:

1. Set $\mathrm{dist}(v)\leftarrow\infty$, $\mathrm{prev}(v)\leftarrow$ undefined;
   $\mathrm{dist}(s)\leftarrow 0$. Closed set empty.
2. While some vertex with finite $\mathrm{dist}$ is not closed:
   - Choose open $u$ minimising $f(u)=\mathrm{dist}(u)+H(u)$ (dense scan).
   - Mark $u$ closed; count an expansion.
   - If $u=t$, stop — with admissible $H$, $\mathrm{dist}(t)$ is optimal.
   - For each edge $u\to w$ with weight $c$: let
     $\mathrm{alt}=\mathrm{dist}(u)+c$; if $\mathrm{alt}<\mathrm{dist}(w)$ then
     update $\mathrm{dist}(w)$, set $\mathrm{prev}(w)\leftarrow u$, and
     **reopen** $w$ if it was closed (needed when $H$ is admissible but not
     consistent).

### Admissibility and consistency

- **Admissible:** $H(v)\le$ true remaining cost from $v$ to $t$ for every $v$.
  Guarantees optimal path cost when the goal is selected.
- **Consistent (monotone):** $H(u)\le c(u,w)+H(w)$ for every edge $u\to w$.
  Implies admissibility (if $H(t)=0$) and that reopen never fires after settle.
- **$H\equiv 0$:** A\* ≡ dense Dijkstra (optimal for non-negative weights).

### Example

Vertices $\{1,2,3,4\}$ with edges
$1\xrightarrow{1}2$, $1\xrightarrow{4}3$, $2\xrightarrow{1}3$,
$2\xrightarrow{5}4$, $3\xrightarrow{1}4$, and admissible
$H=(2,1,1,0)$:

- Optimal $1\to 4$ cost is $3$ along $(1,2,3,4)$
- A\* with this $H$ returns the same cost as Dijkstra ($H\equiv 0$)

### Asymptotic cost

With array scan for the open minimum:

$$
O(V^{2} + E)
$$

Graph storage is $O(V+E)$ in fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$. Heap-based A\* variants
achieve $O((V+E)\log V)$; this sheet keeps the dense scan for clarity.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (dense A\*) | $O(V^{2} + E)$ |
| Time (heap A\*, not used here) | $O((V+E)\log V)$ |
| Auxiliary space (search) | $O(V)$ closed / scratch |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Weights | Non-negative integers; negatives raise `Invalid_Argument` |
| Heuristic | Non-negative integers per vertex; negatives raise `Invalid_Argument` |
| Unreachable | $\mathrm{dist}(t)=\mathrm{Infinity}$, `Found = False` |

## Features

- **`Clear` / `Add_Edge`** — build a weighted digraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Search`** — A\* Source→Goal: `Dist` (g-scores), `Prev`, `Path`, `Found`.
- **`Search` (with `Nodes_Expanded`)** — same, plus expansion count.
- **`Find_Path`** — convenience returning cost + path (or `Infinity`).
- **`Distance`** — Source→Goal cost only (or `Infinity`).
- **`Reconstruct_Path`** — recover a vertex sequence from `Prev`.
- **`Infinity`** — sentinel distance for unreachable vertices.
- **Zero heuristic ≡ Dijkstra** — document and test that $H\equiv 0$ matches
  dense Dijkstra behaviour on the same digraph.
- **Capacity / weight / heuristic guards** — `Invalid_Argument` for bad ids,
  overflow, negative weights, negative $H$, or insufficient array bounds.
- **Educational layout** — 1-based indices; dense open scan; fixed arrays
  sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pa_star.gpr`.

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

- Empty graph guards; single vertex; Source = Goal
- Direct edges; multi-hop optimal diamonds and DAGs
- Disconnected / unreachable (`Infinity`)
- Zero heuristic ≡ Dijkstra on the same graph
- Admissible Manhattan heuristic on small grid graphs
- Consistent vs inconsistent (admissible) notes and checks
- Parallel edges; self-loops; zero-weight edges
- `Invalid_Argument` for capacity, range, negative weights / heuristics,
  array bounds
- Expansion counts: guiding $H$ expands no more than $H\equiv 0$ on grids
- Larger chain / star / random-ish digraphs
- `Find_Path` / `Distance` / `Reconstruct_Path` agreement

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package A_Star is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range 0 .. 2**31 - 1;
   type Distance_Value is range 0 .. 2**63 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;
   type Heuristic_Array is array (Vertex_Id range <>) of Integer;
   type Prev_Array is array (Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Search
     (G : Graph; Source, Goal : Vertex_Id; Heuristic : Heuristic_Array;
      Dist : out Distance_Array; Prev : out Prev_Array;
      Path : out Path_Array; Length : out Natural; Found : out Boolean);

   procedure Search
     (G : Graph; Source, Goal : Vertex_Id; Heuristic : Heuristic_Array;
      Dist : out Distance_Array; Prev : out Prev_Array;
      Path : out Path_Array; Length : out Natural; Found : out Boolean;
      Nodes_Expanded : out Natural);

   function Find_Path
     (G : Graph; Source, Goal : Vertex_Id; Heuristic : Heuristic_Array;
      Path : out Path_Array; Length : out Natural) return Distance_Value;

   function Distance
     (G : Graph; Source, Goal : Vertex_Id; Heuristic : Heuristic_Array)
      return Distance_Value;

   function Reconstruct_Path
     (Prev : Prev_Array; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural) return Boolean;
end A_Star;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, negative `Weight`, negative heuristic entries, $N=0$ on
search APIs, Heuristic range not covering $1 .. N$, or `Dist`/`Prev`/`Path`
with `First /= 1` or `Last < N`.

Path convention: on success `Path(1) = Source`, `Path(Length) = Goal`, and
`Length` is the number of vertices (arc count $= Length - 1$).
`Prev(Source) = 0`; unreachable goals leave `Found = False` and
`Distance = Infinity`.

## License

Educational reference implementation. See repository `LICENSE` if present.
