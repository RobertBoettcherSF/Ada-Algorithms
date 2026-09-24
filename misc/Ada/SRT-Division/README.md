# SRT Division — Ada 2023

Educational, self-contained Ada 2023 package for **SRT division**
(Sweeney–Robertson–Tocher) — a radix-$r$ digit-recurrence divider that
selects **redundant** quotient digits from a small set (here
$\{-1,0,1\}$ for radix $2$) using a P-D style comparison on the
shifted partial remainder and the divisor. See
[SRT division](https://en.wikipedia.org/wiki/SRT_division)
(redirects to
[Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm)).

This package uses **fixed-width signed integers** (default $N=8$ bit
operands), with an explicit digit-recurrence loop so students see
selection, the update $P \leftarrow 2P - q_i D$, and redundant-to-binary
conversion — not a thin wrapper around Ada `/`. Style matches the
series' teaching packages (e.g. Booth multiplication); it is **not** a
big-integer divider.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Addition-Chain-Exponentiation](https://github.com/RobertBoettcherSF/Ada-Addition-Chain-Exponentiation)** — addition-chain powering
- **Restoring division** — upcoming
- **Non-restoring division** — upcoming
- **Newton–Raphson division** — upcoming
- **Long division** — upcoming
- **Goldschmidt division** — upcoming
- **Division algorithms survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Fixed $N$-bit two's complement | `Operand_Bits=8` |
| **Radix / digits** | Radix-$2$ SRT | Quotient digits in $\{-1,0,1\}$ |
| **Selection** | `Select_Quotient_Digit` | Thresholds $\pm\lceil D/2\rceil$ (P-D plot) |
| **Recurrence** | `Divide_SRT_Unsigned` | $P \leftarrow 2P + n_i - q_i D$ |
| **Conversion** | `Convert_Redundant_Quotient` | $Q=\sum q_i 2^{n-1-i}$ (+ correction) |
| **Signed API** | `Divide_SRT` | Magnitudes + Ada truncating signs |
| **Oracle** | `Divide_Oracle` | Ada `/` and `rem` |
| **Invalid input** | `Invalid_Argument` | $D=0$, range errors, $N_{\min}/(-1)$ |

## Algorithm

SRT is named after D. W. Sweeney (IBM), James E. Robertson (Illinois),
and K. D. Tocher (Imperial College), who developed the method
independently around 1957–58. It is similar to non-restoring division,
but uses a **lookup / comparison** on truncated partial remainder and
divisor to choose each quotient digit from a **redundant** digit set.
Because later digits can correct earlier ones, the selection need not be
perfect — which is why a few most-significant bits suffice in hardware
(and why the original Pentium FDIV bug was a faulty table).

For radix $r=2$ with digits $q_i\in\{-1,0,1\}$, each step is:

$$
P \leftarrow 2P + n_i, \qquad
q_i = \mathrm{SEL}(P,D), \qquad
P \leftarrow P - q_i D.
$$

This package's educational selector (full-precision stand-in for a P-D
LUT) uses thresholds at half the positive divisor:

$$
\mathrm{SEL}(P,D)=
\begin{cases}
+1 & \text{if } P \ge \lceil D/2\rceil, \\
-1 & \text{if } P \le -\lceil D/2\rceil, \\
0 & \text{otherwise.}
\end{cases}
$$

After $n$ digits (MSB first), convert the redundant string

$$
Q_{\mathrm{raw}}=\sum_{i=0}^{n-1} q_i\,2^{n-1-i}
$$

and apply a final correction so the residual satisfies $0\le R<D$
(unsigned core). Signed `Divide_SRT` divides magnitudes, then applies
**Ada truncating** signs: quotient toward zero, remainder
$R = N - Q\cdot D$ with the sign of $N$ when $R\neq 0$ (Ada `rem`).

**Identity.** For all supported pairs:

$$
N = Q\cdot D + R, \qquad |R| < |D| \text{ or } R=0.
$$

**Overflow.** The single 8-bit signed case $N=-2^{n-1}$, $D=-1$ has
quotient $2^{n-1}$, which does not fit in $n$-bit two's complement;
both `Divide_SRT` and `Divide_Oracle` raise `Invalid_Argument`.

## API summary

| Symbol | Role |
| --- | --- |
| `Operand_Bits` | Educational width $n=8$ |
| `SRT_Operand` | Signed range $[-2^{n-1},2^{n-1}-1]$ |
| `Quotient_Digit` / `Quotient_Digit_Array` | Redundant digits $\{-1,0,1\}$ |
| `Division_Result` | Record `(Quotient, Remainder)` |
| `As_Unsigned` / `Extract_Bit` / `To_Twos_Complement_String` | Bit teaching helpers |
| `Select_Quotient_Digit` | P-D / threshold digit selection |
| `Convert_Redundant_Quotient` | Redundant string → integer |
| `Divide_SRT_Unsigned` | Unsigned magnitude core + digit trace |
| `Divide_SRT` | Signed SRT (`SRT_Operand` or `Integer`) |
| `Divide_Oracle` | Ada `/` and `rem` reference |
| `Invalid_Argument` | $D=0$, OOR, or $N_{\min}/(-1)$ |

## Limits and caveats

- **Educational sizes** — default $n=8$ so an exhaustive signed grid
  against the oracle finishes quickly; raise `Operand_Bits` only with
  care for test time (`Divide_SRT_Unsigned` allows `Width` up to $16$).
- **Radix-2 only** in this package (radix-4 SRT with
  $\{-2,-1,0,1,2\}$ is the usual hardware step up; same recurrence idea).
- **Full-precision SEL** — hardware SRT truncates $P$ and $D$ into a
  small table; here `Select_Quotient_Digit` compares full values so the
  recurrence stays obviously correct while still using redundant digits.
- **Not a big-int library** — fixed-width teaching sketch only.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Psrt_division.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`;
`tests.adb` is the sole main unit listed in `srt_division.gpr`.

## References

1. [SRT division](https://en.wikipedia.org/wiki/SRT_division) /
   [Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm) — Wikipedia
2. Robertson, J. E. (1958). *A New Class of Digital Division Methods*.
   IRE Transactions on Electronic Computers.
3. Tocher, K. D. (1958). *Techniques of Multiplication and Division for
   Automatic Binary Computers*.
4. Harris, Oberman, Horowitz (1998). *SRT Division: Architectures,
   Models, and Implementations*. Stanford tech report.
5. Ercegovac & Lang. *Division and Square Root: Digit-Recurrence
   Algorithms and Implementations*.

## License

Educational use. Part of the RobertBoettcherSF Ada algorithm series.
