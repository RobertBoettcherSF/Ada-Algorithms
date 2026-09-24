# ITP Method — Ada 2023

Educational, self-contained Ada 2023 package implementing the **ITP method**
(**Interpolate Truncate Project**) — a **bracketed** scalar root finder due to
**Oliveira & Takahashi (2021)**. It is the first algorithm that achieves the
**superlinear** convergence of the secant / regula-falsi family while retaining
the **optimal worst-case** performance of the **bisection** method, and the
first with guaranteed **average** performance strictly better than bisection
under any continuous distribution on the root.

Based on [Wikipedia: ITP method](https://en.wikipedia.org/wiki/ITP_method).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (root-finding series):

| Package | Role |
| --- | --- |
| [Ada-Ridders-Method](https://github.com/RobertBoettcherSF/Ada-Ridders-Method) | Ridders' exponential false-position hybrid |
| [Ada-Bisection-Method](https://github.com/RobertBoettcherSF/Ada-Bisection-Method) | Classic bisection (forthcoming) |
| [Ada-False-Position-Method](https://github.com/RobertBoettcherSF/Ada-False-Position-Method) | Regula falsi (forthcoming) |
| [Ada-Newtons-Method](https://github.com/RobertBoettcherSF/Ada-Newtons-Method) | Newton–Raphson (forthcoming) |
| [Ada-ITP-Method](https://github.com/RobertBoettcherSF/Ada-ITP-Method) | This package |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Interpolate → Truncate → Project | Regula falsi + minmax neighbourhood |
| **Bracket** | Require $f(a)f(b)<0$ | Guaranteed enclosure |
| **Worst case** | At most $n_{1/2}+n_0$ iters | Equals bisection when $n_0=0$ |
| **Average** | Strictly better than bisection | For any continuous root prior ($n_0=0$) |
| **Asymptotics** | Order $\sqrt{\kappa_2}$ when smooth | With slack $n_0\neq 0$ (typical) |
| **API** | `Objective_Fn` access-to-function | `Result` with `Status` + final bracket |
| **Limits** | Educational `Real` (digits 15) | Not a production solver |

## Brief history and claims

**I. F. D. Oliveira** and **R. H. C. Takahashi** introduced ITP in *ACM TOMS*
(2021) as an enhancement of bisection that preserves **minmax optimality**
while exploiting interpolation when it helps. Practically it often beats
Brent, Ridders, and Illinois-style hybrids on both well-behaved and
ill-behaved objectives, because failed interpolations cannot destroy the
bisection-style worst-case budget.

Hyper-parameters:

$$
\kappa_1\in(0,\infty),\qquad
\kappa_2\in\bigl[1,\,1+\phi\bigr),\qquad
n_0\in[0,\infty),
$$

where $\phi=\tfrac12(1+\sqrt{5})$ is the golden ratio. Defaults used here
follow the Wikipedia example: $\kappa_1=0.1$, $\kappa_2=2$, $n_0=1$.
(The R `itp` package often uses $\kappa_1=0.2/(b-a)$ instead.)

## Method

Given continuous $f$ on $[a,b]$ with $f(a)f(b)<0$ and target precision
$\epsilon>0$, define

$$
n_{1/2}\equiv\left\lceil\log_2\frac{b-a}{2\epsilon}\right\rceil,
\qquad
n_{\max}=n_{1/2}+n_0.
$$

While $b-a>2\epsilon$, each iteration $j=0,1,2,\ldots$ builds a query
$x_{\mathrm{ITP}}$ in three steps.

**Interpolation** — bisection midpoint and regula falsi:

$$
x_{1/2}=\frac{a+b}{2},\qquad
x_f=\frac{b\,f(a)-a\,f(b)}{f(a)-f(b)}.
$$

(Equivalently $x_f=(y_b a-y_a b)/(y_b-y_a)$ with $y_a=f(a)$, $y_b=f(b)$.)

**Truncation** — perturb $x_f$ toward the centre:

$$
\sigma=\operatorname{sign}(x_{1/2}-x_f),\qquad
\delta=\min\bigl\{\kappa_1|b-a|^{\kappa_2},\,|x_{1/2}-x_f|\bigr\},
$$

$$
x_t=x_f+\sigma\delta
\quad\text{(or $x_t=x_{1/2}$ when $\delta>|x_{1/2}-x_f|$).}
$$

**Projection** — clamp into the minmax neighbourhood of the midpoint:

$$
\rho_k=\min\left\{\epsilon\,2^{n_{1/2}+n_0-j}-\frac{b-a}{2},\,
|x_t-x_{1/2}|\right\},
\qquad
x_{\mathrm{ITP}}=x_{1/2}-\sigma\rho_k.
$$

Evaluate $f(x_{\mathrm{ITP}})$ and keep the sub-interval with opposite signs.
Output $\hat x=(a+b)/2$ when $b-a\le 2\epsilon$.

Inline check: a valid start needs $f(a)f(b)<0$ and $a\neq b$.

## API summary

```ada
type Real is digits 15;
type Objective_Fn is access function (X : Real) return Real;

function Sign (X : Real) return Real;
function Bracket_Valid (A, B : Real; F : Objective_Fn) return Boolean;
function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean;
function N_Half (A, B, Eps : Real) return Natural;

function Next_Point
  (A, B, YA, YB : Real;
   Kappa1, Kappa2 : Positive_Real;
   For_Rk : Real) return Real;

type Config is record
   Max_Iterations : Positive      := 100;
   Tol            : Positive_Real := 1.0E-10;
   Kappa1         : Positive_Real := 0.1;
   Kappa2         : Positive_Real := 2.0;
   N0             : Natural       := 1;
end record;

type Status_Kind is
  (Ok, Invalid_Bracket, Max_Iterations_Reached, Degenerate);

type Result is record
   Root, Final_F, Bracket_A, Bracket_B : Real;
   Iterations : Natural;
   Success    : Boolean;
   Status     : Status_Kind;
end record;

function Find_Root
  (F : Objective_Fn; A, B : Real; Cfg : Config := (others => <>))
  return Result;

function Find_Root
  (F : Objective_Fn; A, B : Real;
   Tol : Positive_Real; Max_Iterations : Positive := 100)
  return Result;
```

- **`Bracket_Valid`** — `True` iff $A\neq B$ and $f(A)f(B)<0$.
- **`N_Half`** — Wikipedia $n_{1/2}=\lceil\log_2((b-a)/(2\epsilon))\rceil$.
- **`Next_Point`** — single Interpolate/Truncate/Project query (raises
  `Invalid_Argument` if $y_a=y_b$).
- **`Find_Root`** — full iteration; invalid brackets return
  `Success => False`, `Status => Invalid_Bracket` (no exception).
  A null `Objective_Fn` raises `Invalid_Argument`.
  $\kappa_2\notin[1,1+\phi)$ raises `Invalid_Argument`.

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision, not interval arithmetic.
- Requires a **strict sign-changing bracket**; multiple roots in $[a,b]$
  may yield any one of them.
- One function evaluation per iteration (plus the two endpoint evaluations
  at start).
- Hyper-parameter $\kappa_2$ must lie in $[1,\,1+\phi)$; $\kappa_1>0$;
  $n_0\ge 0$. Defaults $\kappa_1=0.1$, $\kappa_2=2$, $n_0=1$ match the
  Wikipedia worked example (not the R package's $\kappa_1=0.2/(b-a)$).
- Bracket updates keep $a<b$ and use $\operatorname{sign}(f(b))$ so the
  algorithm works when $f(a)>0>f(b)$ as well as the Wikipedia-oriented
  $f(a)<0<f(b)$ case.
- Not a substitute for Brent / TOMS 748 in production libraries, but a
  strong educational / practical alternative with clear worst-case math.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pitp_method.gpr
make test     # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. Zero warnings expected under
`-gnatwa -gnat2022`.

## Layout

Exactly seven root files (no `main.adb`):

| File | Role |
| --- | --- |
| `.gitignore` | Ignores `obj/`, `bin/` |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `itp_method.ads` | Package spec |
| `itp_method.adb` | Package body |
| `itp_method.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- I. F. D. Oliveira and R. H. C. Takahashi, “An Enhancement of the
  Bisection Method Average Performance Preserving Minmax Optimality,”
  *ACM Transactions on Mathematical Software*, 47(1), 2021.
  DOI: 10.1145/3423597.
- [Wikipedia: ITP method](https://en.wikipedia.org/wiki/ITP_method)
- Bisection / regula falsi / Ridders (sibling packages; some forthcoming).
