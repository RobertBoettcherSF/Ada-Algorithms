# Graph Coloring in Ada 2023

## Project Overview

**Graph coloring** (vertex coloring) assigns labels traditionally called
**colours** to the vertices of an undirected graph so that no two adjacent
vertices share a colour. The **chromatic number** $\chi(G)$ is the smallest
number of colours needed for a proper colouring of $G$. Colouring is
NP-hard in general; this package teaches the classical educational
algorithms: **greedy colouring** (including Welsh–Powell /
degree-descending order), **BFS 2-colouring** for bipartiteness, and
**exact** $\chi(G)$ by **backtracking** on tiny instances
($N\le\mathrm{Max\_Exact}$).

A proper $k$-colouring partitions $V$ into $k$ independent sets. Always

$$
1 \le \chi(G) \le n
$$

for a loopless graph on $n\ge 1$ vertices (edgeless graphs have
$\chi=1$; $\chi(K_n)=n$). Brooks’ theorem further bounds $\chi(G)$ by
$\Delta(G)$ except for complete graphs and odd cycles. Greedy colouring
uses at most $\Delta(G)+1$ colours but need not achieve $\chi(G)$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: undirected loopless graphs via `Add_Edge(U, V)`, vertices
indexed from $1$, colours as positive integers ($0$ = uncoloured), fixed
arrays (no dynamic heap), and `Invalid_Argument` for capacity / bound
errors.

