# Floyd–Warshall Algorithm in Ada 2023

## Project Overview

The **Floyd–Warshall algorithm** computes **all-pairs shortest paths** in a
**dense edge-weighted directed graph**. Edge weights may be **positive or
negative**; a **negative-weight cycle** is detected when some diagonal entry
of the distance matrix is negative after (or during) the run. Robert Floyd
published the modern formulation in 1962; closely related Boolean / algebraic
variants appear in Roy (1959) and Warshall (1962) for **transitive closure**.

The educational dynamic-programming recurrence implemented here is:

$$
d_{ij}^{(k)}=\min\bigl(d_{ij}^{(k-1)},\,d_{ik}^{(k-1)}+d_{kj}^{(k-1)}\bigr)
$$

with $d_{ij}^{(0)}$ the direct-edge estimate (`Infinity` if no edge,
$0$ on the diagonal). Intermediate vertex $k$ ranges over $1 .. N$; the
correct nest order is **K–I–J**.

Optional **Next** (successor) and **Prev** (predecessor) matrices support
**path reconstruction** without storing full paths. An `Infinity` sentinel
marks unreachable pairs. Graphs are built with `Clear` / `Add_Edge`, or a
`Dist` matrix may be initialised directly via `Init_Dist` / `Put_Edge`.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, dense fixed arrays up to
$\mathrm{Max\_Vertices}$, `Run_Status` / `Negative_Cycle_Error` for cycle
reporting, and `Invalid_Argument` for bad ids / capacity / bounds.

