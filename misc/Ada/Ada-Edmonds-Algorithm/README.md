# Edmonds' Algorithm (Chu–Liu/Edmonds) in Ada 2023

## Project Overview

**Edmonds' algorithm** (also called the **Chu–Liu/Edmonds algorithm**)
computes a **minimum spanning arborescence** — a directed spanning tree of
minimum total weight rooted at a distinguished vertex $r$ — of a
**directed weighted graph**. It is the directed analogue of the minimum
spanning tree problem. The method was proposed independently by
Yoeng-Jin Chu and Tseng-Hong Liu (1965) and by Jack Edmonds (1967).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, a directed edge list in fixed
arrays (no dynamic heap beyond stack-sized / package-body scratch
workspaces), integer weights that **may be negative**, Chu–Liu/Edmonds
via recursive cycle contraction with weight adjustment, and an optional
in-package `Brute_Minimum_Arborescence` oracle for $N\le 8$ cross-checks.

Primary source:
[Wikipedia — Edmonds' algorithm](https://en.wikipedia.org/wiki/Edmonds%27_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with undirected MST

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Edmonds-Algorithm`) | Directed edges; fix root $r$; cheapest **incoming** edge per non-root; contract cycles; adjust $w'(u,v_C)=w(u,v)-w(\pi(v),v)$; expand |
| Undirected MST (Kruskal / Prim siblings) | Undirected edges; no distinguished root; Union–Find add or grow from a seed |

README links only — **no** package `with` of siblings. An undirected MST
and a rooted arborescence are different objects: reversing all arcs of an
arborescence yields a branching **into** the root in some presentations;
this sheet follows the standard Chu–Liu/Edmonds form with **incoming**
selection toward each non-root (edges oriented away from the root in the
returned tree).

## Algorithm

### Chu–Liu / Edmonds (contract cycles)

Given a digraph $D=\langle V,E\rangle$, root $r\in V$, and weights $w(e)$
(any integers; negatives allowed):

1. Discard every edge whose head is $r$ (and ignore self-loops). Optionally
   replace parallel arcs by the cheapest in each direction.
2. For each $v\in V\setminus\{r\}$, let $\pi(v)$ be a cheapest incoming
   edge; write
   $P=\{(\pi(v),v)\mid v\in V\setminus\{r\}\}$.
3. If $P$ contains no directed cycle, return $P$ (it is a minimum spanning
   arborescence).
4. Otherwise pick a cycle $C\subseteq P$. Contract $C$ to a supernode
   $v_C$. For every edge $(u,v)$ with $u\notin C$, $v\in C$, define
   $$
   w'(u,v_C)=w(u,v)-w(\pi(v),v).
   $$
   Edges leaving $C$ or avoiding $C$ keep their weights (mapped through
   the contraction).
5. Recursively compute a minimum arborescence $A'$ of the contracted
   digraph. Expand: restore $C$ minus the unique cycle edge whose head is
   the entry point of the unique $A'$ edge into $v_C$.

### Pseudocode

```text
function Edmonds(D, r, w):
    remove edges into r; ignore self-loops
    for each v ≠ r:
        π(v) := cheapest incoming edge to v
        if none: return IMPOSSIBLE
    P := {(π(v), v) | v ≠ r}
    if P is acyclic:
        return P
    C := a directed cycle in P
    D', w' := contract C to v_C with adjusted incoming weights
    A' := Edmonds(D', image(r), w')
    return expand(A', C, π)
```

### Example

Vertices $\{1,2,3,4\}$ with root $r=1$ and directed edges
$(1,2):3$, $(1,3):10$, $(2,3):2$, $(3,2):1$, $(2,4):5$, $(3,4):4$:

- Cheapest incoming: $2\leftarrow 3$ (weight $1$), $3\leftarrow 2$
  (weight $2$), $4\leftarrow 3$ (weight $4$) — but $\{2,3\}$ forms a
  cycle, so contract and adjust.
- After contraction / expansion the unique minimum arborescence has
  edges $(1,2)$, $(2,3)$, $(3,4)$ with total weight $3+2+4=9$.

### Asymptotic cost

With educational recursive contraction over an edge list:

$$
O(VE)
$$

in the typical implementation (each of up to $V$ contractions rescans the
edges). Faster realizations (e.g. Tarjan) exist; this sheet prioritises
clarity. Graph storage is $O(V+E)$ in fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (educational contraction) | $O(VE)$ typical |
| Auxiliary space | $O(V+E)$ package-body scratch levels |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Weights | Integers in $\mathrm{Weight\_Type}$ (negatives allowed) |
| Output | Kept directed edges + total weight, or Impossible |

## Features

- **`Clear` / `Add_Edge`** — build a directed weighted graph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Minimum_Arborescence` / `Edmonds`** — Chu–Liu/Edmonds with `Run_Status`
  (`Success` / `Impossible`); raising overload throws
  `Impossible_Arborescence`.
- **`Brute_Minimum_Arborescence`** — exact oracle for $N\le 8$.
- **Capacity / range guards** — `Invalid_Argument` for bad ids, overflow,
  weight range, or insufficient `Tree_Edges` bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pedmonds_algorithm.gpr`.

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

=== 1. Single vertex / trivial ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Single-vertex and two-vertex digraphs
- Stars, paths, complete small digraphs
- Cycle contraction and nested contractions
- Negative weights; zero weights; weight extremes
- Impossible graphs (missing in-edges / unreachable vertices)
- Self-loops ignored; parallel arcs; edges into the root discarded
- Agreement with `Brute_Minimum_Arborescence` on $N\le 8$
- `Invalid_Argument` for capacity, range, buffer bounds
- Raising `Impossible_Arborescence` overload

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Edmonds_Algorithm is
   Max_Vertices       : constant Positive := 256;
   Max_Edges          : constant Positive := 10_000;
   Brute_Max_Vertices : constant Positive := 8;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range -(2**30) .. 2**30 - 1;
   type Weight_Sum is range -(2**62) .. 2**62 - 1;

   type Edge_Record is record
      From, To : Vertex_Id;
      Weight   : Weight_Type;
   end record;
   type Edge_List is array (Positive range <>) of Edge_Record;

   type Run_Status is (Success, Impossible);
   type Graph is limited private;

   Invalid_Argument        : exception;
   Impossible_Arborescence : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status);

   procedure Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Edmonds
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status);

   procedure Brute_Minimum_Arborescence
     (G            : Graph;
      Root         : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum;
      Status       : out Run_Status);
end Edmonds_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Weight` outside `Weight_Type`, `Root` outside $1 .. N$,
$N=0$ on search APIs, or `Tree_Edges` with `First /= 1` or
`Last < N-1` when $N>0$.

Weight policy: **integers may be negative** (Chu–Liu/Edmonds admits
arbitrary real weights). The graph is **directed**: each `Add_Edge`
stores one arc $\mathrm{From}\to\mathrm{To}$. Parallel arcs and
self-loops are accepted; self-loops and arcs into the root never appear
in the returned arborescence.

## License

Educational reference implementation. See repository `LICENSE` if present.
