# Tarjan's Off-Line Lowest Common Ancestors in Ada 2023

## Project Overview

**Tarjan's off-line lowest common ancestors (LCA) algorithm** computes the
**lowest common ancestor** of many node pairs in a **rooted tree** when
**all query pairs are known in advance**. It performs one depth-first
traversal of the tree and uses a **Union–Find** (disjoint-set) structure
with path compression and union-by-rank so that, as soon as both endpoints
of a query have been visited (coloured black in post-order), the LCA is
available as the ancestor of the Find-set representative. Robert Tarjan
described the technique in 1979; a later refinement by Gabow & Tarjan
(1983) yields linear time for a special case of disjoint-set union.

The **lowest common ancestor** of nodes $u$ and $v$ in a rooted tree $T$
is the deepest node that is an ancestor of both $u$ and $v$ (equivalently,
the unique node of greatest depth on both root-to-$u$ and root-to-$v$
paths).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, a rooted tree built with
`Clear` / `Set_Parent` / `Add_Child`, offline queries via `Add_Query`,
answers after `Compute`, fixed arrays (no dynamic heap beyond
stack-sized workspaces), Union–Find as a package-body private detail,
and an optional in-package `Naive_LCA` for cross-checks on small trees
(depth-lift walk; self-contained — no `with` of sibling packages).

