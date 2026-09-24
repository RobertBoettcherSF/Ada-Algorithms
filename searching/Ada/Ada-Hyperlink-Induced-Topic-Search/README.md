# Hyperlink-Induced Topic Search (HITS) in Ada 2023

## Project Overview

**Hyperlink-Induced Topic Search (HITS)**, also known as **hubs and
authorities**, is a link-analysis algorithm introduced by Jon Kleinberg
(Cornell, 1999) that assigns **two** scores to each page in a focused
hyperlink subgraph: an **authority** score (value of the page's content)
and a **hub** score (value of its links to authorities). A good hub points
to many good authorities; a good authority is pointed to by many good hubs.

With (unweighted) adjacency matrix $A$ of the digraph, the mutual updates
are

$$
a \leftarrow A^{T} h,\qquad h \leftarrow A a,
$$

followed by **L2 normalization** of each vector every iteration (Kleinberg /
Wikipedia convention).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, unweighted dual adjacency lists
in fixed arrays (no dynamic heap), Float scores with `SPARK_Mode => Off`,
and `Invalid_Argument` guards for empty graphs, negative tolerance, and
out-of-range ids. Self-contained — **no** `with` of PageRank or TrustRank.

Primary source:
[Wikipedia — HITS algorithm](https://en.wikipedia.org/wiki/HITS_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with PageRank / TrustRank (README only)

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Hyperlink-Induced-Topic-Search`) | Mutual **hub** / **authority** scores; L2-normalized iteration |
| PageRank (sibling sheet) | Single random-surfer score with uniform teleport $s=1/N$ |
| TrustRank (sibling sheet) | Same PageRank iteration with a **seed-biased** teleport $s$ |

README links only — **no** package `with` of siblings. PageRank and TrustRank
each maintain one stationary distribution; HITS maintains a reinforcing
hub/authority pair and is typically **query-dependent** (run on a focused
base set at query time).

## Algorithm

### Authority and hub updates

Start with $a(p)=h(p)=1$ for every page $p$. Each iteration:

1. **Authority update.** For each page $p$,

$$
\mathrm{auth}(p)=\sum_{q\to p}\mathrm{hub}(q).
$$

In matrix form: $a \leftarrow A^{T} h$.

2. **Hub update.** For each page $p$,

$$
\mathrm{hub}(p)=\sum_{p\to r}\mathrm{auth}(r).
$$

In matrix form: $h \leftarrow A a$.

### L2 normalization

After each of the two updates, renormalize so that

$$
\|a\|_2=1,\qquad \|h\|_2=1
$$

(when the vector is not identically zero). Without normalization the scores
diverge; with L2 normalization they converge to the principal singular
vectors of $A$. This package documents and implements **L2** (not L1)
normalization.

### Convergence

Stop when

$$
\|a'-a\|_1+\|h'-h\|_1\le\mathrm{Tolerance}
$$

or `Max_Iters` outer steps elapse. Edgeless graphs yield all-zero scores
(zero L2 norms skip renormalization).

### Example (bipartite hubs → authorities)

Hubs $\{1,2,3\}$ and authorities $\{4,5\}$ with edges
$1\to4$, $1\to5$, $2\to4$, $2\to5$, $3\to4$: after convergence
$\mathrm{auth}(4)>\mathrm{auth}(5)$ (more hub support) and
$\mathrm{hub}(1)\approx\mathrm{hub}(2)>\mathrm{hub}(3)$ (broader
authority coverage).

### Pseudocode

```text
function HITS(G, max_iters, tol):
    a ← ones(N); h ← ones(N)
    for k = 1 .. max_iters:
        a' ← Aᵀ h;  a' ← a' / ‖a'‖₂   # authority update + L2
        h' ← A  a';  h' ← h' / ‖h'‖₂   # hub update + L2
        if ‖a'−a‖₁ + ‖h'−h‖₁ ≤ tol: return a', h'
        a ← a'; h ← h'
    return a, h
```

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time per iteration | $O(V+E)$ |
| Iterations | at most `Max_Iters` (often $\ll$ with $\mathrm{tol}=10^{-6}$) |
| Auxiliary space | $O(V)$ score scratch |
| Graph storage | $O(V+E)$ fixed dual adjacency arrays |
| Vertex indices | $1 .. N$ with $N\le\mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed links |
| Output | authority + hub vectors (each $\|\cdot\|_2\approx 1$), iteration count |

## Features

- **`Clear` / `Add_Edge`** — directed unweighted link graph on vertices
  $1 .. N$; parallel edges and self-loops permitted.
- **`Compute(Max_Iters, Tolerance)`** — HITS iteration; writes
  `Authorities`, `Hubs`, and `Iterations`.
- **L2 normalization** each authority / hub update (documented).
- **`Score_Of`** — bounds-checked accessor into a score vector.
- **Capacity / request guards** — `Invalid_Argument` for bad ids, negative
  tolerance, empty graph, or array bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}=1024$ / $\mathrm{Max\_Edges}=50000$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022
  -Phyperlink_induced_topic_search.gpr`.

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

- Clear / Add_Edge / counts / parallel edges / self-loops
- Bipartite hub/authority patterns (classic Kleinberg intuition)
- Mutual reinforcement (hubs that cover strong authorities win)
- `Invalid_Argument` for empty graph, bad ids, negative tolerance, bounds
- L2 unit-norm of authority and hub vectors
- Non-negativity, edgeless zeros, Max_Iters cap
- Volume battery over paths, stars, complete digraphs, and random digraphs

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Hyperlink_Induced_Topic_Search is
   Max_Vertices : constant Positive := 1_024;
   Max_Edges    : constant Positive := 50_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Score_Array is array (Vertex_Id range <>) of Float;

   Invalid_Argument : exception;

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Compute
     (G           : Graph;
      Max_Iters   : Positive := 100;
      Tolerance   : Float := 1.0e-6;
      Authorities : out Score_Array;
      Hubs        : out Score_Array;
      Iterations  : out Natural);

   function Score_Of
     (Scores : Score_Array; V : Vertex_Id) return Float;
end Hyperlink_Induced_Topic_Search;
```

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning.
