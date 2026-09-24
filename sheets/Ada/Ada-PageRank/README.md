# PageRank in Ada 2023

## Project Overview

**PageRank** is the classic link-analysis algorithm introduced by Larry Page
and Sergey Brin (Stanford, 1998) and used by Google Search to estimate the
importance of web pages. It models a **random surfer** who, at each step,
either follows an outbound hyperlink or teleports to a random page. The
PageRank of a page is the long-run probability that the surfer is on that
page.

With damping $\alpha\in[0,1]$, column-stochastic transition $T$, and
teleport distribution $s$ (default uniform $s=1/N$):

$$
r=\alpha\,T r+(1-\alpha)\,s.
$$

Equivalently, for each page $p_i$:

$$
PR(p_i)=\frac{1-\alpha}{N}+\alpha\sum_{p_j\in M(p_i)}\frac{PR(p_j)}{L(p_j)},
$$

where $M(p_i)$ is the set of pages linking to $p_i$ and $L(p_j)$ is the
out-degree of $p_j$ (dangling nodes redistribute according to $s$).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, unweighted adjacency lists in
fixed arrays (no dynamic heap), optional personalized teleport via
`Set_Teleport`, Float scores with `SPARK_Mode => Off`, and
`Invalid_Argument` guards for bad damping, empty graphs, and out-of-range
ids.

Primary source:
[Wikipedia — PageRank](https://en.wikipedia.org/wiki/PageRank).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with TrustRank / HITS (README only)

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-PageRank`) | Classic (or personalized) random-surfer PageRank |
| TrustRank (sibling sheet) | Same iteration with a **seed-biased** teleport $s$ |
| HITS (sibling sheet) | Separate **hub** / **authority** scores; mutual reinforcement |

README links only — **no** package `with` of siblings. TrustRank differs from
PageRank only in the teleport vector; HITS differs by maintaining a
hub/authority pair rather than a single random-walk score.

## Algorithm

### Random surfer and damping

At each step the surfer follows a random outbound link with probability
$\alpha$ (typical educational value $\alpha=0.85$) and otherwise jumps
according to the teleport distribution $s$. Classic PageRank uses

$$
s(v)=\frac{1}{N}\qquad\text{for all }v.
$$

`Set_Teleport` accepts an arbitrary non-negative mass vector and normalizes
it to a probability vector $s$ (personalized PageRank).

### Transition and dangling nodes

For each node $u$ with out-degree $\mathrm{outdeg}(u)>0$ and each stored
link $u\to v$:

$$
T(v,u)=\frac{1}{\mathrm{outdeg}(u)}.
$$

Dangling nodes ($\mathrm{outdeg}=0$) would otherwise trap the surfer. This
implementation **redistributes** dangling mass according to $s$ (the same
teleport used for damping), which is equivalent to treating a dangling page
as linking to every page with probabilities $s$.

### Power iteration

Start from $r_0=s$ and iterate

$$
r_{k+1}=\alpha\,T r_k+(1-\alpha)\,s
$$

until $\|r_{k+1}-r_k\|_1\le\mathrm{Tolerance}$ or `Max_Iters` steps elapse.
When $\alpha=0$ the result is exactly $s$; as $\alpha\to 1$ the walk follows
the link structure more aggressively. The returned scores are non-negative
and sum to approximately $1$.

### Example

Four pages $A,B,C,D$ with links $B\to A$, $B\to C$, $C\to A$,
$D\to A$, $D\to B$, $D\to C$ ($A$ dangling): after convergence with
$\alpha=0.85$, $PR(A)$ is strictly largest because $A$ collects the most
inbound mass.

### Pseudocode

```text
function PageRank(G, s, α, max_iters, tol):
    s ← normalize(teleport)   # default: uniform 1/N
    r ← s
    for k = 1 .. max_iters:
        dangling ← sum of r(u) over u with outdeg(u) = 0
        r' ← (1−α + α·dangling) · s
        for each non-dangling u:
            for each edge u → v:
                r'(v) ← r'(v) + α · r(u) / outdeg(u)
        if ‖r' − r‖₁ ≤ tol: return r'
        r ← r'
    return r
```

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time per iteration | $O(V+E)$ |
| Iterations | at most `Max_Iters` (often $\ll$ with $\mathrm{tol}=10^{-6}$) |
| Auxiliary space | $O(V)$ score scratch |
| Graph storage | $O(V+E)$ fixed arrays |
| Vertex indices | $1 .. N$ with $N\le\mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ directed links |
| Output | score vector (sum $\approx 1$), iteration count |

## Features

- **`Clear` / `Add_Edge`** — directed unweighted link graph on vertices
  $1 .. N$; parallel edges and self-loops permitted.
- **`Clear_Teleport` / `Set_Teleport` / `Has_Custom_Teleport`** — uniform
  default or personalized teleport mass (normalized inside `Compute`).
- **`Compute(Damping, Max_Iters, Tolerance)`** — power iteration; writes
  `Scores` and `Iterations`.
- **Dangling handling** — redistribute dangling mass via teleport $s$.
- **`Score_Of`** — bounds-checked accessor into a score vector.
- **Capacity / request guards** — `Invalid_Argument` for bad ids, damping
  outside $[0,1]$, negative tolerance, empty graph, or array bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}=1024$ / $\mathrm{Max\_Edges}=50000$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ppagerank.gpr`.

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

- Clear / Add_Edge / teleport helpers / custom teleport
- Classic Wikipedia-style small graph (inbound mass at $A$)
- Dangling-node redistribution (isolated, chain sink, personalized)
- Damping extremes ($\alpha=0$ recovers $s$; $\alpha=1$ on a cycle is
  uniform)
- `Invalid_Argument` for empty graph, bad damping, bad ids, bounds
- Small hand graphs (star, $K_n$, cycle, hub) with known ordering /
  uniformity
- Normalization (scores sum to $\approx 1$), non-negativity
- Volume battery over paths, stars, complete digraphs, and random digraphs

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package PageRank is
   Max_Vertices : constant Positive := 1_024;
   Max_Edges    : constant Positive := 50_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Score_Array is array (Vertex_Id range <>) of Float;
   type Teleport_Array is array (Vertex_Id range <>) of Float;

   Invalid_Argument : exception;

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Clear_Teleport (G : in out Graph);
   procedure Set_Teleport (G : in out Graph; Mass : Teleport_Array);
   function Has_Custom_Teleport (G : Graph) return Boolean;

   procedure Compute
     (G          : Graph;
      Damping    : Float := 0.85;
      Max_Iters  : Positive := 100;
      Tolerance  : Float := 1.0e-6;
      Scores     : out Score_Array;
      Iterations : out Natural);

   function Score_Of
     (Scores : Score_Array; V : Vertex_Id) return Float;
end PageRank;
```

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning.
