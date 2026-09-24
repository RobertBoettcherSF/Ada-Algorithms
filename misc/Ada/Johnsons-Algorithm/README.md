# Johnson's Algorithm in Ada 2023

## Project Overview

**Johnson's algorithm** computes **all-pairs shortest paths** in an
**edge-weighted directed graph** that may contain **negative edge weights**,
provided there is **no negative-weight cycle**. Donald B. Johnson published
the method in 1977. It combines one Bellman–Ford pass (to obtain vertex
potentials) with a Dijkstra run from every vertex on a **reweighted** graph
whose edges are all non-negative.

The educational pipeline implemented here is:

1. Imagine a virtual super-source $q$ joined to every vertex by a $0$-weight edge.
2. Run Bellman–Ford from $q$ to obtain potentials $h(v)=\delta(q,v)$.
3. Reweight each original edge by
   $$w'(u,v)=w(u,v)+h(u)-h(v).$$
   Every $s$–$t$ path gains the same additive $h(s)-h(t)$, so shortest paths
   are preserved and $w'\ge 0$ whenever no negative cycle exists.
4. Run **dense** Dijkstra from every vertex on $w'$; recover original
   distances by $d(u,v)=d'(u,v)+h(v)-h(u)$ (`Infinity` stays `Infinity`).

Bellman–Ford and dense Dijkstra live **inside this package** (self-contained).
Sibling sheets are contrasted in the README only — there is **no** package
`with` of Dijkstra / Floyd–Warshall / Bellman–Ford implementations.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, weighted adjacency lists in
fixed arrays, an `Infinity` sentinel for unreachable pairs, optional
predecessor matrices for path reconstruction, `Run_Status` /
`Negative_Cycle_Error` for negative-cycle reporting, and
`Invalid_Argument` for bad ids / capacity / bounds.

