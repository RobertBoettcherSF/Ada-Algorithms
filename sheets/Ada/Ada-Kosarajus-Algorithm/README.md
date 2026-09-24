# Kosaraju's Algorithm (Kosaraju–Sharir SCC) in Ada 2023

## Project Overview

**Kosaraju–Sharir's algorithm** (also called **Kosaraju's algorithm**)
partitions the vertices of a **directed graph** into its **strongly
connected components** (SCCs) using **two** depth-first search forest
passes. Two vertices $u$ and $v$ lie in the same SCC iff each is reachable
from the other. The algorithm records post-order finish times on $G$,
builds the **transpose** $G^\top$ (every edge reversed), then explores
$G^\top$ in **reverse finish order**, assigning one component id per newly
reached DFS tree.

S. Rao Kosaraju suggested the method in 1978 (unpublished); Micha Sharir
independently discovered and published it in 1981. Aho, Hopcroft and Ullman
popularised the credit as Kosaraju–Sharir. The bound matches Tarjan's
low-link algorithm and the path-based strong component algorithm:
$O(|V|+|E|)$. It is the conceptually simplest linear SCC algorithm, at the
cost of a second full traversal (and an explicit transpose).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, adjacency lists in fixed
educational arrays (no dynamic heap beyond stack-sized workspaces), and
$O(|V|+|E|)$ documented complexity.

Primary source:
[Wikipedia — Kosaraju's algorithm](https://en.wikipedia.org/wiki/Kosaraju%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Kosarajus-Algorithm`) | **Two DFS** passes ($G$ then $G^\top$) + finish stack |
| Tarjan (`Ada-Tarjans-Strongly-Connected-Components`) | One-pass DFS + one stack + **low-link** / index |
| Path-based (`Ada-Path-Based-Strong-Component`) | One-pass DFS + **two stacks** $S,P$ (no low-link) |

README links only — **no** package `with` of siblings.

All three report the same partition of $V$ and run in linear time. This
package never computes $\mathrm{lowlink}$ values and never maintains a
path-merge stack: the second search on $G^\top$ recovers each SCC as the
set of vertices reachable backwards from a carefully ordered root.

## Algorithm

### Strong connectivity

A directed graph $G = (V, E)$ has a strongly connected component for each
maximal set $C \subseteq V$ such that for all $u, v \in C$, there is a
directed path $u \rightsquigarrow v$ and $v \rightsquigarrow u$. Vertices
not on any directed cycle form singleton SCCs. The **condensation** of $G$
(contract each SCC to a supernode) is a DAG. Crucially, $G$ and $G^\top$
have **exactly the same** SCCs.

### Two DFS passes

1. **Finish order on $G$.** Mark every vertex unvisited. For each unvisited
   $u$, run `Visit(u)`: mark $u$ visited; recurse on every out-neighbour;
   then **push** $u$ onto stack $L$ (post-order / finish time).
2. **Build $G^\top$.** For every directed edge $u \rightarrow v$ in $G$,
   store $v \rightarrow u$ in a transpose adjacency pool.
3. **Assign on $G^\top$.** While $L$ is non-empty, pop $u$. If $u$ is still
   unassigned, allocate the next `Component_Id` and `Assign(u)`: label $u$
   and every vertex reachable from $u$ in $G^\top$ (equivalently, every
   vertex that can reach $u$ in $G$ among the still-unassigned set).

Why reverse finish order works: if there is a path $u \rightsquigarrow v$
in $G$ with $u$ and $v$ in distinct SCCs, then $u$ finishes **after** $v$,
so $u$ appears **before** $v$ when popping $L$. Processing $u$ first on
$G^\top$ therefore cannot leak into $v$'s component. Writing $F(u)$ /
$B(u)$ for forward / backward reachability sets and $P(u)$ for vertices
strictly before $u$ on $L$,

$$
B(u) \cap F(u) = B(u) \setminus P(u).
$$

SCCs receive ids in **topological order** of the condensation DAG: the
first `Assign` root (a source of the remaining condensation) gets
`Component_Id` $1$. (Tarjan and path-based emit **reverse** topological
order instead.)

### Example

Graph on vertices $\{1,2,3,4,5\}$ with edges
$1\to 2\to 3\to 1$, $2\to 4$, $4\to 5\to 4$:

- SCC $\{1,2,3\}$ (the triangle);
- SCC $\{4,5\}$ (the mutual pair).

A forward chain $1\to 2\to 3\to 4$ with no back edges yields four singleton
SCCs (every DAG vertex is its own component), with ids increasing along
the chain under Kosaraju's topological numbering.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(\|V\| + \|E\|)$ |
| Auxiliary space | $O(\|V\| + \|E\|)$ (finish stack, visited, transpose pool) |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |

Two complete adjacency-list traversals are asymptotically optimal; an
adjacency-matrix representation would cost $O(|V|^2)$.

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Compute_SCC`** — Kosaraju–Sharir partition into
  `Component_Of(V) ∈ 1 .. Count`.
- **`Same_SCC`** — Boolean co-membership test on a completed labelling.
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or mismatched `Component_Of` bounds.
- **Educational layout** — 1-based indices; no heap beyond fixed arrays
  sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pkosarajus_algorithm.gpr`.

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

- Empty graph, single vertex, self-loops, isolated vertices
- Chains and DAGs (all singleton SCCs)
- 2-cycles, $k$-cycles, linked pairs of cycles
- Classic multi-SCC textbook graphs and condensation order
- Small complete digraphs ($K_3$, $K_4$, $K_5$)
- Disconnected unions of cycles and arcs
- Cross / forward / back edges via transpose reachability
- Nested / hierarchical SCCs and DFS forests
- Topological condensation numbering (sources before sinks)
- Transpose invariance of the SCC partition
- Parallel edges, clear/reset, API counters
- `Invalid_Argument` for capacity, range, and bound errors
- Larger patterns (five 2-cycles, 20-cycle, 50/200 isolates, Max_Vertices)

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Kosarajus_Algorithm is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Component_Id is new Natural;
   type Component_Array is array (Vertex_Id range <>) of Component_Id;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Compute_SCC
     (G               : Graph;
      Component_Of    : out Component_Array;
      Component_Count : out Natural);

   function Same_SCC
     (Component_Of : Component_Array;
      U, V         : Vertex_Id) return Boolean;
end Kosarajus_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, or `Component_Of` bounds that do not cover $1 .. N$.

## License

Educational reference implementation. See repository `LICENSE` if present.
