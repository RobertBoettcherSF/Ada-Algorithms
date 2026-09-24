# Kabsch Algorithm (Ada 2023)

Educational, self-contained Ada 2023 package implementing the **Kabsch**
(also **Kabsch–Umeyama**) algorithm from
[Wikipedia: Kabsch algorithm](https://en.wikipedia.org/wiki/Kabsch_algorithm):
the optimal rotation matrix minimizing RMSD between two paired 3-D point
clouds, with optional rigid **superimposition** (rotation + translation) and
a 2-D variant. Includes a dense $3\times 3$ SVD built from Jacobi
eigen-decomposition of $H^T H$ — no external BLAS/LAPACK.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Centroid** | Mean of point rows | Translate both clouds to origin |
| **Covariance** | $H=P^T Q$ | $3\times 3$ cross-covariance |
| **SVD** | Jacobi on $H^T H$ | Self-contained $3\times 3$ |
| **Rotation** | $R=U\,S\,V^T$, $S=\mathrm{diag}(1,1,d)$ | Enforce $\det(R)=+1$ |
| **RMSD** | $\sqrt{\frac1N\sum\|p_k-q_k\|^2}$ | After optional alignment |
| **Superimpose** | $q\mapsto Rq+t$, $t=c_P-Rc_Q$ | Partial Procrustes |
| **2-D** | Analytic $2\times 2$ SVD | Optional XY helper |

## Kabsch / Umeyama idea

Given paired clouds $P,Q\in\mathbb{R}^{N\times 3}$ (rows are points), find the
**proper rotation** $R\in\mathrm{SO}(3)$ minimizing

$$
\sum_{k=1}^{N}\|R q_k-p_k\|_2^2
$$

(after centering). Wolfgang Kabsch (1976/1978) and Shinji Umeyama (1991)
give equivalent SVD / eigenvalue routes; the modern presentation is often
called **Kabsch–Umeyama**. When translation is included, the procedure is
partial **Procrustes superimposition**.

## Algorithm

### 1. Translation (centroids)

Subtract each cloud’s centroid so both are origin-centered:

$$
c_P=\frac1N\sum_k p_k,\qquad
\tilde P=P-\mathbf{1}c_P^T
\quad(\text{likewise for }Q).
$$

### 2. Covariance $H=P^T Q$

$$
H=\tilde P^T\tilde Q,\qquad
H_{ij}=\sum_{k=1}^{N}\tilde P_{ki}\,\tilde Q_{kj}.
$$

### 3. SVD and optimal rotation

Factor $H=U\Sigma V^T$. Let

$$
d=\det(UV^T)=\det(U)\det(V)\in\{\pm 1\}
$$

and set

$$
R=U\begin{pmatrix}1&0&0\\0&1&0\\0&0&d\end{pmatrix}V^T.
$$

Flipping the last singular vector when $d=-1$ removes reflections so
$\det(R)=+1$. Equivalently one may write $R=VU^T$ under the dual
convention $H=Q^T P$; this package follows the Wikipedia $H=P^T Q$ form
above.

### 4. RMSD and rigid map

$$
\mathrm{RMSD}(P,Q)=\sqrt{\frac1N\sum_{k=1}^{N}\|p_k-q_k\|_2^2}.
$$

Full superimposition uses $t=c_P-R c_Q$ so $q\mapsto Rq+t$ aligns $Q$ onto
$P$.

## Bioinformatics / applications

- **Protein / molecular structure** comparison (backbone RMSD after Kabsch
  fit; FoldX, VMD, and many MD tools).
- **Cheminformatics** and **point-set registration** in computer graphics.
- Related: Wahba’s problem, orthogonal Procrustes, quaternion RMSD
  (Horn / Coutsias).

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Vec3`, `Point_Cloud`, `Mat3` | $N\times 3$ clouds, $3\times 3$ mats |
| Helpers | `Near`, `Near_Vec3`, `Near_Mat3`, `Dot`, `Norm`, `Cross` | Numerics |
| Matrices | `Identity_Mat3`, `Mat3_Mul`, `Mat3_Det`, `Mat3_Transpose`, … | Dense $3\times 3$ |
| Centering | `Centroid`, `Translate_To_Origin`, `Translate_By` | Step 1 |
| Covariance | `Covariance_H` | $H=P^T Q$ |
| SVD | `SVD_3x3` | Jacobi on $A^T A$ |
| Kabsch | `Kabsch_Rotation`, `Apply_Rotation`, `RMSD` | Core |
| Rigid | `Superimpose`, `Transformed_Cloud`, `Superimpose_Result` | $R,t,\mathrm{RMSD}$ |
| 2-D | `Kabsch_Rotation_2D`, `Centroid_2D`, `RMSD_2D`, `Mat2` | Optional XY |

Named exceptions: `Invalid_Argument`, `Degenerate`.

Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`). Capacity: `Max_N = 256`.

## Build and test

```bash
make clean && make        # gnatmake -gnatwa -gnat2022 -Pkabsch.gpr
make test                 # runs bin/tests; expect Fail_Count=0 and ≥100 PASS
```

Requirements: GNAT (GCC Ada) with Ada 2022/2023 support.

## Layout

Exactly seven root entries (no `main.adb`):

1. `kabsch.ads`
2. `kabsch.adb`
3. `kabsch.gpr`
4. `Makefile`
5. `tests.adb`
6. `README.md`
7. `.gitignore` (`obj/`, `bin/`)

## References

- [Wikipedia: Kabsch algorithm](https://en.wikipedia.org/wiki/Kabsch_algorithm)
- Kabsch, W. (1976/1978), *Acta Crystallographica* A32/A34
- Umeyama, S. (1991), *IEEE TPAMI* 13(4)
- Lawrence, Bernal & Witzgall (2019), NIST JRES (algebraic Kabsch–Umeyama)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
