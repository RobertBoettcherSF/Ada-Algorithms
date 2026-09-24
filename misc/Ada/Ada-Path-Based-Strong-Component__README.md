# Path-Based Strong Component Algorithm in Ada 2023

## Project Overview

The **path-based strong component algorithm** partitions the vertices of a
**directed graph** into its **strongly connected components** (SCCs) in a
single depth-first search forest pass. Two vertices $u$ and $v$ lie in the
same SCC iff each is reachable from the other. The method keeps **two
stacks**: $S$ holds vertices not yet assigned to a component, and $P$
holds vertices that have not yet been shown to belong to distinct
components (the current DFS path / preorder merge frontier). When a
completed SCC **root** $v$ is found ($v$ remains the top of $P$), $S$ is
popped through $v$ to emit one component.

Versions appear in Purdom (1970), Munro (1971), Dijkstra (1976; first
linear-time formulation), Cheriyan & Mehlhorn (1996), and Gabow (2000).
The bound matches Tarjan's low-link algorithm and Kosaraju's two-pass
method: $O(|V|+|E|)$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation of the Gabow / Cheriyan–Mehlhorn two-stack DFS:
vertices indexed from $1$, adjacency lists in fixed educational arrays
(no dynamic heap beyond stack-sized workspaces), and $O(|V|+|E|)$
documented complexity.

Primary source:
[Wikipedia — Path-based strong component algorithm](https://en.wikipedia.org/wiki/Path-based_strong_component_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with graph siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Path-Based-Strong-Component`) | One-pass DFS + **two stacks** $S,P$ (no low-link) |
| Tarjan (`Ada-Tarjans-Strongly-Connected-Components`) | One-pass DFS + one stack + **low-link** / index |
| Kosaraju (sibling sheet) | **Two DFS** passes (graph then transpose) |

README links only — **no** package `with` of siblings.

All three report the same partition of $V$ and run in linear time. This
package never computes $\mathrm{lowlink}$ values: path contraction on $P$
replaces Tarjan's min-updates, and a single DFS forest replaces Kosaraju's
second search on $G^\top$.

## Algorithm

### Strong connectivity

A directed graph $G = (V, E)$ has a strongly connected component for each
maximal set $C \subseteq V$ such that for all $u, v \in C$, there is a
directed path $u \rightsquigarrow v$ and $v \rightsquigarrow u$. Vertices
not on any directed cycle form singleton SCCs. The **condensation** of $G$
(contract each SCC to a supernode) is a DAG.

### Two stacks, preorder, and path contraction

Process every unvisited vertex with `Visit(v)`:

1. Assign $\mathrm{preorder}(v) \leftarrow C$; increment the discovery
   counter $C$; push $v$ onto both $S$ and $P$.
2. For each edge $v \rightarrow w$:
   - if $w$ is unvisited, recurse (`Visit(w)` — tree edge);
   - else if $w$ is not yet assigned to an SCC (forward / back / cross
     edge into the current forest), repeatedly pop $P$ until
     $\mathrm{preorder}(\mathrm{top}(P)) \le \mathrm{preorder}(w)$.
3. If $v$ is the top of $P$, $v$ is an SCC root: pop $S$ until $v$
   inclusive; those vertices form one SCC; then pop $v$ from $P$.

Invariant: $S$ stores every discovered vertex still unassigned, in DFS
order. $P$ stores a subsequence of $S$ — the candidates for being the
root of the SCC that will contain the current vertex. A back / cross edge
to an unassigned $w$ contracts that path so a later vertex cannot be
declared a root until the earlier vertex on $P$ finishes.

SCCs are emitted in **reverse topological order** of the condensation DAG:
the first finished component receives `Component_Id` $1$.

### Example

Graph on vertices $\{1,2,3,4,5\}$ with edges
$1\to 2\to 3\to 1$, $2\to 4$, $4\to 5\to 4$:

- SCC $\{1,2,3\}$ (the triangle);
- SCC $\{4,5\}$ (the mutual pair).

A forward chain $1\to 2\to 3\to 4$ with no back edges yields four singleton
SCCs (every DAG vertex is its own component).

### Worked path-stack step

On the 3-cycle $1\to 2\to 3\to 1$, discovery pushes $1,2,3$ onto $S$ and
$P$. The back edge $3\to 1$ pops $P$ until $1$ (the only vertex with
preorder $\le \mathrm{preorder}(1)$). Vertices $2$ and $3$ are therefore
not roots; when `Visit(1)` returns to the root test, $1$ is still
$\mathrm{top}(P)$, so $S$ is popped through $1$ and $\{1,2,3\}$ is emitted
as a single SCC.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time | $O(\|V\| + \|E\|)$ |
| Auxiliary space | $O(\|V\|)$ (preorder, assigned, stacks $S$ and $P$) |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed edges (parallels allowed) |

Each vertex is pushed and popped on $S$ and on $P$ at most once; each
edge is examined a constant number of times.

## Features

- **`Clear` / `Add_Edge`** — build a digraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Compute_SCC`** — two-stack path-based partition into
  `Component_Of(V) ∈ 1 .. Count`.
- **`Same_SCC`** — Boolean co-membership test on a completed labelling.
- **Capacity guards** — `Invalid_Argument` for bad vertex ids, oversized
  $N$, edge overflow, or mismatched `Component_Of` bounds.
- **Educational layout** — 1-based indices; no heap beyond fixed arrays
  sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Ppath_based_strong_component.gpr`.

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
- Cross edges, forward edges, and Gabow $P$-stack contraction
- Nested / hierarchical SCCs and DFS forests
- Parallel edges, clear/reset, API counters
- `Invalid_Argument` for capacity, range, and bound errors
- Larger patterns (five 2-cycles, 20-cycle, 50 isolates, 200 isolates)

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Path_Based_Strong_Component is
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
end Path_Based_Strong_Component;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, or `Component_Of` bounds that do not cover $1 .. N$.

## License

Educational reference implementation. See repository `LICENSE` if present.
