# Force-Based Algorithms in Ada 2023

## Project Overview

**Force-directed** (also called **force-based**) graph drawing algorithms
place the vertices of a graph in the plane so that edges have roughly
uniform length and unrelated vertices stay apart. The drawing is the
equilibrium of a physical metaphor:

- each **edge** is a **spring** (Hooke's law) that *attracts* its
  endpoints;
- each **vertex** is an electric **charge** (Coulomb's law) that
  *repels* every other vertex.

No planarity test or combinatorial embedding is required: the layout is a
plain $n$-body simulation with a cooling step-cap.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
Fruchterman–Reingold / spring-embedder sheet: undirected graphs on
vertices $1..N$, Float `Point2D` positions, deterministic seeded initial
placement, linear or exponential temperature, and `Invalid_Argument`
guards. `SPARK_Mode => Off` because the coordinates are Float.

Primary source:
[Wikipedia — Force-directed graph drawing](https://en.wikipedia.org/wiki/Force-directed_graph_drawing).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Spring / charge intuition

With ideal length $k>0$ and Euclidean distance $d$ between two vertices:

$$
f_a(d)=\frac{d^{2}}{k},\qquad f_r(d)=\frac{k^{2}}{d}.
$$

$f_a$ acts **along stored edges** (the spring). $f_r$ acts **between every
pair of vertices** (the charge). A single isolated edge is in equilibrium
when attraction equals repulsion:

$$
\frac{d^{2}}{k}=\frac{k^{2}}{d}\quad\Rightarrow\quad d=k.
$$

So tiny connected graphs (an edge, a triangle, $K_n$) tend to have edge
lengths near $k$. Vertices that start on top of each other still separate:
$d$ is floored away from zero and the pair is pushed along a deterministic
axis. Each iteration then moves vertex $v$ by at most the current
**temperature** $t$ in the direction of the accumulated displacement
$\Delta_v$:

$$
p_v\leftarrow p_v+\frac{\Delta_v}{\|\Delta_v\|}\cdot\min\bigl(\|\Delta_v\|,t\bigr).
$$

Cooling shrinks $t$ so large early steps untangle the drawing and small
late steps settle it. This package offers two schedules over $I$
iterations with initial temperature $t_0$:

$$
\begin{align*}
\text{Linear:}&\quad t_i=t_0\cdot\frac{I-i+1}{I}, \\
\text{Exponential:}&\quad t_i=t_0\cdot\gamma^{i-1},\quad\gamma\in(0,1].
\end{align*}
$$

Because every step is capped by $t$, connected graphs (and disconnected
ones) keep **finite** coordinates after a finite number of iterations.

Eades (1984) introduced the spring-plus-charge combination; Fruchterman
and Reingold (1991) gave the $d^{2}/k$ and $k^{2}/d$ kernels used here.
Tutte (1963) used springs alone with a fixed outer face (a convex
embedding). Kamada–Kawai (1989) puts a spring on *every* pair, with ideal
length proportional to graph distance — a different force model, not
implemented in this sheet.

## Contrast with spectral layout (README only)

| Package / method | Idea |
| --- | --- |
| **This package** (`Ada-Force-Based-Algorithms`) | Iterative spring / charge simulation (Fruchterman–Reingold) |
| Spectral layout (sibling sheet) | Vertex coordinates from **Laplacian eigenvectors** (Fiedler / $k$ smallest) |
| Barnes–Hut (sibling sheet) | Fast $n$-body repulsion ($n\log n$ per step); not used here |

README links only — **no** package `with` of siblings. Spectral layout is a
**linear-algebra** one-shot: if $L=D-A$ is the graph Laplacian, the
eigenvectors for the smallest positive eigenvalues give coordinates that
minimize a quadratic stress. Force-directed layout is **nonlinear** and
iterative; it typically shows symmetry well and is trivial to extend
(gravity, magnetic fields, clustered graphs), at the cost of local minima
and $O(n^{2})$ work per iteration in this educational all-pairs form.

## Algorithm

### Graph

`Clear(N)` builds an undirected graph on vertices $1..N$. `Add_Edge(U,V)`
stores an unweighted undirected edge (parallels allowed; self-loops are
stored but skipped by the force model).

### Seeded placement

`Seed_Positions` places vertex $i$ on a circle of radius
$\mathrm{Scale}\cdot\sqrt{N}$ with a small deterministic LCG jitter from
`Seed`, so two runs with the same seed produce the same coordinates.

`Compute` seeds with $\mathrm{Scale}=k$ and then calls `Layout`.
`Layout` continues from whatever positions the caller supplies (no
re-seed).

### One iteration

1. Zero the displacement of every vertex.
2. For every pair $\{u,v\}$, add the repulsive contribution
   $(p_u-p_v)/d\cdot f_r(d)$ (action–reaction).
3. For every non-loop edge $\{u,v\}$, add the attractive contribution
   $(p_v-p_u)/d\cdot f_a(d)$.
4. Move each vertex by at most $t$ along its displacement; cool $t$.

### Pseudocode

```text
function Layout(G, P, I, k, t0, schedule):
    for i = 1 .. I:
        t ← cool(t0, i, I, schedule)
        Δ ← 0
        for all pairs {u, v}:
            d ← max(‖P[u]−P[v]‖, ε)
            Δ[u] += ((P[u]−P[v])/d) · (k² / d)
            Δ[v] -= ((P[u]−P[v])/d) · (k² / d)
        for each non-loop edge {u, v}:
            d ← max(‖P[u]−P[v]‖, ε)
            Δ[u] -= ((P[u]−P[v])/d) · (d² / k)
            Δ[v] += ((P[u]−P[v])/d) · (d² / k)
        for each vertex v:
            P[v] += (Δ[v] / ‖Δ[v]‖) · min(‖Δ[v]‖, t)
    return P
```

### Hand-checked examples

**$K_2$** (one edge). Equilibrium $d=k$. After a few hundred cooled
steps the drawn length sits near `Ideal_Length`.

**$K_3$**. Three springs and three charges: a roughly equilateral
triangle with side $\approx k$.

**Path of 3**. Adjacent lengths near $k$; the two ends stay farther
apart than either adjacent pair (the missing spring does not cancel the
charge).

### Asymptotic cost

$$
\begin{align*}
\text{time per iteration (all-pairs repulsion)} &\colon O(N^{2}+E) \\
\text{typical full layout} &\colon O(I\cdot N^{2})\ \text{with}\ I\sim N \\
\text{Barnes–Hut / FADE (not implemented)} &\colon O(N\log N)\ \text{per iteration}
\end{align*}
$$

## Complexity

| Measure | Bound |
| ------- | ----- |
| Time per iteration | $O(N^{2}+E)$ all-pairs repulsion |
| Iterations | exactly `Iterations` (no early stop) |
| Auxiliary space | $O(N)$ displacement scratch |
| Graph storage | $O(N+E)$ fixed arrays |
| Vertex indices | $1 .. N$ with $N\le\mathrm{Max\_Vertices}$ |
| Edge capacity | $\mathrm{Max\_Edges}$ undirected records |
| Output | `Point2D` positions for vertices $1..N$ |

## Features

- **`Clear` / `Add_Edge`** — undirected unweighted graph on vertices
  $1..N$; parallel edges and self-loops permitted.
- **`Seed_Positions(Seed, Scale)`** — deterministic circle + LCG jitter.
- **`Layout(Iterations, Ideal_Length, Initial_Temperature, Schedule,
  Cooling_Factor)`** — Fruchterman–Reingold steps from given positions.
- **`Compute(...)`** — seed then layout (primary one-shot API).
- **`Euclidean` / `Position_Of` / `Mean_Edge_Length` / `Is_Finite`** —
  geometry helpers for tests and classroom checks.
- **Linear and exponential cooling** — `Temperature_Schedule`.
- **Capacity / request guards** — `Invalid_Argument` for bad ids, empty
  graph, non-positive $k$, negative temperature, bad $\gamma$, or short
  position buffers.
- **Educational layout** — 1-based indices; fixed arrays sized to
  $\mathrm{Max\_Vertices}=256$ / $\mathrm{Max\_Edges}=8192$.
- **Zero-warning build** — `gnatmake -gnatwa -gnat2022 -Pforce_based_algorithms.gpr`.

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

- Clear / Add_Edge / counts, including parallels and self-loops
- `Invalid_Argument` for empty graphs, bad $k$, bad temperature, short
  buffers, capacity overflow
- Single vertex at the origin
- $K_2$ / $K_3$ / $K_n$ edge lengths trending toward the ideal $k$
- Path-of-3 geometry; cycles, stars, grids, wheels, $K_{2,3}$
- Deterministic seeds; different seeds differ
- `Layout` reuse and $t=0$ freeze
- Linear vs exponential cooling
- Finite positions on connected (and disconnected) graphs
- `Position_Of` / `Euclidean` / `Mean_Edge_Length` / `Is_Finite`

## Building

- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g. GNAT FSF
  13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build flag: `-gnatwa -gnat2022` with zero compiler warnings.

## API

```ada
package Force_Based_Algorithms is
   Max_Vertices : constant Positive := 256;
   Max_Edges    : constant Positive := 8_192;

   type Vertex_Id is range 1 .. Max_Vertices;
   type Point2D is record
      X, Y : Float := 0.0;
   end record;
   type Position_Array is array (Vertex_Id range <>) of Point2D;
   type Temperature_Schedule is (Linear, Exponential);

   Invalid_Argument : exception;

   type Graph is limited private;

   procedure Clear (G : in out Graph; Vertex_Count : Natural);
   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id);
   function Vertex_Count (G : Graph) return Natural;
   function Edge_Count (G : Graph) return Natural;

   procedure Seed_Positions
     (G : Graph; Seed : Natural := 1; Scale : Float := 1.0;
      Positions : out Position_Array);

   procedure Layout
     (G : Graph;
      Iterations : Positive := 100;
      Ideal_Length : Float := 1.0;
      Initial_Temperature : Float := 1.0;
      Schedule : Temperature_Schedule := Linear;
      Cooling_Factor : Float := 0.95;
      Positions : in out Position_Array);

   procedure Compute
     (G : Graph;
      Iterations : Positive := 100;
      Ideal_Length : Float := 1.0;
      Initial_Temperature : Float := 1.0;
      Schedule : Temperature_Schedule := Linear;
      Cooling_Factor : Float := 0.95;
      Seed : Natural := 1;
      Positions : out Position_Array);

   function Euclidean (A, B : Point2D) return Float;
   function Position_Of
     (Positions : Position_Array; V : Vertex_Id) return Point2D;
   function Mean_Edge_Length
     (G : Graph; Positions : Position_Array) return Float;
   function Is_Finite (P : Point2D) return Boolean;
end Force_Based_Algorithms;
```

Raises `Invalid_Argument` when `Clear` would exceed `Max_Vertices`, when
`Add_Edge` ids are out of range or the edge table is full, when
`Seed_Positions` / `Layout` / `Compute` see $N=0$, `Ideal_Length<=0`,
`Initial_Temperature<0`, an exponential `Cooling_Factor` outside
$(0,1]$, or a position array with `First/=1` or `Last<N`, when
`Position_Of` is out of range, or when `Mean_Edge_Length` has no counted
(non-loop) edge.

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning.
