# Point set registration — Ada 2023

Educational, self-contained Ada 2023 package for **point-set registration**
(also **point-cloud registration** / **scan matching**): find a spatial
transform that aligns two point clouds. This classroom sketch focuses on
**2-D rigid** registration — a rotation plus a translation — with

1. a **known-correspondence** Kabsch-style closed form (SVD-free via
   $\operatorname{atan2}$ of cross/dot covariance sums), and
2. a small **ICP** (Iterative Closest Point) sketch that alternates
   nearest-neighbour correspondences with that rigid fit.

See
[Wikipedia: Point set registration](https://en.wikipedia.org/wiki/Point_set_registration).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Bounds: `Max_Points = 64`, `Max_Iters = 16`. Ordinary `Real` (`digits 15`)
arithmetic — **not** a production SLAM / PCL stack.

Part of the **RobertBoettcherSF** Ada algorithm series.

## Rigid vs non-rigid (survey)

| Kind | Idea |
| --- | --- |
| **Rigid** | Rotation + translation (SE($d$)); distances between points preserved. Wahba / orthogonal Procrustes / **Kabsch** when correspondences are known. |
| **Similarity** | Rigid + uniform scale (**Umeyama**). |
| **Affine** | Linear $A$ + translation (shear/scale allowed). |
| **Non-rigid** | Nonlinear warps (thin-plate splines, CPD / BCPD, RPM, …). |

This package implements **rigid** 2-D only. Sibling **Ada-Kabsch** covers
the classic 3-D Kabsch–Umeyama path with Jacobi SVD — README link only;
**no** package `with`.

## ICP sketch

The **iterative closest point** algorithm (Besl & McKay) alternates:

1. given the current pose, assign each model point its **nearest** scene
   point;
2. given those correspondences, solve the rigid least-squares fit;
3. apply the incremental transform and repeat.

ICP is intuitive and widely used, but it is only locally optimal and
needs a reasonable initial pose. This package warm-starts by aligning
centroids (identity rotation), which helps pure-translation cases from a
cold start. Variants (EM-ICP, LM-ICP, point-to-plane, …) improve
robustness further; they are out of educational scope here.

## Known-correspondence 2-D closed form

Paired clouds $S_i \leftrightarrow T_i$. Centroids $\mu_S$, $\mu_T$;
centered points $s'_i = s_i - \mu_S$, $t'_i = t_i - \mu_T$:

$$
\begin{align*}
\mathrm{Dot}   &= \sum_i (s'_{i,x}\, t'_{i,x} + s'_{i,y}\, t'_{i,y}), \\
\mathrm{Cross} &= \sum_i (s'_{i,x}\, t'_{i,y} - s'_{i,y}\, t'_{i,x}), \\
\theta &= \operatorname{atan2}(\mathrm{Cross}, \mathrm{Dot}).
\end{align*}
$$

Then $R = R(\theta) \in \mathrm{SO}(2)$ and
$t = \mu_T - R\mu_S$, so $p \mapsto R p + t$ aligns $S$ onto $T$.
Proper rotations only (no reflection / scale in this sketch).

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Point-Set-Registration`) | Align two 2-D point clouds (Kabsch-style + ICP sketch) |
| **[Ada-Kabsch](https://github.com/RobertBoettcherSF/Ada-Kabsch)** | 3-D Kabsch / Kabsch–Umeyama with Jacobi SVD |
| **[Ada-Shoelace-Algorithm](https://github.com/RobertBoettcherSF/Ada-Shoelace-Algorithm)** | Polygon area / centroid from vertex ring |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Diameter / width / antipodal pairs on a convex hull |
| **Ada-Point-In-Polygon** (ahead) | Ray casting / winding tests for containment |

README links only — **no** package `with` of siblings.

## API sketch

| Operation | Role |
| --- | --- |
| `Centroid` | Arithmetic mean of a cloud |
| `Make_Transform` / `Identity_Transform` | Build SE(2) from angle + translation |
| `Apply_Transform` | $p \mapsto R p + t$ (point or cloud) |
| `Register_Correspondences` | Kabsch-style rigid fit on paired clouds |
| `Register_ICP` | Nearest-neighbour ICP for a few iterations |
| `Nearest_Index` | Closest-point index (ICP building block) |
| `RMSE` / `Sum_Squared_Error` | Residual helpers (paired, optional $T$) |
| `Near` / `Near_Point` / `Dist` / `Dist2` | Educational floating comparisons |

Domain types: `Point`, `Point_Array` / `Point_Cloud`, `Mat2`,
`Rigid_Transform`, `Registration_Result`, `Real`.
Exception: `Invalid_Argument` on empty clouds, length mismatch
(correspondence API), or capacity / `Max_Iters` violations.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
