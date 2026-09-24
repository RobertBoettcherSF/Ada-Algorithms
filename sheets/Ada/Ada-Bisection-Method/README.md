# Bisection Method — Ada 2023

Educational, self-contained Ada 2023 package implementing the classic
**bisection method** (**interval halving**, **binary search method**,
**dichotomy**) — a **bracketed** scalar root finder that repeatedly replaces
$[a,b]$ by the half-interval that still contains a sign change of continuous
$f$. It is **robust** and **simple**, with guaranteed **linear** convergence,
but relatively **slow**; often used to seed faster methods.

Based on [Wikipedia: Bisection method](https://en.wikipedia.org/wiki/Bisection_method).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (root-finding series):

| Package | Role |
| --- | --- |
| [Ada-Bisection-Method](https://github.com/RobertBoettcherSF/Ada-Bisection-Method) | This package |
| [Ada-False-Position-Method](https://github.com/RobertBoettcherSF/Ada-False-Position-Method) | Regula falsi / Illinois |
| [Ada-Ridders-Method](https://github.com/RobertBoettcherSF/Ada-Ridders-Method) | Ridders' exponential false-position hybrid |
| [Ada-ITP-Method](https://github.com/RobertBoettcherSF/Ada-ITP-Method) | Interpolate Truncate Project |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Interval halving on bracket | Midpoint query each step |
| **Bracket** | Require $f(a)f(b)<0$ | IVT guarantees a root |
| **Update** | $c=(a+b)/2$ | Keep half with sign change |
| **Stop** | $(b-a)/2<\mathrm{Tol}$ or $\|f(c)\|<\mathrm{Tol}$ | Or max iterations |
| **Estimate** | $\lceil\log_2((b-a)/\mathrm{Tol})\rceil$ | `Iterations_Needed` |
| **API** | `Objective_Fn` access-to-function | `Result` with `Status` + bracket |
| **Limits** | Educational `Real` (digits 15) | Not a production solver |

## Brief history

Bisection is among the oldest and most transparent **bracketing** algorithms:
given continuous $f$ with opposite signs at the ends of $[a,b]$, the
intermediate value theorem guarantees at least one root in $(a,b)$. Each step
evaluates $f$ at the midpoint and retains the subinterval that still changes
sign. The method is also called **interval halving**, the **binary search
method**, or the **dichotomy method**.

Because the bracket width halves every iteration, the absolute error shrinks
by a factor of $1/2$ each step — **linear** convergence with rate $1/2$. That
guarantee makes bisection a reliable starter for faster hybrids (false
position, Ridders, ITP, Brent).

## Method

Given continuous $f$ and a bracket $[a,b]$ with

$$
f(a)\,f(b)<0,
$$

compute the midpoint

$$
c=\frac{a+b}{2}.
$$

If $f(c)=0$ (or $|f(c)|$ is within tolerance), stop. Otherwise, if
$f(a)f(c)<0$, replace $b\leftarrow c$; else replace $a\leftarrow c$. Iterate
until

$$
\frac{b-a}{2}<\mathrm{Tol}
\quad\text{or}\quad
|f(c)|<\mathrm{Tol},
$$

or until a maximum iteration count is reached.

A useful a priori estimate of the number of halvings needed to drive the
bracket width below $\mathrm{Tol}$ is

$$
n=\left\lceil\log_2\frac{b-a}{\mathrm{Tol}}\right\rceil,
$$

exposed here as `Iterations_Needed`.

Inline check: a valid start needs $f(a)f(b)<0$ and $a\neq b$.

## API summary

```ada
type Real is digits 15;
type Objective_Fn is access function (X : Real) return Real;

function Sign (X : Real) return Real;
function Bracket_Valid (A, B : Real; F : Objective_Fn) return Boolean;
function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean;
function Iterations_Needed (A, B : Real; Tol : Positive_Real) return Natural;

function Next_Point (A, B : Real) return Real;

type Config is record
   Max_Iterations : Positive      := 100;
   Tol            : Positive_Real := 1.0E-10;
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
- **`Next_Point`** — single midpoint $c=(A+B)/2$.
- **`Iterations_Needed`** — $\lceil\log_2((B-A)/\mathrm{Tol})\rceil$ (0 when
  already within width).
- **`Find_Root`** — full iteration; invalid brackets return
  `Success => False`, `Status => Invalid_Bracket` (no exception).
  A null `Objective_Fn` raises `Invalid_Argument`.

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision, not interval arithmetic.
- Requires a **strict sign-changing bracket**; multiple roots in
  $[a,b]$ may yield any one of them (the half retained first).
- **Linear** convergence only: roughly one correct bit per iteration.
  Prefer Ridders / ITP / Brent when speed matters.
- Stopping on $|f|<\mathrm{Tol}$ can succeed while the final bracket is still
  relatively wide if $f$ is flat near the root; inspect `Bracket_A` /
  `Bracket_B`.
- Not a substitute for Brent / TOMS 748 in production libraries.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pbisection_method.gpr
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
| `bisection_method.ads` | Package spec |
| `bisection_method.adb` | Package body |
| `bisection_method.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Bisection method](https://en.wikipedia.org/wiki/Bisection_method)
- Burden, R. L.; Faires, J. D. (2016). *Numerical Analysis*, §2.1 The
  Bisection Algorithm.
- Sibling packages: False Position, Ridders, ITP.
