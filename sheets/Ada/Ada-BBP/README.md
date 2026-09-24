# Bailey–Borwein–Plouffe formula — Ada 2023

Educational, self-contained Ada 2023 package for the **Bailey–Borwein–Plouffe
(BBP) formula**, a base-$16$ series for $\pi$ discovered by Simon Plouffe in
1995 and published with David H. Bailey and Peter Borwein. Implemented in
classroom `Long_Float`: each term shrinks by about $1/16$ ($\approx 4$ bits),
so double precision saturates by roughly $10$–$15$ terms; the public cap is
$\mathrm{Terms}\le 40$. An optional educational sketch extracts the $N$-th
hexadecimal digit of $\pi$ after the radix point via modular exponentiation
and fractional parts (classic BBP digit extraction), capped at
$N\le 12$ for `Long_Float` reliability.

Based on
[Wikipedia: Bailey–Borwein–Plouffe formula](https://en.wikipedia.org/wiki/Bailey–Borwein–Plouffe_formula).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Borwein](https://github.com/RobertBoettcherSF/Ada-Borwein)** — quartic AGM-style iteration for $1/\pi$
- **[Ada-Chudnovsky](https://github.com/RobertBoettcherSF/Ada-Chudnovsky)** — Ramanujan–Sato series for $1/\pi$ (~14 digits / term)
- **[Ada-Gauss-Legendre](https://github.com/RobertBoettcherSF/Ada-Gauss-Legendre)** — Brent–Salamin / AGM iteration for $\pi$
- **Computation of π** — upcoming survey package

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Series** | Classic BBP $\pi$ sum (Wikipedia) | ~4 bits / term |
| **Estimate** | Partial sum $S_N=\sum_{k=0}^{N-1}t_k$ | `Approximate_Pi` / `Series_Sum` |
| **Cap** | $1\le\mathrm{Terms}\le 40$ | `Max_Terms = 40` |
| **Hex digit** | Modular / fractional BBP extract | `Hex_Digit_Of_Pi` ($N\le 12$) |
| **Reference** | `Pi_Constant`, `Ada_Pi`, `Elementary_Pi` | Literals + `Ada.Numerics` + $4\arctan 1$ |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | Bad $K$/Terms / hex index |

## Brief history

Plouffe found the series experimentally (PSLQ) in 1995; Bailey, Borwein, and
Plouffe published it soon after. The striking feature is a **spigot** /
digit-extraction algorithm: the $n$-th hexadecimal (hence binary) digit of
$\pi$ can be computed without the preceding digits, using modular
exponentiation. Projects such as PiHex used BBP-type methods in distributed
computing. This package teaches the floating partial-sum form plus a small
educational hex-digit sketch — not a production multiprecision spigot.

## Algorithm (this package)

**Classic BBP series.**

$$
\pi
=\sum_{k=0}^{\infty}
\frac{1}{16^k}
\left(
\frac{4}{8k+1}-\frac{2}{8k+4}-\frac{1}{8k+5}-\frac{1}{8k+6}
\right).
$$

With

$$
t_k=\frac{1}{16^k}\left(
\frac{4}{8k+1}-\frac{2}{8k+4}-\frac{1}{8k+5}-\frac{1}{8k+6}
\right),
\qquad
S_N=\sum_{k=0}^{N-1}t_k,
$$

$$
\pi\approx S_N.
$$

`Term_Parenthesis(K)` evaluates the parenthesis alone;
`Series_Term(K)` multiplies by $16^{-K}$; `Series_Sum` / `Approximate_Pi`
accumulate the partial sum in `Long_Float` by successive division by $16$
(no large $16^k$ intermediates).

**Convergence.** About **4** correct bits ($\approx 1.2$ decimal digits) per
term. With $N=1$ ($k=0$ alone) $\pi_1\approx 3.133$; by $N\approx 12$ the
absolute error is $\lesssim 10^{-12}$; by $N\approx 20$ IEEE `Long_Float` is
saturated. Further terms leave the estimate unchanged within rounding noise —
hence the educational cap $N\le 40$.

**Worked check.** $t_0=4-1/2-1/5-1/6\approx 3.133333$; with twelve terms the
value matches `Pi_Constant` / `Ada.Numerics.Pi` / $4\arctan(1)$ to about
$12$ decimals; twenty terms match to machine precision.

### Hex-digit extraction (educational sketch)

Rewrite the series as four sums and shift by $16^n$ so the hexadecimal point
sits before the desired digit (Wikipedia “BBP digit-extraction algorithm for
$\pi$”). For each offset $j\in\{1,4,5,6\}$:

$$
\sum_{k=0}^{\infty}\frac{16^{n-k}}{8k+j}
=
\sum_{k=0}^{n}\frac{16^{n-k}\bmod(8k+j)}{8k+j}
+\sum_{k=n+1}^{\infty}\frac{16^{n-k}}{8k+j}.
$$

Keep fractional parts, form
$4S_1-2S_4-S_5-S_6$, take $\{\cdot\}\in[0,1)$, multiply by $16$, and truncate
to obtain the digit. `Hex_Digit_Of_Pi(N)` implements this for
$0\le N\le\mathrm{Max\_Hex\_Digit}$ and is checked against the known
expansion $\pi=3.243\mathrm{F}6\mathrm{A}8885\mathrm{A}30\ldots_{16}$.

## API summary

| Symbol | Role |
| --- | --- |
| `Approximate_Pi(Terms)` | $\pi$ from first $\mathrm{Terms}$ series terms |
| `Approximate_Pi(..., Estimate, Sum)` | Same; `Estimate = Sum` for BBP |
| `Series_Term(K)` | Term $t_K=16^{-K}\cdot(\cdots)$ |
| `Term_Parenthesis(K)` | $4/(8K+1)-2/(8K+4)-1/(8K+5)-1/(8K+6)$ |
| `Series_Sum(Terms)` | $S=\sum_{k=0}^{\mathrm{Terms}-1}t_k$ |
| `Hex_Digit_Of_Pi(N)` | $N$-th hex digit of $\pi$ after the point |
| `Hex_Fractional_Part(N)` | $\{16^N\pi\}$ used by the digit sketch |
| `Pi_Constant` | Reference $\pi$ literal (`Long_Float`) |
| `Ada_Pi` | `Long_Float (Ada.Numerics.Pi)` |
| `Elementary_Pi` | $4\arctan(1)$ via `Long_Elementary_Functions` |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Term_Count` | Subtype $1..40$ |
| `Hex_Digit` / `Hex_Digit_Index` | $0..15$ / $0..12$ |
| `Invalid_Argument` | Bad index / Terms / hex $N$ |

## Limits and caveats

- **Educational `Long_Float`** — not a multiprecision $\pi$ engine; arctan
  uses `Ada.Numerics.Long_Elementary_Functions`.
- **Cap** — `Max_Terms = 40`; useful new digits stop by $N\approx 15$–$20$.
- **Hex sketch** — `Max_Hex_Digit = 12`; production digit extraction uses
  carefully tuned floating or big-int modular arithmetic for large $n$.
- **Not** Chudnovsky series, Borwein quartic, Gauss–Legendre AGM, or a
  decimal spigot (see siblings / upcoming Computation of $\pi$ survey).
- **Base 16 only** — BBP extracts hex/binary digits; it does not give the
  $n$-th decimal digit without essentially computing prior digits.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pbbp.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `bbp.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
bbp.ads
bbp.adb
bbp.gpr
tests.adb
```

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
