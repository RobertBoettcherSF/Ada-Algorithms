# Minimum Spanning Tree in Ada 2023

## Project Overview

A **minimum spanning tree (MST)** of a connected, edge-weighted undirected
graph is a subset of the edges that connects every vertex, forms no
cycles, and has the **minimum possible total weight**. When the graph is
disconnected the same idea yields a **minimum spanning forest (MSF)** —
the union of MSTs of the connected components.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
**survey**: one shared undirected weighted-graph API plus self-contained
re-implementations of the classical methods (do **not** `with` the
sibling packages):

| Method | Idea | Educational cost |
| --- | --- | --- |
| **Kruskal** | Sort ascending; add an edge when endpoints lie in different components (Union–Find) | $O(E^{2}+E\,\alpha(V))$ (insertion sort) |
| **Prim** (dense) | Multi-start grow by attaching the lightest cut edge (array scan) | $O(V^{2}+VE)$ |
| **Borůvka** | In phases, every component adds its cheapest outgoing edge | $O(E\log V)$ |
| **Reverse_Delete** | Start with all edges; delete heavy edges that are not bridges | $O(E^{2}\alpha(V))$ |

Vertices are indexed from $1$. Storage uses fixed educational arrays up
to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$ (no dynamic heap).
Weights are **non-negative integers**. All four methods agree on
`Total_Weight` (and edge count) for every input; when equal weights
create alternate optima the kept **edge sets** may differ.

