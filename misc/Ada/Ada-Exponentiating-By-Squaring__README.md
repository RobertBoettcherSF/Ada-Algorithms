# Exponentiating by Squaring — Ada 2023

Educational, self-contained Ada 2023 package for **exponentiating by
squaring** (also called **binary exponentiation** or
**square-and-multiply**). See
[Exponentiating by squaring](https://en.wikipedia.org/wiki/Exponentiating_by_squaring).

The method computes $x^n$ with $O(\log n)$ multiplications by repeatedly
squaring and multiplying according to the bits of $n$. Variants here
cover recursive and iterative integer powering, modular
$\mathrm{Pow\_Mod}$, optional `Float` reciprocal powers for negative
exponents, and a small $2\times 2$ matrix powering sketch (semigroup
example). A naive multiply-loop oracle is included for small exponents.

Educational `Long_Integer` domain: non-modular $x^n$ can overflow;
prefer modular powering for large exponents. Documented bounds and the
optional `Multiplication_Count` counter make the logarithmic saving
visible in the classroom.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-BKM](https://github.com/RobertBoettcherSF/Ada-BKM)** — Bajard–Kla–Muller shift-and-add exp / ln
- **[Ada-Montgomery-Reduction](https://github.com/RobertBoettcherSF/Ada-Montgomery-Reduction)** — REDC / Montgomery multiply and pow
- **Addition-chain exponentiation** — upcoming
- **SRT division** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Recursive** | `Power_Recursive` | Wikipedia odd/even recurrence |
| **Iterative RTL** | `Power_Iterative` | Right-to-left square-and-multiply |
| **Iterative LTR** | `Power_Left_To_Right` | Scan bits MSB→LSB |
| **Modular** | `Pow_Mod(Base, Exp, Modulus)` | Preferred for large $n$ |
| **Naive oracle** | `Power_Naive` | Loop; `Exp ≤ Max_Naive_Exp` |
| **Float** | `Power_Float` | Negative $n$ → $(1/x)^{|n|}$ |
| **Matrix sketch** | `Power_Matrix_2x2` | $2\times 2$ semigroup example |
| **Mul counter** | `Multiplication_Count` | Optional educational tally |
| **Invalid input** | `Invalid_Argument` | Bad modulus, naive bound, $0^{≤0}$ float, … |

## Brief history

Exponentiating by squaring is classical; binary methods appear throughout
number theory and cryptography (RSA modular exponentiation, elliptic-curve
double-and-add). The Wikipedia page surveys recursive and constant-space
iterative forms, $2^k$-ary and sliding-window variants, and applications
to matrices and polynomials. This package teaches the core binary
algorithms plus modular and `Float` extensions in the style of the
series' Montgomery and multiplicative-inverse packages.

## Algorithm

### Recursive form

For integer $n>0$:

$$
x^{n}=
\begin{cases}
x\,(x^{2})^{(n-1)/2} & \text{if }n\text{ is odd},\\
(x^{2})^{n/2} & \text{if }n\text{ is even}.
\end{cases}
$$

With $x^{0}=1$ (this package uses the programming convention $0^{0}:=1$).
Negative exponents on integers are rejected; for `Float`,

$$
x^{n}=\Bigl(\frac{1}{x}\Bigr)^{-n}\qquad(n<0,\;x\neq 0).
$$

Each recursive step drops the least-significant bit of $n$, so there are
$\lceil\log_{2} n\rceil$ squarings and a number of extra multiplications
equal to the Hamming weight of $n$ minus one (for $n>0$).

### Iterative right-to-left

Maintain the invariant $y\cdot x^{n}$ equal to the original power while
halving $n$:

$$
yx^{n}=
\begin{cases}
yx\,(x^{2})^{(n-1)/2} & \text{if }n\text{ is odd},\\
y\,(x^{2})^{n/2} & \text{if }n\text{ is even}.
\end{cases}
$$

Start with $y=1$. Same multiplication count as the recursive form, with
$O(1)$ auxiliary memory.

### Left-to-right

Scan bits of $n$ from MSB to LSB: square the running result each bit;
multiply by the base when the bit is $1$.

### Modular powering

$\mathrm{Pow\_Mod}(b,e,m)=b^{e}\bmod m$ uses the same square-and-multiply
schedule with modular multiplies, keeping intermediates in
$0,\ldots,m-1$. Use this whenever $b^{e}$ would overflow `Long_Integer`.

### Complexity

About $\lfloor\log_{2} n\rfloor$ squarings and at most
$\lfloor\log_{2} n\rfloor$ additional multiplications — versus $n-1$ for
the naive loop when $n\gtrsim 4$.

## API summary

| Symbol | Role |
| --- | --- |
| `Max_Naive_Exp` | Cap for `Power_Naive` ($10\,000$) |
| `Invalid_Argument` | Bad modulus / naive bound / float $0^{≤0}$ / … |
| `Reset_Multiplication_Count` / `Enable_Counting` / `Multiplication_Count` | Educational mul tally |
| `Abs_LI` / `Mod_Nonneg` / `Mod_Mul` | Integer helpers |
| `Power_Recursive` | Recursive binary $x^{n}$ |
| `Power_Iterative` | Right-to-left iterative $x^{n}$ |
| `Power_Left_To_Right` | Left-to-right iterative $x^{n}$ |
| `Power_Naive` | Multiply-loop oracle (small $n$) |
| `Pow_Mod` | $b^{e}\bmod m$ |
| `Power_Float` | `Float` power; negative $n$ via reciprocal |
| `Matrix_2x2` / `Identity_2x2` / `Multiply_2x2` / `Power_Matrix_2x2` | $2\times 2$ sketch |

## Limits and caveats

- **Overflow.** Non-modular `Power_*` on `Long_Integer` may raise
  `Constraint_Error` when $|x|^{n}$ exceeds the signed range. Prefer
  `Pow_Mod` for large exponents. Classroom examples such as $2^{10}$,
  $2^{30}$, and modest negative bases are safe.
- **Modular intermediates.** `Mod_Mul` forms a product of two residues
  before reducing; keep $m$ educationally small so $m^{2}$ fits in
  `Long_Integer` (same discipline as the Montgomery teaching package).
- **$0^{0}$.** Defined as $1$ for integer, modular, and float APIs here.
- **Float.** `Power_Float(0.0, n)` for $n\le 0$ raises `Invalid_Argument`.
- **Matrices.** `Power_Matrix_2x2` is a pedagogy sketch (e.g. Fibonacci
  companion $\begin{pmatrix}1&1\\1&0\end{pmatrix}^{n}$); entries can
  overflow — keep exponents modest.
- **Counter.** Squares count as one multiplication; enable with
  `Enable_Counting(True)` then read `Multiplication_Count`.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pexponentiating_by_squaring.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022/2023 support. Zero `-gnatwa` warnings expected.

## Repository layout

Exactly seven root files (no `main.adb`):

| File | Role |
| --- | --- |
| `.gitignore` | Ignores `obj/`, `bin/` |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `exponentiating_by_squaring.ads` | Package spec |
| `exponentiating_by_squaring.adb` | Package body |
| `exponentiating_by_squaring.gpr` | GPRbuild project (`tests.adb` main) |
| `tests.adb` | Standalone test harness |

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
