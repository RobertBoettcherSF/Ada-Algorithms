# Fast Multipole Method — Ada 2023

Educational, self-contained Ada 2023 package implementing a **hierarchical
multipole method** for the two-dimensional logarithmic (Laplace / Coulomb)
$n$-body potential, in the spirit of the
[Wikipedia: Fast multipole method](https://en.wikipedia.org/wiki/Fast_multipole_method)
introduced by **Leslie Greengard** and **Vladimir Rokhlin Jr.**

This repository is an **educational FMM / hierarchical multipole** package:
it builds a quadtree, forms complex multipole expansions of order $P\ge 2$,
shifts them upward (P2M / M2M), and evaluates far-field interactions with a
Barnes–Hut-style multipole acceptance criterion (MAC) plus direct near-field
sums. It is **not** a production Greengard–Rokhlin kernel with a full
M2L + L2L downward pass; see the complexity notes below.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Kernel** | 2-D log potential | $\Phi=\sum q_j\log(1/r)$ |
| **Soft core** | $r_\varepsilon=\sqrt{r^2+\varepsilon^2}$ | Avoids singularities |
| **Partition** | Adaptive quadtree | Leaf capacity threshold |
| **Moments** | Complex GR multipoles | Order $P=1..8$ |
| **Far field** | MAC + M2P | Well-separated boxes |
| **Near field** | Direct particle sum | Soft-core log kernel |

## Purpose

Long-range $n$-body forces (gravitation, electrostatics, and related integral
operators) cost $O(N^2)$ if every pair is summed explicitly. The fast
multipole method expands the Green's function in a **multipole expansion**,
groups nearby sources, and treats a distant cluster as a single expanded
source. Hierarchical grouping on a tree then reduces the cost dramatically.

Greengard & Rokhlin's FMM (and Rokhlin's related rapid integral-equation
work) is often listed among the top algorithms of the 20th century. The same
ideas accelerate method-of-moments solvers, quantum-chemistry Coulomb sums,
and many other dense kernel interactions.

## What this package implements

**Kernel (2-D logarithmic potential):**

$$
\Phi_i=\sum_{j\neq i} q_j\log\bigl(1/r_{ij}^{(\varepsilon)}\bigr),
\qquad
r_{ij}^{(\varepsilon)}=\sqrt{|x_i-x_j|^2+\varepsilon^2}.
$$

**Multipole about a box centre** $z_c$ (complex form, relative sources $z_j$):

$$
a_0=\sum_j q_j,\qquad
a_k=-\sum_j q_j\frac{z_j^k}{k}\quad(k=1,\ldots,P).
$$

**Far-field evaluation (M2P)** at relative target $z$:

$$
\Phi\approx a_0\log(1/|z|)+\Re\sum_{k=1}^{P}\frac{a_k}{z^k}.
$$

**Pipeline in this package:**

1. Build an adaptive **quadtree** over a square domain.
2. **P2M** — form multipoles in leaves from particles.
3. **M2M** — shift child multipoles to parents (upward pass).
4. For each target, traverse the tree: if a box is **well-separated** under
   the MAC $\mathrm{size}/\mathrm{dist}<\theta$, evaluate **M2P**; otherwise
   recurse or sum the near field directly.

## Complexity (honest)

| Method | Cost (typical) |
| --- | --- |
| Brute force | $O(N^2)$ |
| This hierarchical multipole (MAC / Barnes–Hut-style) | $O(N\log N)$ for fixed $\theta,P$ |
| Classical Greengard–Rokhlin FMM (full M2L/L2L) | $O(N)$ or $O\bigl(N\log(1/\varepsilon)\bigr)$ |

Because evaluation uses a multipole-acceptance traversal rather than a full
interaction-list + local-expansion downward pass, expect **$O(N\log N)$**
behaviour here, with error controlled by order $P$ and MAC parameter $\theta$.

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Particle`, `Particle_Array`, `Real_Array` | Domain model |
| Helpers | `Near`, `Hypot`, `Soft_Radius`, `Log_Kernel` | Numerics |
| Separation | `Well_Separated` | MAC test |
| Multipoles | `Multipole`, `P2M`, `M2M`, `Evaluate_Multipole` | Expansions |
| Tree | `Tree`, `Build_Tree`, `Clear_Tree`, `Node_Count` | Quadtree |
| Potentials | `Compute_Potentials_Brute`, `Compute_Potentials_FMM` | $O(N^2)$ / FMM |
| Errors | `Max_Abs_Error`, `Total_Charge`, `Root_Monopole` | Checks |
| Config | `FMM_Config`, `Default_Config` | $P$, $\theta$, $\varepsilon$, leaf size |

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022` and `fast_multipole_method.gpr`
(`Source_Dirs "."`, `Object_Dir "obj"`, `Exec_Dir "bin"`, `Main "tests.adb"`).

## References

- [Fast multipole method (Wikipedia)](https://en.wikipedia.org/wiki/Fast_multipole_method)
- Greengard, L. & Rokhlin, V. (1987). A fast algorithm for particle simulations.
- Rokhlin, V. (1985). Rapid solution of integral equations of classic potential theory.
- Related: Barnes–Hut simulation, multipole expansion, $n$-body problem.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
