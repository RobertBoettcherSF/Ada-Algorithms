# Non-Restoring Division — Ada 2023

Educational, self-contained Ada 2023 package for **non-restoring division** —
the classical radix-$2$ *slow division* variant that forms each quotient
digit from the set $\{-1,1\}$ (no $0$) by shifting the partial remainder
and either **subtracting or adding** the divisor according to the sign of
$R$, with **no restore step**. After the loop, convert the $\{-1,1\}$
digit string to conventional binary and apply a single correction if the
remainder is negative. See
[Non-restoring division](https://en.wikipedia.org/wiki/Non-restoring_division)
(section of
[Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm)).

This package uses **fixed-width signed integers** (default $N=8$ bit
operands), with an explicit bit-level loop so students see the shift,
sign-based add/subtract, digit conversion, and final correction — not a
thin wrapper around Ada `/`. Style matches the series' teaching packages
(restoring division, SRT division); it is **not** a big-integer divider.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Restoring-Division)** — radix-$2$ restoring with digits $\{0,1\}$
- **[Ada-SRT-Division](https://github.com/RobertBoettcherSF/Ada-SRT-Division)** — radix-$2$ SRT with redundant digits $\{-1,0,1\}$
- **Newton–Raphson division** — upcoming
- **Long division** — upcoming
- **Goldschmidt division** — upcoming
- **Division algorithms survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Fixed $N$-bit two's complement | `Operand_Bits=8` |
| **Radix / digits** | Radix-$2$ non-restoring | Quotient digits in $\{-1,1\}$ |
| **Step** | Shift + add or subtract | No restore; decision by $\mathrm{sign}(R)$ |
| **Unsigned core** | `Divide_Non_Restoring_Unsigned` | Digit trace MSB-first |
| **Signed API** | `Divide_Non_Restoring` | Magnitudes + Ada truncating signs |
| **Oracle** | `Divide_Oracle` | Ada `/` and `rem` |
| **Invalid input** | `Invalid_Argument` | $D=0$, range errors, $N_{\min}/(-1)$ |

## Algorithm

Non-restoring division avoids the restore add-back of classical restoring
division by using the digit set $\{-1,1\}$ instead of $\{0,1\}$. Wikipedia
presents the loop (with $R$ and $D$ held at double word width) as:

$$
\begin{cases}
R \leftarrow 2R - D,\quad q_i := +1 & \text{if } R \ge 0, \\
R \leftarrow 2R + D,\quad q_i := -1 & \text{if } R < 0
\end{cases}
$$

for $i = n-1,\ldots,0$. Equivalently, this package's educational core
brings dividend bits $n_i$ MSB-first (same teaching style as the restoring
sibling):

$$
\begin{cases}
R \leftarrow 2R + n_i - D,\quad q_i := +1 & \text{if } R \ge 0, \\
R \leftarrow 2R + n_i + D,\quad q_i := -1 & \text{if } R < 0.
\end{cases}
$$

The raw quotient is then a string of $\{-1,1\}$ digits. Convert to binary:

$$
Q = \sum_{i=0}^{n-1} q_i \cdot 2^{n-1-i}
$$

(equivalently Wikipedia's $P - M$ mask form when $-1$ digits are stored as
zeros). Before correction the remainder satisfies $-D \le R < D$ and $Q$
is always odd. One restoring step after conversion yields a conventional
non-negative remainder:

$$
\text{if } R < 0 \text{ then } Q \leftarrow Q - 1,\ R \leftarrow R + D.
$$

Signed `Divide_Non_Restoring` divides **magnitudes** with the unsigned
core, then applies **Ada truncating** signs: quotient toward zero,
remainder $R = N - Q\cdot D$ with the sign of $N$ when $R\neq 0$ (Ada
`rem`) — same fixup style as the restoring and SRT siblings.

**Identity.** For all supported pairs:

$$
N = Q\cdot D + R, \qquad |R| < |D| \text{ or } R=0.
$$

**Overflow.** The single 8-bit signed case $N=-2^{n-1}$, $D=-1$ has
quotient $2^{n-1}$, which does not fit in $n$-bit two's complement;
both `Divide_Non_Restoring` and `Divide_Oracle` raise `Invalid_Argument`.

## API summary

| Symbol | Role |
| --- | --- |
| `Operand_Bits` | Educational width $n=8$ |
| `Non_Restoring_Operand` | Signed range $[-2^{n-1},2^{n-1}-1]$ |
| `Quotient_Digit` / `Quotient_Digit_Array` | Digits $\{-1,1\}$ |
| `Bit` | Teaching bit $0$/$1$ |
| `Division_Result` | Record `(Quotient, Remainder)` |
| `As_Unsigned` / `Extract_Bit` / `To_Twos_Complement_String` | Bit teaching helpers |
| `Convert_Non_Restoring_Quotient` | $\{-1,1\}$ digit string $\to$ integer |
| `Divide_Non_Restoring_Unsigned` | Unsigned magnitude core + digit trace |
| `Divide_Non_Restoring` | Signed non-restoring (`Non_Restoring_Operand` or `Integer`) |
| `Divide_Oracle` | Ada `/` and `rem` reference |
| `Invalid_Argument` | $D=0$, OOR, or $N_{\min}/(-1)$ |

## Limits and caveats

- **Educational sizes** — default $n=8$ so an exhaustive signed grid
  against the oracle finishes quickly; raise `Operand_Bits` only with
  care for test time (`Divide_Non_Restoring_Unsigned` allows `Width` up to $16$).
- **Radix-2 only** — classical binary non-restoring; higher radices and
  SRT (digits including $0$) are covered by sibling packages.
- **No restore in the loop** — each step is one add/subtract; the single
  post-loop correction is the only “restore-like” step.
- **Not a big-int library** — fixed-width teaching sketch only.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pnon_restoring_division.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`;
`tests.adb` is the sole main unit listed in `non_restoring_division.gpr`.

## References

1. [Non-restoring division](https://en.wikipedia.org/wiki/Non-restoring_division) /
   [Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm) — Wikipedia
2. Shaw, R. F. (1950). *Arithmetic Operations in a Binary Computer*.
   Review of Scientific Instruments.
3. Flynn / Stanford EE486. *Advanced Computer Arithmetic* — division notes.
4. Ercegovac & Lang. *Division and Square Root: Digit-Recurrence
   Algorithms and Implementations*.

## License

Educational use. Part of the RobertBoettcherSF Ada algorithm series.
