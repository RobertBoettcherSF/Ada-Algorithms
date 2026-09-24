# Karatsuba Algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Karatsuba**
multiplication algorithm, following
[Wikipedia: Karatsuba algorithm](https://en.wikipedia.org/wiki/Karatsuba_algorithm).

Non-negative integers are stored as little-endian **base-$B$ digit vectors**
($B=10^{4}$) with a modest limb cap — a “big-int lite” so the classroom code
stays correct without an external multiprecision library. **Schoolbook**
multiplication is the oracle; **Karatsuba** splits each operand in half,
forms three half-size products, and recomposes with shifts — asymptotically
$O(n^{\log_{2} 3})\approx O(n^{1.58})$ limb work versus $O(n^{2})$ schoolbook.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Toom-Cook](https://github.com/RobertBoettcherSF/Ada-Toom-Cook)** — Toom-3 digit-vector multiply
- **[Ada-Schonhage-Strassen](https://github.com/RobertBoettcherSF/Ada-Schonhage-Strassen)** — NTT / convolution teaching sketch
- **Fürer** — upcoming
- **Booth** — upcoming
- **Multiplication algorithms** — upcoming survey
- **Montgomery** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | `Digit_Vector` base $B=10^{4}$ | Little-endian limbs; `Max_Operand_Limbs=64` |
| **Oracle** | `Multiply_Schoolbook` | $O(n^{2})$ limb products |
| **Karatsuba** | `Multiply_Karatsuba` | Three recursive half-size products |
| **Base case** | `Default_Karatsuba_Threshold` | Schoolbook when $\max(\|A\|,\|B\|)\le T$ |
| **Split** | $m=\lfloor n/2\rfloor$ | $x=x_{1}B^{m}+x_{0}$, same $m$ for $y$ |
| **Invalid input** | `Invalid_Argument` | Empty / non-digit strings, `Sub` underflow, overflow |

## Brief history

Andrey Kolmogorov conjectured that multiplying two $n$-digit numbers requires
$\Omega(n^{2})$ elementary operations. In 1960, Anatoly **Karatsuba**, then a
23-year-old student at Moscow State University, found a divide-and-conquer
scheme that needs only three multiplications of $\approx n/2$-digit numbers
instead of four, yielding

$$
O\!\left(n^{\log_{2} 3}\right)\approx O(n^{1.58}).
$$

The result (published 1962 with Yu. Ofman) was the first multiplication
algorithm asymptotically faster than grade-school arithmetic. **Toom–Cook**
generalizes the idea to $k$ parts; **Schönhage–Strassen** and later FFT-style
methods push the exponent still closer to $1$ for huge $n$. This package
teaches the classic three-product Karatsuba step on digit vectors, with
schoolbook as both oracle and recursive leaf.

## Algorithm (classic Karatsuba)

Write the operands in some base power $B^{m}$:

$$
x = x_{1} B^{m} + x_{0},\qquad
y = y_{1} B^{m} + y_{0}.
$$

Naive expansion needs four products $x_{i}y_{j}$. Karatsuba computes only
three:

$$
\begin{aligned}
z_{0} &= x_{0}\, y_{0}, \\
z_{2} &= x_{1}\, y_{1}, \\
z_{1} &= (x_{0}+x_{1})(y_{0}+y_{1}) - z_{0} - z_{2},
\end{aligned}
$$

and recomposes

$$
xy = z_{2}\, B^{2m} + z_{1}\, B^{m} + z_{0}.
$$

(The middle identity follows because
$(x_{0}+x_{1})(y_{0}+y_{1})=z_{0}+z_{1}+z_{2}$.) Recurse on each of the three
products; stop when $\max(\mathrm{Length}(x),\mathrm{Length}(y))$ is at most
the schoolbook threshold.

**Worked size.** With $B=10^{4}$, a $60$-digit decimal factor uses about
$15$ limbs — above `Default_Karatsuba_Threshold` ($8$), so one or more
Karatsuba layers run before schoolbook leaves. Tests compare every Karatsuba
result to the schoolbook oracle.

## API summary

| Symbol | Role |
| --- | --- |
| `Base` | Limb radix $10^{4}$ |
| `Max_Operand_Limbs` / `Max_Limbs` | Operand / product capacity |
| `Default_Karatsuba_Threshold` | Schoolbook cutoff (limbs) |
| `Digit` / `Digit_Vector` | Limb type / big-int lite value |
| `Zero` / `One` | Constants $0$, $1$ |
| `From_Natural` / `From_String` | Constructors (decimal string) |
| `To_String` / `To_Natural` | Conversions |
| `Length` / `Is_Zero` / `Get_Digit` | Queries (little-endian limbs) |
| `Compare` / `Equal` | Magnitude order / equality |
| `Add` / `Sub` | Non-negative add; `Sub` requires $A\ge B$ |
| `Shift_Limbs` | Multiply by $B^{k}$ |
| `Multiply_Schoolbook` | $O(n^{2})$ oracle |
| `Multiply_Karatsuba` | Classic Karatsuba (+ optional `Threshold`) |
| `Invalid_Argument` | Domain / overflow errors |

## Limits and caveats

- **Educational sizes** — keep operands $\le$ `Max_Operand_Limbs` limbs so
  schoolbook stays fast and Karatsuba temporaries fit in `Max_Limbs`.
- **Non-negative only** at the public API.
- **Karatsuba is Toom-2** — three products; Toom-3 / FFT siblings live in
  **Ada-Toom-Cook** and **Ada-Schonhage-Strassen** (this package does not
  `with` them; the digit API is reimplemented locally).
- **No** Fürer / Booth / Montgomery here — upcoming siblings.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pkaratsuba.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `karatsuba.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
karatsuba.ads
karatsuba.adb
karatsuba.gpr
tests.adb
```

## References

1. [Wikipedia: Karatsuba algorithm](https://en.wikipedia.org/wiki/Karatsuba_algorithm)
2. [Wikipedia: Toom–Cook multiplication](https://en.wikipedia.org/wiki/Toom–Cook_multiplication) (Toom-3 generalization)
3. [Wikipedia: Schönhage–Strassen algorithm](https://en.wikipedia.org/wiki/Schönhage–Strassen_algorithm)
4. [Wikipedia: Multiplication algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm)
5. Karatsuba, A.; Ofman, Yu. (1962) — Multiplication of multidigit numbers on automata
