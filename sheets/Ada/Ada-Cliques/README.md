# Cliques (Graph Theory Survey) in Ada 2023

## Project Overview

A **clique** in an undirected simple graph $G = (V, E)$ is a vertex subset
$C \subseteq V$ such that every two distinct members are adjacent — equivalently,
the induced subgraph $G[C]$ is complete. This package is an **Ada 2023
(ISO/IEC 8652:2023)** educational **survey**: definitions and predicates,
**Bron–Kerbosch** enumeration of all **maximal** cliques (Tomita pivoting),
and colouring-bound **branch-and-bound** for one **maximum** clique and the
**clique number** $\omega(G)$. Algorithms are **inlined** and self-contained.

**Maximal** vs **maximum**: a clique is maximal when no further vertex can be
added; a maximum clique has globally largest cardinality $\omega(G)$. Every
maximum clique is maximal; the converse fails (many small maximal cliques can
coexist with a larger one). Sibling sheets **Bron–Kerbosch**
(`Ada-Bron-Kerbosch`) and **MaxCliqueDyn** (`Ada-MaxCliqueDyn`) deepen each
algorithm separately — README names only, **no** package `with`.

Vertices are indexed from $1$; adjacency uses $\mathtt{Unsigned\_64}$ bitsets
($\mathrm{Max\_Vertices} = 64$); enumeration is capped at
$\mathrm{Max\_Cliques} = 10\,000$.

Primary source:
[Wikipedia — Clique (graph theory)](https://en.wikipedia.org/wiki/Clique_(graph_theory)).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Cliques`) | Survey: definitions + maximal enum + $\omega(G)$ BnB |
| Bron–Kerbosch (sibling sheet) | Enumerate *all* maximal cliques (pivoted BK) |
| MaxCliqueDyn (sibling sheet) | BnB *maximum* clique + ColorSort colouring bound |

README links only — **no** package `with` of siblings.

## Algorithm

### Definitions

- **Clique**: complete induced subgraph (or its vertex set).
- **Maximal clique**: a clique that is not a proper subset of any larger clique.
- **Maximum clique**: a clique of largest size; $\omega(G)$ is that size.
- Duality: $\omega(G) = \alpha(\overline{G})$ (independence number of the
  complement). Moon–Moser: at most $3^{n/3}$ maximal cliques on $n$ vertices.

### Bron–Kerbosch with pivoting (enumeration)

Recursive backtracking on disjoint sets $R$ (growing clique), $P$ (candidates),
$X$ (excluded). When $P = X = \emptyset$, report $R$. Pivot $u \in P \cup X$
maximizing $|P \cap N(u)|$ (Tomita); recurse only on $v \in P \setminus N(u)$:

$$
\begin{align*}
&\mathbf{BronKerbosch2}(R, P, X): \\
&\quad \text{if } P = X = \emptyset \text{ then report } R \\
&\quad \text{choose pivot } u \in P \cup X \\
&\quad \text{for each } v \in P \setminus N(u): \\
&\quad\quad \mathbf{BronKerbosch2}(R \cup \{v\},\, P \cap N(v),\, X \cap N(v)) \\
&\quad\quad P \leftarrow P \setminus \{v\};\quad X \leftarrow X \cup \{v\}
\end{align*}
$$

Worst-case time $O(3^{n/3})$ matches the Moon–Moser bound.

### Colouring-bound BnB (maximum clique)

Grow $Q$ with incumbent $Q_{\max}$. At each node order candidates $R$ by
nonincreasing degree in $G[R]$, greedily colour (ColorSort spirit), and prune
when

$$
|Q| + C(p) \le |Q_{\max}|
$$

Expand highest colour first. Educational simplification of MaxCliqueDyn
(always recolour; no $T_{\mathrm{limit}}$ gate) — correct BnB, not
bit-identical to Konc & Janežič (2007).

### Consistency

On every finite graph, $\omega(G)$ equals the maximum cardinality among all
maximal cliques. The test suite checks this on small instances by comparing
`Clique_Number` to the largest `Set_Size` over `Enumerate_Maximal_Cliques`.

### Examples

Triangle $K_3$: one maximal (= maximum) clique of size $3$, $\omega = 3$.
Edgeless $n$-vertex: $n$ singleton maximal cliques, $\omega = 1$. Complete
$K_n$: one clique of size $n$, $\omega = n$. Complete bipartite $K_{a,b}$:
$a\cdot b$ maximal edges, $\omega = 2$. Bowtie (two triangles sharing a
vertex): two maximal triangles, $\omega = 3$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Maximal enumeration | $O(3^{n/3})$ worst case with good pivoting |
| Output size | $\le 3^{n/3}$ maximal cliques; cap $\mathrm{Max\_Cliques}$ |
| Maximum clique BnB | Exponential worst case (NP-hard); colouring prunes |
| Graph storage | $O(\|V\|)$ words — one `Unsigned_64` neighbourhood per vertex |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices} = 64$ |

