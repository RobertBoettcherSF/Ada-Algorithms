# Gauss–Jordan Elimination (RREF / Inverse) — Ada 2023

Educational, self-contained Ada 2023 package implementing **Gauss–Jordan
elimination** with **partial pivoting**: continue row reduction past upper
triangular form all the way to **reduced row echelon form** (RREF). For a
nonsingular system this yields the solution in one pass by reducing the
augmented matrix

$$
[A\mid b]\;\longrightarrow\;[I\mid x],
$$

and likewise the inverse by reducing

$$
[A\mid I]\;\longrightarrow\;[I\mid A^{-1}].
$$

Cap $n\le 32$, dense educational `Float`. This is classical dense
Gauss–Jordan — not blocked / sparse production code, not complete / rook
pivoting.

Based on [Wikipedia: Gaussian elimination](https://en.wikipedia.org/wiki/Gaussian_elimination)
(see the **reduced row echelon form** and **Finding the inverse of a matrix**
sections; the RREF process is often called **Gauss–Jordan elimination**).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Gaussian-Elimination](https://github.com/RobertBoettcherSF/Ada-Gaussian-Elimination)** — GEPP forward elimination + back-sub (stops at $U$)
- **[Ada-Gauss-Seidel](https://github.com/RobertBoettcherSF/Ada-Gauss-Seidel)** — iterative successive displacement
- **[Ada-Thomas-Algorithm](https://github.com/RobertBoettcherSF/Ada-Thomas-Algorithm)** — $O(n)$ TDMA for tridiagonal systems
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** — iterative SPD Krylov solver

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Full RREF row reduction | Scale pivots to $1$; clear above & below |
| **Solve** | $[A\mid b]\to[I\mid x]$ | One-pass; no separate back-sub |
| **Inverse** | $[A\mid I]\to[I\mid A^{-1}]$ | Same GJ kernel |
| **Pivoting** | Partial (column max $\|a_{ik}\|$) | Educational Float |
| **Det** | $\mathrm{sign}\cdot\prod$ pivots | Pivots recorded **before** scaling |
| **Rank** | Count RREF pivots above `Tol` | Continues past zero columns |
| **vs GE** | Sibling stops at $U$ + back-sub | GJ denser arithmetic, same $O(n^3)$ class |
| **Cap** | $n\le 32$ | `Max_N = 32`; dense |

## How this differs from Ada-Gaussian-Elimination

| | **Ada-Gaussian-Elimination** | **This package (Gauss–Jordan)** |
| --- | --- | --- |
| End form | Upper triangular $U$ (REF) | Reduced row echelon $I$ (RREF) |
| Solution | Back substitution on $U x = b'$ | RHS column already is $x$ |
| Inverse | Not provided | Built-in via $[A\mid I]$ |
| Work | Eliminate **below** only | Eliminate **above and below** + scale |
| Complexity | $O(n^3)$ | Same class; denser constant factor |

Prefer the GE sibling when you only need $Ax=b$ / $\det$ / rank and want
the classical two-phase presentation. Prefer this package when you want
RREF explicitly, or a compact inverse routine.

## Brief history

Carl Friedrich **Gauss** popularized systematic elimination; the full
reduction to RREF is associated with **Wilhelm Jordan** (1888; independently
noted by Clasen the same year). Wikipedia uses **Gaussian elimination** for
the process through (unreduced) row echelon form, and **Gauss–Jordan
elimination** for continuing to reduced row echelon form. The inverse
algorithm — augment $A$ with $I$ and reduce — is the standard textbook
variant of that process.

## Method (this package)

### Partial pivoting Gauss–Jordan

For column $k=1,\ldots,n$ (strict mode used by `Solve` / `Invert` /
`Determinant`):

1. Find row $p\in\{k,\ldots,n\}$ maximizing $|A_{pk}|$.
2. If that maximum is $\le$ `Pivot_Tol`, report **`Singular`** /
   **`Zero_Pivot`**.
3. Swap rows $k$ and $p$ (and all augmented columns); each swap multiplies
   $\det$ by $-1$.
4. **Record** the pivot value $p_k := A_{kk}$ for the determinant product
   (before scaling).
5. Scale row $k$ by $1/p_k$ so the pivot becomes $1$.
6. For every other row $i\neq k$, subtract $A_{ik}$ times row $k$ (clear
   the whole pivot column).

After $n$ successful steps the left block is $I$. For `Rank` /
`Reduce_To_RREF`, a skip-column variant continues past tiny columns so
deficient rank is reported correctly.

### Determinant

$$
\det(A) = (-1)^{s}\prod_{k=1}^{n} p_k,
$$

where $s$ is the number of row swaps and $p_k$ are the pivots **before**
row scaling. Scaling would otherwise destroy the product (every scaled
pivot is $1$).

## API summary

| Symbol | Role |
| --- | --- |
| `Matrix` / `Vector` | 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($32$) |
| `Status` | `Ok`, `Singular`, `Zero_Pivot`, `Dimension_Error`, `Ill_Started` |
| `Result` | `X`, `N`, `Stat`, `Success`, `Swap_Count` from `Solve` |
| `Invert_Result` | `Inv`, `N`, `Stat`, `Success`, `Swap_Count` from `Invert` |
| `RREF_Result` | `R`, `Rank_Value`, status from `Reduce_To_RREF` |
| `Solve` | Non-mutating GJ on $[A\mid b]$ |
| `Invert` | Non-mutating GJ on $[A\mid I]$ |
| `Reduce_To_RREF` | RREF of square $A$ (skip-column for rank) |
| `Determinant` | $\det(A)$ via pre-scale pivot product |
| `Rank` | Pivot-count rank estimate |
| `Residual` / `Residual_Norm` | $r=b-Ax$ and $\|r\|_2$ |
| `Inverse_Residual_Max_Abs` | $\max\|A A^{-1}-I\|$ entrywise |
| `Mat_Mul` / `Mat_Near` | Inverse round-trip helpers |
| `Identity`, `Make_Diagonally_Dominant`, `Make_Hilbert`, `Make_Poisson_1D` | Builders |
| `Make_Example` | Fixed $2\times2$ / $3\times3$ / needs-pivot / singular demos |

## Limits and caveats

- **$n\le 32$**, educational `Float` — not LAPACK, not blocked GJ, not sparse.
- **Partial pivoting only** (not complete / rook). Stability is weak;
  ill-conditioned matrices (e.g. Hilbert) may show larger solution / inverse
  error even when residuals look moderate.
- Denser arithmetic than plain GE (eliminate above *and* below, plus scale)
  but the same $O(n^3)$ complexity class. Prefer structure-exploiting
  siblings (Thomas / CG) when applicable.
- Inputs to `Solve` / `Invert` / `Reduce_To_RREF` are **not** modified.
- Singular or near-singular systems return `Singular` / `Zero_Pivot` with
  `Success = False` for `Solve` / `Invert`.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pgauss_jordan.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `gauss_jordan.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
gauss_jordan.ads
gauss_jordan.adb
gauss_jordan.gpr
tests.adb
```

## References

1. [Wikipedia: Gaussian elimination](https://en.wikipedia.org/wiki/Gaussian_elimination) — RREF / Gauss–Jordan / inverse sections
2. Higham, N. J. *Accuracy and Stability of Numerical Algorithms* (pivoting /
   stability).
3. Golub & Van Loan, *Matrix Computations* (elimination / inverse).
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
