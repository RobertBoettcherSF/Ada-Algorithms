# Tarjan's Strongly Connected Components in Ada 2023

## Project Overview

**Tarjan's strongly connected components algorithm** partitions the vertices
of a **directed graph** into its **strongly connected components** (SCCs)
in a single depth-first search forest pass. Two vertices $u$ and $v$ lie in
the same SCC iff each is reachable from the other. The algorithm maintains
DFS discovery times, **low-link** values, and an explicit stack of vertices
that may still belong to an unfinished component; when a vertex $v$ is a
component root ($\mathrm{lowlink}(v) = \mathrm{index}(v)$), the stack is
popped through $v$ to emit one SCC.

Robert Tarjan (1972) introduced the method; it matches the linear-time
bound of Kosaraju's two-pass algorithm and the path-based strong component
algorithm. Donald Knuth called Tarjan's SCC structures among his favourite
graph implementations (Stanford GraphBase).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, adjacency lists in fixed
educational arrays (no dynamic heap beyond stack-sized workspaces), and
$O(|V|+|E|)$ documented complexity.

Primary source:
[Wikipedia — Tarjan's strongly connected components algorithm](https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Tarjans-Strongly-Connected-Components`) | One-pass DFS + stack + low-link SCCs |
| Kosaraju (sibling sheet) | Two DFS passes (transpose graph) |
| Path-based strong components (sibling sheet) | Dual stacks, same linear bound |

README links only — **no** package `with` of siblings.

## Algorithm

### Strong connectivity

A directed graph $G = (V, E)$ has a strongly connected component for each
maximal set $C \subseteq V$ such that for all $u, v \in C$, there is a
directed path $u \rightsquigarrow v$ and $v \rightsquigarrow u$. Vertices
not on any directed cycle form singleton SCCs. The **condensation** of $G$
(contract each SCC to a supernode) is a DAG.

### DFS numbering, stack, and low-link

Process every unvisited vertex with `Strong_Connect(v)`:

1. Assign $\mathrm{index}(v) \leftarrow \mathrm{lowlink}(v) \leftarrow t$;
   increment the global DFS clock $t$; push $v$; mark $v$ on the stack.
2. For each edge $v \rightarrow w$:
   - if $w$ is unvisited, recurse and set
     $\mathrm{lowlink}(v) \leftarrow \min(\mathrm{lowlink}(v), \mathrm{lowlink}(w))$;
   - else if $w$ is on the stack, set
     $\mathrm{lowlink}(v) \leftarrow \min(\mathrm{lowlink}(v), \mathrm{index}(w))$.
3. If $\mathrm{lowlink}(v) = \mathrm{index}(v)$, pop the stack until $v$
   inclusive; those vertices form one SCC.

Invariant: a visited vertex remains on the stack iff there is a path from
it to some earlier stack vertex. Roots are exactly the vertices with
$\mathrm{lowlink} = \mathrm{index}$. This package uses Tarjan's classic
update with $\mathrm{index}(w)$ (not $\mathrm{lowlink}(w)$) when $w$ is on
the stack.

SCCs are emitted in **reverse topological order** of the condensation DAG:
the first finished component receives `Component_Id` $1$.

### Example

Graph on vertices $\{1,2,3,4,5\}$ with edges
$1\to 2\to 3\to 1$, $2\to 4$, $4\to 5\to 4$:

- SCC $\{1,2,3\}$ (the triangle);
- SCC $\{4,5\}$ (the mutual pair).

A forward chain $1\to 2\to 3\to 4$ with no back edges yields four singleton
SCCs (every DAG vertex is its own component).

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(\|V\| + \|E\|)$ |
| Auxiliary space | $O(\|V\|)$ (index, low-link, on-stack, DFS stack) |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Compute_SCC`** — Tarjan partition into `Component_Of(V) ∈ 1 .. Count`.
- **`Same_SCC`** — Boolean co-membership test on a completed labelling.
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or mismatched `Component_Of` bounds.
- **Educational layout** — 1-based indices; no heap beyond fixed arrays
  sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ptarjans_scc.gpr`.

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
- Parallel edges, clear/reset, API counters
- `Invalid_Argument` for capacity, range, and bound errors
- Larger patterns (five 2-cycles, 20-cycle, 50 isolates)

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Tarjans_SCC is
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
end Tarjans_SCC;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, or `Component_Of` bounds that do not cover $1 .. N$.

## License

Educational reference implementation. See repository `LICENSE` if present.
