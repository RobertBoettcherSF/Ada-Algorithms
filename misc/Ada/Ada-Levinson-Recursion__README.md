# Levinson Recursion (Levinson–Durbin) — Ada 2023

Educational, self-contained Ada 2023 package implementing **Levinson recursion**
(also **Levinson–Durbin**): an $O(n^2)$ solver for **Toeplitz** linear systems

$$
T x = y,
$$

where $T$ is constant along diagonals. The first row (and, for the symmetric
case treated here, the first column) fully defines $T$:

$$
T_{i,j} = t_{|i-j|},\qquad
R = (t_0,t_1,\ldots,t_{n-1}).
$$

Cap $n\le 128$, dense educational `Float`. Improvements by **Trench** and
**Zohar** reduce the leading constant further; this package teaches the
classical forward/backward-vector form.

Based on [Wikipedia: Levinson recursion](https://en.wikipedia.org/wiki/Levinson_recursion).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Thomas-Algorithm](https://github.com/RobertBoettcherSF/Ada-Thomas-Algorithm)** — $O(n)$ TDMA for tridiagonal systems
- **[Ada-Gaussian-Elimination](https://github.com/RobertBoettcherSF/Ada-Gaussian-Elimination)** — forthcoming dense GE / GEPP
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** — iterative SPD Krylov solver

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Exploit Toeplitz displacement | Only $n$ parameters, not $n^2$ |
| **Levinson** | Forward/backward vectors | Build order $1\to n$ |
| **Durbin** | Yule–Walker specialization | $T a = -\rho$ for prediction |
| **PARCOR** | Reflection coefficients $k_m$ | $|k_m|<1$ for SPD |
| **Complexity** | $\Theta(n^2)$ time, $O(n)$ work vectors | vs $\Theta(n^3)$ dense GE |
| **Stability** | Weakly stable (well-conditioned) | Prefer Bareiss / GEPP if unsure |
| **Cap** | $n\le 128$ | `Max_N = 128` |

## Brief history

Norman **Levinson** (1947) introduced the recursion for Wiener filter design;
James **Durbin** (1960) specialized it to time-series / Yule–Walker fitting.
**Trench** and **Zohar** later trimmed the arithmetic to about $3n^2$–$4n^2$
multiplications. Despite newer $\Theta(n(\log n)^p)$ “superfast” Toeplitz
solvers, Levinson–Durbin remains popular for moderate $n$ (often $n<256$)
and for its transparent link to linear prediction and reflection
(PARCOR) coefficients.

## Toeplitz structure

A matrix is Toeplitz when each descending diagonal is constant. Symmetric
Toeplitz matrices arise from stationary autocorrelation: the Yule–Walker
system of an AR process is exactly of this form. Compared with general dense
GE ($O(n^3)$), Levinson uses the structure to reach $O(n^2)$.

## Method (this package)

### Forward / backward vectors (Levinson)

At order $m$, the forward vector $f^{(m)}$ satisfies

$$
T_m\, f^{(m)} = e_1
$$

($e_1$ is the first unit vector). For **symmetric** $T$, the backward vector
is the reversal $b^{(m)}_i = f^{(m)}_{m+1-i}$. Extending with a trailing /
leading zero produces error terms $\varepsilon_f$ (and $\varepsilon_b=\varepsilon_f$
when symmetric). The update

$$
f^{(m+1)}
=
\frac{1}{1-\varepsilon_f^2}
\left(
\begin{bmatrix} f^{(m)} \\ 0 \end{bmatrix}
-
\varepsilon_f
\begin{bmatrix} 0 \\ b^{(m)} \end{bmatrix}
\right)
$$

raises the order. The solution is built in parallel:

$$
x^{(m+1)}
=
\begin{bmatrix} x^{(m)} \\ 0 \end{bmatrix}
+
\varepsilon_x\, b^{(m+1)},
$$

where $\varepsilon_x$ is the residual of the new last equation when $x^{(m)}$
is padded with a zero. If $|t_0|$ or $|1-\varepsilon_f^2|$ falls below
`Pivot_Tol`, the solver returns **`Degenerate`** (singular / vanishing $E_m$).

### Durbin (Yule–Walker)

For prediction coefficients, Durbin solves $T a = -\rho$ with
$\rho=(t_1,\ldots,t_P)$ using reflection coefficients

$$
k_m
=
-\frac{
t_m + \sum_{j=1}^{m-1} a_j^{(m-1)} t_{m-j}
}{E_{m-1}},
\qquad
E_m = E_{m-1}(1-k_m^2),
$$

and the usual lattice update of $a^{(m)}$. Input `R` has length $P+1$
(lags $0..P$).

## Stability

Levinson recursion is at best **weakly stable**: reliable for well-conditioned
SPD Toeplitz systems (e.g. decaying autocorrelations with $t_0$ dominant),
more sensitive to round-off than Bareiss or GEPP on the same matrix. For
ill-conditioned $T$, prefer those siblings / dense methods. Vanishing
prediction-error power $E_m$ (equivalently $|k_m|\to 1$ or
$|1-\varepsilon_f^2|\to 0$) is reported as `Degenerate`.

## API summary

| Symbol | Role |
| --- | --- |
| `Toeplitz_Row` / `Vector` | Lags $t_0,\ldots,t_{n-1}$ (1-based `Float`) |
| `Max_N` | Hard dimension cap ($128$) |
| `Status` | `Ok`, `Degenerate`, `Ill_Started`, `Size_Mismatch` |
| `Result` | `X`, `N`, `Stat`, `Success`, `Order` |
| `Solve_Levinson` / `Solve` | Symmetric Toeplitz solve (alias pair) |
| `Durbin_Yule_Walker` | Prediction coeffs $a$, PARCOR $k$, final $E$ |
| `Reflection_Coefficients` | PARCOR $k_1..k_{n-1}$ from lags |
| `Multiply_Toeplitz` | Dense $y=Tx$ for residual checks |
| `Residual` / `Residual_Norm` | $r=y-Tx$ and $\|r\|_2$ |
| `Make_Exponential_Toeplitz` | $t_0=\mathrm{Diag}$, $t_k=\mathrm{Scale}\,\rho^k$ |
| `Make_Constant_Toeplitz` | Constant off-diagonals |
| `Toeplitz_Entry` | $T_{i,j}=R(1+\|i-j\|)$ |
| `Near`, `Vec_Near`, `Norm2` | Numeric helpers |

## Limits and caveats

- **$n\le 128$**, educational `Float` — not a production blocked / packed /
  superfast Toeplitz solver; no non-symmetric (row $\neq$ column) Levinson,
  no split-Levinson, no Schur-parameter pipeline beyond PARCOR.
- **Symmetric Toeplitz only** in this teaching package: first row equals
  first column.
- **Weak stability** — check residuals (`Residual_Norm`) on ill-conditioned
  inputs; zero / tiny $E_m$ yields `Degenerate`.
- Durbin expects `R'Length = P+1`; Levinson expects `R'Length = Y'Length`.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Plevinson_recursion.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `levinson_recursion.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
levinson_recursion.ads
levinson_recursion.adb
levinson_recursion.gpr
tests.adb
```

## References

1. [Wikipedia: Levinson recursion](https://en.wikipedia.org/wiki/Levinson_recursion)
2. Levinson, N. (1947). “The Wiener RMS error criterion in filter design and prediction.”
3. Durbin, J. (1960). “The fitting of time series models.”
4. Trench / Zohar refinements; Bareiss algorithm (stable $O(n^2)$ alternative).
5. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
