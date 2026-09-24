# Edmonds–Karp Algorithm in Ada 2023

## Project Overview

The **Edmonds–Karp algorithm** is the **Ford–Fulkerson method** with a
fully specified search for **augmenting paths**: each path is a
**shortest residual $s$–$t$ path** in the number of edges, found by
**breadth-first search** (unit hop weight). The resulting maximum-flow
algorithm is strongly polynomial,

$$
O(VE^{2}).
$$

Yefim Dinitz published the idea in 1970; Jack Edmonds and Richard Karp
published it independently in 1972. (Dinitz's later **Dinic** algorithm
adds a level graph and blocking flows, improving the bound to
$O(V^{2}E)$ — that method is **not** this package.)

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, directed integer capacities in
fixed arrays (no dynamic heap), residual reverse arcs installed by
`Add_Edge`, `Max_Flow` (BFS / fewest-edge augmenting paths), per-edge
flows, and a min-cut partition from residual reachability.

Primary source:
[Wikipedia — Edmonds–Karp algorithm](https://en.wikipedia.org/wiki/Edmonds%E2%80%93Karp_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Ford–Fulkerson / Dinic / Push–relabel

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Edmonds-Karp-Algorithm`) | Ford–Fulkerson with BFS shortest residual paths; $O(VE^{2})$ |
| Ford–Fulkerson (README only) | Augmenting-path *method*; path search unspecified (often DFS); $O(E\cdot\|f^{*}\|)$ on integer capacities |
| Dinic (README only) | Level graph + blocking flows; $O(V^{2}E)$ (better on unit networks) |
| Push–relabel (README only) | Local height / excess pushes; practical $O(V^{2}\sqrt{E})$ variants |

README links only — **no** package `with` of siblings. On **integer**
capacities all correct max-flow algorithms return the same *value*; they
differ in path / push strategy and asymptotic cost. Edmonds–Karp is the
canonical polynomial specialisation of Ford–Fulkerson.

## Algorithm

### Residual graph and shortest augmenting paths

Given a flow network $G=(V,E)$ with capacity $c(u,v)\ge 0$ and flow
$f$, the **residual capacity** is

$$
c_{f}(u,v)=c(u,v)-f(u,v)
$$

(with reverse residual $c_{f}(v,u)=f(u,v)$ when the reverse original
capacity is zero). An **augmenting path** is a Source$\leadsto$Sink walk
in which every residual capacity is positive. Edmonds–Karp always
chooses a path $P$ of **minimum hop length**. Pushing the bottleneck

$$
\Delta=\min_{(u,v)\in P} c_{f}(u,v)
$$

along $P$ increases the net Source$\to$Sink flow by $\Delta$. The length
of the shortest residual path increases monotonically; each of the $E$
edges is critical $O(V)$ times, giving $O(VE)$ augmentations.

### Pseudocode

```text
function Max_Flow(G, source, sink):   -- Edmonds–Karp
    reset residual capacities from original edges
    total := 0
    loop
        P := BFS shortest residual path source ↝ sink
        exit when P does not exist
        Δ := bottleneck(P)
        augment residual along P by Δ
        total := total + Δ
    return total
```

### Max-flow min-cut

When no Source$\leadsto$Sink residual path remains, let $S$ be the set of
vertices reachable from Source in the residual graph and $T=V\setminus S$.
Then $(S,T)$ is a **minimum $s$–$t$ cut**, and

$$
|f|=\sum_{u\in S,\,v\in T} c(u,v)
$$

### Example

Wikipedia's seven-node network (source $A$, sink $G$) has capacities
$A\to B:3$, $A\to D:3$, $B\to C:4$, $C\to D:1$, $C\to E:2$, $D\to E:2$,
$D\to F:6$, $E\to G:1$, $F\to G:9$. Edmonds–Karp augments along shortest
paths $A,D,E,G$ ($\Delta=1$), $A,D,F,G$ ($\Delta=2$), $A,B,C,D,F,G$
($\Delta=1$), $A,B,C,E,D,F,G$ ($\Delta=1$). Maximum flow is $5$, equal to
the unique min-cut

$$
c(A,D)+c(C,D)+c(E,G)=3+1+1=5
$$

with partition $\{A,B,C,E\}$ / $\{D,F,G\}$.

A smaller diamond: vertices $\{1,2,3,4\}$, edges $1\to2:3$, $1\to3:2$,
$2\to3:5$, $2\to4:2$, $3\to4:3$. Maximum $1\to4$ flow is $5$.

### Asymptotic cost

Each BFS is $O(E)$. There are $O(VE)$ augmentations, so

$$
O(VE^{2}).
$$

Graph storage is $O(V+E)$ in fixed arrays up to $\mathrm{Max\_Vertices}$ /
$\mathrm{Max\_Edges}$ (each user edge stores a residual pair).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Max_Flow`, BFS) | $O(VE^{2})$ |
| Augmentations | $O(VE)$ (each edge critical $O(V)$ times) |
| Per augmentation | $O(E)$ BFS + $O(V)$ bottleneck / update |
| Auxiliary space | $O(V)$ BFS queue / parent scratch |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays (residual pool $2E$) |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed user edges |
| Output | Flow value; optional per-edge flow; min-cut partition |

