# Gram–Schmidt Process — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Gram–Schmidt process** for orthonormalizing $k$ vectors in
$\mathbb{R}^n$ (columns of an $n\times k$ matrix). Both **classical**
Gram–Schmidt (CGS) and **modified** Gram–Schmidt (MGS) are provided;
MGS is the default because it has better numerical behaviour in
floating point.

$$
\begin{aligned}
u_1 &= v_1, &
q_1 &= \frac{u_1}{\|u_1\|},\\
u_i &= v_i - \sum_{j=1}^{i-1}\mathrm{proj}_{q_j}(v_i), &
q_i &= \frac{u_i}{\|u_i\|}.
\end{aligned}
$$

Near-zero residual norms are treated as **rank deficiency** (the column
is skipped). Cap $n,k\le 32$, dense educational `Float`.

Based on [Wikipedia: Gram–Schmidt process](https://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Gaussian-Elimination](https://github.com/RobertBoettcherSF/Ada-Gaussian-Elimination)** — dense GEPP / det / rank
- **QR decomposition** — upcoming (GS applied to matrix columns)
- **Rayleigh quotient iteration** — upcoming
- **Power method** — upcoming
- **Lanczos algorithm** — upcoming
- **Arnoldi iteration** — upcoming
- **Eigenvalue methods survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Build orthonormal $q_i$ spanning $\mathrm{span}\{v_j\}$ | Euclidean inner product |
| **Classical** | Project original $v_i$ onto all prior $q_j$ | Unstable in Float |
| **Modified** | Subtract $\langle u,q_j\rangle q_j$ from updated $u$ | Preferred default |
| **Rank** | Skip columns with $\|u\|\le$ `Tol` | `Rank_Deficient` / `Zero_Vector` |
| **Check** | $\|Q^\top Q - I\|_\infty$ residual | `Is_Orthonormal` |
| **Builders** | Basis / independent / dependent / Hilbert | Teaching matrices |
| **Cap** | $n,k\le 32$ | `Max_N = 32`; dense $O(nk^2)$ |

## Brief history

The process is named after **Jørgen Pedersen Gram** and **Erhard Schmidt**,
though **Pierre-Simon Laplace** knew equivalent ideas earlier. In modern
numerical linear algebra it is the classical route from a full-column-rank
matrix to a thin **QR** factorization ($A=QR$ with $Q$ orthonormal and $R$
upper triangular). Wikipedia emphasizes that classical GS loses orthogonality
under roundoff, while the modified algorithm is substantially more stable.

## Classical vs modified

**Projection** onto a nonzero $u$:

$$
\mathrm{proj}_{u}(v) = \frac{\langle v,u\rangle}{\langle u,u\rangle}\,u.
$$

**Classical Gram–Schmidt** forms each residual from the *original* column:

$$
u_i = v_i - \sum_{j<i}\langle v_i,q_j\rangle q_j,\qquad
q_i = u_i/\|u_i\|.
$$

**Modified Gram–Schmidt** updates the working vector one projection at a
time:

$$
\begin{aligned}
u_i^{(0)} &= v_i,\\
u_i^{(j)} &= u_i^{(j-1)} - \langle u_i^{(j-1)},q_j\rangle q_j
  \quad (j=1,\ldots,i-1),\\
q_i &= u_i^{(i-1)} / \|u_i^{(i-1)}\|.
\end{aligned}
$$

In exact arithmetic both produce the same $Q$. In floating point, CGS can
lose orthogonality badly on ill-conditioned inputs (e.g. Hilbert columns);
MGS typically keeps $Q^\top Q\approx I$ much closer to identity. This package
defaults `Orthonormalize` to **Modified**.

## Method (this package)

1. Copy the $n\times k$ input (columns $=$ vectors); do not mutate the caller.
2. For each column $j=1,\ldots,k$, form the residual $u$ by CGS or MGS against
   already accepted orthonormal columns.
3. If $\|u\|_2 >$ `Rank_Tol`, append $q=\|u\|^{-1}u$; otherwise skip (rank drop).
4. Return `Result` with leading $N\times\mathrm{Rank}$ block of $Q$, status, and
   method tag.

Status meanings:

- `Ok` — $\mathrm{Rank}=k$ (full column rank under the tolerance)
- `Rank_Deficient` — $0<\mathrm{Rank}<k$ (still a valid orthonormal set)
- `Zero_Vector` — every column was near zero ($\mathrm{Rank}=0$)
- `Dimension_Error` / `Ill_Started` — invalid sizes / unused default

## API summary

| Symbol | Role |
| --- | --- |
| `Vector` / `Matrix` | 1-based educational `Float`; columns $=$ vectors |
| `Max_N` | Hard dimension cap ($32$) |
| `Status` | `Ok`, `Rank_Deficient`, `Dimension_Error`, `Ill_Started`, `Zero_Vector` |
| `Method_Kind` | `Classical`, `Modified` |
| `Result` | `Q`, `N`, `K`, `Rank`, `Stat`, `Success`, `Method` |
| `Classical_GS` | Classical orthonormalization |
| `Modified_GS` | Modified orthonormalization |
| `Orthonormalize` | Dispatch (default **Modified**) |
| `Dot`, `Norm2`, `Proj`, `Scale`, `Add`, `Sub` | Vector helpers |
| `Column`, `Set_Column` | Extract / write a matrix column |
| `Is_Orthonormal`, `Orthonormality_Residual` | $Q^\top Q\approx I$ checks |
| `Near`, `Vec_Near` | Tolerance comparisons |
| `Standard_Basis`, `Make_Independent`, `Make_Dependent` | Builders |
| `Make_Hilbert_Columns`, `Make_Orthogonal_Already`, `Make_Nearly_Dependent` | Builders |
| `Make_Example` | Dispatch over `Example_Kind` |

## Limits and caveats

- **$n,k\le 32$**, educational `Float` — not LAPACK / Householder QR, not a
  blocked production routine.
- **Classical GS is numerically unstable**; prefer `Modified_GS` /
  default `Orthonormalize` when orthogonality matters.
- Rank detection uses a residual-norm tolerance (`Rank_Tol`), not a
  rigorous exact-arithmetic rank test.
- Inputs to the GS entry points are **not** modified.
- Applying GS to matrix columns is the classical path to thin QR; a
  dedicated QR sibling is planned (see links above).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pgram_schmidt.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `gram_schmidt.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
gram_schmidt.ads
gram_schmidt.adb
gram_schmidt.gpr
tests.adb
```

## References

1. [Wikipedia: Gram–Schmidt process](https://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process)
2. Trefethen & Bau, *Numerical Linear Algebra* (Lecture 8: Gram–Schmidt /
   QR).
3. Golub & Van Loan, *Matrix Computations* (classical vs modified GS).
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
