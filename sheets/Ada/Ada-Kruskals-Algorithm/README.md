# Kruskal's Algorithm in Ada 2023

## Project Overview

**Kruskal's algorithm** computes a **minimum spanning tree (MST)** — or a
**minimum spanning forest (MSF)** when the input is disconnected — of an
**undirected weighted graph**. It sorts all edges by ascending weight and
greedily **adds** the next edge whenever its endpoints lie in different
components, using a **Union–Find** (disjoint-set) structure to detect
cycles. Joseph Kruskal published the method in 1956; it was rediscovered
soon afterward by Loberman & Weinberger (1957).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, an undirected edge list in
fixed arrays (no dynamic heap beyond stack-sized workspaces),
Union–Find with path compression and union-by-rank (package-body
private), non-negative integer weights, and an optional in-package
`Prim_Reference` for cross-checks on small graphs (self-contained —
no `with` of Prim / Reverse-delete sibling packages).

Primary source:
[Wikipedia — Kruskal's algorithm](https://en.wikipedia.org/wiki/Kruskal%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Prim / Reverse-delete / Borůvka

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Kruskals-Algorithm`) | Sort ascending; add an edge when endpoints lie in different components (Union–Find) |
| Prim (sibling sheet) | Grow a tree from a seed by repeatedly attaching the lightest edge leaving the tree; multi-start ⇒ MSF |
| Reverse-delete (sibling sheet) | Start with all edges; delete heavy edges that are not bridges of the kept graph |
| Borůvka (sibling sheet) | In phases, every component adds its lightest outgoing edge (contracts / merges) |

README links only — **no** package `with` of siblings. Kruskal, Prim
(forest form), reverse-delete, and Borůvka produce the same MST / MSF
**total weight** (and the same number of kept edges); when edge weights
are not unique the kept **edge sets** may differ among alternate optima.

## Algorithm

### Kruskal (sort + Union–Find)

Given an undirected graph $G=(V,E)$ with edge weights $w(e)\ge 0$:

1. Create a forest of $|V|$ single-vertex trees: for each $v\in V$,
   $\mathrm{Make\textrm{-}Set}(v)$.
2. Sort the edges so that $w(e_1)\le w(e_2)\le\cdots\le w(e_m)$ (ties
   broken by insertion index).
3. For each $e=\{u,v\}$ in that order:
   - If $\mathrm{Find}(u)\ne\mathrm{Find}(v)$, keep $e$ and
     $\mathrm{Union}(u,v)$.
4. The kept edges form an MST when $G$ is connected, otherwise an MSF.

Self-loops are never kept ($\mathrm{Find}(u)=\mathrm{Find}(v)$);
parallel edges compete by weight. Running time is dominated by sorting.

### Pseudocode

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

- Ascending order considers weights $1,2,3,4,5$.
- Keep $\{1,2\}$ (weight $1$), $\{2,3\}$ (weight $2$), $\{3,4\}$
  (weight $3$); reject $\{1,3\}$ and $\{2,4\}$ (same component).
- Edges $\{1,2\},\{2,3\},\{3,4\}$ form the unique MST of total weight
  $1+2+3=6$.

### Asymptotic cost

With educational insertion sort and Union–Find:

$$
O(E^{2} + E\,\alpha(V))
$$

which simplifies to $O(E^{2})$ for the sort-dominated educational build.
With a comparison sort the classic bound is $O(E\log E)$ (equivalently
$O(E\log V)$ when there are no isolated vertices). Graph storage is
$O(V+E)$ in fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (educational Kruskal) | $O(E^{2})$ sort + $O(E\,\alpha(V))$ merges (insertion sort) |
| Time (classic, comparison sort) | $O(E\log E)$ or $O(E\log V)$ |
| Time (Prim reference, in-package) | $O(V^{2}+VE)$ educational edge-list scan |
| Auxiliary space | $O(V+E)$ Union–Find / index permutation |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ undirected edges (parallels allowed) |
| Weights | Non-negative integers; negatives raise `Invalid_Argument` |
| Output | Kept edges + total weight (MST or MSF) |

## Features

- **`Clear` / `Add_Edge`** — build an undirected weighted graph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Minimum_Spanning_Tree` / `Kruskal`** — MST / MSF via Kruskal (alias pair).
- **`Prim_Reference`** — in-package multi-start Prim for agreement checks on small graphs.
- **Union–Find** — path compression + union-by-rank (package-body private).
- **Capacity / weight guards** — `Invalid_Argument` for bad ids, overflow, negative weights, or insufficient `Tree_Edges` bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pkruskals_algorithm.gpr`.

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

- Empty graph; single vertex; edgeless multi-vertex (MSF of $0$ edges)
- Unique-weight MST examples with known total weight and edge count
- Forests / disconnected graphs (MSF)
- Self-loops ignored; parallel edges; zero-weight edges
- Agreement with `Prim_Reference` on total weight and edge count
- Stars, paths, cycles, complete small graphs $K_3$, $K_4$
- Clear / rebuild; API counters
- `Invalid_Argument` for capacity, range, negative weights, buffer bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Kruskals_Algorithm is
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

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Kruskal
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Prim_Reference
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);
end Kruskals_Algorithm;
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
