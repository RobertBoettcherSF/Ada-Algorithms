# Rounding Functions — Ada 2023

Educational, self-contained Ada 2023 package implementing **classic rounding
modes** for $\mathrm{Long\_Float}\to\mathrm{Integer}$ (whole-number modes) and
$\mathrm{Long\_Float}\to\mathrm{Long\_Float}$ (decimal-place helpers). Covers
**directed** rounding — floor, ceiling, truncate / toward zero, away from
zero — and **tie-breaking** nearest modes — half up, half down, half away
from zero, half toward zero, half to even (banker's), and half to odd.
Definitions are taught explicitly (careful with negatives); this is not a
thin wrapper over Ada `'Floor` / `'Rounding` attributes alone.

Based on [Wikipedia: Rounding](https://en.wikipedia.org/wiki/Rounding) and
[Wikipedia: Floor and ceiling functions](https://en.wikipedia.org/wiki/Floor_and_ceiling_functions).
Overview / spreadsheet-style table:
[Rounding functions](https://en.wikipedia.org/wiki/Rounding_functions).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (related numeric helpers):

- **[Ada-Spigot-Algorithm](https://github.com/RobertBoettcherSF/Ada-Spigot-Algorithm)** — digit-by-digit $e$ / $\pi$ remainders
- **Newton’s method (multiplicative inverses)** — upcoming
- **Multiplicative inverse Algorithms** — upcoming
- **Toom–Cook** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Directed** | Floor / Ceiling / Truncate / Away | Toward $-\infty$, $+\infty$, $0$, or $\infty$ |
| **Nearest + ties** | Half-up / down / away / to-zero / even / odd | Exact $.5$ ties for modest magnitudes |
| **Core type** | `Long_Float` → `Integer` | Domain $\|X\|\le\mathrm{Max\_Abs\_Arg}=10^9$ |
| **Decimals** | `Round_To_Decimals(X,N)` | Scale $10^N$, round, scale back; $N\le 9$ |
| **Helpers** | `Frac`, `Floor_Frac`, `Is_Integer`, `Near` | Signed vs unit-interval fraction |
| **Teaching** | Definitions from truncate / floor | Not attribute-only |

## Brief history

Rounding is as old as positional numerals: merchants and surveyors needed
shorter representations; computers inherited the same need under fixed
word sizes. **Directed** modes (floor, ceiling, toward zero) underpin
interval arithmetic and many financial rules. **Round-to-nearest** needs a
**tie-break** when the fractional part is exactly $\tfrac12$; schoolbooks
often use half-away-from-zero, while IEEE 754 default binary floating point
uses **round half to even** (banker's / convergent rounding) to avoid
systematic bias. Famous cautionary tales (e.g. the 1980s Vancouver Stock
Exchange index truncated toward $-\infty$ at each update) show how mode
choice accumulates. This package stays with the classical integer-valued
modes from the Wikipedia articles.

## Algorithm (this package)

### Directed modes

$$
\lfloor x\rfloor=\max\{n\in\mathbb{Z}:n\le x\},\qquad
\lceil x\rceil=\min\{n\in\mathbb{Z}:n\ge x\}
$$

with duality $\lceil x\rceil=-\lfloor -x\rfloor$. Toward zero (truncate) is
$\mathrm{sgn}(x)\,\lfloor |x|\rfloor$; away from zero is
$\mathrm{sgn}(x)\,\lceil |x|\rceil$.

Educational construction from Ada's toward-zero conversion
$T=\mathrm{Truncate}(x)$:

$$
\lfloor x\rfloor=
\begin{cases}
T & x\ge 0\text{ or }x=T\\
T-1 & x<0\text{ and }x\neq T
\end{cases}
\qquad
\lceil x\rceil=
\begin{cases}
T & x\le 0\text{ or }x=T\\
T+1 & x>0\text{ and }x\neq T
\end{cases}
$$

**Worked check.** $\lfloor -23.2\rfloor=-24$, $\lceil -23.7\rceil=-23$,
$\mathrm{Truncate}(-23.7)=-23$.

### Tie-breaking nearest modes

Write $\{x\}=x-\lfloor x\rfloor\in[0,1)$. Ordinary nearest uses
$\lfloor x\rfloor$ when $\{x\}<\tfrac12$ and $\lceil x\rceil$ when
$\{x\}>\tfrac12$. On a half-tie $\{x\}=\tfrac12$:

| Mode | Rule on $.5$ ties | Examples |
| --- | --- | --- |
| Half up | toward $+\infty$: $\lfloor x+\tfrac12\rfloor$ | $2.5\to 3$, $-2.5\to -2$ |
| Half down | toward $-\infty$: $\lceil x-\tfrac12\rceil$ | $2.5\to 2$, $-2.5\to -3$ |
| Half away from $0$ | $\mathrm{sgn}(x)\,\lfloor |x|+\tfrac12\rfloor$ | $2.5\to 3$, $-2.5\to -3$ |
| Half toward $0$ | ties move toward $0$ | $2.5\to 2$, $-2.5\to -2$ |
| Half to even | choose the even neighbour | $2.5\to 2$, $3.5\to 4$ |
| Half to odd | choose the odd neighbour | $2.5\to 3$, $3.5\to 3$ |

Binary IEEE `Long_Float` represents $n+\tfrac12$ exactly for modest
integers $n$, so classroom tie tests are reliable inside
$\mathrm{Max\_Abs\_Arg}$.

### Decimal places

$$
\mathrm{RoundToDecimals}(x,N)=\frac{1}{10^N}\,
\mathrm{RoundHalfAway}\bigl(x\cdot 10^N\bigr)
$$

(and an even-tie sibling). $N\le\mathrm{Max\_Decimals}=9$.

## API summary

| Symbol | Role |
| --- | --- |
| `Max_Abs_Arg` | Domain cap $\|X\|\le 10^9$ for `Integer` results |
| `Max_Decimals` / `Decimal_Count` | $N\in 0..9$ for decimal helpers |
| `Near(A,B[,Tol])` | Absolute tolerance compare (tests) |
| `Sign`, `In_Domain`, `Is_Integer`, `Is_Half_Tie` | Predicates / sign |
| `Frac` | Signed fraction $X-\mathrm{Truncate}(X)$ |
| `Floor_Frac` | Unit interval $\{X\}=X-\lfloor X\rfloor$ |
| `Floor` / `Ceiling` | $\lfloor X\rfloor$ / $\lceil X\rceil$ → `Integer` |
| `Truncate` | Toward zero → `Integer` |
| `Round_Away_From_Zero` | Directed away from $0$ |
| `Round_Half_Up` / `Round_Half_Down` | Ties toward $+\infty$ / $-\infty$ |
| `Round_Half_Away_From_Zero` | School half-away rule |
| `Round_Half_Toward_Zero` | Ties toward $0$ |
| `Round_Half_To_Even` / `Round_Half_To_Odd` | Banker's / odd ties |
| `Round_To_Decimals` / `_Even` | $N$ decimal places → `Long_Float` |
| `Out_Of_Range` / `Invalid_Argument` | Domain / argument errors |

## Limits and caveats

- **Ada `Integer (X)` rounds** — converting `Long_Float` to `Integer`
  does *not* truncate; it rounds. This package uses
  `Long_Float'Truncation` as the toward-zero primitive, then builds
  floor / ceiling / tie modes from the educational definitions above.
- **Educational `Integer` range** — $\|X\|\le 10^9$ leaves headroom so
  floor/ceiling $\pm 1$ adjustments cannot hit `Integer'First`/`Last`.
  Magnitudes near `Integer'Last` are out of scope; raise `Out_Of_Range`.
- **Exact $.5$ ties** — rely on binary-exact half-integers; do not expect
  the same for arbitrary decimal strings that are not dyadic.
- **Not IEEE attribute wrappers** — Ada `'Floor`, `'Ceiling`,
  `'Truncation`, `'Rounding`, `'Unbiased_Rounding` exist; this package
  reimplements the definitions for teaching (and cross-checks them in
  spirit via tests).
- **Idempotence / monotonicity** — as on Wikipedia: rounding to the same
  precision twice is a no-op; modes are piecewise constant and monotonic.
- **Double rounding** — rounding to fine then coarse precision need not
  match one-shot coarse rounding (except directed modes).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Prounding_functions.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `rounding_functions.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
rounding_functions.ads
rounding_functions.adb
rounding_functions.gpr
tests.adb
```

## References

1. [Wikipedia: Rounding](https://en.wikipedia.org/wiki/Rounding)
2. [Wikipedia: Floor and ceiling functions](https://en.wikipedia.org/wiki/Floor_and_ceiling_functions)
3. [Wikipedia: Rounding functions](https://en.wikipedia.org/wiki/Rounding_functions) (overview / spreadsheet link)
4. IEEE 754 — default round-to-nearest, ties to even
5. European Commission — *The Introduction of the Euro and the Rounding of Currency Amounts* (banking half-up note)
6. Siblings: [Ada-Spigot-Algorithm](https://github.com/RobertBoettcherSF/Ada-Spigot-Algorithm);
   upcoming Newton’s method (multiplicative inverses), Multiplicative inverse Algorithms, Toom–Cook
