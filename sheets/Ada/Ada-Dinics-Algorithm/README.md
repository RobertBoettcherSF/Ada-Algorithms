# Dinic's Algorithm in Ada 2023

## Project Overview

**Dinic's algorithm** (also **Dinitz's algorithm**), invented by Yefim
Dinitz in 1970, computes a **maximum $s$–$t$ flow** by alternating
**level-graph** phases (BFS hop distances in the residual network) with
**blocking flows** (DFS along edges that advance one level at a time).
The resulting algorithm is strongly polynomial,

$$
O(V^{2}E).
$$

It improves on **Edmonds–Karp** ($O(VE^{2})$), which also uses shortest
augmenting paths but pushes only **one** path per BFS. Dinic reuses a
single level graph until it is blocked.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, directed integer capacities in
fixed arrays (no dynamic heap), residual reverse arcs installed by
`Add_Edge`, `Max_Flow` (BFS levels + DFS blocking flow), per-edge flows,
and a min-cut partition from residual reachability.

Primary source:
[Wikipedia — Dinic's algorithm](https://en.wikipedia.org/wiki/Dinic%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Edmonds–Karp / Ford–Fulkerson / Push–relabel

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Dinics-Algorithm`) | Level graph + blocking flows; $O(V^{2}E)$ |
| Edmonds–Karp (README only) | Ford–Fulkerson with BFS shortest residual paths; $O(VE^{2})$ |
| Ford–Fulkerson (README only) | Augmenting-path *method*; path search unspecified (often DFS); $O(E\cdot\|f^{*}\|)$ on integer capacities |
| Push–relabel (README only) | Local height / excess pushes; practical $O(V^{2}\sqrt{E})$ variants |

README links only — **no** package `with` of siblings. On **integer**
capacities all correct max-flow algorithms return the same *value*; they
differ in path / push strategy and asymptotic cost. Dinic is typically
faster than Edmonds–Karp in practice and asymptotically better on unit
networks ($O(\min\{V^{2/3},E^{1/2}\}E)$ with suitable analysis).

## Algorithm

### Residual graph, level graph, blocking flow

Given a flow network $G=(V,E)$ with capacity $c(u,v)\ge 0$ and flow
$f$, the **residual capacity** is

$$
c_{f}(u,v)=c(u,v)-f(u,v)
$$

(with reverse residual $c_{f}(v,u)=f(u,v)$ when the reverse original
capacity is zero). Let $\operatorname{dist}(v)$ be the hop distance from
Source to $v$ in the residual graph. The **level graph** keeps only edges
$(u,v)$ with

$$
\operatorname{dist}(v)=\operatorname{dist}(u)+1.
$$

A **blocking flow** on the level graph is a flow such that every
Source$\leadsto$Sink path in the level graph uses at least one saturated
edge. After a blocking flow is pushed into the residual network, the next
BFS yields a strictly larger Source–Sink distance (or Sink is unreachable).

### Pseudocode

```text
function Max_Flow(G, source, sink):   -- Dinic
    reset residual capacities from original edges
    total := 0
    loop
        build level graph by BFS from source
        exit when sink unreachable
        reset current-edge pointers to adjacency heads
        loop
            Δ := DFS push along one level path (≤ ∞)
            exit when Δ = 0          -- blocking flow complete
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
$D\to F:6$, $E\to G:1$, $F\to G:9$. Dinic builds level graphs and pushes
blocking flows until the residual Source–Sink distance grows past
reachability. Maximum flow is $5$, equal to the unique min-cut

$$
c(A,D)+c(C,D)+c(E,G)=3+1+1=5
$$

with partition $\{A,B,C,E\}$ / $\{D,F,G\}$.

A smaller diamond: vertices $\{1,2,3,4\}$, edges $1\to2:3$, $1\to3:2$,
$2\to3:5$, $2\to4:2$, $3\to4:3$. Maximum $1\to4$ flow is $5$.

### Asymptotic cost

There are $O(V)$ phases (Source–Sink distance increases each phase). Each
phase costs $O(VE)$ with current-edge DFS, so

$$
O(V^{2}E).
$$

Graph storage is $O(V+E)$ in fixed arrays up to $\mathrm{Max\_Vertices}$ /
$\mathrm{Max\_Edges}$ (each user edge stores a residual pair).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Max_Flow`) | $O(V^{2}E)$ |
| Phases | $O(V)$ (distance increases each phase) |
| Per phase | $O(VE)$ BFS + blocking DFS |
| Auxiliary space | $O(V)$ level / queue / current-edge scratch |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays (residual pool $2E$) |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed user edges |
| Output | Flow value; optional per-edge flow; min-cut partition |

## Features

- **`Clear` / `Add_Edge`** — directed flow network on vertices $1 .. N$
  with integer capacities $\ge 0$; residual reverse arcs installed automatically.
- **`Vertex_Count` / `Edge_Count`** — size queries (user edges only).
- **`Max_Flow`** — Dinic (BFS level graph + DFS blocking flow).
- **`Min_Cut_Partition` / `Cut_Capacity`** — source-side residual
  reachability and cut capacity (max-flow = min-cut).
- **`Edge_From` / `Edge_To` / `Edge_Capacity` / `Edge_Flow`** — inspect
  user edges after a flow computation.
- **Capacity / index guards** — `Invalid_Argument` for bad ids, negative
  capacity, overflow, empty graph on flow APIs, or bad array / edge index.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pdinics_algorithm.gpr`.

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
package Dinics_Algorithm is
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
end Dinics_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, negative capacities, empty graph on flow APIs, bad
`Reachability_Array` bounds, or edge `Index` outside $1 .. M$.

The network is **directed** with **integer capacities**. Each `Add_Edge`
stores one user arc and a paired residual reverse arc.

## License

Educational reference implementation. See repository `LICENSE` if present.
