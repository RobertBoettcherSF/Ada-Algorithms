# Hopcroft–Karp Algorithm in Ada 2023

## Project Overview

The **Hopcroft–Karp algorithm** (also **Hopcroft–Karp–Karzanov**) computes a
**maximum-cardinality matching** in a **bipartite** graph: a largest set of
edges with no two sharing a vertex. John Hopcroft and Richard Karp (1973),
and independently Alexander Karzanov (1973), showed how to find a *maximal
set of shortest* augmenting paths in each phase so that only
$O(\sqrt{|V|})$ phases are needed, for worst-case time

$$
O\!\left(|E|\sqrt{|V|}\right)
$$

(assuming $|E|=\Omega(|V|)$). On dense graphs this is $O(|V|^{2.5})$; on
sparse random graphs the expected cost is often near $O(|E|\log|V|)$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: left vertices $1..L$, right vertices $1..R$,
`Add_Edge(Left, Right)`, classic BFS layering plus multi-DFS augmentation,
mate arrays `Pair_U` / `Pair_V` ($0$ = unmatched), fixed arrays (no dynamic
heap), an optional DFS-only Ford–Fulkerson matching oracle for tiny
graphs, and `Invalid_Argument` for capacity / bound errors.

Primary source:
[Wikipedia — Hopcroft–Karp algorithm](https://en.wikipedia.org/wiki/Hopcroft%E2%80%93Karp_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Hungarian / Blossom

| Package / method | Problem | Notes |
| --- | --- | --- |
| **This package** (`Ada-Hopcroft-Karp-Algorithm`) | **Cardinality** bipartite matching | Unweighted max matching; $O(E\sqrt{V})$ |
| Hungarian (sibling sheet) | Weighted bipartite **assignment** | Min-/max-cost perfect matching; dual $O(n^{3})$ |
| Blossom / Edmonds (sibling sheet) | Matching in **general** graphs | Handles odd cycles (blossoms); not bipartite-only |

README links only — **no** package `with` of siblings. Hopcroft–Karp
maximizes the *number* of matched edges in a bipartite graph; Hungarian
optimizes *edge weights* under a perfect-matching constraint. Blossom
algorithms extend matching beyond bipartite graphs. The same
$O(E\sqrt{V})$ bound for general graphs needs the more involved
Micali–Vazirani method.

## Maximum cardinality matching

A matching $M$ in $G=(U\cup V,E)$ is a set of edges with distinct
endpoints. It is **maximum** if $|M|$ is largest possible. A vertex not
incident to $M$ is **free**. An **augmenting path** relative to $M$ is a
path that starts and ends at free vertices and alternates unmatched /
matched edges. Flipping membership of edges along an augmenting path
yields a matching of size $|M|+1$. By Berge’s lemma, $M$ is maximum iff
no augmenting path exists.

Bipartite matching is a unit-capacity max-flow problem (source to every
$u\in U$, every $v\in V$ to sink, edges $U\to V$ capacity $1$).
Hopcroft–Karp is the bipartite specialization of the Dinic idea: build a
shortest-path layer graph, then push a maximal set of shortest augmenting
paths per phase.

### Example

Left $\{1,2,3\}$, right $\{1,2\}$, edges $1\!-\!1$, $2\!-\!1$, $3\!-\!2$.
A maximum matching has size $2$ (e.g. $\{1\!-\!1,\,3\!-\!2\}$); a perfect
matching is impossible because $|U|>|V|$.

## Algorithm

### BFS layers + multi-DFS phases

Maintain mates `Pair_U[u]`, `Pair_V[v]` with $0$ as NIL. Each phase:

1. **BFS** from all free left vertices assigns distances on left vertices
   and a distance `Dist_Nil` for the dummy free-right sink. Only shortest
   alternating paths are layered. If `Dist_Nil` stays $\infty$, stop.
2. **DFS** from each free left vertex, guided by BFS distances, finds
   vertex-disjoint shortest augmenting paths and flips them, increasing
   the matching by one per successful DFS.

Repeat until BFS finds no augmenting path. Number of phases is
$O(\sqrt{|V|})$; each phase costs $O(|E|)$.

### Pseudocode

```text
function BFS():
    for each free u in U: Dist[u] := 0; enqueue u
    Dist[NIL] := ∞
    while queue not empty:
        u := dequeue
        if Dist[u] < Dist[NIL]:
            for each neighbor v of u:
                if Dist[Pair_V[v]] = ∞:          -- Pair_V[v]=NIL ⇒ Dist[NIL]
                    Dist[Pair_V[v]] := Dist[u]+1
                    enqueue Pair_V[v] if ≠ NIL
    return Dist[NIL] ≠ ∞

function DFS(u):
    if u = NIL: return true
    for each neighbor v of u:
        if Dist[Pair_V[v]] = Dist[u]+1 and DFS(Pair_V[v]):
            Pair_V[v] := u; Pair_U[u] := v; return true
    Dist[u] := ∞; return false

function Hopcroft_Karp:
    Pair_U[*] := NIL; Pair_V[*] := NIL; matching := 0
    while BFS():
        for each free u in U:
            if DFS(u): matching := matching + 1
    return matching
```

### DFS-only oracle ($L,R\le 64$)

`Matching_Oracle_DFS` repeatedly finds one augmenting path by DFS (Kuhn /
Ford–Fulkerson style) until none remain. Same cardinality as
`Maximum_Matching` on every valid instance; raises `Invalid_Argument`
when a side exceeds $\mathrm{Max\_Oracle\_Side}$.

### Asymptotic cost

$$
O\!\left(|E|\sqrt{|V|}\right)
$$

worst case for `Maximum_Matching`. The oracle is $O(|V|\,|E|)$ in the
worst case and is intended only for teaching / cross-checks on tiny
graphs.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Maximum_Matching`) | $O(E\sqrt{V})$ |
| Time (`Matching_Oracle_DFS`) | $O(VE)$ for $L,R\le 64$ |
| Auxiliary space | $O(L+R+E)$ fixed stores |
| Left / right caps | $L\le\mathrm{Max\_Left}=1024$, $R\le\mathrm{Max\_Right}=1024$ |
| Edge cap | $E\le\mathrm{Max\_Edges}=50000$ |
| Indices | Left $1..L$, right $1..R$ |
| Unmatched mate | $0$ (NIL) |
| Empty $L=0$ or $R=0$ | Feasible; size $0$ |

## Features

- **`Clear` / `Add_Edge`** — build a bipartite instance ($L=0$ or $R=0$
  allowed).
- **`Left_Count` / `Right_Count` / `Edge_Count`** — inspectors.
- **`Maximum_Matching`** — Hopcroft–Karp; fills size and `Pair_U` /
  `Pair_V`.
- **`Matching_Oracle_DFS`** — DFS-only Ford–Fulkerson / Kuhn oracle for
  $L,R\le 64$.
- **`Is_Valid_Matching` / `Edge_Left` / `Edge_Right`** — validation
  helpers.
- **Capacity / bound guards** — `Invalid_Argument` for overflow or
  out-of-range ids.
- **Educational layout** — 1-based indices; fixed arrays sized to the
  caps above.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Phopcroft_karp_algorithm.gpr`.

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

=== 1. Empty / trivial sides ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty $L=0$ / $R=0$; single edge; no-edge graphs
- Perfect matchings (identity, cycles, complete $K_{n,n}$)
- Non-perfect matchings (unbalanced sides, bottlenecks, isolates)
- Parallel edges; mate-array mutual consistency
- Agreement with `Matching_Oracle_DFS` on many small families
- Larger $n=32,64,100,200$ Hopcroft–Karp-only instances
- Star graphs; disconnected components; long augmenting paths
- Complete bipartite $K_{n,m}$ size $\min(n,m)$
- `Invalid_Argument` for side / edge overflow, OOB vertices, oracle
  oversize, and bad edge indices
- Capacity smoke tests at $\mathrm{Max\_Left}$ / $\mathrm{Max\_Right}$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Hopcroft_Karp_Algorithm is
   Max_Left        : constant Positive := 1024;
   Max_Right       : constant Positive := 1024;
   Max_Edges       : constant Positive := 50_000;
   Max_Oracle_Side : constant Positive := 64;

   type Left_Id is range 1 .. Max_Left;
   type Right_Id is range 1 .. Max_Right;

   type Pair_U_Array is array (Positive range <>) of Natural;
   type Pair_V_Array is array (Positive range <>) of Natural;

   type Matching_Result is record
      Size    : Natural := 0;
      Left_N  : Natural := 0;
      Right_N : Natural := 0;
      Pair_U  : Pair_U_Array (1 .. Max_Left);
      Pair_V  : Pair_V_Array (1 .. Max_Right);
   end record;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear
     (G : in out Graph; Left_Count, Right_Count : Natural);
   procedure Add_Edge
     (G : in out Graph; Left : Left_Id; Right : Right_Id);
   function Left_Count (G : Graph) return Natural;
   function Right_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Maximum_Matching (G : Graph; Result : out Matching_Result);
   procedure Matching_Oracle_DFS (G : Graph; Result : out Matching_Result);

   function Is_Valid_Matching
     (G : Graph; Result : Matching_Result) return Boolean;
   function Edge_Left (G : Graph; Index : Positive) return Left_Id;
   function Edge_Right (G : Graph; Index : Positive) return Right_Id;
end Hopcroft_Karp_Algorithm;
```

Raises `Invalid_Argument` for $L>\mathrm{Max\_Left}$,
$R>\mathrm{Max\_Right}$, edge count above $\mathrm{Max\_Edges}$, left /
right ids outside $1..L$ / $1..R$, `Matching_Oracle_DFS` when a side
exceeds $64$, or edge inspectors when the index is out of range.

`Pair_U(U)=V` and `Pair_V(V)=U` are mutual mates; $0$ means unmatched.
Empty $L=0$ or $R=0$ is feasible with matching size $0$.

## License

Educational reference implementation. See repository `LICENSE` if present.
