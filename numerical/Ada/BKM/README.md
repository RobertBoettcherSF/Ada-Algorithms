# BKM algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **BKM algorithm**
(Bajard–Kla–Muller), a shift-and-add method for real **exponentials**
(E-mode) and **natural logarithms** (L-mode). Prefills
$A_k=\ln(1+2^{-k})$, runs classic real iterations with $d_k\in\{0,1\}$,
extends the domain by **binary range reduction**, and caps iterations at
$40$. Educational `Long_Float` multiplies by $2^{-k}$ stand in for
hardware arithmetic shifts. Unlike CORDIC, BKM needs **no** result
scaling factor $K$.

Based on [Wikipedia: BKM algorithm](https://en.wikipedia.org/wiki/BKM_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-CORDIC](https://github.com/RobertBoettcherSF/Ada-CORDIC)** — circular CORDIC $\sin$/$\cos$/$\mathrm{atan2}$/magnitude
- **Exponentiating by squaring** — upcoming
- **Addition-chain exponentiation** — upcoming
- **SRT division** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Table** | $A_k=\ln(1+2^{-k})$ | Prefill $k=0..39$ at elaboration |
| **E-mode** | Drive residual $y\to Y$ | $\mathrm{Exp}(Y)$ via product of $(1+2^{-k})$ |
| **L-mode** | Drive product $x\to X$ | $\mathrm{Ln}(X)$ via sum of selected $A_k$ |
| **Gain** | None | No CORDIC-style $K$ / $1/K$ factor |
| **Range** | Binary reduction | $\mathrm{Exp}$: $Y=N\ln 2+R$; $\mathrm{Ln}$: $X=M\cdot 2^E$ |
| **Shift stand-in** | Multiply by $2^{-k}$ / `'Scaling` | Documents hardware add/shift/compare |
| **Cap** | $n\le 40$ | `Max_Iterations = 40` |
| **Oracle** | `Exact_Exp` / `Exact_Ln` | Ada `Long_Elementary_Functions` |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | Raised by `Ln` when $X\le 0$ |

## Brief history

BKM was published in 1994 by Jean-Claude Bajard, Sylvanus Kla, and
Jean-Michel Muller as a hardware-friendly algorithm for **complex**
elementary functions. It generalizes ideas going back to Briggs’
logarithm tables: represent a factor as a product of terms
$(1+d\cdot 2^{-k})$ and accumulate precomputed $\ln(1+d\cdot 2^{-k})$ by
addition only. Relative to CORDIC, BKM stores logarithms rather than
arctangents, chooses coefficients from a richer digit set (nine complex
values in the full algorithm), and **does not** require a constant scale
factor $K$. The convergence rate is about one bit per iteration. This
package teaches the **real** E/L cores ($d_k\in\{0,1\}$) with binary
range reduction; complex modes are documented but not implemented.

## Algorithm (this package)

**Identity.** From $\ln(ab)=\ln a+\ln b$:

$$
\ln\Bigl(\prod_{k\in K}(1+2^{-k})\Bigr)=\sum_{k\in K}\ln(1+2^{-k}).
$$

Prefill $A_k=\ln(1+2^{-k})$. Hardware then needs only add, shift, and
compare.

**L-mode (logarithm core).** For $X$ in the classic cone
$[1,\prod_{k=0}^{\infty}(1+2^{-k})]\approx[1,\,4.768]$:

$$
x_0=1,\quad y_0=0,\qquad
\begin{cases}
x\leftarrow x\cdot(1+2^{-k}),\; y\leftarrow y+A_k
& \text{if }x\cdot(1+2^{-k})\le X,\\
\text{skip}
& \text{otherwise.}
\end{cases}
$$

After $N$ steps, $y_N\approx\ln X$ with $|\Delta\ln X|\lesssim 2^{-N}$.

**E-mode (exponential core).** Dual form for $Y$ in
$[0,\sum A_k]\approx[0,\,1.562]$: accept digit $d_k=1$ when
$y+A_k\le Y$, updating the same product / sum pair so $x_N\approx\exp Y$.

**Range reduction (this package).**

- $\mathrm{Exp}(Y)$: write $Y=N\ln 2+R$ with $R\in[0,\ln 2]\subset[0,\sum A_k]$,
  then $\exp Y=2^N\cdot\mathrm{Exp\_Core}(R)$ (`'Scaling` for $2^N$).
- $\mathrm{Ln}(X)$ for $X>0$: write $X=M\cdot 2^E$ with $M\in[1,2)$,
  then $\ln X=\mathrm{Ln\_Core}(M)+E\ln 2$.

**Optional minus table.** $A_k^-=\ln(1-2^{-k})$ for $k\ge 1$ is prefilled
(`Log_Table_Minus`) for experiments with $d_k\in\{-1,0,1\}$; the public
`Exp` / `Ln` paths keep $d_k\in\{0,1\}$ plus reduction.

**Worked check.** $\exp(0)=1$; $\exp(1)\approx e$; $\ln e=1$; $\ln 1=0$;
$\exp(\ln 2)=2$; round-trips $\exp(\ln x)\approx x$ and $\ln(\exp y)\approx y$
on the documented domains.

## API summary

| Symbol | Role |
| --- | --- |
| `Exp(Y, Iterations)` | E-mode exponential (range-reduced) |
| `Ln(X, Iterations)` | L-mode natural log; raises `Invalid_Argument` if $X\le 0$ |
| `Log_Table(K)` | Prefill entry $A_k=\ln(1+2^{-k})$ |
| `Log_Table_Minus(K)` | Prefill $A_k^-=\ln(1-2^{-k})$ for $k\ge 1$ |
| `Exact_Exp`, `Exact_Ln` | Oracles via `Long_Elementary_Functions` |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Iteration_Count` | Subtype $1..40$ |
| `Ln_2`, `E_Const`, `Prod_Bound`, `Sum_Bound` | Documented constants |
| `Invalid_Argument` | Domain exception for non-positive `Ln` |

## Limits and caveats

- **Educational `Long_Float`** — multiplies by $2^{-k}$ and `'Scaling`
  replace shifts so the control flow matches hardware BKM without
  fixed-point scaling noise.
- **Cap** — `Max_Iterations = 40`; double precision is saturated earlier.
- **Classic cone** — without reduction, real $d_k\in\{0,1\}$ BKM converges
  for arguments in $[1,\approx 4.768]$ (L) and $[0,\approx 1.562]$ (E). This
  package always reduces so classroom inputs covering $\mathbb{R}$ (Exp)
  and $(0,\infty)$ (Ln) still work.
- **No $K$ factor** — a deliberate contrast with CORDIC.
- **Not** complex BKM, high-radix BKM, or a multiprecision kernel.
- **Overflow / underflow** — extreme $|Y|$ in `Exp` follows `Long_Float`
  IEEE behaviour after scaling.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pbkm.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `bkm.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
bkm.ads
bkm.adb
bkm.gpr
tests.adb
```

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
