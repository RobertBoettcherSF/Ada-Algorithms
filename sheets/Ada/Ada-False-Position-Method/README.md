# False Position Method (Regula Falsi) — Ada 2023

Educational, self-contained Ada 2023 package implementing the **false position**
method (**regula falsi**) — a **bracketed** scalar root finder that replaces
$f$ on $[a,b]$ by the secant through $(a,f(a))$ and $(b,f(b))$ and takes the
$x$-intercept as the next estimate. An optional **Illinois** flag halves the
retained endpoint's $f$ value when the same endpoint is kept repeatedly,
mitigating the classic stalling mode.

Based on [Wikipedia: Regula falsi](https://en.wikipedia.org/wiki/Regula_falsi).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (root-finding series):

| Package | Role |
| --- | --- |
| [Ada-False-Position-Method](https://github.com/RobertBoettcherSF/Ada-False-Position-Method) | This package |
| [Ada-Bisection-Method](https://github.com/RobertBoettcherSF/Ada-Bisection-Method) | Classic bisection (forthcoming) |
| [Ada-Ridders-Method](https://github.com/RobertBoettcherSF/Ada-Ridders-Method) | Ridders' exponential false-position hybrid |
| [Ada-ITP-Method](https://github.com/RobertBoettcherSF/Ada-ITP-Method) | Interpolate Truncate Project |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Linear interpolation on bracket | Classical double false position |
| **Bracket** | Require $f(a)f(b)<0$ | Guaranteed enclosure |
| **Update** | $c=(a f(b)-b f(a))/(f(b)-f(a))$ | One $f$-eval per iter |
| **Illinois** | Halve retained endpoint's $f$ | Optional `Config.Illinois` |
| **Stop** | $\|b-a\|\le\mathrm{Tol}$ or $\|f\|\le\mathrm{Tol}$ | Or max iterations |
| **API** | `Objective_Fn` access-to-function | `Result` with `Status` + bracket |
| **Limits** | Educational `Real` (digits 15) | Not a production solver |

## Brief history

**False position** is among the oldest numerical recipes: **simple** false
position (proportional correction of one guess) appears in Egyptian and
Babylonian sources; **double** false position — mathematically equivalent to
linear interpolation from two trial points — is developed in the Chinese
*Nine Chapters*, medieval Arabic *ḥisāb al-khaṭāʾayn*, and later European
practical arithmetic.

In modern numerical analysis the same chord formula becomes an **iterative
bracketing** root finder: given a continuous $f$ with a sign change on
$[a,b]$, replace one endpoint so the sign change is preserved. Convergence is
usually faster than bisection, but when $f''$ keeps constant sign one endpoint
can stick and the bracket width may stop shrinking — the failure mode that
**Illinois** (and Anderson–Björck) address by down-weighting the retained
endpoint.

## Method

Given continuous $f$ and a bracket $[a,b]$ with

$$
f(a)\,f(b)<0,
$$

the classic regula falsi estimate is

$$
c=\frac{a\,f(b)-b\,f(a)}{f(b)-f(a)}.
$$

If $f(a)f(c)<0$, replace $b\leftarrow c$; otherwise replace $a\leftarrow c$.
Iterate until the bracket or $|f(c)|$ is within tolerance.

**Illinois variant.** When the same endpoint is retained twice in a row,
halve that endpoint's $f$ value in the next interpolation (e.g. if $b$ is
kept again, use $\tfrac12 f(b)$ in place of $f(b)$). This pushes $c$ toward
the stuck side and restores superlinear behaviour at negligible cost.

Inline check: a valid start needs $f(a)f(b)<0$ and $a\neq b$.

## API summary

```ada
type Real is digits 15;
type Objective_Fn is access function (X : Real) return Real;

function Sign (X : Real) return Real;
function Bracket_Valid (A, B : Real; F : Objective_Fn) return Boolean;
function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean;

function Next_Point (A, B, FA, FB : Real) return Real;

type Config is record
   Max_Iterations : Positive      := 100;
   Tol            : Positive_Real := 1.0E-10;
   Illinois       : Boolean       := False;
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
- **`Sign`** — classical $-1,0,+1$.
- **`Next_Point`** — single classic $c$ step (raises `Invalid_Argument` on a
  zero denominator).
- **`Find_Root`** — full iteration; invalid brackets return
  `Success => False`, `Status => Invalid_Bracket` (no exception).
  A null `Objective_Fn` raises `Invalid_Argument`.
  Set `Cfg.Illinois => True` for the Illinois variant.

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision, not interval arithmetic.
- Requires a **strict sign-changing bracket**; multiple roots in
  $[a,b]$ may yield any one of them.
- Classic regula falsi may **stall** (one endpoint fixed, bracket width
  bounded away from zero) when $f''$ has constant sign; prefer Illinois
  (or Ridders / ITP / Brent) for production robustness.
- Stopping on $|f|\le\mathrm{Tol}$ can succeed while the final bracket is
  still wide (classic stall mode); inspect `Bracket_A` / `Bracket_B`.
- Not a substitute for Brent / TOMS 748 in production libraries.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pfalse_position_method.gpr
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
| `false_position_method.ads` | Package spec |
| `false_position_method.adb` | Package body |
| `false_position_method.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Regula falsi](https://en.wikipedia.org/wiki/Regula_falsi)
- Ford, J. A. (1995). Improved algorithms of Illinois-type for the numerical
  solution of nonlinear equations (see Wikipedia).
- Sibling packages: Ridders, ITP, bisection (forthcoming).
