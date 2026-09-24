# Blossom Algorithm in Ada 2023

## Project Overview

The **blossom algorithm** (Edmonds, 1965) computes a **maximum-cardinality
matching** in a **general undirected** graph: a largest set of edges with no
two sharing a vertex. Jack Edmonds showed that odd-length alternating cycles
— **blossoms** — can be *contracted* to a single supervertex so that the
search for an augmenting path continues in the contracted graph. The
educational bound is

$$
O\!\left(|E|\,|V|^{2}\right)
$$

A faster $O(|E|\sqrt{|V|})$ algorithm for the same task exists (Micali and
Vazirani) but is substantially more involved.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices $1..N$, `Add_Edge(U, V)` (undirected, loopless),
alternating-forest search with blossom contraction, mate array `Mate`
($0$ = unmatched), fixed arrays (no dynamic heap), an optional subset-DP /
bitset matching oracle for tiny graphs, and `Invalid_Argument` for
capacity / bound errors.

Primary source:
[Wikipedia — Blossom algorithm](https://en.wikipedia.org/wiki/Blossom_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Hopcroft–Karp

| Package / method | Problem | Notes |
| --- | --- | --- |
| **This package** (`Ada-Blossom-Algorithm`) | **Cardinality** matching in **general** graphs | Contracts odd cycles (blossoms); $O(EV^{2})$ |
| Hopcroft–Karp (sibling sheet) | Cardinality matching, **bipartite only** | No odd cycles, so no blossoms; $O(E\sqrt{V})$ |
| Hungarian (sibling sheet) | Weighted bipartite **assignment** | Min-/max-cost perfect matching |

README links only — **no** package `with` of siblings. Hopcroft–Karp
maximizes the *number* of matched edges when $G$ is bipartite: every cycle
is even, the alternating forest never sees an $S$–$S$ edge inside one tree,
and blossom contraction is unused. Edmonds' algorithm is the extension that
handles non-bipartite graphs. On a bipartite instance both methods return
the same cardinality; this package does **not** `with`
`Hopcroft_Karp_Algorithm`.

## Maximum cardinality matching

A matching $M$ in $G=(V,E)$ is a set of edges with distinct endpoints. It
is **maximum** if $|M|$ is largest possible. A vertex not incident to $M$
is **exposed** (free). An **alternating path** relative to $M$ has edges
alternately not in $M$ and in $M$. An **augmenting path** is an alternating
path that starts and ends at distinct exposed vertices (odd length).
Flipping membership along an augmenting path $P$ yields

$$
M\oplus P=(M\setminus P)\cup(P\setminus M)
$$

of size $|M|+1$. By **Berge's lemma**, $M$ is maximum iff no augmenting
path exists.

### Example

Triangle $C_3$: vertices $\{1,2,3\}$, edges $1\!-\!2$, $2\!-\!3$,
$3\!-\!1$. A maximum matching has size $1$ (any single edge). Path $P_4$
has size $2$. Two triangles joined by a bridge have size $3$.

## Blossoms

In a *bipartite* graph the alternating forest never contains an odd cycle.
In a general graph an unmatched edge may join two **outer** (even distance
from a free root) vertices of the *same* tree. That closes an odd cycle

$$
B=(v_0,v_1,\ldots,v_{2k})
$$

with $2k+1$ edges of which exactly $k$ lie in $M$. The unique vertex of $B$
not matched *inside* $B$ is the **base**; the even-length alternating path
from the base to a free vertex is the **stem**.

$B$ is a **blossom**. Contracting every edge of $B$ to a supervertex $v_B$
produces $G'$ and a matching $M'$. $G'$ has an $M'$-augmenting path iff $G$
has an $M$-augmenting path; any such path in $G'$ **lifts** through $B$ by
replacing the hop through $v_B$ with the unique alternating walk around the
cycle. Nested blossoms (a contracted blossom sitting on another odd cycle)
are handled by repeating contraction.

This package implements contraction *implicitly*: each vertex $v$ stores
`Base(v)`, the current blossom representative, updated for every vertex
whose old base lies in the newly found odd cycle (union of bases).

## Algorithm

### Alternating forest + contraction

Maintain mates `Mate[v]` with $0$ as NIL. From each free vertex $s$ run a
BFS-style search:

1. Grow the forest along unmatched then matched edges (`Father` pointers).
   An unmatched neighbour of an outer vertex is an **augmenting path**;
   flip along `Father`.
2. An edge to an already-outer vertex in a *different* tree is also
   augmenting (two free roots).
3. An edge to an already-outer vertex in the *same* tree is a blossom:
   compute the LCA (base), mark the cycle, set `Base(x)` to that base for
   every $x$ in the blossom, and continue the search as if the blossom were
   a single outer vertex.
4. Edges into inner (odd) vertices are ignored.

Repeat from the next free vertex until a whole pass finds no augmenting
path.

### Pseudocode

```text
function Find_Path(s):
    Base[*] := identity; Father[*] := 0
    queue := {s}                    -- outer / even vertices
    while queue not empty:
        u := dequeue
        for each neighbour v of u:
            if Base[u] = Base[v] or Mate[u] = v: continue
            if v is outer in this tree:          -- odd cycle
                contract blossom(u, v) to LCA
            else if Father[v] = 0:
                Father[v] := u
                if Mate[v] = 0: return v         -- augment
                enqueue Mate[v]
    return 0

function Edmonds:
    Mate[*] := 0; matching := 0
    for each free s:
        t := Find_Path(s)
        if t ≠ 0: augment along Father from t; matching += 1
    return matching
```

### Subset-DP oracle ($N\le 16$)

`Matching_Oracle_Brute` computes

$$
\mathrm{dp}[S]=\max_{v\in S}\bigl\{\mathrm{dp}[S\setminus\{v\}],\;
1+\mathrm{dp}[S\setminus\{v,u\}]\bigr\}
$$

over neighbour $u\in S$ of $v$ (bitset of adjacency). Same cardinality as
`Maximum_Matching` on every valid instance with $N\le\mathrm{Max\_Oracle}$;
raises `Invalid_Argument` when $N$ exceeds $16$.

### Asymptotic cost

$$
O\!\left(|E|\,|V|^{2}\right)
$$

worst case for `Maximum_Matching` (up to $O(|V|)$ augmentations, each
scanning edges while contracting blossoms). The oracle is
$O(2^{N}N)$ and is intended only for teaching / cross-checks on tiny
graphs.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (`Maximum_Matching`) | $O(EV^{2})$ |
| Time (`Matching_Oracle_Brute`) | $O(2^{N}N)$ for $N\le 16$ |
| Auxiliary space | $O(N+E)$ fixed stores |
| Vertex cap | $N\le\mathrm{Max\_Vertices}=256$ |
| Edge cap | $E\le\mathrm{Max\_Edges}=16384$ |
| Indices | Vertices $1..N$ |
| Unmatched mate | $0$ (NIL) |
| Empty $N=0$ | Feasible; size $0$ |
| Self-loops | Rejected (`Invalid_Argument`) |

## Features

- **`Clear` / `Add_Edge`** — build an undirected loopless instance ($N=0$
  allowed).
- **`Vertex_Count` / `Edge_Count`** — inspectors.
- **`Maximum_Matching`** — Edmonds blossom; fills size and `Mate`.
- **`Matching_Oracle_Brute`** — subset-DP / bitset oracle for $N\le 16$.
- **`Is_Valid_Matching` / `Edge_U` / `Edge_V`** — validation helpers.
- **Capacity / bound guards** — `Invalid_Argument` for overflow,
  out-of-range ids, or self-loops.
- **Educational layout** — 1-based indices; fixed arrays sized to the
  caps above.
- **Zero-warning build** —
  `gnatmake -gnatwa -gnat2022 -Pblossom_algorithm.gpr`.

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

=== 1. Empty / trivial ===
  PASS: ...
...
Results:  NN PASS, 0 FAIL
```

(Exact `NN` is the current suite size; it is at least 150.)

## Testing

The test suite in `tests.adb` covers:

- Empty $N=0$; isolates; single edge; no-edge graphs
- Triangle $C_3$ (matching size $1$); paths $P_2$–$P_7$
- Odd and even cycles; complete $K_n$; stars
- Classic blossom instances (triangle + pendants, two triangles and a
  bridge, stem + blossom)
- Petersen graph (size $5$)
- Parallel edges; mate-array mutual consistency
- Agreement with `Matching_Oracle_Brute` on many small families,
  including tiny non-bipartite graphs
- Larger $n=32,64,100,128$ blossom-only instances
- Bipartite families (cardinality still correct without needing a
  blossom in the input)
- `Invalid_Argument` for vertex / edge overflow, OOB vertices,
  self-loops, oracle oversize, and bad edge indices
- Capacity smoke tests at $\mathrm{Max\_Vertices}$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Blossom_Algorithm is
   Max_Vertices : constant Positive := 256;
   Max_Edges    : constant Positive := 16_384;
   Max_Oracle   : constant Positive := 16;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Mate_Array is array (Positive range <>) of Natural;

   type Matching_Result is record
      Size : Natural := 0;
      N    : Natural := 0;
      Mate : Mate_Array (1 .. Max_Vertices);
   end record;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Maximum_Matching (G : Graph; Result : out Matching_Result);
   procedure Matching_Oracle_Brute (G : Graph; Result : out Matching_Result);

   function Is_Valid_Matching
     (G : Graph; Result : Matching_Result) return Boolean;
   function Edge_U (G : Graph; Index : Positive) return Vertex_Id;
   function Edge_V (G : Graph; Index : Positive) return Vertex_Id;
end Blossom_Algorithm;
```

Raises `Invalid_Argument` for $N>\mathrm{Max\_Vertices}$, edge count above
$\mathrm{Max\_Edges}$, vertex ids outside $1..N$, self-loops,
`Matching_Oracle_Brute` when $N>16$, or edge inspectors when the index is
out of range.

`Mate(V)=W` and `Mate(W)=V` are mutual partners; $0$ means unmatched.
Empty $N=0$ is feasible with matching size $0$.

## License

Educational reference implementation. See repository `LICENSE` if present.
