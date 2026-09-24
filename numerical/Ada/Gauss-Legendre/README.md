# Gauss–Legendre algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Gauss–Legendre
algorithm** (also called **Brent–Salamin** / **Gauss–Euler**), an
arithmetic–geometric mean (AGM) iteration that approximates $\pi$ with
roughly **digit-doubling** convergence. Implemented in classroom
`Long_Float`: after about $5$–$6$ steps double precision is saturated, so
the public cap is $n\le 20$.

Based on
[Wikipedia: Gauss–Legendre algorithm](https://en.wikipedia.org/wiki/Gauss–Legendre_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Division-Algorithms](https://github.com/RobertBoettcherSF/Ada-Division-Algorithms)** — restoring / non-restoring / SRT / Goldschmidt / Newton–Raphson survey
- **[Ada-Spigot-Algorithm](https://github.com/RobertBoettcherSF/Ada-Spigot-Algorithm)** — digit-by-digit $e$ / $\pi$ spigots
- **Chudnovsky** — upcoming
- **Borwein** — upcoming
- **BBP** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Init** | $a_0=1$, $b_0=1/\sqrt{2}$, $t_0=1/4$, $p_0=1$ | `Initial_State` |
| **Step** | AM / GM + $t$, $p$ update | `Iterate` |
| **Estimate** | $(a+b)^2/(4t)$ | `Pi_Estimate` / `Approximate_Pi` |
| **Cap** | $n\le 20$ | `Max_Iterations = 20` |
| **Reference** | `Pi_Constant`, `Ada_Pi`, `Elementary_Pi` | Literals + `Ada.Numerics` + $4\arctan 1$ |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | Past cap / non-positive $t$ |

## Brief history

Gauss studied the AGM of $1$ and $\sqrt{2}$ in connection with elliptic
integrals; Legendre related related integrals to $\pi$. In 1975
**Eugene Salamin** and **Richard Brent** independently turned the AGM into
a practical $\pi$ algorithm with quadratic convergence. The method was used
for record computations (for example hundreds of billions of digits in the
late 1990s) before series methods such as **Chudnovsky** became dominant
for extreme precision. This package teaches the classical Brent–Salamin
recurrence in `Long_Float` only.

## Algorithm (this package)

**Initialisation.**

$$
a_0=1,\qquad
b_0=\frac{1}{\sqrt{2}},\qquad
t_0=\frac{1}{4},\qquad
p_0=1.
$$

**Iteration.**

$$
\begin{aligned}
a_{n+1}&=\frac{a_n+b_n}{2},\\
b_{n+1}&=\sqrt{a_n b_n},\\
t_{n+1}&=t_n-p_n(a_n-a_{n+1})^2,\\
p_{n+1}&=2 p_n.
\end{aligned}
$$

**Estimate.**

$$
\pi \approx \frac{(a_{n+1}+b_{n+1})^2}{4 t_{n+1}}.
$$

(Equivalently evaluate $(a+b)^2/(4t)$ on the state after $n$ steps,
including $n=0$.)

**Convergence.** Correct decimal digits roughly **double** each
iteration ($\approx 1,3,8,19,\ldots$). In IEEE `Long_Float` the absolute
error typically falls below $10^{-15}$ by $n\approx 5$. Further steps
leave the estimate unchanged within rounding noise — hence the educational
cap $n\le 20$.

**Worked check.** After one step $\pi_1\approx 3.140579$; after two
$\pi_2\approx 3.141592646$; by $n=5$ the value matches `Pi_Constant` /
`Ada.Numerics.Pi` / $4\arctan(1)$ to machine precision.

## API summary

| Symbol | Role |
| --- | --- |
| `Initial_State` | $a_0,b_0,t_0,p_0$ with `Iterations = 0` |
| `Iterate(S)` | One AGM / Brent–Salamin step |
| `Pi_Estimate(S)` | $(a+b)^2/(4t)$ from a state |
| `Approximate_Pi(Iterations)` | Run $n$ steps; return $\pi$ estimate |
| `Approximate_Pi(..., Final, Estimate)` | Same, also returns final `State` |
| `Pi_Constant` | Reference $\pi$ literal (`Long_Float`) |
| `Ada_Pi` | `Long_Float (Ada.Numerics.Pi)` |
| `Elementary_Pi` | $4\arctan(1)$ via `Long_Elementary_Functions` |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Iteration_Count` | Subtype $0..20$ |
| `State` | Record fields $A,B,T,P$, `Iterations` |
| `Invalid_Argument` | Cap / non-positive $t$ |

## Limits and caveats

- **Educational `Long_Float`** — not a multiprecision $\pi$ engine; square
  roots use `Ada.Numerics.Long_Elementary_Functions.Sqrt`.
- **Cap** — `Max_Iterations = 20`; useful new digits stop much earlier.
- **AGM invariants** — after each step $a\ge b\ge 0$, $t>0$, and
  $p=2^n$; the gap $a-b$ shrinks monotonically in exact arithmetic.
- **Not** Chudnovsky, Borwein quartic, BBP digit-extraction, or a
  binary-splitting series package (see siblings / upcoming).
- **Memory** — the classical AGM $\pi$ algorithms are memory-heavy at
  extreme precision; irrelevant at `Long_Float` scale.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pgauss_legendre.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `gauss_legendre.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
gauss_legendre.ads
gauss_legendre.adb
gauss_legendre.gpr
tests.adb
```

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
