# Schönhage–Strassen Algorithm — Ada 2023 (educational sketch)

Educational, self-contained Ada 2023 package for the **Schönhage–Strassen**
idea of multiplying large integers via **cyclic convolution / DFT**, following
[Wikipedia: Schönhage–Strassen algorithm](https://en.wikipedia.org/wiki/Schönhage–Strassen_algorithm).

**This is a teaching sketch, not a production Schönhage–Strassen
implementation.** Full SS works recursively over the Fermat ring
$\mathbb{Z}/(2^{n}+1)\mathbb{Z}$ with weight factors and achieves
$O(n\cdot\log n\cdot\log\log n)$ bit complexity. Here we keep the *same
convolution idea* but realize the DFT as an exact **number-theoretic
transform (NTT)** modulo two NTT-friendly primes, combined with the Chinese
Remainder Theorem — integer-only, capped sizes, schoolbook as oracle.

Non-negative integers are stored as little-endian **base-$B$ digit vectors**
($B=10^{4}$) with a modest limb cap. Below a limb threshold, `Multiply_SS`
falls back to schoolbook.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Toom-Cook](https://github.com/RobertBoettcherSF/Ada-Toom-Cook)** — Toom-3 digit-vector multiply
- **Karatsuba** — upcoming (Toom-2)
- **Fürer** — upcoming
- **Booth** — upcoming
- **Multiplication algorithms** — upcoming survey
- **Montgomery** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | `Digit_Vector` base $B=10^{4}$ | Little-endian limbs; `Max_Operand_Limbs=32` |
| **Oracle** | `Multiply_Schoolbook` | $O(n^{2})$ limb products |
| **SS sketch** | `Multiply_SS` / `Multiply_NTT` | Exact NTT + CRT convolution |
| **Base case** | `Default_SS_Threshold` | Schoolbook when $\max(\|A\|,\|B\|)\le T$ |
| **Ring** | Two primes $P_{1},P_{2}$ + CRT | Fermat-friendly $P-1$ divisible by $64$ |
| **Invalid input** | `Invalid_Argument` | Empty / non-digit strings, `Sub` underflow, overflow |

## Brief history

Arnold **Schönhage** and Volker **Strassen** (1971) showed that integer
multiplication can be reduced to a carefully weighted **cyclic convolution**
computed by FFT over $\mathbb{Z}/(2^{n}+1)\mathbb{Z}$. The asymptotic
complexity

$$
O(n\cdot\log n\cdot\log\log n)
$$

was the best known until Fürer (2007); Harvey–van der Hoeven later proved
$O(n\log n)$ is achievable in theory (galactic constants). SS remains the
workhorse behind many practical huge-integer multiplications (π, GIMPS, …
via Kronecker substitution for polynomials).

This package teaches the **convolution / DFT core** on digit vectors with an
exact modular NTT, not the full recursive Fermat-ring pipeline.

## Algorithm (educational NTT sketch)

Write each operand in base $B$ as a limb sequence (little-endian):

$$
a = \sum_{i=0}^{n-1} a_{i} B^{i},\qquad
b = \sum_{j=0}^{m-1} b_{j} B^{j}.
$$

The integer product is the **linear convolution** of $(a_{i})$ and $(b_{j})$
followed by carry propagation in base $B$. Embedding that convolution in a
cyclic convolution of length $N=2^{k}\ge n+m$ lets us use a length-$N$ DFT:

$$
c = \mathrm{IDFT}\bigl(\mathrm{DFT}(a)\odot\mathrm{DFT}(b)\bigr).
$$

**Exact modular NTT.** Choose primes $P$ with $N\mid(P-1)$ so a primitive
$N$-th root of unity exists in $\mathbb{Z}/P\mathbb{Z}$. This package uses

$$
\begin{aligned}
P_{1} &= 998244353 = 119\cdot 2^{23}+1, \\
P_{2} &= 1004535809 = 479\cdot 2^{21}+1,
\end{aligned}
$$

runs NTT multiplication modulo each $P_{\ell}$, and recovers each
non-negative convolution coefficient by CRT (product $P_{1}P_{2}$ far larger
than any coefficient for operands $\le$ `Max_Operand_Limbs`). Finally carry:

$$
c_{i} + \mathit{carry} = q\cdot B + r,\quad
\text{limb}=r,\ \mathit{carry}=q.
$$

**Relation to true SS.** Classical Schönhage–Strassen replaces the prime-field
NTT by an FFT over $\mathbb{Z}/(2^{n}+1)\mathbb{Z}$ (roots of unity are powers
of two — cheap shifts) and recurses on the pointwise products. The classroom
code keeps the same high-level shape — split into digits, transform, pointwise
multiply, inverse transform, recompose — while staying exact and small.

**Worked size.** With $B=10^{4}$, a $48$-digit factor uses about $12$ limbs —
above `Default_SS_Threshold` ($8$), so `Multiply_SS` uses NTT. Tests compare
every NTT / SS result to the schoolbook oracle.

## API summary

| Symbol | Role |
| --- | --- |
| `Base` | Limb radix $10^{4}$ |
| `Max_Operand_Limbs` / `Max_Limbs` | Operand / product capacity |
| `Max_NTT_Length` | Power-of-two transform cap ($64$) |
| `Default_SS_Threshold` | Schoolbook cutoff (limbs) |
| `Digit` / `Digit_Vector` | Limb type / big-int lite value |
| `Zero` / `One` | Constants $0$, $1$ |
| `From_Natural` / `From_String` | Constructors (decimal string) |
| `To_String` / `To_Natural` | Conversions |
| `Length` / `Is_Zero` / `Get_Digit` | Queries (little-endian limbs) |
| `Compare` / `Equal` | Magnitude order / equality |
| `Add` / `Sub` | Non-negative add; `Sub` requires $A\ge B$ |
| `Shift_Limbs` | Multiply by $B^{k}$ |
| `Multiply_Schoolbook` | $O(n^{2})$ oracle |
| `Multiply_NTT` | Exact NTT + CRT convolution |
| `Multiply_SS` | Thresholded schoolbook / NTT (+ optional `Threshold`) |
| `Invalid_Argument` | Domain / overflow errors |

## Limits and caveats

- **Educational sizes** — operands $\le$ `Max_Operand_Limbs` limbs; transform
  length $\le$ `Max_NTT_Length`.
- **Not production SS** — no recursive Fermat-ring FFT, no $\sqrt{2}$ weights,
  no $O(n\log n\log\log n)$ claims for this code path.
- **Non-negative only** at the public API.
- **Exact integers** — modular NTT + CRT; no floating-point FFT rounding.
- Sibling digit-vector style matches **Ada-Toom-Cook**; this package does not
  `with` that project.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pschonhage_strassen.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `schonhage_strassen.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
schonhage_strassen.ads
schonhage_strassen.adb
schonhage_strassen.gpr
tests.adb
```

## References

1. [Wikipedia: Schönhage–Strassen algorithm](https://en.wikipedia.org/wiki/Schönhage–Strassen_algorithm)
2. [Wikipedia: Number-theoretic transform](https://en.wikipedia.org/wiki/Discrete_Fourier_transform_(general)#Number-theoretic_transform)
3. [Wikipedia: Multiplication algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm)
4. Schönhage, A. & Strassen, V. — Schnelle Multiplikation großer Zahlen (1971)
