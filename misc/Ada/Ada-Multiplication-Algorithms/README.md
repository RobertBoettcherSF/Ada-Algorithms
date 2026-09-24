# Multiplication Algorithms — Ada 2023 Survey

Educational, self-contained Ada 2023 **survey** of classic **multiplication
algorithms**, following
[Wikipedia: Multiplication algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm).

This package implements classroom sketches (no sibling `with`):

1. **Schoolbook / long multiplication** on base-$B$ `Digit_Vector` limbs
   ($B=10^{4}$) — the $O(n^{2})$ oracle.
2. **Karatsuba** recursive three-product multiply with a schoolbook threshold.
3. **Peasant / Russian peasant** shift-and-add for `Long_Integer` and a
   digit-vector variant.
4. **Lattice / grid** digit multiply — another presentation of schoolbook
   (same products, column / diagonal accumulation).
5. **Complex Karatsuba trick** — $(a+bi)(c+di)$ with three real multiplies.

Full **Toom–Cook**, **Schönhage–Strassen** (NTT), and **Fürer** sketches live
in sibling repos — this survey only points at them. **Booth** is likewise a
sibling (fixed-width signed). **Montgomery reduction** is upcoming.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Karatsuba](https://github.com/RobertBoettcherSF/Ada-Karatsuba)** — dedicated Karatsuba digit-vector package
- **[Ada-Toom-Cook](https://github.com/RobertBoettcherSF/Ada-Toom-Cook)** — Toom-3 digit-vector multiply
- **[Ada-Schonhage-Strassen](https://github.com/RobertBoettcherSF/Ada-Schonhage-Strassen)** — NTT / convolution teaching sketch
- **[Ada-Furer](https://github.com/RobertBoettcherSF/Ada-Furer)** — Fürer-style FFT multiply sketch
- **[Ada-Booth-Multiplication](https://github.com/RobertBoettcherSF/Ada-Booth-Multiplication)** — radix-2 / radix-4 Booth
- **Montgomery reduction** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | `Digit_Vector` base $B=10^{4}$ | Little-endian limbs; `Max_Operand_Limbs=64` |
| **Oracle** | `Multiply_Schoolbook` | $O(n^{2})$ limb products |
| **Lattice** | `Multiply_Lattice` | Same algebra as schoolbook; grid presentation |
| **Karatsuba** | `Multiply_Karatsuba` | Three recursive half-size products |
| **Peasant** | `Multiply_Peasant` / `_Digits` | Shift-and-add; LI + digit sketches |
| **Complex 3-mul** | `Multiply_Complex_Karatsuba` | $(a+bi)(c+di)$ with 3 real muls |
| **Compare helpers** | `Products_Agree_*` | Methods vs schoolbook oracle |
| **Invalid input** | `Invalid_Argument` | Empty / non-digit strings, `Sub` underflow, overflow |

## Complexity table (sketch)

| Family | Asymptotic (limb / digit work) | This package / sibling |
| --- | --- | --- |
| Schoolbook / lattice | $O(n^{2})$ | `Multiply_Schoolbook`, `Multiply_Lattice` |
| Karatsuba | $O(n^{\log_{2} 3})\approx O(n^{1.58})$ | `Multiply_Karatsuba` (+ sibling) |
| Toom–Cook (e.g. Toom-3) | $O(n^{\log_{3} 5})\approx O(n^{1.47})$ | [Ada-Toom-Cook](https://github.com/RobertBoettcherSF/Ada-Toom-Cook) |
| Schönhage–Strassen | $O(n\log n\log\log n)$ | [Ada-Schonhage-Strassen](https://github.com/RobertBoettcherSF/Ada-Schonhage-Strassen) |
| Fürer / later FFT | $O(n\log n\,2^{\Theta(\log^{*} n)})$ | [Ada-Furer](https://github.com/RobertBoettcherSF/Ada-Furer) |
| Peasant (bit length $b$) | $O(b)$ adds / doubles | `Multiply_Peasant` |

Peasant is excellent for tiny word sizes; FFT-style methods win only for huge
$n$. Karatsuba / Toom bridge the middle.

## Brief history

Long multiplication — multiply every digit of one factor by every digit of
the other and add — has been known since antiquity and costs $O(n^{2})$ for
$n$-digit operands. Lattice (grid) multiplication is the same arithmetic
drawn as a table. The **Russian peasant** method doubles one factor and
halves the other, adding when the halved factor is odd — shift-and-add in
modern terms.

In 1960, Anatoly **Karatsuba** found a divide-and-conquer scheme that needs
only three half-size products instead of four, giving

$$
O\!\left(n^{\log_{2} 3}\right)\approx O(n^{1.58}).
$$

**Toom–Cook** splits into more parts; **Schönhage–Strassen** (1968) uses an
FFT over a modular ring; **Fürer** (2007) and later Harvey–van der Hoeven
work push the exponent still closer to $1$ for enormous $n$. A related
Karatsuba identity multiplies complex numbers with three real multiplies
instead of four. This survey packages the elementary end of that story for
Ada 2023 study.

## Algorithms (this package)

### Schoolbook / long multiplication

For little-endian limbs in base $B$,

$$
\Bigl(\sum_{i} a_{i} B^{i}\Bigr)
\Bigl(\sum_{j} b_{j} B^{j}\Bigr)
=
\sum_{i,j} a_{i} b_{j}\, B^{i+j},
$$

with carries normalized into digits $0,\ldots,B-1$. Cost $\Theta(n^{2})$
limb multiplications.

### Lattice / grid

Place each product $a_{i} b_{j}$ on a grid cell and sum along diagonals
(here: accumulate low/high halves of each limb product into columns
$i+j-1$ and $i+j$). Algebraically identical to schoolbook — a teaching
presentation, not a faster algorithm.

### Karatsuba

Write $x=x_{1}B^{m}+x_{0}$, $y=y_{1}B^{m}+y_{0}$. Compute

$$
\begin{aligned}
z_{0} &= x_{0}\, y_{0}, \\
z_{2} &= x_{1}\, y_{1}, \\
z_{1} &= (x_{0}+x_{1})(y_{0}+y_{1}) - z_{0} - z_{2},
\end{aligned}
$$

then $xy = z_{2} B^{2m} + z_{1} B^{m} + z_{0}$. Recurse until
$\max(\mathrm{Length}(x),\mathrm{Length}(y))\le T$ (schoolbook leaf).

### Peasant / Russian peasant

While the multiplier $b>0$: if $b$ is odd, add the multiplicand $a$ into
the running total; replace $b\leftarrow\lfloor b/2\rfloor$ and
$a\leftarrow 2a$. Implemented for non-negative `Long_Integer` and for
`Digit_Vector` via `Double` / `Halve` / `Add`.

### Complex three-product trick

$$
\begin{aligned}
p_{1}&=ac,\quad p_{2}=bd,\quad p_{3}=(a+b)(c+d),\\
(a+bi)(c+di)&=(p_{1}-p_{2})+(p_{3}-p_{1}-p_{2})i.
\end{aligned}
$$

`Multiply_Complex_Naive` uses four real products as oracle;
`Multiply_Complex_Karatsuba` uses three.

## API summary

| Symbol | Role |
| --- | --- |
| `Base` | Limb radix $10^{4}$ |
| `Max_Operand_Limbs` / `Max_Limbs` | Operand / product capacity |
| `Default_Karatsuba_Threshold` | Schoolbook cutoff (limbs) |
| `Digit` / `Digit_Vector` | Limb type / big-int lite value |
| `Complex_Int` | Educational $(Re,Im)$ pair (`Long_Integer`) |
| `Zero` / `One` | Constants $0$, $1$ |
| `From_Natural` / `From_String` | Constructors (decimal string) |
| `To_String` / `To_Natural` | Conversions |
| `Length` / `Is_Zero` / `Get_Digit` | Queries (little-endian limbs) |
| `Compare` / `Equal` | Magnitude order / equality |
| `Add` / `Sub` / `Shift_Limbs` | Non-negative add; `Sub` needs $A\ge B$ |
| `Double` / `Halve` | Peasant digit helpers |
| `Multiply_Schoolbook` | $O(n^{2})$ oracle |
| `Multiply_Lattice` | Lattice presentation of schoolbook |
| `Multiply_Karatsuba` | Classic Karatsuba (+ optional `Threshold`) |
| `Multiply_Peasant` | Peasant on non-negative `Long_Integer` |
| `Multiply_Peasant_Digits` | Peasant on `Digit_Vector` |
| `Multiply_Complex_Naive` | Four-real-product complex multiply |
| `Multiply_Complex_Karatsuba` | Three-real-product complex multiply |
| `Products_Agree_*` | Cross-method equality vs schoolbook |
| `Invalid_Argument` | Domain / overflow errors |

## Limits and caveats

- **Educational sizes** — keep operands $\le$ `Max_Operand_Limbs` so
  schoolbook stays fast and Karatsuba temporaries fit in `Max_Limbs`.
- **Non-negative** digit API; peasant `Long_Integer` also requires
  $X,Y\ge 0$.
- **Self-contained** — does **not** `with` Ada-Karatsuba / Toom / SS /
  Fürer / Booth; digit helpers are reimplemented locally. README links
  siblings for deeper NTT / Fürer / Booth study.
- **No** Montgomery modular reduction here — upcoming sibling.
- Complex multiply is a tiny `Long_Integer` sketch, not multiprecision.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pmultiplication_algorithms.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `multiplication_algorithms.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
multiplication_algorithms.ads
multiplication_algorithms.adb
multiplication_algorithms.gpr
tests.adb
```

## References

1. [Wikipedia: Multiplication algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm)
2. [Wikipedia: Karatsuba algorithm](https://en.wikipedia.org/wiki/Karatsuba_algorithm)
3. [Wikipedia: Ancient Egyptian multiplication](https://en.wikipedia.org/wiki/Ancient_Egyptian_multiplication) (peasant / doubling)
4. [Wikipedia: Lattice multiplication](https://en.wikipedia.org/wiki/Lattice_multiplication)
5. [Wikipedia: Toom–Cook multiplication](https://en.wikipedia.org/wiki/Toom–Cook_multiplication)
6. [Wikipedia: Schönhage–Strassen algorithm](https://en.wikipedia.org/wiki/Schönhage–Strassen_algorithm)
7. [Wikipedia: Fürer's algorithm](https://en.wikipedia.org/wiki/F%C3%BCrer's_algorithm)