Primary source:
[Wikipedia — Minimum spanning tree](https://en.wikipedia.org/wiki/Minimum_spanning_tree).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with algorithm siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Minimum-Spanning-Tree`) | Survey: Kruskal + Prim + Borůvka + Reverse-delete |
| Kruskal (sibling sheet) | Dedicated sort + Union–Find MST / MSF |
| Prim (sibling sheet) | Dedicated dense Prim with seeded / forest forms |
| Borůvka (sibling sheet) | Dedicated phased cheapest-outgoing merges |
| Reverse-delete (sibling sheet) | Dedicated dual of Kruskal (delete heavy non-bridges) |

README links only — **no** package `with` of siblings. Each dedicated
sheet may expose extra helpers (e.g. Prim Parent/Key forms); this survey
keeps a uniform `(Tree_Edges, Tree_Count, Total_Weight)` contract.

## When to use which method

$$
\begin{align*}
\text{sparse, sort-friendly} &\Rightarrow \textbf{Kruskal} \\
\text{dense, } V \ll E &\Rightarrow \textbf{Prim (dense)} \\
\text{parallel / contraction-friendly} &\Rightarrow \textbf{Borůvka} \\
\text{dual / bridge-deletion view} &\Rightarrow \textbf{Reverse-delete}
\end{align*}
$$

All four are correct for non-negative undirected weights and produce the
same MST / MSF **total weight**.

## Algorithm sketches

### Kruskal (sort + Union–Find)

Given $G=(V,E)$ with $w(e)\ge 0$:

1. $\mathrm{Make\textrm{-}Set}(v)$ for each $v\in V$.
2. Sort edges so $w(e_1)\le\cdots\le w(e_m)$.
3. For each $e=\{u,v\}$ in that order: if $\mathrm{Find}(u)\ne\mathrm{Find}(v)$,
   keep $e$ and $\mathrm{Union}(u,v)$.

### Dense Prim (multi-start)

From each unsettled seed, grow a tree by repeatedly settling the
unsettled vertex of minimum cut-key and relaxing its incident edges.
Restart on every unsettled vertex to obtain an MSF.

### Borůvka

In phases, every component selects its cheapest outgoing edge (with a
deterministic tie-break); selected edges are unioned. Each productive
phase at most halves the number of components inside a connected piece.

### Reverse-delete

Start with every edge kept. Consider edges in **decreasing** weight
order; tentatively delete each edge and restore it only when its
endpoints become disconnected (i.e. it is a bridge of the current kept
graph). Dual of Kruskal.

### Pseudocode (Kruskal as reference)

```text
function Kruskal(G):
    F := ∅
    for each v in G.Vertices:
        MAKE-SET(v)
    for each {u, v} in G.Edges ordered by increasing weight:
        if FIND-SET(u) ≠ FIND-SET(v):
            F := F ∪ {{u, v}}
            UNION(u, v)
    return F
```

### Example

Vertices $\{1,2,3,4\}$ with undirected edges
$\{1,2\}:1$, $\{1,3\}:4$, $\{2,3\}:2$, $\{2,4\}:5$, $\{3,4\}:3$:

- MST edges $\{1,2\},\{2,3\},\{3,4\}$ with total weight $1+2+3=6$.
- Kruskal, Prim, Borůvka, and reverse-delete all report
  `Total_Weight = 6` and `Tree_Count = 3`.

### Asymptotic cost (survey sheet)

$$
\begin{align*}
\text{Kruskal (educational)} &\colon O(E^{2}+E\,\alpha(V)) \\
\text{Prim (dense)} &\colon O(V^{2}+VE) \\
\text{Borůvka} &\colon O(E\log V) \\
\text{Reverse-delete} &\colon O(E^{2}\alpha(V))
\end{align*}
$$

Graph storage is $O(V+E)$ in fixed arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (Kruskal, educational) | $O(E^{2})$ sort + $O(E\,\alpha(V))$ merges |
| Time (Prim, dense multi-start) | $O(V^{2}+VE)$ |
| Time (Borůvka) | $O(E\log V)$ |
| Time (Reverse-delete) | $O(E^{2}\alpha(V))$ |
| Auxiliary space | $O(V+E)$ Union–Find / keys / index permutation |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ undirected edges (parallels allowed) |
| Weights | Non-negative integers; negatives raise `Invalid_Argument` |
| Output | Kept edges + total weight (MST or MSF); four methods agree |

## Features

- **`Clear` / `Add_Edge`** — shared undirected weighted graph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Kruskal`** — sort + Union–Find MST / MSF.
- **`Prim`** — dense multi-start Prim MST / MSF.
- **`Boruvka`** — phased cheapest-outgoing MST / MSF.
- **`Reverse_Delete`** — dual delete-heavy-non-bridges MST / MSF.
- **Capacity / weight guards** — `Invalid_Argument` for bad ids, overflow, negative weights, or insufficient `Tree_Edges` bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pminimum_spanning_tree.gpr`.

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

(Exact `NN` is the current suite size; it is at least 200.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph; single vertex; edgeless multi-vertex (MSF of $0$ edges)
- Unique-weight MST examples with known total weight and edge count
- Forests / disconnected graphs (MSF)
- Self-loops ignored; parallel edges; zero-weight edges
- Cross-agreement of Kruskal / Prim / Borůvka / Reverse-delete on total weight and edge count
- Stars, paths, cycles, complete small graphs $K_3$, $K_4$, $K_5$
- Grids, bridged components, duplicate-weight alternate optima
- Clear / rebuild; API counters; exact buffer sizing
- `Invalid_Argument` for capacity, range, negative weights, buffer bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Minimum_Spanning_Tree is
   Max_Vertices : constant Positive := 512;
   Max_Edges    : constant Positive := 20_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range 0 .. 2**31 - 1;
   type Weight_Sum is range 0 .. 2**63 - 1;

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

   procedure Kruskal
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Prim
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Boruvka
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Reverse_Delete
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);
end Minimum_Spanning_Tree;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, negative `Weight`, or `Tree_Edges` with `First /= 1`
or `Last < Edge_Count(G)` when $M>0$.

Weight policy: **non-negative integers only**; `Add_Edge` rejects
`Weight < 0`. Zero weights are allowed. The graph is **undirected**: each
`Add_Edge` stores one undirected edge. Parallel edges and self-loops are
accepted; self-loops never appear in the MST / MSF.

## License

Educational reference implementation. See repository `LICENSE` if present.
