# Prim's Algorithm in Ada 2023

## Project Overview

**Prim's algorithm** (also Jarník's algorithm, the Prim–Jarník algorithm,
or the DJP algorithm) computes a **minimum spanning tree (MST)** of a
**weighted undirected graph** by growing a tree from a seed vertex: at
each step it attaches the lightest edge that leaves the current tree.
Joseph Kruskal (1956), Robert C. Prim (1957), and Edsger W. Dijkstra
(1959) rediscovered Vojtěch Jarník's 1930 method. The basic form yields
one tree in the seed's connected component; restarting on every
unsettled component produces a **minimum spanning forest (MSF)**.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, undirected adjacency lists in
fixed arrays (no dynamic heap beyond stack-sized workspaces), the classic
dense $O(V^{2})$ array scan for the minimum unsettled key, non-negative
integer weights, an `Infinity` sentinel for unreachable keys, and an
optional in-package `Kruskal_Reference` for cross-checks on small graphs
(self-contained — no `with` of Kruskal / Reverse-delete sibling packages).

Primary source:
[Wikipedia — Prim's algorithm](https://en.wikipedia.org/wiki/Prim%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Kruskal / Reverse-delete / Borůvka

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Prims-Algorithm`) | Grow a tree from a seed by repeatedly attaching the lightest edge leaving the tree; multi-start ⇒ MSF |
| Kruskal (sibling sheet) | Sort ascending; add an edge when endpoints lie in different components (Union–Find) |
| Reverse-delete (sibling sheet) | Start with all edges; delete heavy edges that are not bridges of the kept graph |
| Borůvka (sibling sheet) | In phases, every component adds its lightest outgoing edge (contracts / merges) |

README links only — **no** package `with` of siblings. Prim (forest form),
Kruskal, reverse-delete, and Borůvka produce the same MST / MSF **total
weight** (and the same number of kept edges); when edge weights are not
unique the kept **edge sets** may differ among alternate optima.

## Algorithm

### Dense Prim from a seed

Given an undirected graph $G=(V,E)$ with edge weights $w(e)\ge 0$ and a
start vertex $s$:

1. Set $\mathrm{Key}(v)\leftarrow\infty$ and $\mathrm{Parent}(v)\leftarrow 0$
   for all $v$; set $\mathrm{Key}(s)\leftarrow 0$.
2. While some vertex remains unsettled:
   - Let $u$ be an unsettled vertex of minimum $\mathrm{Key}(u)$.
   - If $\mathrm{Key}(u)=\infty$, stop — remaining vertices lie outside
     $s$'s connected component.
   - Mark $u$ settled. For each neighbour $w$ of $u$ with weight $c$:
     if $w$ is unsettled and $c<\mathrm{Key}(w)$, set
     $\mathrm{Key}(w)\leftarrow c$ and $\mathrm{Parent}(w)\leftarrow u$.
3. Edges $\{\mathrm{Parent}(v),v\}$ for $\mathrm{Parent}(v)\ne 0$ form the
   MST of $s$'s component; their weights sum to the total.

### Minimum spanning forest

Restart the same growth on every vertex that is still unsettled (seeds
chosen in ascending id). Each component root $r$ has
$\mathrm{Parent}(r)=0$ and $\mathrm{Key}(r)=0$. The union of all tree
edges is an MSF of $G$.

### Example

Vertices $\{1,2,3,4\}$ with undirected edges
$\{1,2\}:1$, $\{1,3\}:4$, $\{2,3\}:2$, $\{2,4\}:5$, $\{3,4\}:3$,
seed $s=1$:

- Attach $2$ with key $1$, then $3$ with key $2$, then $4$ with key $3$.
- Edges $\{1,2\},\{2,3\},\{3,4\}$ form the unique MST of total weight
  $1+2+3=6$.

### Asymptotic cost

With an array scan for the minimum unsettled key each step:

$$
O(V^{2}+E)
$$

which is $\Theta(V^{2})$ on dense graphs. Graph storage is
$O(V+E)$ in fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$. Binary-heap and
Fibonacci-heap variants achieve $O(E\log V)$ and $O(E+V\log V)$; this
sheet favours the transparent dense scan.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (dense Prim) | $O(V^{2}+E)$ |
| Time (Kruskal reference, in-package) | $O(E^{2})$ sort + $O(E\,\alpha(V))$ merges (insertion sort) |
| Auxiliary space | $O(V)$ Parent / Key / settled flags |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ undirected edges (parallels allowed) |
| Weights | Non-negative integers; negatives raise `Invalid_Argument` |
| Unreachable key | `Infinity` ($=`Key_Value'Last`) |
| Output | Parent/Key or kept edges + total weight (one tree or MSF) |

## Features

- **`Clear` / `Add_Edge`** — build an undirected weighted graph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Minimum_Spanning_Tree` / `Prim`** — grow from `Start` (Parent/Key or edge-list forms; alias pair).
- **`Minimum_Spanning_Forest`** — multi-start Prim covering every component.
- **`Kruskal_Reference`** — in-package Kruskal for agreement checks on small graphs.
- **`Infinity` sentinel** — marks vertices outside the grown tree / component.
- **Capacity / weight guards** — `Invalid_Argument` for bad ids, overflow, negative weights, bad `Start`, or insufficient buffers.
- **Educational layout** — 1-based indices; fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pprims_algorithm.gpr`.

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

=== 1. Empty / single / edgeless ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph; single vertex; edgeless multi-vertex
- Seeded Prim vs forest on disconnected graphs (`Infinity` outside the seed component)
- Unique-weight MST examples with known total weight and edge count
- Self-loops ignored; parallel edges; zero-weight edges
- Agreement with `Kruskal_Reference` on MSF total weight and edge count
- Stars, paths, cycles, complete small graphs $K_3$, $K_4$
- Clear / rebuild; API counters; `Prim` aliases
- `Invalid_Argument` for capacity, range, negative weights, bad `Start`, buffer bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Prims_Algorithm is
   Max_Vertices : constant Positive := 512;
   Max_Edges    : constant Positive := 20_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range 0 .. 2**31 - 1;
   type Weight_Sum is range 0 .. 2**63 - 1;
   type Key_Value is range 0 .. 2**63 - 1;
   Infinity : constant Key_Value := Key_Value'Last;

   type Key_Array is array (Vertex_Id range <>) of Key_Value;
   type Parent_Array is array (Vertex_Id range <>) of Natural;

   type Edge_Record is record
      U, V   : Vertex_Id;
      Weight : Weight_Type;
   end record;
   type Edge_List is array (Positive range <>) of Edge_Record;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; U, V : Vertex_Id; Weight : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Minimum_Spanning_Tree
     (G : Graph; Start : Vertex_Id;
      Parent : out Parent_Array; Key : out Key_Array;
      Total_Weight : out Weight_Sum);
   procedure Minimum_Spanning_Tree
     (G : Graph; Start : Vertex_Id;
      Tree_Edges : in out Edge_List; Tree_Count : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Prim
     (G : Graph; Start : Vertex_Id;
      Parent : out Parent_Array; Key : out Key_Array;
      Total_Weight : out Weight_Sum);
   procedure Prim
     (G : Graph; Start : Vertex_Id;
      Tree_Edges : in out Edge_List; Tree_Count : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Minimum_Spanning_Forest
     (G : Graph;
      Parent : out Parent_Array; Key : out Key_Array;
      Total_Weight : out Weight_Sum);
   procedure Minimum_Spanning_Forest
     (G : Graph;
      Tree_Edges : in out Edge_List; Tree_Count : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Kruskal_Reference
     (G : Graph;
      Tree_Edges : in out Edge_List; Tree_Count : out Natural;
      Total_Weight : out Weight_Sum);
end Prims_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, negative `Weight`, `Start` outside $1 .. N$, seeded
Prim on $N=0$, or buffers with `First /= 1` / insufficient `Last`.

Weight policy: **non-negative integers only**; `Add_Edge` rejects
`Weight < 0`. Zero weights are allowed. The graph is **undirected**: each
`Add_Edge` stores one logical undirected edge (adjacency both ways).
Parallel edges and self-loops are accepted; self-loops never appear in
the MST / MSF. Seeded `Minimum_Spanning_Tree` / `Prim` grow **one tree**
from `Start`; `Minimum_Spanning_Forest` covers **all** components.

## License

Educational reference implementation. See repository `LICENSE` if present.
