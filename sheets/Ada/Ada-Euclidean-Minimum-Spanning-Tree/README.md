# Euclidean Minimum Spanning Tree in Ada 2023

## Project Overview

A **Euclidean minimum spanning tree (EMST)** of a finite set of points in
the Euclidean plane connects the points by line segments that use only
those points as endpoints, form a tree, and have the **minimum possible
total length**. Equivalently, it is a minimum spanning tree of the
**complete graph** on the points with edge weights equal to Euclidean
distances.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational sheet for
2-D point sets with **integer coordinates** and **rounded Euclidean**
edge lengths $\mathrm{round}(\sqrt{\Delta x^{2}+\Delta y^{2}})$ for
reproducible classroom tests. It builds the complete geometric graph in
fixed arrays (up to $\mathrm{Max\_Points}=256$) and runs self-contained
**dense Prim** and **Kruskal** (no `with` of abstract MST siblings).

Primary source:
[Wikipedia — Euclidean minimum spanning tree](https://en.wikipedia.org/wiki/Euclidean_minimum_spanning_tree).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with abstract MST siblings

| Package | Domain | Idea |
| --- | --- | --- |
| **This package** (`Ada-Euclidean-Minimum-Spanning-Tree`) | 2-D point set → EMST | Complete geometric graph + Prim / Kruskal |
| Minimum Spanning Tree (sibling sheet) | Abstract undirected weighted graph | Survey: Kruskal + Prim + Borůvka + Reverse-delete |
| Prim (sibling sheet) | Abstract undirected weighted graph | Dedicated dense Prim (seeded / forest) |
| Kruskal (sibling sheet) | Abstract undirected weighted graph | Dedicated sort + Union–Find MST / MSF |

README links only — **no** package `with` of siblings. Abstract MST
packages take an explicit edge list; this sheet **owns** the geometry
(`Add_Point`) and derives all $\binom{N}{2}$ distances internally.

## Delaunay relationship

Every EMST edge is an edge of the **Delaunay triangulation** of the same
point set: the EMST is always a subgraph of the Delaunay graph. Therefore
one may compute a Delaunay triangulation in $O(N\log N)$ time and then
run a graph MST algorithm on that sparse graph, obtaining an EMST in
$O(N\log N)$ overall — optimal in some models of computation.

This educational sheet **does not** implement Delaunay (see sibling
`Ada-Delaunay-Triangulation`). It uses the simpler complete-graph
approach, which is $O(N^{2})$ in time and storage and is ideal for small
classroom instances ($N\le 256$).

## When to use which method (inside this sheet)

$$
\begin{align*}
\text{primary API (Compute / EMST)} &\Rightarrow \textbf{dense Prim on } K_N \\
\text{cross-check / alternate optima} &\Rightarrow \textbf{Kruskal on } K_N
\end{align*}
$$

Both methods agree on `Total_Length` and edge count $N-1$ for every
input; when equal rounded lengths create alternate optima the kept
**edge sets** may differ.

## Algorithm sketches

### Definition

Given points $P=\{p_1,\ldots,p_N\}\subset\mathbb{R}^{2}$:

$$
\mathrm{EMST}(P)=\arg\min_{T\text{ tree on }P}\sum_{\{u,v\}\in T}\|p_u-p_v\|_{2}.
$$

In this package distances are replaced by the rounded integer length

$$
w(u,v)=\mathrm{round}\bigl(\sqrt{(x_u-x_v)^{2}+(y_u-y_v)^{2}}\bigr).
$$

### Dense Prim on $K_N$

1. Seed at point $1$: $\mathrm{Key}(1)\leftarrow 0$, $\mathrm{Key}(v)\leftarrow\infty$.
2. While unsettled vertices remain: settle $u=\arg\min \mathrm{Key}$; for
   each unsettled $v$ set $\mathrm{Key}(v)\leftarrow\min(\mathrm{Key}(v),w(u,v))$.
3. Emit parent edges; total length is $\sum \mathrm{Key}(v)$ over non-roots.

Educational cost $O(N^{2})$ — natural for the dense complete graph.

### Kruskal on $K_N$

1. Materialize all $\binom{N}{2}$ edges with weights $w(u,v)$.
2. Sort ascending; Union–Find add when endpoints differ.
3. Stop after $N-1$ edges.

Educational cost $O(E^{2})$ with insertion sort, $E=\binom{N}{2}$.

### Pseudocode (Prim as reference)

```text
function EMST_Prim(Points):
    Key[1] := 0; Parent[1] := 0
    for v := 2 .. N: Key[v] := ∞
    unsettled := {1 .. N}
    while unsettled ≠ ∅:
        u := argmin_{v in unsettled} Key[v]
        remove u from unsettled
        for v in unsettled:
            d := RoundedEuclidean(Points[u], Points[v])
            if d < Key[v]:
                Key[v] := d; Parent[v] := u
    return edges {Parent[v], v} for v with Parent[v] ≠ 0
```

### Hand-checked examples

**Axis-aligned unit square** $\{(0,0),(1,0),(1,1),(0,1)\}$:
three sides of length $1$; total length $3$ (diagonal $\sqrt{2}\approx 1$
rounded is $1$, but any MST uses three unit sides).

**Collinear** $\{(0,0),(1,0),(2,0),(3,0)\}$: path of three unit edges;
total length $3$.

**3-4-5 right triangle** $\{(0,0),(3,0),(0,4)\}$: MST uses legs $3$ and
$4$ (not the hypotenuse $5$); total length $7$.

### Asymptotic cost

$$
\begin{align*}
\text{Prim (dense, this sheet)} &\colon O(N^{2}) \\
\text{Kruskal (educational sort)} &\colon O(E^{2}),\ E=\binom{N}{2} \\
\text{via Delaunay + graph MST (not implemented)} &\colon O(N\log N)
\end{align*}
$$

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (Prim, dense) | $O(N^{2})$ |
| Time (Kruskal, educational) | $O(E^{2})$ with $E=\binom{N}{2}$ |
| Auxiliary / graph storage | $O(N^{2})$ fixed arrays up to $\mathrm{Max\_Points}$ |
| Point indices | $1 .. N$ with $N \le \mathrm{Max\_Points}$ |
| Coordinates | Integer; rounded Euclidean lengths |
| Output | $N-1$ edges + `Total_Length`; Prim and Kruskal agree on length |
| Too few points | $N<2$ raises `Invalid_Argument` on Compute / EMST / Prim / Kruskal |

## Features

- **`Clear` / `Add_Point` / `Point_Count` / `Get_Point`** — 2-D integer point set.
- **`Rounded_Euclidean`** — $\mathrm{round}(\sqrt{\Delta x^{2}+\Delta y^{2}})$.
- **`Prim`** — dense Prim EMST on the complete geometric graph.
- **`Kruskal`** — Kruskal EMST (cross-check / alternate edge sets).
- **`Compute` / `EMST`** — primary API (aliases of Prim).
- **Capacity / arity guards** — `Invalid_Argument` for overflow, $N<2$, or insufficient `Tree_Edges` bounds.
- **Educational layout** — 1-based indices; fixed arrays; zero dynamic heap.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Peuclidean_minimum_spanning_tree.gpr`.

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

=== 1. Rounded Euclidean ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Rounded Euclidean unit cases (axis, diagonal, 3-4-5)
- Hand-checked square, collinear line, and triangle EMSTs
- Two-point trees; duplicate / coincident points
- Prim vs Kruskal agreement on `Total_Length` and edge count
- Stars, grids, regular polygons, random-ish clouds
- `Clear` / rebuild; API counters; `Get_Point`
- `Invalid_Argument` for capacity, too few points, buffer bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Euclidean_Minimum_Spanning_Tree is
   Max_Points : constant Positive := 256;
   Max_Edges  : constant Positive := Max_Points * (Max_Points - 1) / 2;

   type Point is record
      X, Y : Integer := 0;
   end record;
   type Point_Index is range 1 .. Max_Points;
   type Length_Type is range 0 .. 2**31 - 1;
   type Length_Sum  is range 0 .. 2**63 - 1;

   type Edge_Record is record
      U, V   : Point_Index;
      Length : Length_Type;
   end record;
   type Edge_List is array (Positive range <>) of Edge_Record;

   type Point_Set is limited private;
   Invalid_Argument : exception;

   procedure Clear (S : in out Point_Set);
   procedure Add_Point (S : in out Point_Set; P : Point);
   function Point_Count (S : Point_Set) return Natural;
   function Get_Point (S : Point_Set; Index : Point_Index) return Point;
   function Rounded_Euclidean (A, B : Point) return Length_Type;

   procedure Prim
     (S : Point_Set; Tree_Edges : in out Edge_List;
      Tree_Count : out Natural; Total_Length : out Length_Sum);
   procedure Kruskal
     (S : Point_Set; Tree_Edges : in out Edge_List;
      Tree_Count : out Natural; Total_Length : out Length_Sum);
   procedure Compute
     (S : Point_Set; Tree_Edges : in out Edge_List;
      Tree_Count : out Natural; Total_Length : out Length_Sum);
   procedure EMST
     (S : Point_Set; Tree_Edges : in out Edge_List;
      Tree_Count : out Natural; Total_Length : out Length_Sum);
end Euclidean_Minimum_Spanning_Tree;
```

Raises `Invalid_Argument` when `Add_Point` would exceed `Max_Points`,
when `Get_Point` index is out of range, when $N<2$ on Prim / Kruskal /
Compute / EMST, or when `Tree_Edges` has `First /= 1` or
`Last < N-1`.

## License

Educational reference implementation. See repository `LICENSE` if present.
