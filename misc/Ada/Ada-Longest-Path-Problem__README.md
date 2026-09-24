# Longest Path Problem in Ada 2023

## Project Overview

The **longest path problem** asks for a **simple** path (no repeated
vertices) of **maximum length** in a graph. Length may be the number of
edges (unweighted / hop count) or the sum of non-negative edge weights.
Unlike the shortest-path problem — which is polynomial-time on graphs
without negative cycles — the longest-path problem is **NP-hard** in
general: a graph has a Hamiltonian path if and only if its longest path
has $n-1$ edges. The decision version (“is there a simple path with at
least $k$ edges?”) is **NP-complete**.

Nevertheless, on a **directed acyclic graph (DAG)** the problem admits a
**linear-time** dynamic program after a topological sort — the same idea
underlying the **critical path method** in project scheduling. For tiny
instances ($n\le\mathrm{Max\_Exact\_Vertices}$), exhaustive DFS with a
bitset visited mask finds an exact optimum on directed graphs (model an
undirected graph by inserting both arcs).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational sheet:

| Solver | Applies when | Role |
| --- | --- | --- |
| **DAG_Longest_Path** | digraph is a DAG | $O(V+E)$ topo + DP; cycle → status / `Cycle_Error` |
| **DAG_Longest_From** | digraph is a DAG | longest paths from one source |
| **Exact_Simple_Path** | $n\le\mathrm{Max\_Exact\_Vertices}$ | exponential bitset DFS (educational) |

Vertices are indexed from $1$. Storage uses fixed educational arrays up
to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$ (no dynamic heap).
Exact search is separately capped at $\mathrm{Max\_Exact\_Vertices}=20$.

