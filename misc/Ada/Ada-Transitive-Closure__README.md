# Transitive Closure in Ada 2023

## Project Overview

The **transitive closure** $R^{+}$ of a homogeneous binary relation $R$ on a
set $X$ is the smallest transitive relation on $X$ that contains $R$.
Equivalently, on a **directed graph**, $u\,R^{+}\,v$ iff there is a directed
walk from $u$ to $v$ of length at least one — i.e. **reachability**. The
optional **reflexive transitive closure** $R^{*}=R^{+}\cup I$ also relates
every element to itself.

If airports are vertices and a direct flight is an edge, then $R^{+}$ answers
“can one fly from $x$ to $y$ in one or more hops?”. Formally

$$
R^{+}=\bigcup_{i=1}^{\infty} R^{i},
\qquad
R^{1}=R,\quad R^{i+1}=R\circ R^{i},
$$

where $\circ$ is relational composition. $R$ is already transitive iff
$R^{+}=R$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, Boolean adjacency and closure
matrices in fixed arrays sized to $\mathrm{Max\_Vertices}$, Warshall’s
$O(n^{3})$ Boolean closure, and equivalent per-source DFS / BFS
reachability.

Primary source:
[Wikipedia — Transitive closure](https://en.wikipedia.org/wiki/Transitive_closure).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Transitive-Closure`) | Boolean $R^{+}$ / $R^{*}$; Warshall + DFS/BFS reachability |
| Floyd–Warshall (sibling sheet) | All-pairs **shortest paths** on weighted digraphs; same triple loop with $\min$ / $+$ |
| Tarjan SCC (sibling sheet) | Partition into strongly connected components; mutual reachability |

Warshall is the Boolean special case of Floyd–Warshall (OR/AND instead of
$\min$/add). SCCs collapse mutual $R^{+}$ pairs; this sheet materialises the
full reachability matrix. README links only — **no** package `with` of
siblings.

## Algorithm

### Warshall Boolean matrix closure

Given the adjacency matrix of $R$ on $n$ vertices:

1. Set $C\leftarrow R$; if computing $R^{*}$, set $C(v,v)\leftarrow\mathrm{true}$ for all $v$.
2. For $k=1..n$, for $i=1..n$, for $j=1..n$:
   $$
   C(i,j)\leftarrow C(i,j)\lor\bigl(C(i,k)\land C(k,j)\bigr).
   $$

After finishing $k$, $C(i,j)$ records a path from $i$ to $j$ whose internal
vertices lie in $\{1,\ldots,k\}$. Time $\Theta(n^{3})$, space $\Theta(n^{2})$.

### DFS / BFS from each vertex

For each source $s$, explore the out-neighbourhood with DFS or BFS and mark
every vertex reachable by a walk of length $\ge 1$. The resulting matrix
equals Warshall’s $R^{+}$. With the reflexive option, also force the
identity. Time $O\bigl(n(n+m)\bigr)$ with a Boolean adjacency scan.

### Example

Vertices $\{1,2,3\}$ with edges $1\to 2$, $2\to 3$:

- $R^{+}$ has $1\to 2$, $2\to 3$, and $1\to 3$ (the missing hop).
- $R^{*}$ additionally has $1\to 1$, $2\to 2$, $3\to 3$.
- Raw $R$ is **not** transitive; $R^{+}$ is.

A directed $3$-cycle yields a complete $R^{+}$ (including the diagonal),
because every vertex reaches every vertex — including itself — by walking
around the cycle.

### Asymptotic cost

$$
O(n^{3})\quad\text{(Warshall)},\qquad
O\bigl(n(n+m)\bigr)\quad\text{(DFS/BFS forest)}.
$$

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (Warshall) | $O(n^{3})$ |
| Time (DFS/BFS from each vertex) | $O(n(n+m))$ |
| Closure / relation storage | $O(n^{2})$ Boolean matrix |
| Graph storage | $O(n^{2})$ Boolean adjacency (educational) |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Reflexive option | $R^{*}=R^{+}\cup I$ (force diagonal) |
| Unreachable | closure entry $\mathrm{False}$ |

## Features

- **`Clear` / `Add_Edge`** — build an unweighted digraph on vertices $1 .. N$
  (idempotent edges; self-loops allowed).
- **`Vertex_Count` / `Edge_Count` / `Has_Edge`** — size and adjacency queries.
- **`Relation_Matrix`** — copy the raw relation $R$.
- **`Warshall` / `Reachability_DFS` / `Reachability_BFS`** — compute $R^{+}$
  or $R^{*}$ (three methods, same result).
- **`Closure_Matrix`** — convenience alias for Warshall.
- **`Warshall_On_Matrix`** — close an explicit square Boolean relation.
- **`Reaches`** — single-pair reachability (DFS).
- **`Is_Transitive`** — check $\forall i,j,k \in 1..N:\ M(i,j)\land M(j,k)\Rightarrow M(i,k)$.
- **Capacity / bounds guards** — `Invalid_Argument` for bad ids, $N=0$ on
  search APIs, or non-$1$-based / undersized matrices.
- **Educational layout** — 1-based indices; fixed Boolean matrices up to
  $\mathrm{Max\_Vertices}=256$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ptransitive_closure.gpr`.

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

=== 1. Empty / capacity / guards ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph guards; capacity overflow; single vertex; self-loops
- Two-vertex arcs, reverse arcs, mutual cycles
- Directed chains and DAG diamonds
- Cycles (diagonal appears in $R^{+}$); disconnected components
- Complete digraphs; out-stars / in-stars; grid DAGs
- Warshall $\equiv$ DFS $\equiv$ BFS on many shapes
- Reflexive $R^{*}$ vs irreflexive $R^{+}$
- `Warshall_On_Matrix` / `Is_Transitive` on raw vs closed relations
- `Invalid_Argument` for ids, empty search, and matrix bounds

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Transitive_Closure is
   Max_Vertices : constant Positive := 256;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Bool_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Boolean;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;
   function Has_Edge (G : Graph; From, To : Vertex_Id) return Boolean;
   procedure Relation_Matrix (G : Graph; M : out Bool_Matrix);

   procedure Warshall
     (G : Graph; Closure : out Bool_Matrix; Reflexive : Boolean := False);
   procedure Reachability_DFS
     (G : Graph; Closure : out Bool_Matrix; Reflexive : Boolean := False);
   procedure Reachability_BFS
     (G : Graph; Closure : out Bool_Matrix; Reflexive : Boolean := False);
   procedure Closure_Matrix
     (G : Graph; Closure : out Bool_Matrix; Reflexive : Boolean := False);
   procedure Warshall_On_Matrix
     (Relation : Bool_Matrix; Closure : out Bool_Matrix;
      Reflexive : Boolean := False);

   function Reaches
     (G : Graph; From, To : Vertex_Id;
      Reflexive : Boolean := False) return Boolean;
   function Is_Transitive (M : Bool_Matrix; N : Natural) return Boolean;
end Transitive_Closure;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N >$
$\mathrm{Max\_Vertices}$, $N=0$ on closure / reachability APIs, or matrices
that are not $1$-based with `Last >= N` on both dimensions.

Convention: `Reflexive => False` yields $R^{+}$ (paths of length $\ge 1$);
`True` yields $R^{*}=R^{+}\cup I$. `Add_Edge` is idempotent on duplicate
pairs. `Is_Transitive` inspects only the $1 .. N$ principal submatrix.

## License

Educational reference implementation. See repository `LICENSE` if present.
