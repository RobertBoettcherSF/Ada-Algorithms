# Flow Networks (survey) in Ada 2023

## Project Overview

A **flow network** is a directed graph $G=(V,E)$ with a non-negative
capacity $c(u,v)$ on each arc and two distinguished terminals — a
**source** $s$ and a **sink** $t$. A **feasible flow** $f$ obeys the
capacity constraint $0\le f(u,v)\le c(u,v)$ and **conservation** at every
vertex except $s$ and $t$. The **value** of the flow is the net outflow of
the source (equivalently the net inflow of the sink):

$$
|f|=-\,x_{f}(s)=x_{f}(t).
$$

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
**survey** of flow-network concepts and maximum $s$–$t$ flow. It models
the network $(G,c,s,t)$ with `Clear` / `Add_Edge` / Source–Sink helpers,
and embeds two classical max-flow algorithms **in-package** (no package
`with` of sibling Ada-* sheets):

| `Method` | Idea | Bound |
| --- | --- | --- |
| `Edmonds_Karp` | Ford–Fulkerson with BFS **shortest** residual paths | $O(VE^{2})$ |
| `Dinic` | Level graph (BFS) + **blocking** flows (DFS) | $O(V^{2}E)$ |

On **integer** capacities both return the same *value*; they differ in
path / phase strategy and asymptotic cost. Vertices are indexed from $1$;
residual reverse arcs are installed by `Add_Edge`; fixed educational
arrays (no dynamic heap).

