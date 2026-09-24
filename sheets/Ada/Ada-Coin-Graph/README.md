# Coin Graphs in Ada 2023

## Project Overview

A **circle packing** is a finite collection of disks in the plane whose
**interiors are pairwise disjoint** (touching is allowed). The
**coin graph** (also called the **contact graph** or **intersection
graph** of the packing) has one vertex per disk and an undirected edge
whenever two disks are **externally tangent**.

Coin graphs are always simple and planar. The **Koebe–Andreev–Thurston
circle packing theorem** states the converse: every finite connected
simple planar graph $G$ is the coin graph of some circle packing in the
plane. Unit-disk special cases are called **penny graphs**.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational sheet
that stores a disk packing with **integer centers and radii** (for
reproducible classroom tests), checks packing validity, tests external
tangency with a fixed `Long_Float` tolerance $\varepsilon$, and
**extracts the contact graph**. It does **not** construct a packing
from an abstract planar graph (that is a harder numerical / combinatorial
problem); an optional equal-radius lattice helper builds simple penny
grids.

Primary sources:

- [Wikipedia — Circle packing theorem](https://en.wikipedia.org/wiki/Circle_packing_theorem)
- [Wikipedia — Coin graph](https://en.wikipedia.org/wiki/Coin_graph)

Part of the **RobertBoettcherSF** Ada algorithm series.

## Koebe–Andreev–Thurston (circle packing theorem)

$$
\begin{align*}
\text{coin graph of a packing} &\Rightarrow \text{connected simple planar}, \\
\text{finite connected simple planar } G &\Rightarrow \exists\text{ packing with coin graph }\cong G.
\end{align*}
$$

A stronger primal–dual form produces mutually orthogonal circle packings
for a polyhedral graph and its dual. This sheet only implements the
**forward** direction: disks $\to$ contact edges.

## Definition used here

Disks $C_i=(x_i,y_i,r_i)$ with $r_i>0$. Euclidean center distance:

$$
d(i,j)=\sqrt{(x_i-x_j)^{2}+(y_i-y_j)^{2}}.
$$

With absolute tolerance $\varepsilon=10^{-6}$:

$$
\begin{align*}
\text{interiors overlap} &\iff d(i,j)+\varepsilon < r_i+r_j, \\
\text{externally tangent (contact)} &\iff \lvert d(i,j)-(r_i+r_j)\rvert\le\varepsilon, \\
\text{valid packing} &\iff \text{no pair overlaps interiors}.
\end{align*}
$$

The contact graph $H$ has $V(H)=\{1..N\}$ and

$$
\{i,j\}\in E(H)\iff C_i\text{ and }C_j\text{ are externally tangent}.
$$

Internal (nested) tangency $d=\lvert r_i-r_j\rvert$ is **not** a coin
edge: the smaller disk lies in the interior of the larger one, so the
packing is invalid under the disjoint-interiors rule.

## Hand-checked examples

**Two unit coins** at $(0,0)$ and $(2,0)$: $d=2=1+1$ → one contact
edge; packing valid.

**Separated** at $(0,0)$ and $(10,0)$ with $r=1$: no edge; valid.

**Overlapping** at $(0,0)$ and $(1,0)$ with $r=2$: invalid packing; no
contact edge.

**Mutual triangle** $(0,0,5)$, $(10,0,5)$, $(5,12,8)$: distances
$10$, $13$, $13$ equal the radius sums → $K_3$ contact graph.

**Equal-radius $m\times n$ grid** with spacing $2r$: axis-adjacent coins
are tangent; diagonals are not ($d=2r\sqrt{2}\neq 2r$).

## Contrast with siblings (README only)

| Package | Domain | Idea |
| --- | --- | --- |
| **This package** (`Ada-Coin-Graph`) | Disks → contact graph | Tangency extraction / packing validity |
| Force-Based Algorithms | Abstract graph → 2-D layout | Spring / charge drawing |
| Euclidean Minimum Spanning Tree | Point set → tree | Complete geometric graph + Prim / Kruskal |
| Delaunay Triangulation | Point set → triangulation | Empty-circumcircle faces |

README links only — **no** package `with` of siblings.

## Algorithm sketch

```text
function Build_Contact_Graph(Packing P):
    Edges := ∅
    for i := 1 .. N-1:
        for j := i+1 .. N:
            if |dist(C_i, C_j) - (r_i + r_j)| ≤ ε:
                append {i,j} to Edges
    return Edges
```

Educational cost $O(N^{2})$ distance checks, $N\le\mathrm{Max\_Circles}=256$.

### Pseudocode (validity)

```text
function Is_Valid_Packing(P):
    for i := 1 .. N-1:
        for j := i+1 .. N:
            if dist(C_i, C_j) + ε < r_i + r_j:
                return False
    return True
```

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Build_Contact_Graph` / `Is_Valid_Packing`) | $O(N^{2})$ |
| Storage | $O(N)$ disks + caller edge buffer up to $\binom{N}{2}$ |
| Circle indices | $1 .. N$ with $N \le \mathrm{Max\_Circles}$ |
| Coordinates / radii | Integer; distance via `Long_Float` + $\varepsilon$ |
| Bad radius / overflow | `Invalid_Argument` |

## Features

- **`Clear` / `Add_Circle` / `Circle_Count` / `Get_Circle`** — integer disk packing.
- **`Euclidean_Distance` / `Sum_Of_Radii` / `Are_Externally_Tangent` / `Interiors_Overlap`** — geometry helpers.
- **`Is_Valid_Packing`** — interiors pairwise disjoint (touching allowed).
- **`Are_Tangent(I,J)`** — external tangency query on stored indices.
- **`Build_Contact_Graph` / `Contact_Edges`** — extract undirected contact edges ($U<V$).
- **`Add_Equal_Radius_Grid`** — optional $Rows\times Cols$ penny lattice helper.
- **Capacity / arity guards** — `Invalid_Argument` for $r\le 0$, overflow, bad indices, insufficient edge buffer.
- **Educational layout** — 1-based indices; fixed arrays; zero dynamic heap.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pcoin_graph.gpr`.

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

=== 1. Empty packing / Clear / Circle_Count ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Two touching disks → one edge; separated → none
- Overlapping interiors → invalid packing
- Triangle of mutually tangent coins ($K_3$)
- Equal-radius grids (penny lattices) and path / star / square patterns
- Internal (nested) tangency rejected as a coin edge
- Geometry helpers (3-4-5, sums, overlap)
- `Invalid_Argument` for bad radii, capacity, indices, buffer bounds
- `Build_Contact_Graph` / `Contact_Edges` synonym agreement

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Coin_Graph is
   Max_Circles : constant Positive := 256;
   Max_Edges   : constant Positive := Max_Circles * (Max_Circles - 1) / 2;
   Epsilon     : constant Long_Float := 1.0E-6;

   type Circle is record
      X, Y : Integer := 0;
      R    : Integer := 1;
   end record;
   type Circle_Index is range 1 .. Max_Circles;

   type Edge_Record is record
      U, V : Circle_Index;
   end record;
   type Edge_List is array (Positive range <>) of Edge_Record;

   type Packing is limited private;
   Invalid_Argument : exception;

   procedure Clear (P : in out Packing);
   procedure Add_Circle (P : in out Packing; C : Circle);
   function Circle_Count (P : Packing) return Natural;
   function Get_Circle (P : Packing; Index : Circle_Index) return Circle;

   function Euclidean_Distance (A, B : Circle) return Long_Float;
   function Sum_Of_Radii (A, B : Circle) return Long_Float;
   function Are_Externally_Tangent (A, B : Circle) return Boolean;
   function Interiors_Overlap (A, B : Circle) return Boolean;

   function Is_Valid_Packing (P : Packing) return Boolean;
   function Are_Tangent (P : Packing; I, J : Circle_Index) return Boolean;

   procedure Build_Contact_Graph
     (P : Packing; Edges : in out Edge_List; Count : out Natural);
   procedure Contact_Edges
     (P : Packing; Edges : in out Edge_List; Count : out Natural);

   procedure Add_Equal_Radius_Grid
     (P : in out Packing; Rows, Cols, Radius : Positive;
      Origin_X : Integer := 0; Origin_Y : Integer := 0);
end Coin_Graph;
```

Raises `Invalid_Argument` when `Add_Circle` has $r\le 0$ or would exceed
`Max_Circles`, when `Get_Circle` / `Are_Tangent` indices are out of range
(or $I=J$ for `Are_Tangent`), when `Build_Contact_Graph` /
`Contact_Edges` have `Edges'First /= 1` or insufficient `Last`
($\ge N(N-1)/2$ for $N\ge 2$), or when `Add_Equal_Radius_Grid` would
overflow capacity.

## License

Educational reference implementation. See repository `LICENSE` if present.