Primary source:
[Wikipedia — Graph coloring](https://en.wikipedia.org/wiki/Graph_coloring).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with siblings

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Coloring-Algorithm`) | Vertex colouring: greedy, 2-colour / bipartite, exact $\chi$ |
| Backtracking (sibling sheet) | General search / prune framework |
| BFS (sibling sheet) | Level-order search; used here for 2-colouring |
| Hopcroft–Karp (sibling sheet) | Bipartite matching (related but distinct) |

README links only — **no** package `with` of siblings.

## Chromatic number

The chromatic number $\chi(G)$ is

$$
\chi(G)=\min\{k\in\mathbb{N}:G\text{ admits a proper }k\text{-colouring}\}.
$$

Useful facts implemented or checked in tests:

- $\chi(K_n)=n$ (complete graphs need $n$ colours)
- $\chi(G)=1$ iff $G$ has no edges ($n\ge 1$)
- $\chi(G)\le 2$ iff $G$ is bipartite (for loopless $G$; empty / edgeless
  included)
- Odd cycles: $\chi(C_{2k+1})=3$; even cycles: $\chi(C_{2k})=2$
- Greedy colouring yields a proper colouring with
  $\chi(G)\le\mathrm{greedy}(G)\le\Delta(G)+1$

### Example

Path $P_4$: vertices $\{1,2,3,4\}$, edges $1\!-\!2$, $2\!-\!3$, $3\!-\!4$.
Then $\chi(P_4)=2$ (colours $1,2,1,2$). Triangle $C_3=K_3$ has
$\chi=3$.

## Algorithm

### Greedy colouring

Process vertices in a fixed order. Assign each vertex the **smallest**
positive colour not used by an already-coloured neighbour.

- `Natural_Order`: vertices $1,2,\ldots,N$
- `Degree_Descending`: Welsh–Powell style — nonincreasing degree; ties
  broken by smaller vertex id

### Bipartite / 2-colour

BFS (or multi-source BFS over components) assigns colours $\{1,2\}$;
an odd cycle causes a conflict. `Is_Bipartite` and `Two_Color` share
this procedure.

### Exact $\chi$ (backtracking, $N\le 16$)

For $k=1,2,\ldots,U$ where $U$ is a greedy upper bound, try to extend a
partial colouring vertex by vertex, reusing colours $1..used$ and
opening a fresh colour when $used<k$. First feasible $k$ is $\chi(G)$.

### Pseudocode (greedy)

```text
function Greedy_Color(G, order):
    for each v in order:
        Colors[v] := smallest c ≥ 1 not used by a coloured neighbour of v
    return max Colors
```

### Asymptotic cost

| Routine | Time (typical) |
| --- | --- |
| `Greedy_Color` | $O(V+E)$ plus $O(V^{2})$ sort when degree-descending |
| `Two_Color` / `Is_Bipartite` | $O(V+E)$ |
| `Chromatic_Number_Exact` | exponential in $V$ (capped at $16$) |

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (greedy, natural) | $O(V+E)$ |
| Time (greedy, degree order) | $O(V^{2}+E)$ educational sort |
| Time (2-colour) | $O(V+E)$ |
| Time (exact) | exponential; $N\le\mathrm{Max\_Exact}=16$ |
| Auxiliary space | $O(V)$ colours / queue / order |
| Graph storage | $O(V+E)$ fixed arrays |
| Vertex indices | $1..N$ with $N\le\mathrm{Max\_Vertices}=512$ |
| Edge capacity | $\mathrm{Max\_Edges}=50000$ undirected edges |
| Exact cap | $N\le 16$ |
| Colours | positive integers; $0$ = uncoloured |

## Features

- **`Clear` / `Add_Edge`** — undirected loopless graphs ($N=0$ allowed).
- **`Vertex_Count` / `Edge_Count` / `Degree`** — inspectors.
- **`Greedy_Color`** — natural or degree-descending order.
- **`Is_Bipartite` / `Two_Color`** — BFS 2-colouring.
- **`Chromatic_Number_Exact`** — backtracking for $N\le 16$.
- **`Is_Proper_Coloring` / `Colors_Used`** — validation helpers.
- **Capacity / bound guards** — `Invalid_Argument` for overflow,
  self-loops, OOB ids, exact oversize, bad array bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to the
  caps above.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pcoloring_algorithm.gpr`.

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

=== 1. Empty / edgeless ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty $N=0$; edgeless graphs; single vertices
- Complete graphs $K_n$ need $n$ colours; greedy matches exact on $K_n$
- Paths, even/odd cycles; stars and trees (bipartite, $\chi=2$)
- Complete bipartite $K_{n,m}$ ($\chi=2$)
- Greedy vs exact on tiny graphs; $\mathrm{greedy}\ge\chi$
- Disconnected mixed components; wheels; Petersen ($\chi=3$)
- Parallel edges; `Is_Proper_Coloring` / `Colors_Used`
- `Invalid_Argument` for overflow, self-loops, OOB, exact oversize,
  bad colour-array bounds, `Max_Edges`
- Larger greedy-only instances ($N$ up to $256$ / $\mathrm{Max\_Vertices}$)
- Degree-descending vs natural order
- Exact at $N=\mathrm{Max\_Exact}$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Coloring_Algorithm is
   Max_Vertices : constant Positive := 512;
   Max_Edges    : constant Positive := 50_000;
   Max_Exact    : constant Positive := 16;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Color_Array is array (Vertex_Id range <>) of Natural;
   type Order_Kind is (Natural_Order, Degree_Descending);

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;
   function Degree (G : Graph; V : Vertex_Id) return Natural;

   procedure Greedy_Color
     (G          : Graph;
      Colors     : out Color_Array;
      Num_Colors : out Natural;
      Order      : Order_Kind := Natural_Order);

   function Is_Bipartite (G : Graph) return Boolean;
   procedure Two_Color
     (G       : Graph;
      Colors  : out Color_Array;
      Success : out Boolean);

   function Chromatic_Number_Exact (G : Graph) return Natural;

   function Is_Proper_Coloring
     (G : Graph; Colors : Color_Array) return Boolean;
   function Colors_Used
     (Colors : Color_Array; N : Natural) return Natural;
end Coloring_Algorithm;
```

Raises `Invalid_Argument` for $N>\mathrm{Max\_Vertices}$, edge count
above $\mathrm{Max\_Edges}$, self-loops, vertex ids outside $1..N$,
`Chromatic_Number_Exact` when $N>16$, or colour-array bounds with
`First/=1` or `Last<N` when $N>0$.

Colours are positive integers; $0$ means uncoloured. Empty $N=0$ is
feasible with $\chi=0$.

## License

Educational reference implementation. See repository `LICENSE` if present.
