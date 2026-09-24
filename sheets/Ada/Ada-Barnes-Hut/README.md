# Barnes–Hut Simulation — Ada 2023

Educational, self-contained Ada 2023 package implementing the classic
**Barnes–Hut tree code** for the two-dimensional gravitational $n$-body
problem (quadtree, **monopole / center-of-mass** approximation), following
[Wikipedia: Barnes–Hut simulation](https://en.wikipedia.org/wiki/Barnes–Hut_simulation)
and **Josh Barnes & Piet Hut** (1986).

This package is the **monopole** tree algorithm: each internal node stores
total mass and center of mass (COM). It is **distinct** from the sibling
`Ada-Fast-Multipole-Method` repository, which forms higher-order multipole
expansions. The original Barnes–Hut paper targeted **3-D octrees**; this
educational code uses a **2-D quadtree** for clarity (same MAC and COM idea).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Kernel** | 2-D Newtonian gravity | Softened pairwise force |
| **Soft core** | $\varepsilon$ softening | Avoids $r\to 0$ singularities |
| **Partition** | Adaptive quadtree | Leaf capacity threshold |
| **Moments** | Monopole = mass + COM | No higher multipoles |
| **Far field** | MAC $s/d < \theta$ | Point-mass at COM |
| **Near field** | Direct particle sum | Soft-core force |

## Purpose

Direct $n$-body gravity costs $O(N^2)$ pair evaluations. Barnes & Hut (1986)
organize bodies in a spatial tree so that a distant cluster can be replaced by
a single point mass at its center of mass whenever the **multipole acceptance
criterion** (opening angle) is satisfied. Typical cost drops to
$O(N\log N)$.

The same treecode idea underpins many astrophysical simulations; the fast
multipole method (FMM) is a related, higher-order hierarchical scheme.

## Algorithm

### Softened gravitational force

Force on body $1$ due to body $2$:

$$
\mathbf{F}_{12}=G\,m_1 m_2\,\frac{\mathbf{r}_2-\mathbf{r}_1}{\bigl(|\mathbf{r}_2-\mathbf{r}_1|^2+\varepsilon^2\bigr)^{3/2}}.
$$

### Barnes–Hut tree

1. Recursively subdivide the domain into four equal squares (quadtree) until
   each leaf holds at most `Leaf_Capacity` bodies (classically one).
2. Each **internal** node stores the **total mass** and **center of mass** of
   all bodies beneath it.
3. Leaves store the bodies (or a small bucket) directly.

In 3-D the analogous structure is an **octree** (eight children per node).

### Force on a body (tree walk)

Starting at the root:

1. If the node is a **leaf**, sum direct softened forces from its bodies
   (skip self).
2. If the node is **internal**, let $s$ be the cell width and $d$ the distance
   from the target body to the node's COM. If

$$
\frac{s}{d}<\theta,
$$

   treat the whole subtree as a point mass at the COM.
3. Otherwise recurse into the children.

$\theta=0$ forces full opening and recovers direct summation (up to
softening). Larger $\theta$ is faster but less accurate.

## Complexity (honest)

| Method | Cost (typical) |
| --- | --- |
| Brute force | $O(N^2)$ |
| Barnes–Hut (this package) | $O(N\log N)$ for fixed $\theta$ |
| Classical Greengard–Rokhlin FMM | $O(N)$ or $O\bigl(N\log(1/\varepsilon)\bigr)$ |

Error is controlled by $\theta$ (and softening $\varepsilon$). This is a
**monopole** treecode, not a full FMM with M2L / local expansions.

## Relation to FMM

| | Barnes–Hut (here) | Fast Multipole Method |
| --- | --- | --- |
| Expansion | Monopole (mass + COM) | Multipoles of order $P\ge 2$ |
| Acceptance | $s/d < \theta$ | Well-separation / MAC |
| Typical cost | $O(N\log N)$ | $O(N)$ (full FMM) |
| Sibling repo | this package | `ada-fast-multipole-method` |

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Vec2`, `Body_State`, `Body_Array`, `Force_Array` | Domain model |
| Helpers | `Near`, `Hypot`, `Soft_Denom`, `Pair_Force` | Numerics |
| MAC | `Accept_Node`, `Well_Separated` | $s/d < \theta$ |
| Config | `BH_Config`, `Default_Config` | $\theta$, $\varepsilon$, $G$, leaf size |
| Tree | `Tree`, `Build_Tree`, `Clear_Tree`, `Node_Count` | Quadtree |
| Moments | `Total_Mass`, `Root_COM`, `Sum_Masses` | Monopole checks |
| Forces | `Force_Brute`, `Force_Barnes_Hut` | Single-body |
| Forces | `Forces_All_Brute`, `Forces_All_Barnes_Hut` | All-body $O(N^2)$ / BH |
| Errors | `Max_Abs_Error` | Compare force fields |
| Step | `Euler_Step` | Optional BH time step |

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022` and `barnes_hut.gpr`
(`Source_Dirs "."`, `Object_Dir "obj"`, `Exec_Dir "bin"`, `Main "tests.adb"`).

## References

- [Barnes–Hut simulation (Wikipedia)](https://en.wikipedia.org/wiki/Barnes–Hut_simulation)
- Barnes, J. & Hut, P. (December 1986). A hierarchical $O(N\log N)$
  force-calculation algorithm. *Nature* 324: 446–449.
- Related: $n$-body problem, fast multipole method, treecode, octree / quadtree.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
