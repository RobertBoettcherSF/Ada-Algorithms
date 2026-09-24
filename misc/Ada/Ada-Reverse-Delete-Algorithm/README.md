# Reverse-Delete Algorithm in Ada 2023

## Project Overview

The **reverse-delete algorithm** computes a **minimum spanning tree (MST)**
— or a **minimum spanning forest (MSF)** when the input is disconnected —
of an **undirected weighted graph**. It starts with the full edge set and
considers edges in **decreasing** weight order, **deleting** an edge
whenever its endpoints remain connected through other surviving edges.
The method is the reverse of Kruskal’s approach (which *adds* light edges
while avoiding cycles). Joseph Kruskal described the dual idea alongside
his additive algorithm; reverse-delete is a standard textbook presentation
of “delete heavy bridges-last” MST construction.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, an undirected edge list in
fixed arrays (no dynamic heap beyond stack-sized workspaces),
Union–Find connectivity checks, non-negative integer weights, and an
optional in-package `Kruskal_Reference` for cross-checks on small graphs
(self-contained — no `with` of Prim / Kruskal sibling packages).

Primary source:
[Wikipedia — Reverse-delete algorithm](https://en.wikipedia.org/wiki/Reverse-delete_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Kruskal / Prim

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Reverse-Delete-Algorithm`) | Start with all edges; delete heavy edges that are not bridges of the kept graph |
| Kruskal (sibling sheet) | Sort ascending; add an edge when endpoints lie in different components (Union–Find) |
| Prim (sibling sheet) | Grow a tree from a seed by repeatedly attaching the lightest edge leaving the tree |

README links only — **no** package `with` of siblings. Reverse-delete and
Kruskal produce the same MST / MSF **total weight** (and the same number
of kept edges); when edge weights are not unique the kept **edge sets**
may differ among alternate optima. Prim grows one tree per component when
restarted, matching the MSF weight as well.

## Algorithm

### Reverse-delete

Given an undirected graph $G=(V,E)$ with edge weights $w(e)\ge 0$:

1. Mark every edge in $E$ as **kept**.
2. Sort the edges so that $w(e_1)\ge w(e_2)\ge\cdots\ge w(e_m)$ (ties broken
   by insertion index).
3. For each $e=\{u,v\}$ in that order:
   - Tentatively un-keep $e$.
   - If $u$ and $v$ remain in the same connected component of the kept
     subgraph, leave $e$ deleted; otherwise restore $e$ (it is a bridge of
     the current kept graph).
4. The surviving kept edges form an MST when $G$ is connected, otherwise
   an MSF.

Connectivity after a tentative deletion is tested by rebuilding a
Union–Find structure on the kept edges (equivalently DFS / BFS from $u$).
Self-loops are always deleted; parallel edges compete by weight.

### Example

Vertices $\{1,2,3,4\}$ with undirected edges
$\{1,2\}:1$, $\{1,3\}:4$, $\{2,3\}:2$, $\{2,4\}:5$, $\{3,4\}:3$:

- Descending order considers weights $5,4,3,2,1$.
- $\{2,4\}$ (weight $5$) is deleted (path $2$–$3$–$4$ remains).
- $\{1,3\}$ (weight $4$) is deleted (path $1$–$2$–$3$ remains).
- Remaining edges $\{3,4\},\{2,3\},\{1,2\}$ form the unique MST of total
  weight $1+2+3=6$.

### Asymptotic cost

With a Union–Find rebuild per candidate edge (educational clarity):

$$
O(E^{2}\,\alpha(V))
$$

Graph storage is $O(V+E)$ in fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$. Faster reverse-delete
variants exist; this sheet favours a transparent $O(E^{2}\alpha(V))$ check.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (educational reverse-delete) | $O(E^{2}\,\alpha(V))$ |
| Time (Kruskal reference, in-package) | $O(E^{2})$ sort + $O(E\,\alpha(V))$ merges (insertion sort) |
| Auxiliary space | $O(V+E)$ kept flags / Union–Find / index permutation |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ undirected edges (parallels allowed) |
| Weights | Non-negative integers; negatives raise `Invalid_Argument` |
| Output | Kept edges + total weight (MST or MSF) |

## Features

- **`Clear` / `Add_Edge`** — build an undirected weighted graph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Minimum_Spanning_Tree` / `Reverse_Delete`** — MST / MSF via reverse-delete (alias pair).
- **`Kruskal_Reference`** — in-package Kruskal for agreement checks on small graphs.
- **Union–Find connectivity** — rebuild on kept edges after each tentative deletion.
- **Capacity / weight guards** — `Invalid_Argument` for bad ids, overflow, negative weights, or insufficient `Tree_Edges` bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Preverse_delete_algorithm.gpr`.

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
- Self-loops deleted; parallel edges; zero-weight edges
- Agreement with `Kruskal_Reference` on total weight and edge count
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
package Reverse_Delete_Algorithm is
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

   procedure Reverse_Delete
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Kruskal_Reference
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);
end Reverse_Delete_Algorithm;
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