Primary source:
[Wikipedia — Flow network](https://en.wikipedia.org/wiki/Flow_network).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with FF / EK / Dinic / Push–relabel siblings

| Package / method | Role |
| --- | --- |
| **This package** (`Ada-Flow-Networks`) | Survey: network model + `Method` enum dispatching EK and Dinic; max-flow min-cut APIs |
| Ford–Fulkerson (README only) | Augmenting-path *method*; path search unspecified (often DFS); $O(E\cdot\|f^{*}\|)$ on integer capacities |
| Edmonds–Karp (`Ada-Edmonds-Karp-Algorithm`) | Standalone BFS shortest residual paths; $O(VE^{2})$ |
| Dinic (`Ada-Dinics-Algorithm`) | Standalone level graph + blocking flows; $O(V^{2}E)$ |
| Push–relabel (README only) | Local height / excess pushes; practical $O(V^{2}\sqrt{E})$ variants |

README links only — **no** package `with` of siblings. Implementations here
are **inline** and self-contained.

## Concepts

### Residual graph and augmenting paths

Given a flow $f$, the **residual capacity** is

$$
c_{f}(u,v)=c(u,v)-f(u,v)
$$

(with reverse residual $c_{f}(v,u)=f(u,v)$ when the reverse original
capacity is zero). An **augmenting path** is a Source$\leadsto$Sink walk
of positive residual capacity. A network is at maximum flow iff no
augmenting path remains (Ford–Fulkerson correctness).

### Max-flow min-cut theorem

When no Source$\leadsto$Sink residual path exists, let $S$ be the set of
vertices reachable from Source in the residual graph and $T=V\setminus S$.
Then $(S,T)$ is a **minimum $s$–$t$ cut**, and

$$
|f|=\sum_{u\in S,\,v\in T} c(u,v).
$$

`Min_Cut_Partition` reports the indicator of $S$; `Cut_Capacity` sums the
original capacities of user edges crossing $(S,T)$.

### Edmonds–Karp vs Dinic (in this survey)

**Edmonds–Karp** repeatedly finds a *shortest* residual path by BFS and
augments once. There are $O(VE)$ augmentations, each $O(E)$, hence
$O(VE^{2})$.

**Dinic** builds a **level graph** by BFS and then pushes a **blocking
flow** along level edges (current-edge DFS) until the level graph is
blocked. Each phase strictly increases the Source–Sink distance; there
are $O(V)$ phases, each $O(VE)$, hence $O(V^{2}E)$.

### Example

Diamond on $\{1,2,3,4\}$: edges $1\to 2:3$, $1\to 3:2$, $2\to 3:5$,
$2\to 4:2$, $3\to 4:3$. Maximum $1\to 4$ flow is $5$, and the min-cut
capacity equals $5$. Both `Edmonds_Karp` and `Dinic` return $5$.

Wikipedia's seven-node Edmonds–Karp network (source $A$, sink $G$) has
maximum flow $5$, equal to the unique min-cut
$c(A,D)+c(C,D)+c(E,G)=3+1+1=5$.

### Pseudocode (dispatch)

```text
function Max_Flow(N, source, sink, algo):
    store terminals; reset residual from original edges
    if algo = Edmonds_Karp:
        while BFS finds shortest residual path P:
            augment by bottleneck(P)
    else:  -- Dinic
        while BFS builds a level graph reaching sink:
            push blocking flow by DFS along level edges
    return total flow value
```

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Edmonds_Karp`) | $O(VE^{2})$ |
| Time (`Dinic`) | $O(V^{2}E)$ |
| Auxiliary space | $O(V)$ queues / levels / parent scratch |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays (residual pool $2E$) |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed user edges |
| Output | Flow value; per-edge flow; min-cut partition / cut capacity |

## Features

- **`Clear` / `Add_Edge`** — directed flow network on vertices $1 .. N$
  with integer capacities $\ge 0$; residual reverse arcs installed automatically.
- **`Set_Source` / `Set_Sink` / `Source` / `Sink` / `Has_*`** — terminals
  for the $(G,c,s,t)$ model; `Max_Flow(N, Algo)` uses stored terminals.
- **`Method` enum** — `Edmonds_Karp`, `Dinic` (inline implementations).
- **`Max_Flow`** — dispatch by `Method`; stores terminals on the
  Source/Sink overload.
- **`Min_Cut_Partition` / `Cut_Capacity`** — residual reachability and
  cut capacity (max-flow = min-cut).
- **`Edge_From` / `Edge_To` / `Edge_Capacity` / `Edge_Flow`** — inspect
  user edges after a flow computation.
- **Capacity / request guards** — `Invalid_Argument` for bad ids, negative
  capacity, overflow, empty network, unset terminals, or bad array / edge index.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pflow_networks.gpr`.

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

(Exact `NN` is the current suite size; it is at least 180.)

## Testing

The test suite in `tests.adb` covers:

- Clear / Add_Edge / Source–Sink helpers / parallel edges / negative capacity
- Classic textbook networks (diamond flow $5$, Wikipedia seven-node
  flow $5$, CLRS-style flow $23$)
- **Edmonds–Karp ≡ Dinic** on shared samples
- Max-flow = min-cut on chains, parallel paths, and random digraphs
- Flow conservation at intermediate vertices
- Trivial Source$=$Sink, disconnected, zero-capacity, self-loops
- `Invalid_Argument` for range, capacity, unset terminals, and bound errors
- Volume battery over paths and dense digraphs

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Flow_Networks is
   Max_Vertices : constant Positive := 512;
   Max_Edges    : constant Positive := 20_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Capacity_Type is range 0 .. 2**31 - 1;
   type Flow_Value is range 0 .. 2**63 - 1;
   type Reachability_Array is array (Vertex_Id range <>) of Boolean;
   type Method is (Edmonds_Karp, Dinic);

   type Network is limited private;
   Invalid_Argument : exception;

   procedure Clear (N : in out Network; Vertex_Count : Natural);
   procedure Add_Edge
     (N : in out Network; From, To : Vertex_Id; Capacity : Integer);
   function Vertex_Count (N : Network) return Natural;
   function Edge_Count (N : Network) return Natural;

   procedure Set_Source (N : in out Network; Source : Vertex_Id);
   procedure Set_Sink (N : in out Network; Sink : Vertex_Id);
   function Has_Source (N : Network) return Boolean;
   function Has_Sink (N : Network) return Boolean;
   function Source (N : Network) return Vertex_Id;
   function Sink (N : Network) return Vertex_Id;

   function Max_Flow
     (N : in out Network; Source, Sink : Vertex_Id;
      Algo : Method := Edmonds_Karp) return Flow_Value;
   function Max_Flow
     (N : in out Network; Algo : Method := Edmonds_Karp) return Flow_Value;

   procedure Min_Cut_Partition
     (N : Network; Source : Vertex_Id; In_S : out Reachability_Array);
   function Cut_Capacity
     (N : Network; In_S : Reachability_Array) return Flow_Value;

   function Edge_From (N : Network; Index : Positive) return Vertex_Id;
   function Edge_To (N : Network; Index : Positive) return Vertex_Id;
   function Edge_Capacity (N : Network; Index : Positive) return Capacity_Type;
   function Edge_Flow (N : Network; Index : Positive) return Flow_Value;
end Flow_Networks;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, negative capacities, empty network on flow APIs, unset
Source/Sink when required, bad `Reachability_Array` bounds, or edge
`Index` outside $1 .. M$.

The network is **directed** with **integer capacities**. Each `Add_Edge`
stores one user arc and a paired residual reverse arc.

## License

Educational reference implementation. See repository `LICENSE` if present.
