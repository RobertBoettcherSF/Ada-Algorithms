# Borůvka's Algorithm in Ada 2023

## Project Overview

**Borůvka's algorithm** (also Sollin's algorithm) computes a **minimum
spanning tree (MST)** — or a **minimum spanning forest (MSF)** when the
input is disconnected — of an **undirected weighted graph**. In successive
**phases**, every current component selects its **cheapest outgoing
edge**; those edges are added and components are **contracted / unioned**.
Each phase at most halves the number of trees inside a connected piece,
so $O(\log V)$ phases suffice. Otakar Borůvka published the method in
1926 for an electricity network in Moravia; it was rediscovered by
Choquet (1938), Florek et al. (1951), and Georges Sollin (1965).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, an undirected edge list in
fixed arrays (no dynamic heap beyond stack-sized workspaces),
Union–Find with path compression and union-by-rank (package-body
private), non-negative integer weights, deterministic tie-breaking on
equal weights (smaller endpoint ids, then insertion index), and an
optional in-package `Kruskal_Reference` for cross-checks on small graphs
(self-contained — no `with` of Kruskal / Prim / Reverse-delete sibling
packages).

Primary source:
[Wikipedia — Borůvka's algorithm](https://en.wikipedia.org/wiki/Bor%C5%AFvka%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Prim / Kruskal / Reverse-delete

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Boruvkas-Algorithm`) | In phases, every component adds its lightest outgoing edge (contracts / merges) |
| Prim (sibling sheet) | Grow a tree from a seed by repeatedly attaching the lightest edge leaving the tree; multi-start ⇒ MSF |
| Kruskal (sibling sheet) | Sort ascending; add an edge when endpoints lie in different components (Union–Find) |
| Reverse-delete (sibling sheet) | Start with all edges; delete heavy edges that are not bridges of the kept graph |

README links only — **no** package `with` of siblings. Borůvka, Kruskal,
Prim (forest form), and reverse-delete produce the same MST / MSF
**total weight** (and the same number of kept edges); when edge weights
are not unique the kept **edge sets** may differ among alternate optima.

## Algorithm

### Borůvka (phased cheapest-outgoing merges)

Given an undirected graph $G=(V,E)$ with edge weights $w(e)\ge 0$:

1. Initialize a forest $F$ of $|V|$ single-vertex components:
   $\mathrm{Make\textrm{-}Set}(v)$ for each $v\in V$.
2. Repeat until no merges remain:
   - For each component $C$, find a cheapest edge leaving $C$ (or
     $\mathrm{None}$ if $C$ is already a whole connected piece).
   - Preference: smaller $w$; on ties smaller $\min(u,v)$; then smaller
     $\max(u,v)$; then smaller insertion index (deterministic — avoids
     equal-weight cycles).
   - If every component has $\mathrm{None}$, halt.
   - Otherwise $\mathrm{Union}$ along each selected edge that still joins
     distinct components, and keep those edges in $F$.
3. The kept edges form an MST when $G$ is connected, otherwise an MSF.

Self-loops are never selected; parallel edges compete by weight (and
tie-break). Running time is $O(E\log V)$ with an $O(E)$ scan per phase.

### Pseudocode

```text
function Boruvka(G):
    F := empty
    for each v in G.Vertices:
        MAKE-SET(v)
    completed := false
    while not completed:
        cheapest[C] := None for each component C of F
        for each edge {u, v} with FIND(u) != FIND(v):
            if preferred({u,v}, cheapest[FIND(u)]):
                cheapest[FIND(u)] := {u, v}
            if preferred({u,v}, cheapest[FIND(v)]):
                cheapest[FIND(v)] := {u, v}
        if all cheapest are None:
            completed := true
        else:
            for each component C with cheapest[C] != None:
                e := cheapest[C]
                if FIND(e.u) != FIND(e.v):
                    F := F union {e}
                    UNION(e.u, e.v)
    return F
```

### Example

Vertices $\{1,2,3,4\}$ with undirected edges
$\{1,2\}:1$, $\{1,3\}:4$, $\{2,3\}:2$, $\{2,4\}:5$, $\{3,4\}:3$:

- **Phase 1:** component $1$ picks $\{1,2\}$ (weight $1$); $2$ picks
  $\{1,2\}$; $3$ picks $\{2,3\}$ (weight $2$); $4$ picks $\{3,4\}$
  (weight $3$). Keep $\{1,2\}$, $\{2,3\}$, $\{3,4\}$ (duplicate
  $\{1,2\}$ once). All four vertices merge into one tree.
- **Phase 2:** no outgoing edges remain → halt.
- Edges $\{1,2\},\{2,3\},\{3,4\}$ form the unique MST of total weight
  $1+2+3=6$.

### Asymptotic cost

With an educational full edge-list scan each phase and Union–Find:

$$
O(E\log V)
$$

($O(\log V)$ phases, $O(E\,\alpha(V))$ work per phase dominated by the
$O(E)$ scan). Classic comparison-sort Kruskal is $O(E\log E)$; dense
Prim is $O(V^{2}+E)$. Graph storage is $O(V+E)$ in fixed educational
arrays up to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (educational Borůvka) | $O(E\log V)$ phases × edge-list scan |
| Time (Kruskal reference, in-package) | $O(E^{2})$ sort + $O(E\,\alpha(V))$ merges (insertion sort) |
| Auxiliary space | $O(V+E)$ Union–Find / cheapest-edge table |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ undirected edges (parallels allowed) |
| Weights | Non-negative integers; negatives raise `Invalid_Argument` |
| Output | Kept edges + total weight (MST or MSF) |

## Features

- **`Clear` / `Add_Edge`** — build an undirected weighted graph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Minimum_Spanning_Tree` / `Boruvka`** — MST / MSF via Borůvka (alias pair).
- **`Kruskal_Reference`** — in-package Kruskal for agreement checks on small graphs.
- **Union–Find** — path compression + union-by-rank (package-body private).
- **Deterministic ties** — equal weights broken by endpoint ids / insertion index.
- **Capacity / weight guards** — `Invalid_Argument` for bad ids, overflow, negative weights, or insufficient `Tree_Edges` bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pboruvkas_algorithm.gpr`.

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
- Equal-weight triangles (tie-break ⇒ no cycle)
- Agreement with `Kruskal_Reference` on total weight and edge count
- Stars, paths, cycles, complete small graphs $K_3$, $K_4$
- Multi-phase merges on longer paths
- Clear / rebuild; API counters
- `Invalid_Argument` for capacity, range, negative weights, buffer bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Boruvkas_Algorithm is
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

   procedure Boruvka
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);

   procedure Kruskal_Reference
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum);
end Boruvkas_Algorithm;
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