## Features

- **`Clear` / `Add_Edge`** — directed flow network on vertices $1 .. N$
  with integer capacities $\ge 0$; residual reverse arcs installed automatically.
- **`Vertex_Count` / `Edge_Count`** — size queries (user edges only).
- **`Max_Flow`** — Edmonds–Karp (BFS / shortest residual path).
- **`Min_Cut_Partition` / `Cut_Capacity`** — source-side residual
  reachability and cut capacity (max-flow = min-cut).
- **`Edge_From` / `Edge_To` / `Edge_Capacity` / `Edge_Flow`** — inspect
  user edges after a flow computation.
- **Capacity / range guards** — `Invalid_Argument` for bad ids, negative
  capacity, overflow, empty graph on flow APIs, or bad array / edge index.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pedmonds_karp_algorithm.gpr`.

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

=== 1. Clear / Add_Edge / counts ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Clear / Add_Edge / parallel edges / negative capacity rejection
- Classic textbook networks (diamond flow $5$, Wikipedia seven-node
  flow $5$, CLRS-style flow $23$)
- Max-flow = min-cut on chains, parallel paths, and random digraphs
- Flow conservation at intermediate vertices
- Trivial Source$=$Sink, disconnected, zero-capacity, self-loops
- `Invalid_Argument` for range, capacity, and bound errors
- Volume battery over paths and dense digraphs

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Edmonds_Karp_Algorithm is
   Max_Vertices : constant Positive := 512;
   Max_Edges    : constant Positive := 20_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Capacity_Type is range 0 .. 2**31 - 1;
   type Flow_Value is range 0 .. 2**63 - 1;
   type Reachability_Array is array (Vertex_Id range <>) of Boolean;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Capacity : Integer);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   function Max_Flow
     (G : in out Graph; Source, Sink : Vertex_Id) return Flow_Value;

   procedure Min_Cut_Partition
     (G : Graph; Source : Vertex_Id; In_S : out Reachability_Array);
   function Cut_Capacity
     (G : Graph; In_S : Reachability_Array) return Flow_Value;

   function Edge_From (G : Graph; Index : Positive) return Vertex_Id;
   function Edge_To (G : Graph; Index : Positive) return Vertex_Id;
   function Edge_Capacity (G : Graph; Index : Positive) return Capacity_Type;
   function Edge_Flow (G : Graph; Index : Positive) return Flow_Value;
end Edmonds_Karp_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, negative capacities, empty graph on flow APIs, bad
`Reachability_Array` bounds, or edge `Index` outside $1 .. M$.

The network is **directed** with **integer capacities**. Each `Add_Edge`
stores one user arc and a paired residual reverse arc.

## License

Educational reference implementation. See repository `LICENSE` if present.
