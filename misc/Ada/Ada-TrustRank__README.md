# TrustRank in Ada 2023

## Project Overview

**TrustRank** is a **biased / personalized PageRank** used to separate
useful web pages from spam. A human expert marks a small **seed set** of
trusted pages; the algorithm then **propagates trust** along directed
hyperlinks. Pages close (in link distance) to the seeds receive high trust;
pages reachable only through long or spammy paths receive little. The method
was introduced by Gyöngyi, Garcia-Molina, and Pedersen (Stanford / Yahoo!,
2004) in *Combating Web Spam with TrustRank*.

Mathematically TrustRank is the unique stationary distribution of a
damped random walk that teleports according to a **seed distribution**
$s$ rather than the uniform $1/N$ teleport of classical PageRank. With
damping $\alpha\in[0,1]$ and column-stochastic transition $T$:

$$
r=\alpha\,T r+(1-\alpha)\,s.
$$

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: vertices indexed from $1$, unweighted adjacency lists in
fixed arrays (no dynamic heap), uniform or custom seed mass, Float scores
with `SPARK_Mode => Off`, and `Invalid_Argument` guards for empty seeds,
bad damping, and out-of-range ids.

Primary source:
[Wikipedia — TrustRank](https://en.wikipedia.org/wiki/TrustRank).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with PageRank / HITS (README only)

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-TrustRank`) | Seed-biased PageRank; trust decays with distance from seeds |
| PageRank (sibling sheet) | Same iteration with **uniform** teleport $s=1/N$ |
| HITS (sibling sheet) | Separate **hub** / **authority** scores; mutual reinforcement |

README links only — **no** package `with` of siblings. TrustRank differs from
PageRank only in the teleport vector; it differs from HITS in using a single
random-walk score rather than a hub/authority pair.

## Algorithm

### Seed distribution

Let $S\subseteq V$ be the expert-chosen seed set. The default (uniform) seed
vector is

$$
s(v)=\begin{cases}
1/|S| & \text{if }v\in S,\\
0 & \text{otherwise.}
\end{cases}
$$

`Set_Seed_Distribution` accepts an arbitrary non-negative mass vector and
normalizes it to a probability vector $s$.

### Transition and dangling nodes

For each node $u$ with out-degree $\mathrm{outdeg}(u)>0$ and each stored
link $u\to v$:

$$
T(v,u)=\frac{1}{\mathrm{outdeg}(u)}.
$$

Dangling nodes ($\mathrm{outdeg}=0$) redistribute their mass according to
$s$ (the same teleport used for damping), matching the usual personalized
PageRank convention.

### Power iteration

Start from $r_0=s$ and iterate

$$
r_{k+1}=\alpha\,T r_k+(1-\alpha)\,s
$$

until $\|r_{k+1}-r_k\|_1\le\mathrm{Tolerance}$ or `Max_Iters` steps elapse.
When $\alpha=0$ the result is exactly $s$; as $\alpha\to 1$ trust follows the
link structure more aggressively. Typical educational damping is
$\alpha=0.85$.

### Trust propagation intuition

Because each step mixes a fraction $(1-\alpha)$ of seed mass back in, trust
**concentrates near seeds** and decays with hop distance — the property
that makes TrustRank useful against spam farms far from the curated set.
Anti-TrustRank (mentioned only here) runs the same idea from known spam
seeds to estimate spam proximity.

### Example

Chain $1\to 2\to 3\to 4$ with sole seed $\{1\}$ and $\alpha=0.85$: after
convergence $r(1)>r(2)>r(3)>r(4)>0$. With seed $\{4\}$ instead, mass
stays near $4$ (little flows upstream on a one-way chain).

### Pseudocode

```text
function TrustRank(G, seeds, α, max_iters, tol):
    s ← normalize(seed_distribution(seeds))
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
- **`Mark_Seed` / `Clear_Seeds` / `Is_Seed` / `Seed_Count`** — uniform
  seed set for TrustRank.
- **`Set_Seed_Distribution` / `Has_Custom_Seeds`** — custom non-negative
  seed mass (normalized inside `Compute`).
- **`Compute(Damping, Max_Iters, Tolerance)`** — power iteration; writes
  `Scores` and `Iterations`.
- **`Score_Of`** — bounds-checked accessor into a score vector.
- **Capacity / request guards** — `Invalid_Argument` for bad ids, empty
  seeds, damping outside $[0,1]$, negative tolerance, or array bounds.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}=1024$ / $\mathrm{Max\_Edges}=50000$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Ptrustrank.gpr`.

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

- Clear / Add_Edge / Seed helpers / custom seed distribution
- Seed mass concentrates near seeds on chains and small DAGs
- Damping extremes ($\alpha=0$ recovers $s$; high $\alpha$ spreads further)
- `Invalid_Argument` for empty seeds, bad damping, bad ids, bounds
- Small hand graphs with known qualitative ordering
- Normalization (scores sum to $\approx 1$), non-negativity
- Volume battery over paths and random digraphs

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package TrustRank is
   Max_Vertices : constant Positive := 1_024;
   Max_Edges    : constant Positive := 50_000;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Score_Array is array (Vertex_Id range <>) of Float;
   type Seed_Mass_Array is array (Vertex_Id range <>) of Float;

   Invalid_Argument : exception;

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Clear_Seeds (G : in out Graph);
   procedure Mark_Seed (G : in out Graph; V : Vertex_Id);
   function Is_Seed (G : Graph; V : Vertex_Id) return Boolean;
   function Seed_Count (G : Graph) return Natural;
   procedure Set_Seed_Distribution
     (G : in out Graph; Mass : Seed_Mass_Array);
   function Has_Custom_Seeds (G : Graph) return Boolean;

   procedure Compute
     (G          : Graph;
      Damping    : Float := 0.85;
      Max_Iters  : Positive := 100;
      Tolerance  : Float := 1.0e-6;
      Scores     : out Score_Array;
      Iterations : out Natural);

   function Score_Of
     (Scores : Score_Array; V : Vertex_Id) return Float;
end TrustRank;
```

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning.
