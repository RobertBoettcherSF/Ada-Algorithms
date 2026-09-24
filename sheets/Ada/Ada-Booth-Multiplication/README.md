# Booth's Multiplication Algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Booth's multiplication
algorithm** — Andrew Donald Booth's 1950 method for multiplying signed
binary integers in two's complement. See
[Booth's multiplication algorithm](https://en.wikipedia.org/wiki/Booth's_multiplication_algorithm).

This package uses **fixed-width signed integers** (default $N=8$ bit
operands → $2N=16$ bit product), with an explicit bit-pair / accumulator
simulation so students see the $(y_i,y_{i-1})$ decisions — not a thin
wrapper around $X\cdot Y$. Style matches the series' teaching packages; it
is **not** a `Digit_Vector` big-integer multiply (see siblings
Ada-Furer / Ada-Karatsuba for that).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Furer](https://github.com/RobertBoettcherSF/Ada-Furer)** — FFT / NTT teaching sketch for integer multiply
- **[Ada-Karatsuba](https://github.com/RobertBoettcherSF/Ada-Karatsuba)** — classic three-product digit-vector multiply
- **Multiplication algorithms** — upcoming survey
- **Montgomery reduction** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Fixed $N$-bit two's complement | `Operand_Bits=8`, `Product_Bits=16` |
| **Classic Booth** | `Multiply_Booth` | Scan $(y_i,y_{i-1})$; add/sub $X\cdot 2^{i}$ |
| **Radix-4** | `Multiply_Booth_Radix4` | Modified Booth; digits in $\{-2,-1,0,1,2\}$ |
| **Shift-register** | `Multiply_Booth_Shift_Register` | Wikipedia A / S / P loop (+ sign extension) |
| **Oracle** | `Multiply_Oracle` | Built-in `Integer` multiply |
| **Helpers** | `Extract_Bit`, `To_Twos_Complement_String` | Bit-level teaching |
| **Invalid input** | `Invalid_Argument` | Integer overload out of $N$-bit range |

## Algorithm

Booth examines adjacent pairs of bits of the $N$-bit multiplier $Y$ in
signed two's complement, including an implicit bit below the LSB,
$y_{-1}=0$. For each $i=0,\ldots,N-1$:

$$
\begin{aligned}
(y_i,y_{i-1}) &= 00 \text{ or } 11 &&\Rightarrow && \text{no operation}, \\
(y_i,y_{i-1}) &= 01 &&\Rightarrow && P \leftarrow P + X\cdot 2^{i}, \\
(y_i,y_{i-1}) &= 10 &&\Rightarrow && P \leftarrow P - X\cdot 2^{i}.
\end{aligned}
$$

The final accumulator $P$ is the signed product. Equivalently, a string of
$1$s in the multiplier is rewritten as a difference of two powers of two:

$$
(\ldots 0\overbrace{1\ldots 1}^{n}0\ldots)_{2}
\equiv
(\ldots 1\overbrace{0\ldots 0}^{n}0\ldots)_{2}
-
(\ldots 0\overbrace{0\ldots 1}^{n}0\ldots)_{2}.
$$

So a run of ones becomes one subtraction at the low end and one addition at
the high end — fewer adders when ones are clustered.

**Wikipedia worked example.** With $N=4$, $X=3=0011_{2}$, $Y=-4=1100_{2}$:

$$
3\times(-4)=-12=11110100_{2}.
$$

**Most-negative multiplicand.** When $X=-2^{N-1}$, forming $-X$ in $N$ bits
overflows. The shift-register implementation extends A / S / P by one bit
(as on the Wikipedia page) so $-X$ is representable; the bit-pair and
radix-4 forms use a wide `Long_Integer` accumulator and need no special case.

**Radix-4 (modified Booth).** Overlapping triples
$(y_{i+1},y_i,y_{i-1})$ for $i=0,2,\ldots,N-2$ recode the multiplier into
digits $d_k\in\{-2,-1,0,1,2\}$:

$$
P=\sum_{k=0}^{N/2-1} d_k\, X\cdot 2^{2k}.
$$

## API summary

| Symbol | Role |
| --- | --- |
| `Operand_Bits` / `Product_Bits` | $N$ / $2N$ educational widths |
| `Booth_Operand` / `Booth_Product` | Signed ranges $[-2^{N-1},2^{N-1}-1]$ / $[-2^{2N-1},2^{2N-1}-1]$ |
| `As_Unsigned` | Two's-complement bit pattern as $0..2^{W}-1$ |
| `Extract_Bit` | Bit $i$ (LSB $=0$) of a $W$-bit value |
| `To_Twos_Complement_String` | Binary string, MSB on the left |
| `Multiply_Oracle` | Built-in product for comparison |
| `Multiply_Booth` | Classic radix-2 Booth (`Booth_Operand` or `Integer`→`Long_Integer`) |
| `Multiply_Booth_Radix4` | Modified / radix-4 Booth |
| `Multiply_Booth_Shift_Register` | A / S / P arithmetic-right-shift form |
| `Invalid_Argument` | Integer overload outside operand range |

## Limits and caveats

- **Educational sizes** — default $N=8$ so exhaustive $256\times 256$ tests
  finish instantly; raise `Operand_Bits` only with care for test time.
- **Signed two's complement only** at the public API (fixed width).
- **Not a big-int library** — no `Digit_Vector`; for asymptotic integer
  multiply see Ada-Karatsuba / Ada-Furer / Ada-Schonhage-Strassen.
- All three Booth paths are checked against `Multiply_Oracle` for every
  $8$-bit pair.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pbooth_multiplication.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `booth_multiplication.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
booth_multiplication.ads
booth_multiplication.adb
booth_multiplication.gpr
tests.adb
```

Empty GitHub scaffold:
https://github.com/RobertBoettcherSF/Ada-Booth-Multiplication
(do not push from this workspace unless explicitly requested).

## References

1. [Wikipedia: Booth's multiplication algorithm](https://en.wikipedia.org/wiki/Booth's_multiplication_algorithm)
2. [Wikipedia: Two's complement](https://en.wikipedia.org/wiki/Two%27s_complement)
3. [Wikipedia: Multiplication algorithm](https://en.wikipedia.org/wiki/Multiplication_algorithm)
4. Booth, A. D. — A signed binary multiplication technique (QJMM 1951)
5. Patterson & Hennessy — Computer Organization and Design (Booth discussion)
