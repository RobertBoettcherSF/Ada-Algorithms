# Karger's Algorithm in Ada 2023

## Project Overview

**Karger's algorithm** is a randomized Monte Carlo method that estimates a
**global minimum cut** of a connected undirected multigraph. Invented by
David Karger (1993), it repeatedly **contracts** a uniformly chosen edge
until only two supernodes remain; the multiplicity of edges between those
supernodes is the cut size of one trial. Repeating the basic contraction
sufficiently often finds a true minimum cut with high probability.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, an undirected edge list in
fixed arrays (no dynamic heap), parallel edges encoding multiplicity,
deterministic seeded LCG RNG for reproducible trials, `Contract_Once` /
`Min_Cut`, and an optional `Exact_Min_Cut` bipartition oracle for
$N\le 10$.

Primary source:
[Wikipedia — Karger's algorithm](https://en.wikipedia.org/wiki/Karger%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with flow-based min-cut

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Kargers-Algorithm`) | Randomized edge contraction; Monte Carlo; one trial succeeds with probability $\Omega(1/n^{2})$ |
| Flow-based global min-cut (README only) | Deterministic: reduce to $O(n)$ $s$–$t$ max-flow computations, or use Stoer–Wagner / Nagamochi–Ibaraki |
| Karger–Stein (variant; not implemented here) | Recursive contraction with early branching; success probability $\Omega(1/\log n)$ per run |

README links only — **no** package `with` of siblings. Flow algorithms give
exact cuts in polynomial time; Karger trades determinism for a simple
contraction loop and a clear probabilistic analysis.

## Algorithm

### Basic contraction

Given an undirected multigraph $G=(V,E)$ with $n=|V|$:

1. While more than two supernodes remain, pick an edge uniformly at
   random among edges whose endpoints lie in different supernodes and
   **contract** it (merge the endpoints; discard self-loops).
2. When two supernodes $S$ and $T$ remain, return the multiplicity of
   edges with one end in $S$ and one end in $T$.

### Pseudocode

```text
function Contract_Once(G, seed):
    H := copy of G as a multigraph of supernodes
    rng := LCG(seed)
    while H has more than 2 supernodes:
        e := uniform random non-loop edge of H  (via rng)
        contract endpoints of e in H
    return multiplicity of edges between the two remaining supernodes

function Min_Cut(G, trials, seed):
    best := +∞
    for t in 0 .. trials-1:
        best := min(best, Contract_Once(G, seed + t))
    return best
```

### Success probability

A single contraction trial returns some fixed minimum cut with probability
at least

$$
\frac{1}{\binom{n}{2}} = \frac{2}{n(n-1)} = O\!\left(\frac{1}{n^{2}}\right)
$$

(more precisely $\Omega(1/n^{2})$). Running $T=\Theta(n^{2}\log n)$
independent trials drives the failure probability below $1/n^{c}$ for any
fixed $c>0$.

### Example

Cycle $C_4$ on vertices $\{1,2,3,4\}$: every cut that separates the cycle
into two nonempty paths has size at least $2$, and the min-cut is $2$.
`Exact_Min_Cut` reports $2$; `Min_Cut` with enough trials also reports
$2$. Complete graph $K_n$ has min-cut $n-1$ (isolate any vertex).

### Asymptotic cost

One trial with an educational edge-list + Union–Find implementation:

$$
O(n\cdot m)
$$

rescans of up to $m$ edges across $n-2$ contractions. `Min_Cut` multiplies
by the number of trials. `Exact_Min_Cut` enumerates $2^{n-1}-1$
bipartitions for $n\le 10$: $O(2^{n}m)$. Graph storage is $O(n+m)$ in
fixed arrays up to $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time (one `Contract_Once`) | $O(nm)$ educational |
| Time (`Min_Cut`, $T$ trials) | $O(T\,nm)$ |
| Time (`Exact_Min_Cut`) | $O(2^{n}m)$ for $n\le 10$ |
| Auxiliary space | $O(n)$ Union–Find / bipartition scratch |
| Graph storage | $O(\|V\| + \|E\|)$ fixed arrays up to educational maxima |
| Vertex indices | $1 .. N$ with $N \le \mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ undirected edges (parallels = multiplicity) |
| Output | Cut size (non-negative integer multiplicity) |

## Features

- **`Clear` / `Add_Edge`** — undirected unweighted multigraph on vertices $1 .. N$.
- **`Vertex_Count` / `Edge_Count`** — size queries.
- **`Contract_Once(Seed)`** — one seeded contraction trial → cut size.
- **`Min_Cut(Trials, Seed)`** — best cut over trials; `Min_Cut(G,1,S)=Contract_Once(G,S)`.
- **`Exact_Min_Cut`** — bipartition enumeration for $N\le 10$.
- **Deterministic LCG** — reproducible tests from a `Seed`.
- **Capacity / range guards** — `Invalid_Argument` for bad ids, self-loops,
  overflow, $N<2$ on cut APIs, or $N>\mathrm{Exact\_Max\_Vertices}$ on exact.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}$ / $\mathrm{Max\_Edges}$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pkargers_algorithm.gpr`.

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

- Clear / Add_Edge / parallel multiplicity / self-loop rejection
- Cycle graphs (min-cut $2$), complete $K_n$ (min-cut $n-1$), paths (min-cut $1$)
- Disconnected and edgeless graphs (min-cut $0$)
- Seeded reproducibility; `Min_Cut(1,S)=Contract_Once(S)`
- Exact vs multi-trial agreement on tiny graphs
- `Invalid_Argument` for capacity, range, $N<2$, exact size limit
- Volume battery over seeds and small $n$

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Kargers_Algorithm is
   Max_Vertices       : constant Positive := 128;
   Max_Edges          : constant Positive := 16_384;
   Exact_Max_Vertices : constant Positive := 10;

   type Vertex_Id is range 1 .. Max_Vertices;
   subtype Cut_Size is Natural range 0 .. Max_Edges;

   type Edge_Record is record
      U, V : Vertex_Id;
   end record;

   type Graph is limited private;
   Invalid_Argument : exception;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   function Contract_Once (G : Graph; Seed : Natural) return Cut_Size;
   function Min_Cut
     (G : Graph; Trials : Positive; Seed : Natural) return Cut_Size;
   function Exact_Min_Cut (G : Graph) return Cut_Size;
end Kargers_Algorithm;
```

Raises `Invalid_Argument` for vertex ids outside $1 .. N$, $N$ or edge
capacity overflow, self-loops on `Add_Edge`, $N<2$ on cut APIs, or
$N>\mathrm{Exact\_Max\_Vertices}$ on `Exact_Min_Cut`.

The graph is **undirected** and **unweighted**: each `Add_Edge` stores one
undirected edge; parallel edges encode multiplicity. Self-loops are
rejected.

## License

Educational reference implementation. See repository `LICENSE` if present.
