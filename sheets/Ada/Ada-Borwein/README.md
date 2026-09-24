# Borwein's algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Borwein's algorithm**,
focusing on the classic **quartic** AGM-style iteration for $1/\pi$
(Jonathan and Peter Borwein, 1985). Implemented in classroom `Long_Float`:
each step roughly **quadruples** the number of correct digits, so double
precision saturates after about $2$–$3$ iterations; the public cap is
$n\le 20$.

Based on
[Wikipedia: Borwein's algorithm](https://en.wikipedia.org/wiki/Borwein's_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Chudnovsky](https://github.com/RobertBoettcherSF/Ada-Chudnovsky)** — Ramanujan–Sato series for $1/\pi$ (~14 digits / term)
- **[Ada-Gauss-Legendre](https://github.com/RobertBoettcherSF/Ada-Gauss-Legendre)** — Brent–Salamin / AGM iteration for $\pi$ (digit-doubling)
- **BBP** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Init** | $y_0=\sqrt{2}-1$, $a_0=6-4\sqrt{2}$ | `Initial_State` ($a_0=2 y_0^2$) |
| **Step** | Quartic $y$, $a$ update | `Iterate` |
| **Estimate** | $a_n\to 1/\pi$, $\pi\approx 1/a_n$ | `Inv_Pi_Estimate` / `Pi_Estimate` |
| **Cap** | $n\le 20$ | `Max_Iterations = 20` |
| **Reference** | `Pi_Constant`, `Inv_Pi_Constant`, `Ada_Pi`, `Elementary_Pi` | Literals + `Ada.Numerics` + $4\arctan 1$ |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | Past cap / non-positive $a$ |

## Brief history

The Borwein brothers developed a family of $\pi$ algorithms in the mid-1980s,
collected in *Pi and the AGM*. Besides Ramanujan–Sato series (related to the
later **Chudnovsky** method), they gave iterative schemes with quadratic,
cubic, **quartic**, quintic, and even nonic convergence. One quartic step is
roughly equivalent to **two** Gauss–Legendre / Brent–Salamin steps. This
package teaches the 1985 quartic recurrence in `Long_Float` only; other
Borwein methods are mentioned below for context.

## Algorithm (this package)

**Primary: quartic convergence (1985).**

**Initialisation.**

$$
y_0=\sqrt{2}-1,\qquad
a_0=6-4\sqrt{2}=2\bigl(\sqrt{2}-1\bigr)^2.
$$

**Iteration** (with current index $n = \mathrm{Iterations}$):

$$
\begin{aligned}
y_{n+1}
&=\frac{1-\bigl(1-y_n^4\bigr)^{1/4}}{1+\bigl(1-y_n^4\bigr)^{1/4}},\\
a_{n+1}
&=a_n\bigl(1+y_{n+1}\bigr)^4
-2^{2n+3}\,y_{n+1}\bigl(1+y_{n+1}+y_{n+1}^2\bigr).
\end{aligned}
$$

**Estimate.**

$$
a_n\to\frac{1}{\pi},\qquad
\pi\approx\frac{1}{a_n}.
$$

Fourth roots are evaluated as $\sqrt{\sqrt{\cdot}}$ via
`Ada.Numerics.Long_Elementary_Functions.Sqrt`.

**Convergence.** Correct decimal digits roughly **quadruple** each
iteration. In IEEE `Long_Float` the absolute error typically falls below
$10^{-8}$ after one step and below $10^{-15}$ by $n=2$. Further steps leave
the estimate unchanged within rounding noise — hence the educational cap
$n\le 20$. The algorithm is **not** self-correcting: each step must be
carried at the working precision of the final result (irrelevant at
`Long_Float` scale).

**Worked check.** After zero steps $\pi_0\approx 2.914213$; after one
$\pi_1\approx 3.141592646$; by $n=2$ the value matches `Pi_Constant` /
`Ada.Numerics.Pi` / $4\arctan(1)$ to machine precision.

## Other Borwein methods (not implemented)

Wikipedia also lists (among others):

- **Quadratic** (1984) — digit-doubling AGM-style iteration for $\pi$
  (closely related to Gauss–Legendre).
- **Cubic / quintic / nonic** — higher-order iterative schemes for $1/\pi$.
- **Ramanujan–Sato series** — class-number forms summing to $1/\pi$
  (each term adds many digits; related educationally to
  [Ada-Chudnovsky](https://github.com/RobertBoettcherSF/Ada-Chudnovsky)).

This package implements **one primary** algorithm (the quartic) solidly.

## API summary

| Symbol | Role |
| --- | --- |
| `Initial_State` | $y_0,a_0$ with `Iterations = 0` |
| `Iterate(S)` | One quartic Borwein step |
| `Inv_Pi_Estimate(S)` | $a$ from a state ($\to 1/\pi$) |
| `Pi_Estimate(S)` | $1/a$ from a state |
| `Approximate_Pi(Iterations)` | Run $n$ steps; return $\pi$ estimate |
| `Approximate_Pi(..., Final, Estimate)` | Same, also returns final `State` |
| `Approximate_Inv_Pi(Iterations)` | Run $n$ steps; return $a_n\approx 1/\pi$ |
| `Approximate_Inv_Pi(..., Final, Estimate)` | Same, also returns final `State` |
| `Pi_Constant` | Reference $\pi$ literal (`Long_Float`) |
| `Inv_Pi_Constant` | Reference $1/\pi$ literal |
| `Ada_Pi` | `Long_Float (Ada.Numerics.Pi)` |
| `Elementary_Pi` | $4\arctan(1)$ via `Long_Elementary_Functions` |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Iteration_Count` | Subtype $0..20$ |
| `State` | Record fields $Y,A$, `Iterations` |
| `Invalid_Argument` | Cap / non-positive $a$ |

## Limits and caveats

- **Educational `Long_Float`** — not a multiprecision $\pi$ engine; square /
  fourth roots use `Ada.Numerics.Long_Elementary_Functions.Sqrt`.
- **Cap** — `Max_Iterations = 20`; useful new digits stop by $n\approx 2$.
- **Quartic invariants** — after each step $a>0$, $0\le y<1$, and $y$
  decreases toward $0$ in exact arithmetic.
- **Not** Chudnovsky series, Gauss–Legendre AGM, BBP digit-extraction, or
  another Borwein order (see siblings / above).
- **Power** — $2^{2n+3}$ is formed by successive doubling in `Long_Float`
  (safe for $n\le 20$).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pborwein.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `borwein.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
borwein.ads
borwein.adb
borwein.gpr
tests.adb
```

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
