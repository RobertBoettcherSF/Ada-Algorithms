# Gaussian Elimination (GEPP) — Ada 2023

Educational, self-contained Ada 2023 package implementing **Gaussian
elimination** with **partial pivoting** (GEPP): forward elimination to upper
triangular form, then back substitution for dense linear systems

$$
A x = b,\qquad A\in\mathbb{R}^{n\times n},\quad x,b\in\mathbb{R}^{n}.
$$

The same factorization yields the **determinant** (product of pivots, with
sign from row swaps) and a **rank** estimate. Cap $n\le 32$, dense educational
`Float`. This is classical dense GE — not complete / rook pivoting, not a
blocked / sparse production solver.

Based on [Wikipedia: Gaussian elimination](https://en.wikipedia.org/wiki/Gaussian_elimination).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Thomas-Algorithm](https://github.com/RobertBoettcherSF/Ada-Thomas-Algorithm)** — $O(n)$ TDMA for tridiagonal systems
- **[Ada-Gauss-Seidel](https://github.com/RobertBoettcherSF/Ada-Gauss-Seidel)** — upcoming iterative smoother
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** — iterative SPD Krylov solver
- **[Ada-Levinson-Recursion](https://github.com/RobertBoettcherSF/Ada-Levinson-Recursion)** — $O(n^2)$ Toeplitz Levinson–Durbin

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Row reduction / LU view of $A$ | Elementary row ops |
| **Forward** | GE with **partial pivoting** | Swap for max $\|a_{ik}\|$ in column |
| **Back-sub** | Solve $U x = b'$ | Upper-triangular |
| **Det** | $\mathrm{sign}\cdot\prod U_{ii}$ | Sign from swap count |
| **Rank** | Count pivots above `Tol` | Continues past zero columns |
| **Stability** | Partial pivoting helps | Weak; Float educational |
| **Builders** | Identity / DD / Hilbert / Poisson | Teaching matrices |
| **Cap** | $n\le 32$ | `Max_N = 32`; dense $O(n^3)$ |

## Brief history

Carl Friedrich **Gauss** popularized systematic elimination for least-squares
and planetary orbit work; the modern algorithmic form (and the link to LU
factorization) is standard numerical linear algebra. Without pivoting, GE can
fail or become unstable when a leading entry is zero or tiny. **Partial
pivoting** (choose the largest absolute entry in the active column) is the
usual practical fix for general dense matrices; complete / rook pivoting is
stronger but costlier. Wikipedia notes that GE is typically considered stable
*with* partial pivoting for general matrices, though pathological
counterexamples exist.

## Method (this package)

### Forward elimination (partial pivoting)

For column $k=1,\ldots,n$:

1. Find row $p\in\{k,\ldots,n\}$ maximizing $|A_{pk}|$.
2. If that maximum is $\le$ `Pivot_Tol`, report **`Singular`** / **`Zero_Pivot`**.
3. Swap rows $k$ and $p$ (and the RHS); each swap multiplies $\det$ by $-1$.
4. For each row $i>k$, subtract $(A_{ik}/A_{kk})$ times row $k$ from row $i$.

The coefficient matrix becomes upper triangular $U$; the RHS is updated in
lockstep.

### Back substitution

$$
x_n = \frac{b'_n}{U_{nn}},\qquad
x_i = \frac{b'_i - \sum_{j=i+1}^{n} U_{ij} x_j}{U_{ii}},
\quad i=n-1,\ldots,1.
$$

### Determinant and rank

$$
\det(A) = (-1)^{s}\prod_{i=1}^{n} U_{ii},
$$

where $s$ is the number of row swaps. Rank is estimated by counting pivots
with $|U_{ii}|$ (or column-pivots in the rank routine) above a tolerance,
skipping zero columns.

## Why pivoting?

Without pivoting, a zero (or tiny) diagonal entry stops elimination or
amplifies roundoff. Example: $A=\begin{bmatrix}0&1\\1&0\end{bmatrix}$ needs
an immediate swap. Partial pivoting chooses the largest available pivot in the
column — cheap ($O(n^2)$ comparisons overall) and usually enough for
educational `Float` work. It is **not** complete pivoting (search a whole
submatrix) and **not** rook pivoting.

Dense GE is $O(n^3)$ arithmetic and $O(n^2)$ storage. For tridiagonal systems
prefer Thomas ($O(n)$); for SPD prefer CG; for Toeplitz prefer Levinson — see
siblings.

## API summary

| Symbol | Role |
| --- | --- |
| `Matrix` / `Vector` | 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($32$) |
| `Status` | `Ok`, `Singular`, `Zero_Pivot`, `Dimension_Error`, `Ill_Started` |
| `Result` | `X`, `N`, `Stat`, `Success`, `Swap_Count` |
| `Factor_Result` | `U`, permuted `B`, `Swap_Count`, `Det_Sign` |
| `Solve` | Non-mutating GEPP solve (copies $A$) |
| `Factor` / `Eliminate` | Forward GEPP → $U$ + RHS |
| `Back_Substitute` | Solve $U x = b'$ from a factor |
| `Determinant` | $\det(A)$ via GEPP pivots |
| `Rank` | Pivot-count rank estimate |
| `Residual` / `Residual_Norm` | $r=b-Ax$ and $\|r\|_2$ |
| `Identity`, `Make_Diagonally_Dominant`, `Make_Hilbert`, `Make_Poisson_1D` | Builders |
| `Make_Example` | Fixed $2\times2$ / $3\times3$ / needs-pivot demos |

## Limits and caveats

- **$n\le 32$**, educational `Float` — not LAPACK, not blocked GE, not sparse.
- **Partial pivoting only** (not complete / rook). Stability is weak;
  ill-conditioned matrices (e.g. Hilbert) may show large solution error even
  when residuals look moderate.
- Dense complexity $O(n^3)$; prefer structure-exploiting siblings when
  applicable.
- Inputs to `Solve` / `Factor` / `Eliminate` are **not** modified.
- Singular or near-singular systems return `Singular` / `Zero_Pivot` with
  `Success = False`.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pgaussian_elimination.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `gaussian_elimination.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
gaussian_elimination.ads
gaussian_elimination.adb
gaussian_elimination.gpr
tests.adb
```

## References

1. [Wikipedia: Gaussian elimination](https://en.wikipedia.org/wiki/Gaussian_elimination)
2. Higham, N. J. *Accuracy and Stability of Numerical Algorithms* (pivoting /
   stability).
3. Golub & Van Loan, *Matrix Computations* (GEPP / LU).
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
