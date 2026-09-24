# Birkhoff Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **Birkhoff
interpolation** (also called *loxodromic* interpolation): find a polynomial
$P$ of degree less than $N$ that matches **selected** derivative conditions

$$
P^{(n_i)}(x_i)=y_i,\qquad i=1,\ldots,N.
$$

Unlike **Hermite** interpolation, the orders $n_i$ need **not** be contiguous
from order $0$ at each node — gaps (“lacunary” conditions) are allowed. The
price is that a Birkhoff problem need **not** have a unique solution: the
**incidence matrix** may be singular. This package builds the monomial linear
system for the coefficients of

$$
P(x)=c_0+c_1 x+\cdots+c_{N-1}x^{N-1}
$$

and solves it with **GEPP** (Gaussian elimination with partial pivoting),
capping $N\le 9$ (degree $\le 8$), educational `Float`. Regular presets cover
Lagrange (values only), Hermite two-point value+derivative, and the Wikipedia
/ Pólya regular pattern $P'(x_L),\,P(x_M),\,P'(x_R)$.

Based on [Wikipedia: Birkhoff interpolation](https://en.wikipedia.org/wiki/Birkhoff_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Hermite-Interpolation](https://github.com/RobertBoettcherSF/Ada-Hermite-Interpolation)** — piecewise cubic Hermite / osculatory
- **[Ada-Lagrange-Interpolation](https://github.com/RobertBoettcherSF/Ada-Lagrange-Interpolation)** — classical / barycentric Lagrange
- **[Ada-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Cubic-Interpolation)** — Catmull–Rom / Keys / thin Hermite survey
- **[Ada-Polynomial-Interpolation](https://github.com/RobertBoettcherSF/Ada-Polynomial-Interpolation)** — Lagrange / Newton / Neville / monomial GEPP

After this sheet (topic list): **Geometric** (header — skip), **Level set**
(Ada $=x$ — skip), next interesting **[Filtered back-projection](https://en.wikipedia.org/wiki/Filtered_back_projection)**,
then **[Kahan summation](https://en.wikipedia.org/wiki/Kahan_summation_algorithm)**, etc.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Selected $P^{(n_i)}(x_i)=y_i$ | Degree $<N$ for $N$ conditions |
| **Linear algebra** | Monomial rows + GEPP | Cap $N\le 9$ |
| **Incidence** | $0/1$ pattern of which $(i,j)$ | May be singular (unlike Lagrange/Hermite) |
| **Presets** | Lagrange / Hermite-2pt / Pólya regular | Known unique examples |
| **Status** | `Ok` … `Dimension_Error` | Incl. `Singular`, `Inconsistent` |
| **Evaluate** | Horner | Plus `Evaluate_Derivative` |
| **Cap** | $N\le 9$ | `Max_Conditions = 9` |

## Brief history

George David Birkhoff studied the problem in 1906: interpolate with a
polynomial when only **some** derivatives are prescribed at the nodes. Lagrange
(all $n_i=0$) and Hermite (contiguous orders $0,1,\ldots$ at each node) are
special cases that are always uniquely solvable for distinct nodes. In the
general Birkhoff setting uniqueness depends on the **incidence matrix** $E$
(Schoenberg): $e_{ij}=1$ iff order $j$ is required at node $i$. For two nodes,
Pólya (1931) gave the necessary and sufficient column-sum condition
$S_m\ge m$ for all $m$; Schoenberg showed necessity for any number of nodes.
A standard Wikipedia pair of $3\times 3$ examples contrasts a **singular**
pattern $\bigl(\begin{smallmatrix}1&0&0\\0&1&0\\1&0&0\end{smallmatrix}\bigr)$
(e.g. $P(-1)=P(1)=0$, $P'(0)=1$ — inconsistent for quadratics) with a
**regular** pattern $\bigl(\begin{smallmatrix}0&1&0\\1&0&0\\0&1&0\end{smallmatrix}\bigr)$
($P'(-1)$, $P(0)$, $P'(1)$ — always unique).

## Algorithm (this package)

Given conditions $(x_i,n_i,y_i)$ for $i=1,\ldots,N$ with $1\le N\le 9$:

1. Validate length (`Ill_Started` if empty, `Too_Many_Conditions` if $N>9$).
2. Form the $N\times N$ matrix $A$ with
   $$
   A_{i,k}=\begin{cases}
   0 & \text{if }k<n_i,\\
   \dfrac{k!}{(k-n_i)!}\,x_i^{k-n_i} & \text{if }k\ge n_i,
   \end{cases}
   \qquad k=0,\ldots,N-1,
   $$
   and RHS $b_i=y_i$ (monomial basis for $P$).
3. Solve $A\,c=b$ by **GEPP**. A vanishing pivot with nonzero residual row
   yields `Inconsistent`; a vanishing pivot with a zero row yields
   `Singular`.
4. On success, store $c_0,\ldots,c_{N-1}$ in `Polynomial` and evaluate with
   **Horner**; derivatives use the same falling-factorial entries.

### Regular presets

- **Lagrange:** $n_i=0$ only — classical value interpolation.
- **Hermite two-point:** value + first derivative at two nodes → unique cubic.
- **Pólya regular:** $P'(x_L)$, $P(x_M)$, $P'(x_R)$ for distinct nodes —
  Wikipedia’s always-unique $3\times 3$ example.
- **Singular demo:** $P(x_L)$, $P'(x_M)$, $P(x_R)$ — Wikipedia’s singular
  pattern (often `Inconsistent` for nonzero middle derivative).

## API summary

| Symbol | Role |
| --- | --- |
| `Condition` | `Node`, `Derivative_Order`, `Value` |
| `Conditions`, `Condition_List` | Array / packed list of conditions |
| `Coefficients`, `Polynomial` | Monomial $c_0+\cdots+c_{N-1}x^{N-1}$ |
| `Abscissae`, `Ordinates` | 0-based $x$ / $y$ for Lagrange builder |
| `Max_Conditions` / `Max_Degree` | Cap $N\le 9$ (degree $\le 8$) |
| `Status` | `Ok` / `Singular` / `Inconsistent` / `Too_Many_Conditions` / `Ill_Started` / `Dimension_Error` |
| `Fit_Result`, `Eval_Result` | Fit/eval + `Stat` + `Success` |
| `Near`, `Make_Condition` | Helpers |
| `Monomial_Derivative_Entry` | Row entry $(k!/(k-d)!)x^{k-d}$ |
| `Validate` | Pre-check lengths |
| `Fit` | Build incidence system + GEPP |
| `Evaluate` | Horner $P(x)$ |
| `Evaluate_Derivative` | $P^{(\mathrm{order})}(x)$ |
| `Matches_Condition`, `Matches_All` | Verify fitted poly vs conditions |
| `Make_Lagrange_Conditions` | Values-only preset |
| `Make_Hermite_Two_Point` | Two-point value+derivative |
| `Make_Birkhoff_Polya_Regular` | Wiki regular lacunary pattern |
| `Make_Birkhoff_Singular_Example` | Wiki singular pattern |
| `Make_Example` | Dispatch by `Example_Kind` |
| `Slice` | View `Condition_List` as `Conditions` |

## Limits and caveats

- **Not always unique** — unlike Lagrange / Hermite, Birkhoff incidence can be
  singular or inconsistent; always check `Status`.
- **Educational `Float` + GEPP** — ordinary single precision; monomial
  Vandermonde-like rows are ill-conditioned for larger $N$ (hence the cap).
- **Square systems only** — $N$ conditions determine degree $<N$; no
  least-squares overdetermination beyond `Too_Many_Conditions`.
- **Sibling depth** — full piecewise Hermite / barycentric Lagrange live in
  their own packages; this one emphasises incidence + linear algebra.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pbirkhoff_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `birkhoff_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
birkhoff_interpolation.ads
birkhoff_interpolation.adb
birkhoff_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Birkhoff interpolation](https://en.wikipedia.org/wiki/Birkhoff_interpolation)
2. G. D. Birkhoff, “General mean value and remainder theorems…,” *Trans. Amer.
   Math. Soc.* **7** (1906)
3. G. Pólya, “Remark on interpolation…,” *Acta Sci. Math. (Szeged)* (1931);
   I. J. Schoenberg on incidence matrices
4. Siblings: [Ada-Hermite-Interpolation](https://github.com/RobertBoettcherSF/Ada-Hermite-Interpolation),
   [Ada-Lagrange-Interpolation](https://github.com/RobertBoettcherSF/Ada-Lagrange-Interpolation),
   [Ada-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Cubic-Interpolation);
   after this sheet: Filtered back-projection, Kahan (Geometric / Level-set skipped)
