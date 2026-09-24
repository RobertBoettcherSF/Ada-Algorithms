# Restoring Division — Ada 2023

Educational, self-contained Ada 2023 package for **restoring division** —
the classic radix-$2$ *slow division* algorithm that forms each quotient
bit from the digit set $\{0,1\}$ by a trial subtraction on the shifted
partial remainder, then **restores** the remainder (adds the divisor
back) when the trial goes negative. See
[Restoring division](https://en.wikipedia.org/wiki/Restoring_division)
(section of
[Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm)).

This package uses **fixed-width signed integers** (default $N=8$ bit
operands), with an explicit bit-level loop so students see the shift,
trial subtract, restore decision, and quotient-bit accumulation — not a
thin wrapper around Ada `/`. Style matches the series' teaching packages
(e.g. SRT division, Booth multiplication); it is **not** a big-integer
divider.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-SRT-Division](https://github.com/RobertBoettcherSF/Ada-SRT-Division)** — radix-$2$ SRT with redundant digits $\{-1,0,1\}$
- **Non-restoring division** — upcoming
- **Newton–Raphson division** — upcoming
- **Long division** — upcoming
- **Goldschmidt division** — upcoming
- **Division algorithms survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Fixed $N$-bit two's complement | `Operand_Bits=8` |
| **Radix / digits** | Radix-$2$ restoring | Quotient digits in $\{0,1\}$ |
| **Step** | Shift + trial subtract | Restore if trial $< 0$ |
| **Unsigned core** | `Divide_Restoring_Unsigned` | Bit trace MSB-first |
| **Signed API** | `Divide_Restoring` | Magnitudes + Ada truncating signs |
| **Oracle** | `Divide_Oracle` | Ada `/` and `rem` |
| **Invalid input** | `Invalid_Argument` | $D=0$, range errors, $N_{\min}/(-1)$ |

## Algorithm

Restoring division is the textbook *slow division* method for fixed-point
binary numbers. Wikipedia presents the loop (with $R$ and $D$ held at
double word width) as:

$$
R \leftarrow 2R - D;\quad
\begin{cases}
q_i := 1 & \text{if } R \ge 0, \\
q_i := 0,\ R \leftarrow R + D & \text{if } R < 0
\end{cases}
$$

for $i = n-1,\ldots,0$. Equivalently, this package's educational core
brings dividend bits $n_i$ MSB-first:

$$
R \leftarrow 2R + n_i,\qquad
\mathrm{Trial} \leftarrow R - D,\qquad
\begin{cases}
q_i := 1,\ R := \mathrm{Trial} & \text{if Trial}\ge 0, \\
q_i := 0 & \text{(restore: leave } R\text{ unchanged)}.
\end{cases}
$$

Non-performing restoring division is the same idea with the pre-subtract
value of $2R$ saved so $D$ need not be added back on a failed trial —
this package implements the classical restore form for clarity.

Signed `Divide_Restoring` divides **magnitudes** with the unsigned core,
then applies **Ada truncating** signs: quotient toward zero, remainder
$R = N - Q\cdot D$ with the sign of $N$ when $R\neq 0$ (Ada `rem`) —
same fixup style as the SRT sibling.

**Identity.** For all supported pairs:

$$
N = Q\cdot D + R, \qquad |R| < |D| \text{ or } R=0.
$$

**Overflow.** The single 8-bit signed case $N=-2^{n-1}$, $D=-1$ has
quotient $2^{n-1}$, which does not fit in $n$-bit two's complement;
both `Divide_Restoring` and `Divide_Oracle` raise `Invalid_Argument`.

## API summary

| Symbol | Role |
| --- | --- |
| `Operand_Bits` | Educational width $n=8$ |
| `Restoring_Operand` | Signed range $[-2^{n-1},2^{n-1}-1]$ |
| `Bit` / `Quotient_Bit_Array` | Quotient digits $\{0,1\}$ |
| `Division_Result` | Record `(Quotient, Remainder)` |
| `As_Unsigned` / `Extract_Bit` / `To_Twos_Complement_String` | Bit teaching helpers |
| `Convert_Quotient_Bits` | Bit string $\to$ non-negative integer |
| `Divide_Restoring_Unsigned` | Unsigned magnitude core + bit trace |
| `Divide_Restoring` | Signed restoring (`Restoring_Operand` or `Integer`) |
| `Divide_Oracle` | Ada `/` and `rem` reference |
| `Invalid_Argument` | $D=0$, OOR, or $N_{\min}/(-1)$ |

## Limits and caveats

- **Educational sizes** — default $n=8$ so an exhaustive signed grid
  against the oracle finishes quickly; raise `Operand_Bits` only with
  care for test time (`Divide_Restoring_Unsigned` allows `Width` up to $16$).
- **Radix-2 only** — classical binary restoring; higher radices exist but
  are outside this teaching sketch.
- **Classical restore** — every failed trial explicitly keeps (restores)
  the pre-subtract remainder; non-performing and non-restoring variants
  are covered by sibling packages in the series.
- **Not a big-int library** — fixed-width teaching sketch only.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Prestoring_division.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`;
`tests.adb` is the sole main unit listed in `restoring_division.gpr`.

## References

1. [Restoring division](https://en.wikipedia.org/wiki/Restoring_division) /
   [Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm) — Wikipedia
2. Ercegovac & Lang. *Division and Square Root: Digit-Recurrence
   Algorithms and Implementations*.
3. Flynn / Stanford EE486. *Advanced Computer Arithmetic* — division notes.

## License

Educational use. Part of the RobertBoettcherSF Ada algorithm series.