Primary source:
[Wikipedia — Tarjan's off-line lowest common ancestors algorithm](https://en.wikipedia.org/wiki/Tarjan%27s_off-line_lowest_common_ancestors_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with online LCA methods

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Tarjans-Off-Line-Lowest-Common-Ancestors`) | Offline batch: one DFS + Union–Find answers all predeclared pairs |
| Binary lifting (sibling idea) | Online: preprocess $O(N\log N)$ ancestor jumps; $O(\log N)$ per query |
| Euler tour + RMQ (sibling idea) | Online: reduce LCA to range-minimum on the Euler tour of the tree |

README links only — **no** package `with` of siblings. Offline Tarjan is
ideal when the full query set is known; online methods pay for
preprocessing so that arbitrary pairs can be answered later.

## Algorithm

### Tarjan offline LCA (DFS + Union–Find)

Given a rooted tree $T$ with root $r$ and a set $P$ of unordered pairs:

1. Colour every vertex white.
2. DFS from $r$. At vertex $u$:
   - $\mathrm{Make\textrm{-}Set}(u)$; set $\mathrm{Ancestor}(\mathrm{Find}(u)) \leftarrow u$.
   - For each child $v$ of $u$: recurse on $v$; $\mathrm{Union}(u,v)$;
     set $\mathrm{Ancestor}(\mathrm{Find}(u)) \leftarrow u$.
   - Colour $u$ black.
   - For each pair $\{u,w\}\in P$ with $w$ already black:
     the LCA is $\mathrm{Ancestor}(\mathrm{Find}(w))$.
3. When both endpoints of a pair are black, the representative's
   ancestor is still the LCA (and remains correct until that LCA itself
   is united into a larger set after being coloured black).

### Pseudocode

```text
function TarjanOLCA(u):
    MAKE-SET(u)
    Ancestor[Find(u)] := u
    for each child v of u:
        TarjanOLCA(v)
        UNION(u, v)
        Ancestor[Find(u)] := u
    colour[u] := black
    for each pair {u, w} in P:
        if colour[w] == black:
            answer({u, w}) := Ancestor[Find(w)]
```

### Example

Tree rooted at $1$ with children $2,3$ of $1$ and children $4,5$ of $2$:

- $\mathrm{LCA}(4,5)=2$, $\mathrm{LCA}(4,3)=1$, $\mathrm{LCA}(2,3)=1$,
  $\mathrm{LCA}(4,4)=4$.

### Asymptotic cost

With Union–Find (path compression + union-by-rank) and adjacency-list
children plus per-vertex query incidence lists:

$$
O\bigl((N+Q)\,\alpha(N)\bigr)
$$

where $N$ is the number of vertices, $Q$ the number of queries, and
$\alpha$ the inverse Ackermann function. Educational storage is
$O(N+Q)$ in fixed arrays up to $\mathrm{Max\_Vertices}$ /
$\mathrm{Max\_Queries}$. A later Gabow–Tarjan disjoint-set specialization
improves the offline LCA bound to linear time; this sheet uses the
classic Union–Find formulation.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (Tarjan offline LCA) | $O((N+Q)\,\alpha(N))$ amortized |
| Time (`Naive_LCA`, per query) | $O(N)$ depth-lift walk |
| Auxiliary space | $O(N+Q)$ Union–Find / DFS / incidence lists |
| Tree storage | $O(N)$ parent + child adjacency up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Query capacity | $\mathrm{Max\_Queries}$ offline pairs |
| Output | One LCA vertex per query after `Compute` |

## Features

- **`Clear` / `Set_Parent` / `Add_Child`** — build a rooted tree on vertices $1 .. N$.
- **`Add_Query` / `Compute` / `Answer`** — offline batch LCA via Tarjan + Union–Find.
- **`Naive_LCA`** — in-package depth-lift reference for agreement checks.
- **`Vertex_Count` / `Root` / `Parent_Of` / `Query_Count` / `Computed`** — inspectors.
- **Union–Find** — path compression + union-by-rank (package-body private).
- **Iterative DFS** — explicit stack simulates the recursive Tarjan walk (line-tree safe).
- **Capacity / structure guards** — `Invalid_Argument` for bad ids, overflow, incomplete trees, or misuse of `Answer` / `Compute`.
- **Educational layout** — 1-based indices; fixed arrays sized to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Queries}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ptarjans_off_line_lowest_common_ancestors.gpr`.

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

=== 1. Empty / single ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty tree; single vertex; two-vertex trees (either endpoint as root)
- Branching trees with known LCAs
- Line trees (root at $1$ and mid-root); binary heap-shaped trees; stars
- Agreement with `Naive_LCA` on every checked pair
- `Set_Parent` vs `Add_Child`; Clear / rebuild; `Computed` invalidation
- Self-queries $\mathrm{LCA}(u,u)=u$
- Deep line trees (iterative DFS)
- `Invalid_Argument` for capacity, range, incomplete / disconnected trees, and `Answer` misuse

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Tarjans_Off_Line_Lowest_Common_Ancestors is
   Max_Vertices : constant Positive := 2_048;
   Max_Queries  : constant Positive := 10_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Tree is limited private;
   Invalid_Argument : exception;

   procedure Clear
     (T : in out Tree; Vertex_Count : Natural; Root : Vertex_Id := 1);
   procedure Set_Parent (T : in out Tree; Child, Parent : Vertex_Id);
   procedure Add_Child  (T : in out Tree; Parent, Child : Vertex_Id);

   function Vertex_Count (T : Tree) return Natural;
   function Root (T : Tree) return Vertex_Id;
   function Parent_Of (T : Tree; V : Vertex_Id) return Natural;
   function Query_Count (T : Tree) return Natural;
   function Computed (T : Tree) return Boolean;

   procedure Add_Query (T : in out Tree; U, V : Vertex_Id);
   procedure Compute (T : in out Tree);
   function Answer (T : Tree; Query_Index : Positive) return Vertex_Id;

   function Naive_LCA (T : Tree; U, V : Vertex_Id) return Vertex_Id;
end Tarjans_Off_Line_Lowest_Common_Ancestors;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or query
capacity overflow, `Clear` with `Root` outside $1 .. N$ when $N>0$,
incomplete / cyclic / disconnected parent structure on `Compute`, or
`Answer` before `Compute` / out-of-range query index.

The tree is **rooted**: each `Set_Parent` / `Add_Child` adds one
parent–child edge. A valid tree for `Compute` has exactly $N-1$ such
edges and every vertex reachable from `Root`. Queries may list $U=V$
(the LCA is $U$). Query order of $U$ and $V$ does not affect the answer.

## License

Educational reference implementation. See repository `LICENSE` if present.
