# Ridders' Method — Ada 2023

Educational, self-contained Ada 2023 package implementing **Ridders' method**
— a **bracketed** scalar root finder that combines the **false position**
idea with an **exponential** reweighting so three sample values of
$h(x)=f(x)\,e^{ax}$ are collinear through the midpoint. Due to **C. Ridders**.
Simpler than Muller's or Brent's methods, with similar practical performance:
quadratic convergence in iterates for well-behaved $f$ (overall order about
$\sqrt{2}$ per function evaluation), and a guaranteed bracket that at least
halves each step when $f$ is not well-behaved.

Based on [Wikipedia: Ridders' method](https://en.wikipedia.org/wiki/Ridders%27_method).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (root-finding series):

| Package | Role |
| --- | --- |
| [Ada-False-Position-Method](https://github.com/RobertBoettcherSF/Ada-False-Position-Method) | Regula falsi (forthcoming) |
| [Ada-Bisection-Method](https://github.com/RobertBoettcherSF/Ada-Bisection-Method) | Classic bisection (forthcoming) |
| [Ada-Newtons-Method](https://github.com/RobertBoettcherSF/Ada-Newtons-Method) | Newton–Raphson (forthcoming) |
| [Ada-Ridders-Method](https://github.com/RobertBoettcherSF/Ada-Ridders-Method) | This package |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | False position on $h(x)=f(x)e^{ax}$ | Exponential fit through midpoint |
| **Bracket** | Require $f(a)f(b)<0$ | Guaranteed enclosure |
| **Update** | Wikipedia $x_3$ formula with $\mathrm{sign}$ and $\sqrt{\cdot}$ | Two $f$-evals per iter |
| **Narrow** | Prefer $[x_1,x_3]$; else opposite-sign endpoint | Interval at least halves |
| **Stop** | $\|b-a\|\le\mathrm{Tol}$ or $\|f\|\le\mathrm{Tol}$ | Or max iterations |
| **API** | `Objective_Fn` access-to-function | `Result` with `Status` |
| **Limits** | Educational `Real` (digits 15) | Not a production solver |

## Brief history

**C. Ridders** introduced the method as a simple, robust improvement over
plain false position: an exponential factor makes the three sampled values
of $h$ lie on a straight line, so the false-position step on $h$ is exact
for that transform. The root remains bracketed at every step. When $f$ is
smooth and the root is simple, convergence is quadratic in the iterate
index; because each iteration evaluates $f$ twice, the effective order in
function evaluations is $\sqrt{2}$.

## Method

Given a continuous $f$ and a bracket $[x_0,x_2]$ with

$$
f(x_0)\,f(x_2)<0,
$$

evaluate the midpoint

$$
x_1=\frac{x_0+x_2}{2}.
$$

Choose $a$ so that $h(x)=f(x)e^{ax}$ satisfies
$h(x_1)=(h(x_0)+h(x_2))/2$. Applying false position to
$(x_0,h(x_0))$ and $(x_2,h(x_2))$ yields the Wikipedia update

$$
x_3=x_1+(x_1-x_0)\,
\frac{\operatorname{sign}\bigl[f(x_0)\bigr]\,f(x_1)}
{\sqrt{f(x_1)^{2}-f(x_0)f(x_2)}}.
$$

The next bracket is $[x_1,x_3]$ when $f(x_1)f(x_3)<0$; otherwise the
endpoint among $\{x_0,x_2\}$ whose value has opposite sign to $f(x_3)$
is kept with $x_3$. Iterate until the bracket (or $|f|$ at the candidate)
is within tolerance.

Inline check: a valid start needs $f(a)f(b)<0$ and $a\neq b$.

## API summary

```ada
type Real is digits 15;
type Objective_Fn is access function (X : Real) return Real;

function Sign (X : Real) return Real;
function Bracket_Valid (A, B : Real; F : Objective_Fn) return Boolean;
function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean;

function Next_Point (X0, X2 : Real; F0, F1, F2 : Real) return Real;

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
- **`Next_Point`** — single Wikipedia $x_3$ step (raises `Invalid_Argument`
  on a non-positive discriminant).
- **`Find_Root`** — full iteration; invalid brackets return
  `Success => False`, `Status => Invalid_Bracket` (no exception).
  A null `Objective_Fn` raises `Invalid_Argument`.

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision, not interval arithmetic.
- Requires a **strict sign-changing bracket**; multiple roots in
  $[a,b]$ may yield any one of them.
- Two function evaluations per iteration (midpoint and $x_3$).
- Degenerate samples ($f(x_1)^2-f(x_0)f(x_2)\le 0$) set
  `Status => Degenerate`.
- Not a substitute for Brent / TOMS 748 in production libraries.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pridders_method.gpr
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
| `ridders_method.ads` | Package spec |
| `ridders_method.adb` | Package body |
| `ridders_method.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- C. Ridders, “A new algorithm for computing a single root of an
  equation,” *Computing* / related numerical literature (see Wikipedia).
- [Wikipedia: Ridders' method](https://en.wikipedia.org/wiki/Ridders%27_method)
- False position / regula falsi (sibling package forthcoming).
