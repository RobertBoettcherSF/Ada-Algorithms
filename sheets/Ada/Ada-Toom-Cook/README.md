# Toom–Cook Multiplication (Toom-3) — Ada 2023

Educational, self-contained Ada 2023 package for **Toom–Cook multiplication**,
focusing on **Toom-3**, following
[Wikipedia: Toom–Cook multiplication](https://en.wikipedia.org/wiki/Toom–Cook_multiplication).

Non-negative integers are stored as little-endian **base-$B$ digit vectors**
($B=10^{4}$) with a modest limb cap — a “big-int lite” so the classroom code
stays correct without an external multiprecision library. **Schoolbook**
multiplication is the oracle; **Toom-3** splits each operand into three
parts, evaluates at $0,1,-1,-2,\infty$, multiplies pointwise (five products),
interpolates (Bodrato sequence), and recomposes.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Multiplicative-Inverse-Algorithms](https://github.com/RobertBoettcherSF/Ada-Multiplicative-Inverse-Algorithms)** — modular / Fermat / Newton reciprocal survey
- **Schönhage–Strassen** — upcoming
- **Karatsuba** — upcoming (Toom-2)
- **Fürer** — upcoming
- **Booth** — upcoming
- **Multiplication algorithms** — upcoming survey
- **Montgomery** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | `Digit_Vector` base $B=10^{4}$ | Little-endian limbs; `Max_Operand_Limbs=64` |
| **Oracle** | `Multiply_Schoolbook` | $O(n^{2})$ limb products |
| **Toom-3** | `Multiply_Toom3` | Five point products; Bodrato eval / interpolate |
| **Base case** | `Default_Toom3_Threshold` | Recurse / schoolbook when $\max(\|A\|,\|B\|)\le T$ |
| **Points** | $0,1,-1,-2,\infty$ | Same set as the Wikipedia Toom-3 example |
| **Invalid input** | `Invalid_Argument` | Empty / non-digit strings, `Sub` underflow, overflow |

## Brief history

Andrei **Toom** introduced a family of multiplication algorithms that split
integers into $k$ parts and reduce the $(k^{2})$ naive subproducts to
$(2k-1)$ pointwise products via polynomial evaluation and interpolation;
Stephen **Cook** cleaned the asymptotic description. **Toom-3** ($k=3$) cuts
nine limb-block multiplications down to five and runs in

$$
\Theta\!\left(n^{\log 5 / \log 3}\right)\approx\Theta(n^{1.46}).
$$

**Karatsuba** is the $k=2$ case (three products). Larger $k$ pushes the
exponent toward $1$ at the cost of heavier evaluation / interpolation
constants. This package teaches the balanced Toom-3 pipeline on digit
vectors, with schoolbook as both oracle and recursive leaf.

## Algorithm (Toom-3)

Write each operand in base $B^{L}$ with three coefficients (pad as needed):

$$
\begin{aligned}
m &= m_{0} + m_{1} B^{L} + m_{2} (B^{L})^{2}, \\
n &= n_{0} + n_{1} B^{L} + n_{2} (B^{L})^{2}.
\end{aligned}
$$

View $m$ and $n$ as polynomials $p(x),q(x)$ of degree $\le 2$. Evaluate at
five points, multiply pointwise, interpolate the unique degree-$\le 4$
product polynomial $r(x)=\sum_{i=0}^{4} r_{i} x^{i}$, then recompose

$$
m\cdot n = r(B^{L}) = r_{0} + r_{1} B^{L} + r_{2} B^{2L} + r_{3} B^{3L} + r_{4} B^{4L}.
$$

**Bodrato evaluation** (per operand), with $p_{0}\leftarrow m_{0}+m_{2}$:

$$
\begin{aligned}
p(0)&=m_{0}, &
p(\infty)&=m_{2}, &
p(1)&=p_{0}+m_{1}, \\
p(-1)&=p_{0}-m_{1}, &
p(-2)&=(p(-1)+m_{2})\cdot 2 - m_{0}.
\end{aligned}
$$

**Pointwise:** $r(a)=p(a)\,q(a)$ for $a\in\{0,1,-1,-2,\infty\}$ (recursive
`Multiply_Toom3` on magnitudes, with sign tracking).

**Bodrato interpolation** (exact divisions by $2$ and $3$):

$$
\begin{aligned}
r_{0}&\leftarrow r(0), &
r_{4}&\leftarrow r(\infty), \\
r_{3}&\leftarrow (r(-2)-r(1))/3, &
r_{1}&\leftarrow (r(1)-r(-1))/2, \\
r_{2}&\leftarrow r(-1)-r(0), \\
r_{3}&\leftarrow (r_{2}-r_{3})/2 + 2\,r(\infty), \\
r_{2}&\leftarrow r_{2}+r_{1}-r_{4}, &
r_{1}&\leftarrow r_{1}-r_{3}.
\end{aligned}
$$

**Worked size.** With $B=10^{4}$, a $60$-digit decimal factor uses about
$15$ limbs — above `Default_Toom3_Threshold` ($8$), so one or more Toom-3
layers run before schoolbook leaves. Tests compare every Toom-3 result to
the schoolbook oracle.

## API summary

| Symbol | Role |
| --- | --- |
| `Base` | Limb radix $10^{4}$ |
| `Max_Operand_Limbs` / `Max_Limbs` | Operand / product capacity |
| `Default_Toom3_Threshold` | Schoolbook cutoff (limbs) |
| `Digit` / `Digit_Vector` | Limb type / big-int lite value |
| `Zero` / `One` | Constants $0$, $1$ |
| `From_Natural` / `From_String` | Constructors (decimal string) |
| `To_String` / `To_Natural` | Conversions |
| `Length` / `Is_Zero` / `Get_Digit` | Queries (little-endian limbs) |
| `Compare` / `Equal` | Magnitude order / equality |
| `Add` / `Sub` | Non-negative add; `Sub` requires $A\ge B$ |
| `Shift_Limbs` | Multiply by $B^{k}$ |
| `Multiply_Schoolbook` | $O(n^{2})$ oracle |
| `Multiply_Toom3` | Toom-3 (+ optional `Threshold`) |
| `Invalid_Argument` | Domain / overflow errors |

## Limits and caveats

- **Educational sizes** — keep operands $\le$ `Max_Operand_Limbs` limbs so
  schoolbook stays fast and Toom temporaries fit in `Max_Limbs`.
- **Non-negative only** at the public API; signs appear only inside Toom-3
  evaluation / interpolation.
- **One balanced split** (Toom-3 / Toom-3); no asymmetric Toom-$2.5$ / Toom-$4$
  here — those belong with a broader multiplication survey.
- **No** FFT / Schönhage–Strassen / Fürer — upcoming siblings.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Ptoom_cook.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `toom_cook.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
toom_cook.ads
toom_cook.adb
toom_cook.gpr
tests.adb
```

## References

1. [Wikipedia: Toom–Cook multiplication](https://en.wikipedia.org/wiki/Toom–Cook_multiplication)
2. [Wikipedia: Karatsuba algorithm](https://en.wikipedia.org/wiki/Karatsuba_algorithm) (Toom-2)
3. [Wikipedia: Multiplication algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm)
4. Bodrato, M. — Towards optimal Toom–Cook multiplication (evaluation /
   interpolation sequences used above)
