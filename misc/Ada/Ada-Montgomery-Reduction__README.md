# Montgomery Reduction — Ada 2023

Educational, self-contained Ada 2023 package for **Montgomery reduction**
(**REDC**) and **Montgomery modular multiplication**. See

- [Montgomery modular multiplication](https://en.wikipedia.org/wiki/Montgomery_modular_multiplication)
- [Montgomery reduction](https://en.wikipedia.org/wiki/Montgomery_reduction)
  (redirects to the page above)

Odd modulus $N$, power-of-two radix $R=2^k>N$ (so $\gcd(N,R)=1$).
Montgomery form of $a$ is $\tilde a=aR\bmod N$. REDC computes
$TR^{-1}\bmod N$ without dividing by $N$, using the precomputed
$N'=-N^{-1}\bmod R$. Montgomery multiplication is $\mathrm{REDC}(\tilde a\cdot\tilde b)$.

Educational `Long_Integer` domain: keep $N<R=2^{R\_\mathrm{Bits}}$ with
$R\_\mathrm{Bits}\le 30$ (default $16$) so REDC intermediates fit safely.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Multiplication-Algorithms](https://github.com/RobertBoettcherSF/Ada-Multiplication-Algorithms)** — survey of classical / Karatsuba / Toom / FFT-style multiply sketches
- **CORDIC** — upcoming
- **BKM** — upcoming
- **Exponentiation by squaring** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Context** | `Create_Context(N, R_Bits)` | Precomputes $N'$, $R\bmod N$, $R^2\bmod N$ |
| **Into Mont** | `To_Montgomery` | $\mathrm{REDC}((a\bmod N)\,(R^2\bmod N))$ |
| **Out of Mont** | `From_Montgomery` | $\mathrm{REDC}(\tilde a)$ |
| **Reduction** | `REDC(T)` | $TR^{-1}\bmod N$ via $N'$ |
| **Multiply** | `Montgomery_Multiply` | $\mathrm{REDC}(\tilde a\cdot\tilde b)$ |
| **Pow** | `Montgomery_Pow` | Square-and-multiply in Mont domain |
| **Oracle** | `Mod_Mul` / `Mod_Pow` | Classical $(A\cdot B)\bmod N$ |
| **Invalid input** | `Invalid_Argument` | Even $N$, $R\le N$, bad $R\_\mathrm{Bits}$, … |

## Brief history

Peter L. Montgomery introduced the method in 1985. Classical modular
multiplication reduces the double-width product $ab$ by dividing by $N$.
Montgomery form replaces that division by cheaper reduction modulo a
convenient radix $R$ (on binary machines, a power of two). Converting a
single product into and out of Montgomery form is not worthwhile, but a
long chain of multiplies — especially modular exponentiation as in RSA —
can stay in Montgomery form so the conversions become negligible.

## Algorithm

### Setup

Choose odd $N>1$ and $R=2^k>N$. Precompute

$$
N'\equiv -N^{-1}\pmod R,\qquad
R\bmod N,\qquad
R^2\bmod N.
$$

Because $N$ is odd, $N^{-1}\bmod R$ exists; this package lifts it by a
Newton / Hensel iteration $\mathrm{inv}\leftarrow\mathrm{inv}\,(2-N\cdot\mathrm{inv})$.

### REDC

Given $0\le T<RN$:

$$
\begin{aligned}
m &\leftarrow ((T\bmod R)\,N')\bmod R, \\
t &\leftarrow (T+mN)/R, \\
S &\leftarrow
\begin{cases}
t-N & \text{if }t\ge N,\\
t & \text{otherwise.}
\end{cases}
\end{aligned}
$$

Then $S\equiv TR^{-1}\pmod N$ and $0\le S<N$. Division by $R$ is a shift
when $R=2^k$; the only reduction modulo $N$ is the final conditional
subtraction.

### Montgomery multiply and conversions

$$
\begin{aligned}
\tilde a\cdot_{\mathrm{Mont}}\tilde b
&=\mathrm{REDC}(\tilde a\cdot\tilde b)
\equiv(ab)R\pmod N, \\
\tilde a
&=\mathrm{REDC}((a\bmod N)\,(R^2\bmod N)), \\
a
&=\mathrm{REDC}(\tilde a).
\end{aligned}
$$

### Worked check (Wikipedia-style, $N=17$, $R=32$)

$N'=15$. Montgomery forms: $\widetilde{7}=3$, $\widetilde{15}=4$.
Product $T=12$; $\mathrm{REDC}(12)=11=\widetilde{3}$, and
$7\cdot 15\equiv 3\pmod{17}$.

### Montgomery exponentiation

Square-and-multiply with Montgomery multiplies, starting from the
Montgomery form of $1$ (namely $R\bmod N$), then one final
`From_Montgomery`.

## API summary

| Symbol | Role |
| --- | --- |
| `Context` | $(N,R,R\_\mathrm{Bits},N',R\bmod N,R^2\bmod N)$ |
| `Create_Context(N, R_Bits)` | Build context; raises `Invalid_Argument` on bad params |
| `Is_Valid_Context(Ctx)` | Sanity-check precomputed fields |
| `To_Montgomery` / `From_Montgomery` | Domain conversions |
| `REDC(Ctx, T)` | Montgomery reduction |
| `Montgomery_Multiply` | REDC of product of Montgomery forms |
| `Montgomery_Pow` | Modpow via Mont square-and-multiply (ordinary I/O) |
| `Mod_Mul` / `Mod_Pow` | Classical oracle |
| `Mod_Inverse` / `Gcd` / `Mod_Nonneg` | Helpers |
| `Is_Power_Of_Two` / `Floor_Log2` / `Abs_LI` | Helpers |
| `Invalid_Argument` | Even $N$, $R\le N$, negative $T$ / `Exp`, … |
| `Max_R_Bits` / `Default_R_Bits` | Educational bounds ($30$ / $16$) |

## Limits and caveats

- **Educational range** — $1<N<R=2^{R\_\mathrm{Bits}}$ with
  $R\_\mathrm{Bits}\le\mathrm{Max\_R\_Bits}=30$ so $T+mN$ fits in
  `Long_Integer`. Default $R=2^{16}$.
- **Odd $N$ only** — required for $\gcd(N,R)=1$ when $R$ is a power of two.
- **Not** a multiprecision / word-by-word CIOS implementation — this is the
  single-precision textbook REDC for classroom study.
- Style matches the series' `Long_Integer` modular packages (e.g. multiplicative
  inverse surveys).

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pmontgomery_reduction.gpr
make test   # build + run bin/tests → Passed / Failed / ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. Zero `-gnatwa` warnings expected.

## Project layout

Exactly seven root files (no `main.adb`; `tests.adb` is the main):

```
.gitignore
Makefile
README.md
montgomery_reduction.ads
montgomery_reduction.adb
montgomery_reduction.gpr
tests.adb
```

## References

1. [Montgomery modular multiplication — Wikipedia](https://en.wikipedia.org/wiki/Montgomery_modular_multiplication)
2. [Montgomery reduction — Wikipedia](https://en.wikipedia.org/wiki/Montgomery_reduction)
3. Peter L. Montgomery, *Modular multiplication without trial division*,
   Mathematics of Computation 44 (1985).
