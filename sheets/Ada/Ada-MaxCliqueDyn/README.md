# MaxCliqueDyn Maximum Clique in Ada 2023

## Project Overview

**MaxCliqueDyn** finds a **maximum clique** in an **undirected simple graph**:
a largest set $C \subseteq V$ such that every pair of distinct vertices in
$C$ is adjacent. The decision version is NP-complete; this package is an
**educational** branch-and-bound search with a **greedy colouring upper
bound** in the spirit of Konc & Janežič's MaxCliqueDyn (2007) — ColorSort
ordering plus degree-aware recolouring of candidate sets — not a
bit-identical reproduction of the paper.

Janez Konc and Dušanka Janežič (2007) extended the earlier MaxClique
algorithm with ColorSort and dynamically tightened bounds on a fraction of
the search tree. Both reduce the number of steps and practical running time
versus plain approximate colouring.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, adjacency as
$\mathtt{Unsigned\_64}$ bitsets ($\mathrm{Max\_Vertices} = 64$), and
documented exponential worst-case complexity with $O(1)$ bitset neighbourhood
tests.

Primary source:
[Wikipedia — MaxCliqueDyn algorithm](https://en.wikipedia.org/wiki/MaxCliqueDyn_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-MaxCliqueDyn`) | BnB max clique + ColorSort colouring bound |
| Branch-and-bound (sibling sheet) | Generic BnB / 0-1 knapsack illustration |
| Bron–Kerbosch (sibling sheet) | Enumerate *all* maximal cliques |

README links only — **no** package `with` of siblings.

## Algorithm

### Maximum clique

For $G = (V, E)$ undirected and simple, a **clique** is a complete induced
subgraph. The **clique number** $\omega(G)$ is the cardinality of a largest
clique. Equivalently, $\omega(G) = \alpha(\overline{G})$ (independence number
of the complement).

### Colouring bound

A proper vertex colouring of the candidate-induced subgraph $G[R]$ with
$\chi$ colours implies $\omega(G[R]) \le \chi$. MaxClique-style search grows
a clique $Q$ and prunes a candidate $p$ when

$$
|Q| + C(p) \le |Q_{\max}|
$$

where $C(p)$ is the colour number assigned by a greedy colouring (an upper
bound on how much $Q$ can still grow through $p$).

### ColorSort (educational)

At each search node:

1. Order candidates $R$ by **nonincreasing degree** in $G[R]$ (MaxCliqueDyn
   dynamic reordering spirit; this package always recolours — no $T_{\mathrm{limit}}$ gate).
2. Assign each vertex the smallest colour class compatible with
   non-adjacency (approximate / greedy colouring).
3. Let $k_{\min} = |Q_{\max}| - |Q| + 1$. Vertices with colour $< k_{\min}$
   cannot improve the incumbent; ColorSort parks them at the front with a
   sentinel colour $0$. Vertices with colour $\ge k_{\min}$ follow in
   nondecreasing colour order and carry $C(v) = k$ for pruning.
4. Expand from the **highest colour** downward; recurse on
   $R' = R \cap \Gamma(p)$ after adding $p$ to $Q$.

### Example

Triangle $K_3$ on $\{1,2,3\}$: $\omega = 3$, the unique maximum clique is
the whole vertex set. A path $1{-}2{-}3$ has $\omega = 2$. A bipartite graph
has $\omega \le 2$. Complete $K_n$ has $\omega = n$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | Exponential in $\|V\|$ worst case (NP-hard); colouring prunes many branches |
| Per-node colouring | $O(\|R\|^2)$ bitset tests on educational instances |
| Auxiliary space | $O(\|V\|)$ per recursion frame (order, colours, degrees) |
| Graph storage | $O(\|V\|)$ words — one `Unsigned_64` neighbourhood per vertex |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices} = 64$ |

## Features

- **`Clear` / `Add_Edge`** — build an undirected simple graph on $1 .. N$
  (self-loops and duplicate edges ignored).
- **`Vertex_Count` / `Edge_Count` / `Is_Adjacent`** — size and adjacency queries.
- **`Find_Maximum_Clique`** — one maximum clique as a `Vertex_Set` plus size.
- **`Maximum_Clique_Size`** — $\omega(G)$ only.
- **`Is_Clique` / `Set_Size`** — verification helpers for callers and tests.
- **Capacity guards** — `Invalid_Argument` for oversized $N$ or bad vertex ids.
- **Bitset adjacency** — fast neighbourhood intersection for $N \le 64$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pmaxcliquedyn.gpr`.

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

=== 1. Empty / single / no edges ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 100.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph, single vertex, edgeless graphs, self-loops / duplicate edges
- Triangles, $K_n$, paths, cycles, stars, bipartite graphs ($\omega = 2$)
- Disjoint unions, known small named patterns
- `Is_Clique` / size consistency after every search
- Brute-force optimality checks on all graphs with $n \le 12$ in the suite
- `Invalid_Argument` for capacity and range errors
- Clear/reset and API counters

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package MaxCliqueDyn is
   Max_Vertices : constant Positive := 64;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Vertex_Set is array (Vertex_Id) of Boolean;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;
   function Is_Adjacent (G : Graph; U, V : Vertex_Id) return Boolean;

   procedure Find_Maximum_Clique
     (G      : Graph;
      Clique : out Vertex_Set;
      Size   : out Natural);

   function Maximum_Clique_Size (G : Graph) return Natural;
   function Set_Size (S : Vertex_Set; N : Natural) return Natural;
   function Is_Clique (G : Graph; S : Vertex_Set) return Boolean;
end MaxCliqueDyn;
```

Raises `Invalid_Argument` for $N > \mathrm{Max\_Vertices}$ or vertex ids
outside $1 .. N$.

## License

Educational reference implementation. See repository `LICENSE` if present.