Primary source:
[Wikipedia — Johnson's algorithm](https://en.wikipedia.org/wiki/Johnson%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Johnsons-Algorithm`) | APSP with negative edges (no neg cycles); BF potentials + Dijkstra |
| Dijkstra (sibling sheet) | Non-negative weighted SSSP; dense $O(V^{2})$ selection |
| Floyd–Warshall (sibling sheet) | Dense APSP $O(V^{3})$ DP; also handles negatives / detects cycles |
| Bellman–Ford (sibling sheet) | Single-source with negatives; $O(VE)$; cycle detection |

README links only — **no** package `with` of siblings.

When is Johnson preferable? With a heap Dijkstra the asymptotic cost is
$O(VE+V^{2}\log V)$, which beats Floyd–Warshall's $O(V^{3})$ on **sparse**
graphs ($E\ll V^{2}$). This sheet uses a dense Dijkstra scan for clarity,
giving an educational $O(VE+V^{3})$ bound while keeping the code free of
priority-queue machinery.

## Algorithm

### Potentials (Bellman–Ford from a virtual super-source)

Initialise $h(v)\leftarrow 0$ for all $v$ (equivalent to edges $q\to v$ of
weight $0$). Relax every original edge $|V|-1$ times. One extra pass that
still improves some $h(v)$ proves a **negative-weight cycle**.

### Reweighting

$$
w'(u,v)=w(u,v)+h(u)-h(v).
$$

For any path $p=s\to\cdots\to t$, the telescoping sum of $h$ terms leaves
exactly $h(s)-h(t)$ added to the original path weight. Therefore a path is
shortest under $w$ if and only if it is shortest under $w'$. Absence of
negative cycles implies $w'\ge 0$, so Dijkstra applies.

### Dense Dijkstra on $w'$

For each source $s$:

1. Set $\mathrm{dist}'(v)\leftarrow\infty$, $\mathrm{prev}(v)\leftarrow 0$;
   $\mathrm{dist}'(s)\leftarrow 0$.
2. Repeatedly settle the unsettled vertex with smallest $\mathrm{dist}'$,
   relaxing outgoing edges under $w'$.
3. Recover $d(s,v)=\mathrm{dist}'(v)+h(v)-h(s)$ when finite.

### Example (CLRS-style)

Vertices $\{1,2,3,4,5\}$ with edges
$1\xrightarrow{3}2$, $1\xrightarrow{8}3$, $1\xrightarrow{-4}5$,
$2\xrightarrow{1}4$, $2\xrightarrow{7}5$, $3\xrightarrow{4}2$,
$4\xrightarrow{2}1$, $4\xrightarrow{-5}3$, $5\xrightarrow{6}4$:

- Potentials $h=(0,-1,-5,0,-4)$.
- Shortest $1\to 3$ distance is $-3$; $4\to 3$ is $-5$; $1\to 5$ is $-4$.

### Asymptotic cost

With array scan for the unsettled minimum (this sheet):

$$
O(VE + V^{3})
$$

With Fibonacci-heap Dijkstra (classic analysis, not used here):

$$
O(VE + V^{2}\log V)
$$

Graph storage is $O(V+E)$ in fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (this sheet: BF + dense Dijkstra × $V$) | $O(VE + V^{3})$ |
| Time (heap Dijkstra variant, not used here) | $O(VE + V^{2}\log V)$ |
| Auxiliary space (search) | $O(V)$ potentials / scratch; $O(V^{2})$ for Dist/Prev |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |
| Weights | Integers in `Weight_Type` (may be negative) |
| Unreachable | $\mathrm{Dist}(u,v)=\mathrm{Infinity}$ |
| Negative cycle | `Run_Status = Negative_Cycle` or `Negative_Cycle_Error` |

## Features

- **`Clear` / `Add_Edge`** — build a weighted digraph on vertices $1 .. N$
  (negative weights allowed at insert time).
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`All_Pairs` / `Johnson`** — full APSP: `Dist` matrix, optional `Prev`,
  `Run_Status` or raising `Negative_Cycle_Error`.
- **`Has_Negative_Cycle`** — Bellman–Ford probe via the virtual super-source.
- **`Distance`** — single Source→Target query (raises on a negative cycle).
- **`Reconstruct_Path`** — recover a Source→Target walk from a `Prev` row
  or matrix.
- **`Infinity`** — sentinel distance for unreachable pairs.
- **Capacity / range guards** — `Invalid_Argument` for bad ids, overflow,
  weight range, or insufficient `Dist` / `Prev` / `Path` bounds.
- **Educational layout** — 1-based indices; self-contained BF + dense
  Dijkstra; fixed arrays sized to $\mathrm{Max\_Vertices}$ /
  $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pjohnsons_algorithm.gpr`.

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

- Empty graph guards; single vertex; positive / negative self-loops
- Two-vertex arcs, zero weights, negative edges without a cycle
- Negative-cycle detection (2-cycles, 3-cycles, raising overloads)
- Chains with mixed signs; diamonds / shortcuts; disconnected components
- CLRS-style Johnson example (full distance matrix)
- Non-negative digraphs with known APSP values; Distance ↔ matrix agreement
- Parallel edges; clear/rebuild; path reconstruction edge cases
- Grid / star / layered DAG; telescoping complete digraph
- `Invalid_Argument` for capacity, range, and array bounds
- `Max_Vertices` boundary; Infinity sentinel

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Johnsons_Algorithm is
   Max_Vertices : constant Positive := 256;
   Max_Edges    : constant Positive := 50_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range -(2**30) .. 2**30 - 1;
   type Distance_Value is range -(2**62) .. 2**62 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Dist_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Distance_Value;
   type Prev_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Natural;
   type Prev_Array is array (Vertex_Id range <>) of Natural;
   type Path_Array is array (Positive range <>) of Vertex_Id;

   type Run_Status is (Success, Negative_Cycle);
   type Graph is limited private;

   Invalid_Argument     : exception;
   Negative_Cycle_Error : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure All_Pairs
     (G : Graph; Dist : out Dist_Matrix; Prev : out Prev_Matrix;
      Status : out Run_Status);
   procedure All_Pairs
     (G : Graph; Dist : out Dist_Matrix; Status : out Run_Status);
   procedure Johnson
     (G : Graph; Dist : out Dist_Matrix; Prev : out Prev_Matrix;
      Status : out Run_Status);
   procedure Johnson
     (G : Graph; Dist : out Dist_Matrix; Status : out Run_Status);
   procedure All_Pairs
     (G : Graph; Dist : out Dist_Matrix; Prev : out Prev_Matrix);
   procedure Johnson
     (G : Graph; Dist : out Dist_Matrix; Prev : out Prev_Matrix);

   function Has_Negative_Cycle (G : Graph) return Boolean;
   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value;

   function Reconstruct_Path
     (Prev : Prev_Array; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural) return Boolean;
   function Reconstruct_Path
     (Prev : Prev_Matrix; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural) return Boolean;
end Johnsons_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Weight` outside `Weight_Type`, $N=0$ on search APIs, or
`Dist`/`Prev`/`Path` with `First /= 1` or `Last < N`.

On a negative-weight cycle, status overloads return `Negative_Cycle`;
raising overloads and `Distance` raise `Negative_Cycle_Error`.

Path convention: on success `Path(1) = Source`, `Path(Length) = Target`,
and `Length` is the number of vertices (arc count $= Length - 1$).
`Prev(S, S) = 0`; unreachable targets leave `Dist = Infinity`.

## License

Educational reference implementation. See repository `LICENSE` if present.
