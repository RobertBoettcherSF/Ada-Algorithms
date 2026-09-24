# Partial Least Squares Regression (Ada 2023)

Educational, self-contained Ada 2022/2023 package implementing
**Partial least squares (PLS) regression** as described on Wikipedia:
a latent-variable **bilinear** model that projects predictors $X$ and
responses $Y$ to a shared score space of **maximum covariance**.

PLS was introduced by **Herman O. A. Wold** and developed with
**Svante Wold**. An alternate name is *projection to latent structures*.
Although early uses were in the social sciences, PLS is now a workhorse
of **chemometrics** (and appears in bioinformatics, sensometrics,
neuroscience, and anthropology). It is especially useful when $X$ has
**more variables than samples** or **multicollinear** columns—settings
where ordinary least squares is unstable or undefined.

## Core idea

Given paired observations $(\mathbf{x}_i, \mathbf{y}_i)$, PLS seeks
directions $\mathbf{p}, \mathbf{q}$ maximising
$\mathbb{E}[(\mathbf{p}\cdot X)\,(\mathbf{q}\cdot Y)]$.
The underlying multi-component model is

$$
X = T P^{\mathrm{T}} + E, \qquad
Y = U Q^{\mathrm{T}} + F,
$$

with score matrices $T,U$ and loadings $P,Q$. Unlike PCA (orthogonal
loadings), PLSR builds an **orthogonal score** basis.

## PLS1 (this package)

**PLS1** is the single-response algorithm. Wikipedia’s listed PLS1
pseudocode carries a caution that $t$-normalisation may be imperfect.
This package uses a **correct educational NIPALS/PLS1** variant:

1. Optionally **center** columns of $X$ and the vector $y$.
2. For each component $k = 1..A$:
   - $w \propto X^{\mathrm{T}} y$, then $\|w\|_2 = 1$;
   - $t = X w$;
   - $p = X^{\mathrm{T}} t / (t^{\mathrm{T}} t)$;
   - $q = y^{\mathrm{T}} t / (t^{\mathrm{T}} t)$;
   - stop early if residual covariance $\approx 0$;
   - **deflate** $X \leftarrow X - t p^{\mathrm{T}}$ and
     $y \leftarrow y - t q$.
3. Form regression weights
   $B = W\,(P^{\mathrm{T}} W)^{-1} q$,
   with intercept $B_0 = \bar y - \bar x^{\mathrm{T}} B$ when centered.

Scores $t$ are orthogonal; weights $w$ are unit-norm. Prediction is
$\hat y = B_0 + X_{\mathrm{new}} B$.

**PLS2** (multi-response) is a compact NIPALS loop
($u \leftarrow Yc$, $w \leftarrow X^{\mathrm{T}} u$, …) with the same
$B = W(P^{\mathrm{T}} W)^{-1} C^{\mathrm{T}}$ construction per response.

Related algorithm **not** implemented here: **SIMPLS** (de Jong, 1993).

## Features

- Bounded row-major matrices (`Max_Rows`, `Max_Cols`, `Max_Components`)
- Embedded educational linear algebra: `Dot`, `Norm2`, `Scale`, `Axpy`,
  `Outer_Add`, `Mat_Vec`, `Mat_T_Vec`, centering / standardise,
  Gaussian elimination for $(P^{\mathrm{T}} W)$
- `PLS1_Fit` / `PLS1_Predict`, `PLS2_Fit` / `PLS2_Predict`
- Helpers: `R_Squared`, `RMSE`, `Near`, `Ordinary_Least_Squares_1D`
- Contracts (`Pre`/`Post`/`Global`), exceptions
  `Invalid_Argument`, `Degenerate_Geometry`, `Capacity_Exceeded`
- `pragma Ada_2022`; `SPARK_Mode => Off`; `type Real is digits 12`

## Layout

Root-only (no `src/`, no `main.adb`):

| File | Role |
|------|------|
| `partial_least_squares.ads` / `.adb` | Package |
| `partial_least_squares.gpr` | GNAT project |
| `tests.adb` | Test main |
| `Makefile` | `gnatmake -gnatwa -gnat2022 -P…` |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## Usage

```ada
with Partial_Least_Squares; use Partial_Least_Squares;

declare
   X : Matrix (1 .. N, 1 .. M) := …;
   Y : Vector (1 .. N) := …;
   Mdl : constant PLS1_Model := PLS1_Fit (X, Y, N_Components => 2);
   Y_Hat : constant Vector := PLS1_Predict (Mdl, X);
begin
   null;  -- inspect Mdl.B, Mdl.B0, R_Squared (Y, Y_Hat), …
end;
```

## Building / testing

```bash
cd /workspace/ada-partial-least-squares
make clean && make          # zero errors / warnings
make test                   # Fail_Count = 0
```

Requires GNAT with Ada 2022 support (`-gnat2022`).

## References

- Wikipedia: *Partial least squares regression*
- Wold, S., Sjöström, M., Eriksson, L. (2001). PLS-regression: a basic
  tool of chemometrics. *Chemometrics and Intelligent Laboratory Systems*.
- Abdi, H. (2010). Partial least squares regression and projection on
  latent structure regression (PLS Regression). *WIREs Computational
  Statistics*.
- Höskuldsson, A. (1988). PLS Regression Methods. *Journal of Chemometrics*.
- de Jong, S. (1993). SIMPLS: an alternative approach to partial least
  squares regression. *Chemometrics and Intelligent Laboratory Systems*
  (related; not implemented here).
- Wold, H. (1966 / 1985). NIPALS / partial least squares foundations.
