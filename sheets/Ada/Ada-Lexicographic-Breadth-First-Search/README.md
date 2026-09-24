# Lexicographic Breadth-First Search (Lex-BFS) in Ada 2023

## Project Overview

**Lexicographic breadth-first search** (Lex-BFS) orders the vertices of an
**undirected graph** so that the order is always a valid breadth-first
search order, while breaking predecessor ties by a **lexicographic** rule:
at each step select an unnumbered vertex whose set of already-numbered
neighbours is smallest in lexicographic order of output positions.

Donald J. Rose, Robert E. Tarjan, and George S. Lueker (1976) introduced
the algorithm via **partition refinement**, replacing the BFS queue with an
ordered sequence of vertex sets. Lex-BFS is a standard subroutine for
**chordal graph** recognition: the **reverse** of a Lex-BFS ordering is
always a **perfect elimination ordering** (PEO) on a chordal graph.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, adjacency lists in fixed
educational arrays (no dynamic heap beyond stack-sized workspaces), and
$O(|V|+|E|)$ documented complexity.

Primary source:
[Wikipedia — Lexicographic breadth-first search](https://en.wikipedia.org/wiki/Lexicographic_breadth-first_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Lexicographic-Breadth-First-Search`) | Lex-BFS order via partition refinement |
| Tarjan SCC (sibling sheet) | Directed SCCs, DFS + low-link |
| Bron–Kerbosch (sibling sheet) | Enumerate maximal cliques |

README links only — **no** package `with` of siblings.

## Algorithm

### Declarative Lex-BFS rule

A standard BFS may be described as repeatedly outputting a vertex $v$ that
has not yet been chosen and that has a predecessor as early in the output
as possible. When two vertices share the same earliest predecessor, ordinary
BFS breaks the tie arbitrarily. Lex-BFS instead compares the **entire**
sets of already-output neighbours and chooses the vertex whose neighbour
set is lexicographically smallest (equivalently: prefer the better
second-earliest neighbour, then third-earliest, and so on).

### Partition refinement (Rose–Tarjan–Lueker)

Maintain an ordered sequence $\Sigma$ of disjoint sets that partition the
yet-unnumbered vertices. This package initialises

$$
\Sigma = \bigl[\{s\},\; V \setminus \{s\}\bigr]
$$

so a distinguished start vertex $s$ is selected first. Then repeatedly:

1. Remove a vertex $v$ from the **first** set of $\Sigma$ (drop the set if
   empty) and append $v$ to the Lex-BFS output.
2. For each still-unnumbered neighbour $w$ belonging to a set $S \in \Sigma$:
   if $S$ has not yet been refined while processing $v$, create a new empty
   set $T$ placed immediately **before** $S$; otherwise reuse that $T$.
   Move $w$ from $S$ to $T$, and delete $S$ if it becomes empty.

The first set of $\Sigma$ always holds the vertices with the currently best
lexicographic label, so each choice matches the declarative rule. With
doubly linked vertex lists and set cells, the implementation runs in
$O(|V|+|E|)$ time.

### Chordal graphs and perfect elimination orderings

A graph is **chordal** when every cycle of length $\ge 4$ has a chord.
Equivalently, its vertices admit a **perfect elimination ordering** (PEO):
an order $u_1,\ldots,u_n$ such that for each $i$, the neighbours of $u_i$
among $\{u_{i+1},\ldots,u_n\}$ form a clique.

**Theorem (Rose–Tarjan–Lueker):** if $G$ is chordal and $\sigma$ is any
Lex-BFS ordering of $G$, then the reverse $\sigma^R$ is a PEO of $G$.

This package exposes `Is_PEO` so tests can verify the reverse Lex-BFS order
on trees, complete graphs, and other chordal examples, and refute it on
induced cycles $C_{\ge 4}$.

### Example

Path $1—2—3—4$ with start $1$ yields Lex-BFS order $(1,2,3,4)$. The reverse
$(4,3,2,1)$ is a PEO (paths are trees, hence chordal). On $C_4$, Lex-BFS
still produces a BFS-consistent order, but the reverse is **not** a PEO.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(\|V\| + \|E\|)$ |
| Auxiliary space | $O(\|V\|)$ (partition cells, links, twin marks) |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ undirected simple edges |

## Features

- **`Clear` / `Add_Edge`** — build an undirected simple graph on
  vertices $1 .. N$ (self-loops and duplicate edges ignored).
- **`Vertex_Count` / `Edge_Count` / `Is_Adjacent`** — size and adjacency
  queries.
- **`Lex_BFS(G, Start, Order)`** — Lex-BFS ordering beginning at `Start`.
- **`Lex_BFS(G, Order)`** — same with default start vertex $1$ (empty
  graph accepted).
- **`Is_PEO`** — test whether an ordering is a perfect elimination
  ordering (for chordal checks on the reversed Lex-BFS order).
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or mismatched `Order` bounds.
- **Educational layout** — 1-based indices; no heap beyond fixed arrays
  sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Plexicographic_breadth_first_search.gpr`.

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

- Empty graph, single vertex, edgeless graphs
- Paths, stars, trees (chordal; reverse Lex-BFS is a PEO)
- Cycles $C_3$ (chordal) through $C_6$, $C_{20}$ (non-chordal)
- Complete graphs $K_2$–$K_{10}$
- Diamond, fans, two triangles sharing an edge
- Disconnected unions of edges and cliques
- Lex-BFS start vertex selection and default overload
- BFS layer consistency on paths; bipartite $K_{2,3}$ non-PEO
- Duplicate edges, self-loops, `Clear` reset, adjacency
- `Invalid_Argument` for capacity, range, bound, and permutation errors
- Larger patterns (P50, star30, 40 isolates)

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Lexicographic_Breadth_First_Search is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Order_Array is array (Vertex_Id range <>) of Vertex_Id;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;
   function Is_Adjacent (G : Graph; U, V : Vertex_Id) return Boolean;

   procedure Lex_BFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array);
   procedure Lex_BFS (G : Graph; Order : out Order_Array);

   function Is_PEO (G : Graph; Order : Order_Array) return Boolean;
end Lexicographic_Breadth_First_Search;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Order` bounds that do not cover $1 .. N$, or a
non-permutation passed to `Is_PEO`.

## License

Educational reference implementation. See repository `LICENSE` if present.
