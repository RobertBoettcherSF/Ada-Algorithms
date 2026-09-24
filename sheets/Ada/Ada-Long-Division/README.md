# Long Division — Ada 2023

Educational, self-contained Ada 2023 package for **long division** — the
standard pencil-and-paper algorithm that divides multi-digit non-negative
integers by forming successive partial dividends, choosing each quotient
digit from $\{0,\ldots,9\}$, subtracting the multiple, and bringing down
the next digit. See
[Wikipedia: Long division](https://en.wikipedia.org/wiki/Long_division).

Non-negative integers are stored as little-endian **decimal digit vectors**
(base $B=10$) so each classroom step matches a single digit on the tableau.
**Short division** covers single-digit divisors. An Ada `Long_Integer`
`/`/`rem` oracle and a schoolbook digit multiply check the identity

$$
N = Q\cdot D + R,\qquad 0\le R < D
$$

for magnitudes inside educational bounds.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Newton-Raphson-Division](https://github.com/RobertBoettcherSF/Ada-Newton-Raphson-Division)** — reciprocal Newton, then $Q=N\cdot X$
- **[Ada-Non-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Non-Restoring-Division)** — radix-$2$ non-restoring, digits $\{-1,1\}$
- **[Ada-Restoring-Division](https://github.com/RobertBoettcherSF/Ada-Restoring-Division)** — radix-$2$ restoring, digits $\{0,1\}$
- **[Ada-SRT-Division](https://github.com/RobertBoettcherSF/Ada-SRT-Division)** — radix-$2$ SRT, redundant digits $\{-1,0,1\}$
- **Goldschmidt division** — upcoming
- **Division algorithms survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | `Digit_Vector` base $B=10$ | Little-endian decimal digits; `Max_Limbs=36` |
| **Long division** | `Divide_Long` | Quotient digits in $\{0,\ldots,9\}$ |
| **Short division** | `Divide_Short` | Single digit divisor $1..9$ |
| **Step** | Partial $\leftarrow 10\cdot$Partial $+$ digit | Then max $q$ with $q\cdot D\le$ Partial |
| **Oracle** | `Exact_Divide` / schoolbook | `Long_Integer` `/`/`rem`; $N=QD+R$ |
| **Signed** | Magnitudes + Ada truncating signs | `Divide_Signed` / `Divide_Signed_Values` |
| **Invalid** | `Invalid_Argument` | Divisor $0$; bad strings; underflow |

## Brief history

Related algorithms appear from the 12th century; Al-Samawal worked with
decimal calculations that essentially require long division. The modern
tableau (divisor, dividend under a vinculum, quotient above) became common
after decimal notation for fractions spread in the early modern period;
Henry Briggs popularized a form close to today’s method around 1600. The
abbreviated form for a one-digit divisor is **short division**. Hardware
“slow division” (restoring, non-restoring, SRT) and “fast division”
(Newton–Raphson, Goldschmidt) are different algorithmic families; this
package teaches the hand algorithm on digit arrays.

## Algorithm (this package)

**Goal.** Given non-negative dividend $N$ and nonzero divisor $D$, compute
integers $Q$ and $R$ such that

$$
N = Q\cdot D + R,\qquad 0\le R < D.
$$

**Representation.** Write $N$ and $D$ in base $10$:

$$
N = \sum_{i=0}^{n-1} n_i\, 10^{i},\qquad
D = \sum_{j=0}^{m-1} d_j\, 10^{j},
$$

with digits $n_i,d_j\in\{0,\ldots,9\}$ stored little-endian in a
`Digit_Vector`.

**Long division (digit loop).** Process $N$ from the most significant digit
downward. Maintain a partial remainder $P$, initially $0$. For each next
digit $n_k$:

$$
P \leftarrow 10\, P + n_k.
$$

Choose the largest digit $q\in\{0,\ldots,9\}$ such that

$$
q\cdot D \le P,
$$

append $q$ to the quotient (skipping leading zeros until the first nonzero
$q$), and update

$$
P \leftarrow P - q\cdot D.
$$

When all digits of $N$ are consumed, $Q$ is the collected quotient and
$R=P$ is the remainder.

**Short division.** If $D=d\in\{1,\ldots,9\}$, the same left-to-right pass
uses ordinary digit arithmetic: at each step let
$a=10\cdot r + n_k$, emit $\lfloor a/d\rfloor$, and set $r=a\bmod d$.

**Worked check.** $N=850$, $D=25$:

$$
850 = 34\cdot 25 + 0.
$$

Tableau sketch: $25$ into $85$ gives $3$ ($75$), bring down $0$ $\to 100$,
then $4$ ($100$), remainder $0$.

## API summary

| Symbol | Role |
| --- | --- |
| `Digit_Vector` | Little-endian base-$10$ digit array |
| `Division_Result` | `(Quotient, Remainder)` as `Digit_Vector` |
| `Signed_Division_Result` | `(Quotient, Remainder)` as `Long_Integer` |
| `From_String` / `To_String` | Decimal text $\leftrightarrow$ digits |
| `From_Natural` / `From_Long_Integer` | Scalar constructors (non-negative) |
| `To_Natural` / `To_Long_Integer` | Scalar views (raise if overflow) |
| `Compare` / `Equal` / `Is_Zero` / `Length` | Queries |
| `Add` / `Sub` / `Shift_Limbs` | Digit-vector helpers |
| `Multiply_By_Digit` | $A\cdot q$ for $q\in\{0,\ldots,9\}$ |
| `Multiply_Schoolbook` | $O(n^{2})$ oracle multiply for $N=QD+R$ |
| `Divide_Long(N,D)` | Pencil-and-paper long division |
| `Divide_Short(N,d)` | Short division, digit divisor $1..9$ |
| `Divide_Signed` / `Divide_Signed_Values` | Magnitudes + toward-zero signs |
| `Exact_Divide(N,D)` | Oracle `Long_Integer` `/` and `rem` |
| `Invalid_Argument` | Zero divisor, bad input, underflow |

## Limits and caveats

- **Educational digit cap** — `Max_Limbs=36`; not a production big-int
  library.
- **Domain** — core API is non-negative; signed helpers use magnitudes and
  Ada toward-zero remainder sign.
- **Divisor $0$** — raises `Invalid_Argument`.
- **Oracle** — `Exact_Divide` applies only where values fit in
  `Long_Integer`; larger strings rely on the digit-vector remainder
  identity via schoolbook multiply.
- **No fractional / decimal expansion** — integer quotient and remainder
  only (the Wikipedia “bring down zeros” decimal continuation is out of
  scope).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Plong_division.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `long_division.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
long_division.ads
long_division.adb
long_division.gpr
tests.adb
```

## References

1. [Wikipedia: Long division](https://en.wikipedia.org/wiki/Long_division)
2. [Wikipedia: Division algorithm](https://en.wikipedia.org/wiki/Division_algorithm)
3. [Wikipedia: Short division](https://en.wikipedia.org/wiki/Short_division)
