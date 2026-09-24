# Bron–Kerbosch Maximal Clique Enumeration in Ada 2023

## Project Overview

**Bron–Kerbosch** enumerates **all maximal cliques** in an **undirected
simple graph**: every set $C \subseteq V$ that is a clique (every pair
adjacent) and cannot be extended by any further vertex. Coenraad Bron and
Joep Kerbosch published the algorithm in 1973; this package implements the
widely used **pivoting** variant with a **Tomita-style** pivot heuristic
(choose $u \in P \cup X$ maximizing $|P \cap N(u)|$).

A **maximal** clique need not be **maximum**. Maximality is a local
property (no vertex can be added); a **maximum** clique has globally
largest size $\omega(G)$. This package lists every maximal clique; the
sibling sheet **MaxCliqueDyn** (`Ada-MaxCliqueDyn`) finds one maximum
clique via colouring-bound branch-and-bound — README link only, **no**
package `with`.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, adjacency as
$\mathtt{Unsigned\_64}$ bitsets ($\mathrm{Max\_Vertices} = 64$), a fixed
result cap $\mathrm{Max\_Cliques} = 10\,000$, and documented
$O(3^{n/3})$ worst-case time matching the Moon–Moser bound.

Primary source:
[Wikipedia — Bron–Kerbosch algorithm](https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Bron-Kerbosch`) | Enumerate *all* maximal cliques (pivoted BK) |
| MaxCliqueDyn (sibling sheet) | BnB *maximum* clique + ColorSort colouring bound |
| Branch-and-bound (sibling sheet) | Generic BnB / 0-1 knapsack illustration |

README links only — **no** package `with` of siblings.

## Algorithm

### Maximal vs maximum

For $G = (V, E)$ undirected and simple, a **clique** is a complete induced
subgraph. Clique $C$ is **maximal** when no $v \notin C$ has
$C \cup \{v\}$ still a clique. The **clique number** $\omega(G)$ is the
size of a **maximum** (largest) clique. Every maximum clique is maximal;
the converse fails (e.g. two triangles sharing a vertex yield two maximal
cliques of size $3$, both maximum in that graph — but a graph can have
many small maximal cliques alongside a larger one).

### Sets $R$, $P$, $X$

Bron–Kerbosch is recursive backtracking on three disjoint vertex sets:

- $R$ — vertices already chosen for the growing clique;
- $P$ — **candidates** that can still extend $R$ (common neighbours of $R$
  not yet processed);
- $X$ — **excluded** vertices already processed (also common neighbours of
  $R$).

Invariant: $P \cup X$ is exactly the set of vertices adjacent to every
member of $R$. When $P = X = \emptyset$, no further vertex can extend $R$,
so $R$ is reported as a maximal clique.

The top-level call starts with $R = \emptyset$, $P = V$, $X = \emptyset$.

### Without pivoting (sketch)

$$
\begin{align*}
&\mathbf{BronKerbosch1}(R, P, X): \\
&\quad \text{if } P = X = \emptyset \text{ then report } R \\
&\quad \text{for each } v \in P: \\
&\quad\quad \mathbf{BronKerbosch1}(R \cup \{v\},\, P \cap N(v),\, X \cap N(v)) \\
&\quad\quad P \leftarrow P \setminus \{v\};\quad X \leftarrow X \cup \{v\}
\end{align*}
$$

### With pivoting (this package)

The basic form recurses on every clique, maximal or not. A **pivot** $u$
chosen from $P \cup X$ lets the algorithm skip neighbours of $u$: any
maximal clique found through a neighbour of $u$ would also be found when
testing $u$ or a non-neighbour. Only vertices in $P \setminus N(u)$ are
tried:

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

**Tomita pivot** (used here): pick $u \in P \cup X$ maximizing
$|P \cap N(u)|$, i.e. minimizing $|P \setminus N(u)|$ and thus the number
of recursive branches.

### Example

Triangle $K_3$: one maximal clique $\{1,2,3\}$. Edgeless $n$-vertex graph:
$n$ singleton maximal cliques. Complete $K_n$: one clique of size $n$.
Complete bipartite $K_{a,b}$ ($a,b \ge 1$): exactly $a \cdot b$ maximal
cliques, each an edge. Two triangles sharing a vertex (bowtie): two
maximal cliques of size $3$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(3^{n/3})$ worst case with good pivoting (Moon–Moser-tight) |
| Output size | At most $3^{n/3}$ maximal cliques; package caps at $\mathrm{Max\_Cliques}$ |
| Auxiliary space | $O(n)$ recursion depth; bitset frames |
| Graph storage | $O(\|V\|)$ words — one `Unsigned_64` neighbourhood per vertex |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices} = 64$ |

## Features

- **`Clear` / `Add_Edge`** — build an undirected simple graph on $1 .. N$
  (self-loops and duplicate edges ignored).
- **`Vertex_Count` / `Edge_Count` / `Is_Adjacent`** — size and adjacency queries.
- **`Enumerate_Maximal_Cliques`** — all maximal cliques into a fixed
  `Clique_List` plus `Count`.
- **`Maximal_Clique_Count`** — cardinality of the maximal-clique family only.
- **`Is_Clique` / `Is_Maximal_Clique` / `Set_Size`** — verification helpers.
- **Capacity guards** — `Invalid_Argument` for oversized $N$ or bad vertex
  ids; `Too_Many_Cliques` when output would exceed $\mathrm{Max\_Cliques}$.
- **Bitset adjacency** — fast neighbourhood intersection for $N \le 64$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pbron_kerbosch.gpr`.

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

(Exact `NN` is the current suite size; it is at least 120.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph, single vertex, edgeless graphs ($n$ singletons), self-loops /
  duplicate edges
- Triangle ($1$ clique), two triangles sharing a vertex, complete $K_n$
  ($1$ clique)
- Paths, cycles, stars, bipartite graphs (edges as size-$2$ maximal cliques)
- Disjoint unions and known small named patterns
- Every reported set is a maximal clique; counts match brute force for
  $n \le 10$ in the suite
- `Invalid_Argument` / `Too_Many_Cliques` capacity and range errors
- Clear/reset and API counters

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Bron_Kerbosch is
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

   procedure Enumerate_Maximal_Cliques
     (G       : Graph;
      Cliques : out Clique_List;
      Count   : out Natural);

   function Maximal_Clique_Count (G : Graph) return Natural;
   function Set_Size (S : Vertex_Set; N : Natural) return Natural;
   function Is_Clique (G : Graph; S : Vertex_Set) return Boolean;
   function Is_Maximal_Clique (G : Graph; S : Vertex_Set) return Boolean;
end Bron_Kerbosch;
```

Raises `Invalid_Argument` for $N > \mathrm{Max\_Vertices}$ or vertex ids
outside $1 .. N$. Raises `Too_Many_Cliques` when more than
$\mathrm{Max\_Cliques}$ maximal cliques would be reported.

## License

Educational reference implementation. See repository `LICENSE` if present.