Primary source:
[Wikipedia — Floyd–Warshall algorithm](https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Floyd-Warshall-Algorithm`) | Dense APSP $O(N^{3})$ DP; negatives OK; diagonal cycle probe |
| Johnson (sibling sheet) | Sparse-leaning APSP: BF potentials + Dijkstra; no neg cycles |
| Bellman–Ford (sibling sheet) | Single-source with negatives; $O(VE)$; cycle detection |
| Dijkstra (sibling sheet) | Non-negative weighted SSSP; dense $O(V^{2})$ selection |
| Transitive closure / Warshall (sibling sheet) | Boolean reachability $O(N^{3})$; same loop skeleton, $\lor$/$\land$ |

README links only — **no** package `with` of siblings.

When is Floyd–Warshall preferable? On **dense** graphs ($E=\Theta(V^{2})$)
the simple triple loop is often fastest in practice and trivial to code.
On **sparse** graphs with negatives but no cycles, **Johnson** (heap
Dijkstra) is asymptotically better; with non-negative weights, repeated
**Dijkstra** from every source is competitive. **Warshall** is the Boolean
analogue for reachability / transitive closure, not weighted distances.

## Algorithm

### Initialisation

$$
d_{ij}^{(0)}=
\begin{cases}
0 & i=j \\
w(i,j) & (i,j)\in E \\
\infty & \text{otherwise}
\end{cases}
$$

Parallel edges keep the **minimum** weight. A negative self-loop makes
$d_{ii}^{(0)}<0$ immediately (cycle).

### Triple loop (K–I–J)

For $k=1..N$, for $i=1..N$, for $j=1..N$, apply the recurrence above when
both $d_{ik}$ and $d_{kj}$ are finite (`Infinity` absorbs under addition).

### Path bookkeeping

- **Next:** on improvement, $\mathrm{Next}(i,j)\leftarrow\mathrm{Next}(i,k)$.
  Walk $u\leftarrow\mathrm{Next}(u,t)$ from $s$ to $t$.
- **Prev:** on improvement, $\mathrm{Prev}(i,j)\leftarrow\mathrm{Prev}(k,j)$.
  Walk predecessors from $t$ back to $s$ and reverse.

### Negative cycles

If some $d_{vv}<0$ after the run, vertex $v$ lies on (or can reach/be
reached from, depending on residual improvements) a **negative-weight
cycle**. Distances involving that cycle are not numerically meaningful;
status overloads return `Negative_Cycle`, and raising overloads raise
`Negative_Cycle_Error`.

### Example (Wikipedia-style)

Vertices $\{1,2,3,4\}$ with edges
$1\xrightarrow{-2}3$, $3\xrightarrow{2}4$, $4\xrightarrow{-1}2$,
$2\xrightarrow{4}1$, $2\xrightarrow{3}3$:

- Shortest $1\to 2$ is $-1$ via $1\to 3\to 4\to 2$.
- Shortest $2\to 4$ is $4$; $4\to 1$ is $3$.

### Asymptotic cost

$$
\Theta(N^{3})\quad\text{time},\qquad \Theta(N^{2})\quad\text{space}
$$

Graph / matrix storage uses fixed educational arrays up to
$\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $\Theta(N^{3})$ |
| Auxiliary / output space | $\Theta(N^{2})$ for `Dist` / `Next` / `Prev` |
| Graph storage | Dense weights up to $\mathrm{Max\_Vertices}$; distinct pairs ≤ $\mathrm{Max\_Edges}$ |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Weights | Integers in `Weight_Type` (may be negative) |
| Unreachable | $\mathrm{Dist}(u,v)=\mathrm{Infinity}$ |
| Negative cycle | $\exists v:\,\mathrm{Dist}(v,v)<0$ → `Negative_Cycle` / `Negative_Cycle_Error` |

## Features

- **`Clear` / `Add_Edge`** — build a weighted digraph on vertices $1 .. N$
  (negative weights allowed; parallels keep the minimum).
- **`Init_Dist` / `Put_Edge`** — initialise a `Dist` matrix directly from
  edges (no Graph required for in-place runs).
- **`All_Pairs` / `Floyd_Warshall`** — full APSP: `Dist`, optional `Next`
  and/or `Prev`, `Run_Status` or raising `Negative_Cycle_Error`.
- **In-place `Floyd_Warshall(Dist, …)`** — run on a caller-initialised
  matrix.
- **`Has_Negative_Cycle`** — Graph probe or post-run diagonal probe on
  `Dist`.
- **`Distance`** — single Source→Target query (raises on a negative cycle).
- **`Reconstruct_Path`** — recover a Source→Target walk from `Next` or
  `Prev` (matrix or single-source `Prev_Array`).
- **`Infinity`** — sentinel distance for unreachable pairs.
- **Capacity / range guards** — `Invalid_Argument` for bad ids, overflow,
  weight range, or insufficient matrix / path bounds.
- **Educational layout** — 1-based indices; self-contained dense DP; fixed
  arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pfloyd_warshall_algorithm.gpr`.

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

=== 1. Empty / capacity / Invalid_Argument ===
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
- Unreachable pairs = `Infinity`; disconnected components
- Wikipedia / CLRS-style example (full distance matrix)
- Path reconstruction via `Next` and `Prev` (and `Prev_Array`)
- Direct `Dist` matrix init (`Init_Dist` / `Put_Edge` / in-place FW)
- Parallel edges (minimum retained); clear/rebuild
- Chains, diamonds, shortcuts; complete digraph; star; layered DAG
- Grid; long telescoping chain; mixed-sign DAG
- `Invalid_Argument` for capacity, range, and array bounds
- `Max_Vertices` boundary APSP; Infinity sentinel
- Alias agreement `Floyd_Warshall` ↔ `All_Pairs`

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Floyd_Warshall_Algorithm is
   Max_Vertices : constant Positive := 256;
   Max_Edges    : constant Positive := 50_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Weight_Type is range -(2**30) .. 2**30 - 1;
   type Distance_Value is range -(2**62) .. 2**62 - 1;
   Infinity : constant Distance_Value := Distance_Value'Last;

   type Dist_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Distance_Value;
   type Next_Matrix is
     array (Vertex_Id range <>, Vertex_Id range <>) of Natural;
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

   procedure Init_Dist (Dist : out Dist_Matrix; N : Natural);
   procedure Put_Edge
     (Dist : in out Dist_Matrix; From, To : Vertex_Id; Weight : Integer);
   procedure Init_Dist (G : Graph; Dist : out Dist_Matrix);

   procedure All_Pairs
     (G : Graph; Dist : out Dist_Matrix; Status : out Run_Status);
   procedure All_Pairs
     (G : Graph; Dist : out Dist_Matrix; Next : out Next_Matrix;
      Status : out Run_Status);
   procedure All_Pairs
     (G : Graph; Dist : out Dist_Matrix; Prev : out Prev_Matrix;
      Status : out Run_Status);
   procedure Floyd_Warshall
     (G : Graph; Dist : out Dist_Matrix; Status : out Run_Status);
   procedure Floyd_Warshall
     (Dist : in out Dist_Matrix; N : Natural; Status : out Run_Status);

   function Has_Negative_Cycle (G : Graph) return Boolean;
   function Has_Negative_Cycle
     (Dist : Dist_Matrix; N : Natural) return Boolean;
   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value;

   function Reconstruct_Path
     (Next : Next_Matrix; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural) return Boolean;
   function Reconstruct_Path
     (Prev : Prev_Matrix; Source, Target : Vertex_Id;
      Path : out Path_Array; Length : out Natural) return Boolean;
end Floyd_Warshall_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, `Weight` outside `Weight_Type`, $N=0$ on search APIs, or
`Dist`/`Next`/`Prev`/`Path` with `First /= 1` or `Last < N`.

On a negative-weight cycle, status overloads return `Negative_Cycle`;
raising overloads and `Distance` raise `Negative_Cycle_Error`.

Path convention: on success `Path(1) = Source`, `Path(Length) = Target`,
and `Length` is the number of vertices (arc count $= Length - 1$).
`Next(S, S) = S`; `Prev(S, S) = 0`; unreachable targets leave
`Dist = Infinity`.

## License

Educational reference implementation. See repository `LICENSE` if present.
