# Cone algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **cone algorithm**:
a computational-geometry / nanoscience method that identifies **surface
particles** in an object composed of discrete particles. See
[Wikipedia: Cone algorithm](https://en.wikipedia.org/wiki/Cone_algorithm).

First described for nanogold clusters by Wang, Teitel, and Dellago
(2005, *J. Chem. Phys.* 122, 214722). Applications include computational
surface science, condensed-phase clusters, and iterative identification
of sub-surface layers. The algorithm handles multiple clusters in one
configuration and holes inside clusters.

This package is a **classroom sketch** on small 3-D point sets
(`Max_Points = 64`). Distances and angles use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production MD post-processing
tool.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Cone-Algorithm`) | Empty-cone surface particle ID (3-D) |
| **[Ada-Barnes-Hut](https://github.com/RobertBoettcherSF/Ada-Barnes-Hut)** | Tree-code $n$-body forces |
| **[Ada-Bowyer-Watson](https://github.com/RobertBoettcherSF/Ada-Bowyer-Watson)** | Delaunay triangulation |
| **[Ada-Geometric-Hashing](https://github.com/RobertBoettcherSF/Ada-Geometric-Hashing)** | Model/scene geometric hashing |
| **[Ada-Chans-Algorithm](https://github.com/RobertBoettcherSF/Ada-Chans-Algorithm)** | Output-sensitive 2-D convex hull |

README links only — **no** package `with` of siblings.

## Algorithm sketch

For a particle $i$ with position $p_i$, collect **neighbors** $j$ with

$$
0 < \|p_j - p_i\|_2 \le R
$$

where $R$ is the **cutoff radius** (cone side length). Let $u_j$ be the
unit vector from $i$ toward neighbor $j$:

$$
u_j = \frac{p_j - p_i}{\|p_j - p_i\|_2}.
$$

Particle $i$ is a **surface** particle if there exists a unit direction
$\hat{u}$ such that every neighbor lies **outside** a cone of half-angle
$\theta$ about $\hat{u}$:

$$
\hat{u} \cdot u_j < \cos\theta \qquad \text{for all neighbors } j.
$$

Equivalently: a **hollow (empty) cone** of side length $R$ and opening
half-angle $\theta$ points from $i$ into free space. Particles with no
neighbors inside the cutoff are surface by definition (fully exposed).

### Parameters

| Parameter | Role | Classroom default |
| --- | --- | --- |
| $R$ (`Cutoff`) | Cone side length / neighbor cutoff | `Default_Cutoff = 1.8` (unit lattice) |
| $\theta$ (`Half_Angle`) | Cone half-angle in radians, $\theta \in (0,\pi/2]$ | `Default_Half_Angle =` $\pi/4$ (45°) |

Larger $\theta$ makes the empty-cone test **stricter** (fewer surface
labels). Larger $R$ includes more neighbors (second shell, etc.).

### Classroom direction search

Exact continuous maximization of the empty half-angle is unnecessary for
$n \le 64$. This package tries candidate axes derived from the neighbor
set plus a fixed sample:

1. Outward mean: $\hat{u} = -\mathrm{normalize}\!\left(\sum_j u_j\right)$.
2. Opposite each neighbor: $\hat{u} = -u_j$.
3. Opposite pairwise averages: $\hat{u} = -\mathrm{normalize}(u_a + u_b)$.
4. Fixed 26 cube directions: $\pm e_x,\pm e_y,\pm e_z$, 12 face
   diagonals, and 8 space diagonals.

If any candidate yields an empty cone, the particle is marked surface.

### Alternative: neighborhood asymmetry

Also exposed as `Is_Surface_By_Asymmetry`: mark surface when

$$
\left\|\sum_j u_j\right\|_2 \ge \tau
$$

for a threshold $\tau \ge 0$ (asymmetric neighborhood ⇒ exposed). Useful
as a teaching comparison; the primary API uses the empty-cone test.

### Classroom simplifications

- Soft capacity `Max_Points = 64`; empty or oversized inputs raise
  `Invalid_Argument`.
- Discrete direction search (not a continuous solid-angle integral).
- Floating predicates with fixed $\varepsilon$; fine for well-separated
  classroom lattices, not an exact kernel.
- No iterative sub-surface peeling loop (call the API repeatedly on the
  remaining bulk if you want layers).

## API sketch

| Operation | Role |
| --- | --- |
| `Is_Surface_Particle` | Empty-cone test for one index |
| `Surface_Mask` | Boolean mask over the whole set |
| `Count_Surface` | Number of surface particles |
| `Extract_Surface` | Positions of surface particles |
| `Extract_Surface_Indices` | Indices of surface particles |
| `Is_Surface_By_Asymmetry` | Teaching oracle (vector-sum magnitude) |
| `Dist2` / `Dist` / `Dot` / `Cross` / `Normalize` | 3-D helpers |
| `Near` / `Near_Point` | Educational floating comparisons |

Domain types: `Point` $(x,y,z)$, `Point_Array` / `Particle_Set`, `Real`,
`Boolean_Array`, `Index_Array`. Exception: `Invalid_Argument` when
$n < 1$ or $n > Max\_Points$, index out of range, $R \le 0$, or
$\theta \notin (0,\pi/2]$.

## Build & test

```bash
make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pcone_algorithm.gpr`. Expect many
`PASS` and `Results: N PASS, 0 FAIL`.

## References

- [Wikipedia: Cone algorithm](https://en.wikipedia.org/wiki/Cone_algorithm)
- Yanting Wang, S. Teitel, and Christoph Dellago (2005), Melting of
  Icosahedral Gold Nanoclusters from Molecular Dynamics Simulations.
  *Journal of Chemical Physics* vol. 122, 214722.
  [doi:10.1063/1.1917756](https://doi.org/10.1063/1.1917756)
- [Cone Algorithm — Yanting Wang](https://www.pas.rochester.edu/~wangyt/algorithms/cone/index.html)
