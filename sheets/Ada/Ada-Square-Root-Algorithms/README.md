# Methods of Computing Square Roots — Ada 2023

Educational, self-contained Ada 2023 package surveying classic **methods of
computing square roots**: Heron's (Babylonian / Newton) iteration, binary
**digit-by-digit** integer floor extraction (with a limited Float digit
sketch), **bisection** on $[0,\max(1,S)]$, and an optional **inverse-sqrt
Newton** Float sketch (no bit hacks). Domain $S\ge 0$; educational
`Long_Float`.

Based on
[Wikipedia: Methods of computing square roots](https://en.wikipedia.org/wiki/Methods_of_computing_square_roots).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (related numeric helpers):

- **[Ada-Nth-Root](https://github.com/RobertBoettcherSF/Ada-Nth-Root)** — Newton / Halley $n$-th roots
- **[Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting)** — product-tree series
- **Alpha max plus beta min** — upcoming
- **Spigot** — upcoming
- **Rounding** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Heron** | $x\leftarrow\frac{1}{2}(x+S/x)$ | Babylonian / Newton for $\sqrt{S}$ |
| **Bisection** | Bisect $x^2-S=0$ on $[0,\max(1,S)]$ | Robust, linear convergence |
| **Digit-by-digit** | Binary bit-by-bit floor $\lfloor\sqrt{N}\rfloor$ | Pencil-and-paper in base 2 |
| **Digit Float** | Scale $S\cdot 10^{2p}$, integer isqrt, $/10^p$ | Educational limited digits |
| **Inv-sqrt Newton** | $x\leftarrow x(\frac{3}{2}-\frac{S}{2}x^2)$, then $Sx$ | Quake-style Float, no bits |
| **Status** | `Converged` / `Bad_Domain` / `Max_Iterations_Reached` | `Bad_Domain` ≡ $S<0$ |
| **Helpers** | `Near`, `Abs_Error`, `Is_Perfect_Square` | Classroom utilities |

## Brief history

Procedures for $\sqrt{2}$ appear by the Old Babylonian period. Hero of
Alexandria (1st century CE) recorded the averaging iteration now called
**Heron's method** — Newton's method on $f(x)=x^2-S$. Digit-by-digit
(Viète and paper-and-pencil schemes) produces each correct digit in turn;
in base 2 the digit search collapses to a bit test and is the classic
integer `isqrt`. When division is costly, Newton on the reciprocal square
root $1/\sqrt{S}$ yields multiplication-only updates popular in graphics
(educational Float form here; hardware “fast invsqrt” bit hacks omitted).

## Algorithm (this package)

**Goal.** For radicand $S\ge 0$, approximate the non-negative square root
$r=\sqrt{S}$ (or $\lfloor\sqrt{N}\rfloor$ for natural $N$).

**Heron.** From a positive guess $x_0$, iterate

$$
x_{k+1}=\frac{1}{2}\left(x_k+\frac{S}{x_k}\right)
$$

until $|x_{k+1}-x_k|$ is below a tolerance (absolute or relative). Special
case: $S=0$ returns $0$ in zero iterations.

**Bisection.** Maintain an interval $[L,H]=[0,\max(1,S)]$ with
$L^2\le S\le H^2$ and repeatedly replace an endpoint by the midpoint until
$H-L\le\mathrm{Tol}$.

**Digit-by-digit (binary).** Starting from the highest power of $4$ not
exceeding $N$, decide each bit of the root by a restoring step — the
Wikipedia integer square-root sketch. `Sqrt_Digit_Float` scales
$S\cdot 10^{2p}$, applies the same floor root, and divides by $10^p$.

**Inverse-sqrt Newton.** For $g(x)=1/x^2-S$,

$$
x\leftarrow x\left(\frac{3}{2}-\frac{S}{2}x^{2}\right),
$$

then $\sqrt{S}\approx S\cdot x$.

**Worked check.** $S=2$: Heron recovers $\sqrt{2}\approx 1.41421356237$.
$S=0.25$ yields $0.5$; perfect squares $k^2$ yield $k$.

## API summary

| Symbol | Role |
| --- | --- |
| `Sqrt_Result` | `(Value, Iterations, Status)` |
| `Status_Kind` | `Converged`, `Bad_Domain` ($S<0$), `Max_Iterations_Reached` |
| `Sqrt_Heron(S,Tol,Max_Iter)` | Heron / Babylonian; never raises |
| `Sqrt_Bisection(S,Tol,Max_Iter)` | Bisection; never raises |
| `Sqrt_Digit_By_Digit(N)` | Integer floor $\lfloor\sqrt{N}\rfloor$ |
| `Sqrt_Digit_Float(S,Num_Digits)` | Limited decimal-digit Float sketch |
| `Sqrt_Inv_Newton(S,Tol,Max_Iter)` | Inverse-sqrt Newton → $\sqrt{S}$ |
| `Sqrt(S)` | Convenience Heron; raises `Invalid_Argument` if not converged |
| `Near`, `Abs_Error` | Numeric helpers |
| `Is_Perfect_Square(N)` | $N=r^{2}$ for some natural $r$ |
| `Invalid_Argument` | Exception from `Sqrt` on failure |

## Limits and caveats

- **Educational `Long_Float`** — double precision; not a multiprecision
  kernel. Tests compare against Ada's elementary `Sqrt` where useful.
- **Domain** — $S<0$ yields `Bad_Domain` / `Invalid_Argument` (no complex
  branch).
- **Digit Float** — `Num_Digits` capped (overflow falls back to Heron);
  truncation error is intentional for the classroom sketch.
- **Inv-sqrt Newton** — needs a reasonable seed; this package seeds from
  $1/\mathrm{Initial\_Guess}(S)$. No IEEE bit-level Quake constant.
- **Bisection** — many more iterations than Heron for the same tolerance;
  pedagogically clear linear convergence.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Psquare_root_algorithms.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `square_root_algorithms.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
square_root_algorithms.ads
square_root_algorithms.adb
square_root_algorithms.gpr
tests.adb
```

## References

1. [Wikipedia: Methods of computing square roots](https://en.wikipedia.org/wiki/Methods_of_computing_square_roots)
2. Hero of Alexandria — *Metrica* (Heron's method).
3. Atkinson, K. E. — An introduction to numerical analysis (Newton for roots).
4. Siblings: [Ada-Nth-Root](https://github.com/RobertBoettcherSF/Ada-Nth-Root),
   [Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting);
   upcoming Alpha max plus beta min, Spigot, Rounding.