Primary source:
[Wikipedia — Longest path problem](https://en.wikipedia.org/wiki/Longest_path_problem).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with shortest path (README only)

| | Shortest path | Longest simple path |
| --- | --- | --- |
| Complexity (general) | Polynomial (no neg.\ cycles) | **NP-hard** |
| Decision version | P | **NP-complete** |
| Negating weights | Longest in $G$ ↔ shortest in $-G$ | Creates negative cycles unless $G$ is a DAG |
| DAG | Linear via topo / BF on $-G$ | **Linear** topo + DP (this sheet) |
| Typical tool | Dijkstra / Bellman–Ford / BFS | DAG DP or exponential exact / FPT |

Sibling sheets ([Ada-Shortest-Path-Problem](https://github.com/RobertBoettcherSF/Ada-Shortest-Path-Problem),
[Ada-Dijkstras-Algorithm](https://github.com/RobertBoettcherSF/Ada-Dijkstras-Algorithm))
are linked here only — **no** package `with` of siblings.

## NP-hardness (sketch)

A reduction from **Hamiltonian path**: $G$ has a Hamiltonian path iff a
longest simple path has length $n-1$. Hence finding (or deciding) a
longest path is at least as hard. Strong inapproximability results are
also known; this sheet does **not** implement approximation algorithms.

$$
\text{HamPath}(G)=\mathsf{yes}\;\iff\;
\text{longest simple path in }G\text{ has }n-1\text{ edges}
$$

## Algorithms

### DAG longest path — `DAG_Longest_Path`

1. Compute a topological order (Kahn); if fewer than $|V|$ vertices are
   ordered, a directed cycle exists → `Cycle_Detected` / `Cycle_Error`.
2. For each vertex $v$ in topo order, relax outgoing edges:

$$
\mathrm{dist}(w)\leftarrow\max\bigl(\mathrm{dist}(w),\,
\mathrm{dist}(u)+c(u,w)\bigr)
$$

   with $\mathrm{dist}(v)=0$ initially (weight of a path ending at $v$
   with no edges yet used).
3. Let $t$ be an $\mathrm{argmax}_v\,\mathrm{dist}(v)$. Walk predecessors
   from $t$ back to a source and reverse to obtain the vertex sequence.

Time $O(V+E)$. Unit weights yield a maximum-hop path in the DAG.

### Single-source DAG — `DAG_Longest_From`

Same DP restricted to vertices reachable from a chosen source $s$.
Unreachable vertices keep $\mathrm{dist}=\mathrm{Infinity}$.

### Exact simple path — `Exact_Simple_Path`

Depth-first search over all simple paths, marking visited vertices with a
bitset mask. Maximizes total edge weight; ties prefer more vertices, then
a lexicographically smaller vertex sequence. For undirected inputs, call
`Add_Edge` in both directions. Requires
$n\le\mathrm{Max\_Exact\_Vertices}$.

$$
T(n) = O\!\left(2^{n}\,n\cdot\mathrm{poly}\right)
\quad\text{(enumerate simple paths; educational)}
$$

### Example (DAG diamond)

Vertices $\{1,2,3,4\}$ with edges
$1\xrightarrow{1}2$, $1\xrightarrow{4}3$, $2\xrightarrow{5}4$,
$3\xrightarrow{1}4$:

- Path $1\to 2\to 4$ has weight $6$
- Path $1\to 3\to 4$ has weight $5$
- Longest weight is $6$ along $(1,2,4)$

(Contrast: the **shortest** $1\to 4$ path would prefer weight $5$.)

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (DAG DP) | $O(V+E)$ |
| Time (Exact DFS) | Exponential in $n$ (cap $n\le 20$) |
| Auxiliary space (DAG) | $O(V)$ |
| Graph storage | $O(\|V\|+\|E\|)$ fixed arrays |
| Vertex indices | $1 .. N$ with $N\le\mathrm{Max\_Vertices}$ |
| Exact cap | $N\le\mathrm{Max\_Exact\_Vertices}=20$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges |
| Weights | Non-negative integers; unit `Add_Edge` ⇒ hop count |
| Cycle on DAG APIs | `Cycle_Detected` / `Cycle_Error` |
| Unreachable (From) | $\mathrm{dist}(v)=\mathrm{Infinity}$ |

## Features

- **`Clear` / `Add_Edge`** — digraph on vertices $1 .. N$; unit or weighted.
- **`Vertex_Count` / `Edge_Count` / `Is_Acyclic`** — size and DAG test.
- **`DAG_Longest_Path`** — global longest path in a DAG (+ status overload).
- **`DAG_Longest_From`** — longest-path tree from one source.
- **`DAG_Longest_Weight`** — weight-only convenience (raises on cycle).
- **`Exact_Simple_Path`** — global / $s\!\to\!t$ / from-$s$ exhaustive search.
- **`Reconstruct_Path`** — recover a Source→Target walk from `Prev`.
- **`Infinity`** — unreachable sentinel for `DAG_Longest_From`.
- **Guards** — `Invalid_Argument` for bad ids, overflow, negatives, exact
  size cap, or insufficient array bounds.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Plongest_path_problem.gpr`.

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

=== 1. Empty / single / self ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty / single-vertex / self-loop cycle detection
- `Clear` / `Add_Edge` guards (range, negative weight, overflow)
- Hand-checked DAG chains, diamonds, critical-path, layered graphs
- Cycle detection (`Cycle_Detected`, `Cycle_Error`, `Is_Acyclic`)
- `DAG_Longest_From` with `Infinity` for unreachable vertices
- Exact DFS on tiny digraphs; undirected via bidirectional arcs
- Exact ↔ DAG agreement on acyclic instances
- Parallel edges, zero weights, disconnected components
- Exact on cyclic graphs (simple-path constraint)
- `Invalid_Argument` for exact size cap and array bounds
- Path reconstruction edge cases

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Longest_Path_Problem is
   Max_Vertices       : constant Positive := 256;
   Max_Exact_Vertices : constant Positive := 20;
   Max_Edges          : constant Positive := 50_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range 0 .. 2**31 - 1;
   type Distance_Value is range 0 .. 2**63 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Distance_Array is array (Vertex_Id range <>) of Distance_Value;
   type Prev_Array is array (Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;

   type Run_Status is (Success, Cycle_Detected);
   type Graph is limited private;

   Invalid_Argument : exception;
   Cycle_Error      : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;
   function Is_Acyclic (G : Graph) return Boolean;

   procedure DAG_Longest_Path
     (G : Graph; Path : out Path_Array; Length : out Natural;
      Weight : out Distance_Value; Status : out Run_Status);
   procedure DAG_Longest_Path
     (G : Graph; Path : out Path_Array; Length : out Natural;
      Weight : out Distance_Value);

   procedure DAG_Longest_From
     (G : Graph; Source : Vertex_Id;
      Dist : out Distance_Array; Prev : out Prev_Array;
      Status : out Run_Status);

   function DAG_Longest_Weight (G : Graph) return Distance_Value;

   procedure Exact_Simple_Path
     (G : Graph; Path : out Path_Array; Length : out Natural;
      Weight : out Distance_Value);
   procedure Exact_Simple_Path
     (G : Graph; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural;
      Weight : out Distance_Value; Found : out Boolean);
   procedure Exact_Simple_Path_From
     (G : Graph; Source : Vertex_Id;
      Path : out Path_Array; Length : out Natural;
      Weight : out Distance_Value);

   function Reconstruct_Path
     (Prev : Prev_Array; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural) return Boolean;
end Longest_Path_Problem;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, negative `Weight`, $N=0$ on search APIs, exact search
when $N>\mathrm{Max\_Exact\_Vertices}$, or `Path`/`Dist`/`Prev` with
`First /= 1` or `Last < N`. DAG raising overloads raise `Cycle_Error`
when a directed cycle is present.

Path convention: on success `Path(1)` is the start vertex,
`Path(Length)` the end, and `Length` is the number of vertices (arc count
$= Length - 1$). A singleton path has weight $0$.

## License

Educational reference implementation. See repository `LICENSE` if present.
