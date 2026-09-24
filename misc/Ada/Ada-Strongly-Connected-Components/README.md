# Strongly Connected Components (survey) in Ada 2023

## Project Overview

A directed graph is **strongly connected** when every vertex is reachable
from every other vertex. The **strongly connected components** (SCCs) of a
digraph $G = (V, E)$ are the maximal strongly connected subgraphs; they
partition $V$. Equivalently, $u$ and $v$ lie in the same SCC iff there is a
directed path $u \rightsquigarrow v$ and $v \rightsquigarrow u$. Contracting
each SCC to a supernode yields the **condensation**, a directed acyclic
graph (DAG). A digraph is acyclic iff every SCC is a trivial singleton
(no non-trivial directed cycle).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational **survey**
of the three classical **linear-time DFS** algorithms that compute SCCs:

| `Method` | Idea | Passes |
| --- | --- | --- |
| `Tarjan` | One DFS + stack + **low-link** / index (Tarjan 1972) | 1 |
| `Kosaraju` | Finish-order DFS on $G$, then Assign on transpose $G^\top$ | 2 |
| `Path_Based` | One DFS + **two stacks** $S,P$ (Dijkstra / Gabow / Cheriyan–Mehlhorn) | 1 |

All three run in $O(|V|+|E|)$ and return the **same partition** of $V$
(component id numbers may differ: Tarjan and path-based emit **reverse**
topological condensation order; Kosaraju emits **topological** order).
Vertices are indexed from $1$; adjacency lists live in fixed educational
arrays (no dynamic heap beyond stack-sized workspaces).

Primary source:
[Wikipedia — Strongly connected component](https://en.wikipedia.org/wiki/Strongly_connected_component).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Role |
| --- | --- |
| **This package** (`Ada-Strongly-Connected-Components`) | Survey: shared graph API + `Method` enum dispatching all three |
| Tarjan (`Ada-Tarjans-Strongly-Connected-Components`) | Standalone Tarjan low-link sheet |
| Kosaraju (`Ada-Kosarajus-Algorithm`) | Standalone Kosaraju–Sharir sheet |
| Path-based (`Ada-Path-Based-Strong-Component`) | Standalone two-stack sheet |

README links only — **no** package `with` of siblings. Implementations here
are **inline** and self-contained.

## Algorithms

### Condensation DAG

If each SCC is contracted to a single vertex, the resulting digraph is
acyclic: any directed cycle would merge into one component. Edges between
distinct SCCs induce a partial order on components. Educational
numberings:

- **Kosaraju** assigns ids so sources of the remaining condensation come
  first (topological order of the DAG).
- **Tarjan** / **Path_Based** finish an SCC when its root is discovered as
  such, so ids increase in **reverse** topological order.

The survey API therefore compares partitions with co-membership
(`Same_SCC`), not raw id equality across methods.

### Tarjan (one pass, low-link)

DFS numbering $\mathrm{Index}(v)$, $\mathrm{LowLink}(v)$, and an explicit
stack of vertices that may still belong to an unfinished SCC. When
$\mathrm{LowLink}(v) = \mathrm{Index}(v)$, $v$ is an SCC root: pop the
stack until $v$ inclusive into a new component.

### Kosaraju–Sharir (two passes)

1. DFS on $G$: push each vertex onto finish stack $L$ in post-order.
2. Build transpose $G^\top$.
3. DFS on $G^\top$ in reverse finish order; each unassigned root starts a
   new component (Assign tree).

$G$ and $G^\top$ share exactly the same SCCs.

### Path-based (two stacks)

Maintain $S$ (unassigned vertices in discovery order) and $P$ (path /
preorder merge frontier). Tree edges recurse; non-tree edges into the
current forest contract $P$ until $\mathrm{Preorder}(\mathrm{top}(P))
\le \mathrm{Preorder}(w)$. When $v$ remains on top of $P$ after scanning
its edges, pop $S$ through $v$ into a new component.

### Example

Graph on $\{1,2,3,4,5\}$ with edges $1\to 2\to 3\to 1$, $2\to 4$,
$4\to 5\to 4$:

- SCC $\{1,2,3\}$ (triangle);
- SCC $\{4,5\}$ (mutual pair).

A forward chain $1\to 2\to 3\to 4$ (no back edges) yields four singleton
SCCs — the condensation equals the graph itself.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (any `Method`) | $O(\|V\| + \|E\|)$ |
| Tarjan / Path_Based aux | $O(\|V\|)$ stacks and arrays |
| Kosaraju aux | $O(\|V\| + \|E\|)$ (finish stack + transpose pool) |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Method` enum** — `Tarjan`, `Kosaraju`, `Path_Based`.
- **`Compute_SCC`** — dispatch by `Method` into
  `Component_Of(V) ∈ 1 .. Count`.
- **`Same_SCC`** — Boolean co-membership on a completed labelling.
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or mismatched `Component_Of` bounds.
- **Cross-method agreement** — tests verify identical partitions up to
  component id renumbering.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pstrongly_connected_components.gpr`.

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

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty graph, single vertex, self-loops, isolated vertices
- Chains and DAGs (all singleton SCCs)
- 2-cycles, $k$-cycles, linked pairs of cycles
- Classic multi-SCC textbook graphs
- Small complete digraphs ($K_3$, $K_4$, $K_5$)
- Disconnected unions of cycles and arcs
- Condensation properties (DAG of components; agreement across methods)
- Parallel edges, clear/reset, API counters
- `Invalid_Argument` for capacity, range, and bound errors
- Larger patterns (multiple 2-cycles, long cycles, many isolates)
- **Triple agreement**: every fixture is run under all three `Method`
  values and partitions are compared pairwise up to renumbering

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Strongly_Connected_Components is
   Max_Vertices : constant Positive := 1_000;
   Max_Edges    : constant Positive := 100_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Component_Id is new Natural;
   type Component_Array is array (Vertex_Id range <>) of Component_Id;

   type Method is (Tarjan, Kosaraju, Path_Based);

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Compute_SCC
     (G               : Graph;
      Algo            : Method;
      Component_Of    : out Component_Array;
      Component_Count : out Natural);

   function Same_SCC
     (Component_Of : Component_Array;
      U, V         : Vertex_Id) return Boolean;
end Strongly_Connected_Components;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, or `Component_Of` bounds that do not cover $1 .. N$.

## License

Educational reference implementation. See repository `LICENSE` if present.
