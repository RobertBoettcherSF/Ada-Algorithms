# Goldschmidt Division — Ada 2023

Educational, self-contained Ada 2023 package for **Goldschmidt division** —
a *fast division* method that iteratively multiplies both the dividend $N$
and the divisor $D$ by common factors $F_i$ so that $D$ converges to $1$ and
$N$ converges to the quotient $Q$:

$$
Q=\frac{N}{D}\frac{F_{1}}{F_{1}}\frac{F_{2}}{F_{2}}\frac{F_{\ldots}}{F_{\ldots}}.
$$

A common choice (after normalizing $D$ near $1$) is the same algebraic step
used in Newton reciprocal iteration:

$$
F_{i}=2-D_{i},\qquad N\leftarrow N F_{i},\qquad D\leftarrow D F_{i}.
$$

Based on
[Wikipedia: Goldschmidt division](https://en.wikipedia.org/wiki/Goldschmidt_division)
(redirects to Division algorithm) and
[Wikipedia: Division algorithm — Goldschmidt division](https://en.wikipedia.org/wiki/Division_algorithm#Goldschmidt_division).

Educational `Long_Float` core: normalize, iterate until $|D-1|$ is small,
return the scaled numerator. Contrast with **Newton–Raphson division**: NR
finds a reciprocal $X\approx 1/D$ then forms $Q=N\cdot X$ once; Goldschmidt
scales **both** $N$ and $D$ each step (the two multiplies can run in
parallel in hardware). This package does **not** `with` the sibling NR
package.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Long-Division](https://github.com/RobertBoettcherSF/Ada-Long-Division)** — pencil-and-paper decimal long division
- **[Ada-Newton-Raphson-Division](https://github.com/RobertBoettcherSF/Ada-Newton-Raphson-Division)** — reciprocal Newton, then $Q=N\cdot X$
- **[Ada-Non-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Non-Restoring-Division)** — radix-$2$ non-restoring, digits $\{-1,1\}$
- **[Ada-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Restoring-Division)** — radix-$2$ restoring, digits $\{0,1\}$
- **[Ada-SRT-Division](https://github.com/RobertBoettcherSF/Ada-SRT-Division)** — radix-$2$ SRT, redundant digits $\{-1,0,1\}$
- **Division algorithms survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Normalize** | Dyadic scale $\|D\|$ into $(\tfrac12,1]$ | Same scale applied to $\|N\|$; sign restored later |
| **Factor** | $F_i=2-D_i$ | Same algebra as Newton reciprocal step |
| **Update** | $N\leftarrow NF_i$, $D\leftarrow DF_i$ | Parallel-friendly multiplies |
| **Stop** | $\|D-1\|\le$ Tol | Quotient is signed scaled $N$ |
| **Convergence** | $\varepsilon_{i+1}=\varepsilon_i^{2}$ | With $\varepsilon=1-D$; digits roughly **double** |
| **Oracle** | `Exact_Quotient` | `Long_Float` `/` |
| **Invalid** | `Invalid_Argument` / `Bad_Domain` | $D=0$ |

## Brief history

Slow division (restoring, non-restoring, SRT) produces about one quotient
digit per iteration. Fast multiplicative methods — Newton–Raphson and
Goldschmidt (after Robert Elliott Goldschmidt) — refine an estimate with
multiplications that map onto hardware multipliers. Goldschmidt repeatedly
scales the fraction $N/D$ so the denominator tends to $1$. It converges at
the same quadratic rate as NR reciprocal iteration, but keeps independent
numerator and denominator multiplies that can be issued in parallel. The
method appears in AMD Athlon-class FPUs and related Anderson–Earle–
Goldschmidt–Powers (AEGP) forms in IBM processors.

## Algorithm (this package)

**Goal.** Given dividend $N$ and nonzero divisor $D$, compute $Q=N/D$.

**Step 1 — normalize.** Work with magnitudes and remember the quotient
sign. Scale by a power of two so

$$
|D|\in\bigl(\tfrac12,1\bigr],
$$

applying the **same** dyadic factor to $|N|$. After this step the ratio
$N/D$ is unchanged.

**Step 2 — iterate Goldschmidt factors.** While $|D-1|$ exceeds the
tolerance, set

$$
F=2-D,\qquad N\leftarrow N F,\qquad D\leftarrow D F.
$$

If $\varepsilon=1-D$, then $F=1+\varepsilon$ and

$$
D_{\mathrm{new}}=D(1+\varepsilon)=(1-\varepsilon)(1+\varepsilon)=1-\varepsilon^{2},
$$

so the residual satisfies $\varepsilon_{\mathrm{new}}=\varepsilon^{2}$
(quadratic convergence / digit doubling) when $D\in(0,1]$.

**Step 3 — read the quotient.** After $k$ successful iterations,
$D_k\approx 1$ and the scaled numerator (with restored sign) is $Q$:

$$
Q=\mathrm{sign}(N/D)\cdot N_k.
$$

**Contrast with Newton–Raphson.** NR iterates only on a reciprocal
$X\leftarrow X(2-DX)$ and finishes with one multiply $Q=N\cdot X$.
Goldschmidt applies $F_i=2-D_i$ to **both** streams; algebraically related,
presentation and parallelism differ.

**Worked check.** $N=15$, $D=3$: after normalize $D=0.75$, $N=3.75$;
factors drive $D\to 1$ and $N\to 5$.

## API summary

| Symbol | Role |
| --- | --- |
| `Division_Result` | `(Quotient, Final_Denom, Iterations, Status)` |
| `Status_Kind` | `Converged`, `Bad_Domain` ($D=0$), `Max_Iterations_Reached` |
| `Divide_Goldschmidt_Detail(N,D,...)` | Full record; never raises |
| `Divide_Goldschmidt(N,D)` | Float quotient; raises `Invalid_Argument` if not converged |
| `Exact_Quotient(N,D)` | Oracle `Long_Float` `/` |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Invalid_Argument` | Exception on $D=0$ / failed convenience calls |

## Limits and caveats

- **Educational `Long_Float`** — double precision; not a multiprecision
  kernel or IEEE correctly-rounded division replacement.
- **Domain** — $D=0$ yields `Bad_Domain` / `Invalid_Argument`.
- **Normalization** — dyadic scaling into $(\tfrac12,1]$ is ample for
  typical classroom magnitudes; subnormals / overflow extremes are out of
  scope.
- **Digit doubling** — quadratic only after a good scaled seed; the
  documented normalize step keeps residuals well behaved.
- **Related NR package** — sibling presentation only; no `with`.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pgoldschmidt_division.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `goldschmidt_division.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
goldschmidt_division.ads
goldschmidt_division.adb
goldschmidt_division.gpr
tests.adb
```

## References

1. [Wikipedia: Goldschmidt division](https://en.wikipedia.org/wiki/Goldschmidt_division)
2. [Wikipedia: Division algorithm — Goldschmidt division](https://en.wikipedia.org/wiki/Division_algorithm#Goldschmidt_division)
3. [Wikipedia: Division algorithm — Newton–Raphson division](https://en.wikipedia.org/wiki/Division_algorithm#Newton%E2%80%93Raphson_division)