## Features

- **`Clear` / `Add_Edge`** — undirected simple graph on $1 .. N$ (self-loops /
  duplicates ignored).
- **`Vertex_Count` / `Edge_Count` / `Is_Adjacent`** — size and adjacency.
- **`Is_Clique` / `Is_Maximal_Clique` / `Set_Size`** — predicates and helpers.
- **`Enumerate_Maximal_Cliques` / `Maximal_Clique_Count`** — pivoted BK.
- **`Find_Maximum_Clique` / `Clique_Number`** — colouring-bound BnB for
  $\omega(G)$.
- **Capacity guards** — `Invalid_Argument`, `Too_Many_Cliques`.
- **Bitset adjacency** — fast neighbourhood ops for $N \le 64$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pcliques.gpr`.

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

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty / single / edgeless graphs, self-loops and duplicate edges
- Triangles, $K_n$, paths, cycles, stars, bipartite graphs
- Composite patterns (bowtie, house, wheel, disjoint unions)
- Every reported maximal clique is maximal; counts vs brute force for
  $n \le 10$
- `Clique_Number` / `Find_Maximum_Clique` vs brute $\omega$ and vs max size
  over enumerated maximal cliques
- `Invalid_Argument` / `Too_Many_Cliques` and Clear/reset

## Building

- Prerequisites: GNAT supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF 13+,
  GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Cliques is
   Max_Vertices : constant Positive := 64;
   Max_Cliques  : constant Positive := 10_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Vertex_Set is array (Vertex_Id) of Boolean;
   type Clique_Array is array (1 .. Max_Cliques) of Vertex_Set;
   type Clique_List is record
      Items : Clique_Array;
   end record;

   type Graph is limited private;
   Invalid_Argument : exception;
   Too_Many_Cliques : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;
   function Is_Adjacent (G : Graph; U, V : Vertex_Id) return Boolean;

   function Set_Size (S : Vertex_Set; N : Natural) return Natural;
   function Is_Clique (G : Graph; S : Vertex_Set) return Boolean;
   function Is_Maximal_Clique (G : Graph; S : Vertex_Set) return Boolean;

   procedure Enumerate_Maximal_Cliques
     (G       : Graph;
      Cliques : out Clique_List;
      Count   : out Natural);
   function Maximal_Clique_Count (G : Graph) return Natural;

   procedure Find_Maximum_Clique
     (G      : Graph;
      Clique : out Vertex_Set;
      Size   : out Natural);
   function Clique_Number (G : Graph) return Natural;
end Cliques;
```

Raises `Invalid_Argument` for $N > \mathrm{Max\_Vertices}$ or vertex ids
outside $1 .. N$. Raises `Too_Many_Cliques` when more than
$\mathrm{Max\_Cliques}$ maximal cliques would be reported.

## License

Educational reference implementation. See repository `LICENSE` if present.
