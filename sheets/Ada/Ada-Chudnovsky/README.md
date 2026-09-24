# Chudnovsky algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Chudnovsky
algorithm**, a rapidly convergent Ramanujan–Sato series for $1/\pi$
(published by the Chudnovsky brothers in 1988). Implemented in classroom
`Long_Float`: each term adds roughly **14** correct decimal digits, so
double precision saturates after about $1$–$2$ terms; the public cap is
$\mathrm{Terms}\le 8$.

Based on
[Wikipedia: Chudnovsky algorithm](https://en.wikipedia.org/wiki/Chudnovsky_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Gauss-Legendre](https://github.com/RobertBoettcherSF/Ada-Gauss-Legendre)** — Brent–Salamin / AGM iteration for $\pi$
- **[Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting)** — recursive integer $(P,Q)$ products (production Chudnovsky uses this)
- **[Ada-Spigot-Algorithm](https://github.com/RobertBoettcherSF/Ada-Spigot-Algorithm)** — digit-by-digit $e$ / $\pi$ spigots
- **Borwein** — upcoming
- **BBP** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Series** | Chudnovsky $1/\pi$ (Wikipedia form) | ~14 digits / term |
| **Recurrence** | Term ratio $t_{k+1}/t_k$ | Avoids huge $(6k)!$ intermediates |
| **Estimate** | $\pi \approx (426880\sqrt{10005})/S$ | `Approximate_Pi` / `Pi_From_Sum` |
| **Cap** | $1\le\mathrm{Terms}\le 8$ | `Max_Terms = 8` |
| **Reference** | `Pi_Constant`, `Ada_Pi`, `Elementary_Pi` | Literals + `Ada.Numerics` + $4\arctan 1$ |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | Bad $K$/Terms / non-positive sum |
| **Production** | Big-int + binary splitting | See Ada-Binary-Splitting |

## Brief history

The Chudnovsky brothers derived a hypergeometric series related to the
negated Heegner number $d=-163$ and $j\bigl((1+i\sqrt{163})/2\bigr)=-640320^3$.
The method is in the family of Ramanujan–Sato series and became the
workhorse for $\pi$ digit records (trillions of digits via y-cruncher and
related software). Extreme-precision evaluation uses **binary splitting**
over big integers — this package teaches only the floating educational
form with a few terms.

## Algorithm (this package)

**Wikipedia series** (equivalent forms).

$$
\frac{1}{\pi}
= 12\sum_{k=0}^{\infty}
\frac{(-1)^k(6k)!(545140134\,k+13591409)}{(3k)!(k!)^3(640320)^{3k+3/2}}.
$$

Equivalently (constant factored out of the sum):

$$
\frac{1}{\pi}
=\frac{\sqrt{10005}}{4270934400}
\sum_{k=0}^{\infty}
\frac{(-1)^k(6k)!(545140134\,k+13591409)}{(3k)!(k!)^3(640320)^{3k}}.
$$

**Practical rearranged form** used here. With
$A=13591409$, $B=545140134$, $C=640320$, and

$$
t_k=\frac{(-1)^k(6k)!(A+Bk)}{(3k)!(k!)^3 C^{3k}},
\qquad
S_N=\sum_{k=0}^{N-1}t_k,
$$

$$
\pi\approx\frac{426880\sqrt{10005}}{S_N}.
$$

(Note $426880\cdot 10005=4270934400$, so the two Wikipedia layouts agree.)

**Term-ratio recurrence** (preferred for `Long_Float` stability). Starting
from $t_0=A$:

$$
\frac{t_{k+1}}{t_k}
=
\frac{(6k+1)\cdots(6k+6)}{(3k+1)(3k+2)(3k+3)\,(k+1)^3\,(-C^3)}
\cdot
\frac{A+B(k+1)}{A+Bk}.
$$

No standalone $(6k)!$ is formed; each step multiplies by a moderate
`Long_Float` factor. $C^3=262537412640768000$.

**Convergence.** About **14** correct decimals per term. With $N=1$
($k=0$ alone) the absolute error is already $\lesssim 10^{-13}$; by
$N=2$ IEEE `Long_Float` is saturated. Further terms leave the estimate
unchanged within rounding noise — hence the educational cap $N\le 8$.

**Worked check.** $t_0=13591409$,
$\pi_1=(426880\sqrt{10005})/t_0\approx 3.141592653589734$; with a second
term the value matches `Pi_Constant` / `Ada.Numerics.Pi` /
$4\arctan(1)$ to machine precision.

## API summary

| Symbol | Role |
| --- | --- |
| `Approximate_Pi(Terms)` | $\pi$ from first $\mathrm{Terms}$ series terms |
| `Approximate_Pi(..., Estimate, Sum)` | Same, also returns partial sum $S$ |
| `Series_Term(K)` | Term $t_K$ via successive ratios from $t_0$ |
| `Term_Ratio(K)` | Factor $t_{K+1}/t_K$ |
| `Series_Sum(Terms)` | $S=\sum_{k=0}^{\mathrm{Terms}-1}t_k$ |
| `Pi_From_Sum(Sum)` | $426880\sqrt{10005}/\mathrm{Sum}$ |
| `Pi_Numerator` | $426880\sqrt{10005}$ |
| `Pi_Constant` | Reference $\pi$ literal (`Long_Float`) |
| `Ada_Pi` | `Long_Float (Ada.Numerics.Pi)` |
| `Elementary_Pi` | $4\arctan(1)$ via `Long_Elementary_Functions` |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `A_Const`, `B_Const`, `C_Const`, `C3_Const` | Series constants |
| `Term_Count` | Subtype $1..8$ |
| `Invalid_Argument` | Bad index / Terms / non-positive sum |

## Limits and caveats

- **Educational `Long_Float`** — not a multiprecision $\pi$ engine; square
  roots use `Ada.Numerics.Long_Elementary_Functions.Sqrt`.
- **Cap** — `Max_Terms = 8`; useful new digits stop after $1$–$2$ terms.
- **Factorials** — never computed directly; use `Term_Ratio` recurrence.
- **Production** — world-record Chudnovsky runs use big integers and
  **binary splitting** (see
  [Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting)).
- **Not** Gauss–Legendre / AGM, Borwein quartic, BBP digit-extraction, or
  a spigot (see siblings / upcoming).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pchudnovsky.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `chudnovsky.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
chudnovsky.ads
chudnovsky.adb
chudnovsky.gpr
tests.adb
```

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
