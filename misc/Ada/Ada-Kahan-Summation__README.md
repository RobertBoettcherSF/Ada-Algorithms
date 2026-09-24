# Kahan Summation — Ada 2023

Educational, self-contained Ada 2023 package implementing the **Kahan
summation algorithm** (compensated summation): a running correction $c$
that recovers low-order bits lost when adding a small $x$ into a large
running sum. Also included: **naïve** left-to-right sum (educational
contrast), **Neumaier**’s improved Kahan–Babuška variant, optional
**pairwise** divide-and-conquer summation, and an online **Accumulator**
(`Add` / `Total`). Cap $n\le 10\,000$; educational `Float`.

Based on [Wikipedia: Kahan summation algorithm](https://en.wikipedia.org/wiki/Kahan_summation_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (upcoming / related numeric helpers):

- **Binary splitting** — upcoming
- **nth root** — upcoming
- **Square roots** — upcoming
- **Alpha max plus beta min** — upcoming
- **Spigot** — upcoming
- **[Ada-Algorithms-For-Calculating-Variance](https://github.com/RobertBoettcherSF/Ada-Algorithms-For-Calculating-Variance)** — Welford / Chan online variance

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Naïve** | $s \leftarrow s + x_i$ | Contrast only; $O(n)$ error growth |
| **Kahan** | Running $c$; $y=x-c$, $t=s+y$, $c=(t-s)-y$ | Compensated sum |
| **Neumaier** | Also when $\|x\|>\|s\|$; apply $c$ once at end | Improves Peters case |
| **Pairwise** | Recursive half-sums | $O(\log n)$ error growth |
| **Accumulator** | Online Kahan `Add` / `Total` | Same recurrence as `Sum_Kahan` |
| **Oracle** | `Long_Float` exact sum in tests | `Abs_Error` / `Abs_Error_Exact` helpers |
| **Cap** | $n\le 10\,000$ | `Max_Length = 10_000` |

## Brief history

William Kahan (1960s) introduced compensated summation to cut the
worst-case roundoff growth of plain summation from proportional to $n$
down to a bound essentially independent of $n$ (for a compensation
variable of sufficient precision). Ivo Babuška developed related ideas
independently (hence **Kahan–Babuška**). A. Neumaier later improved the
update so that a term larger in magnitude than the running sum is handled
symmetrically — recovering cases such as
$[1,+10^{100},1,-10^{100}]$ where classical Kahan returns $0$ but the
true sum is $2$.

## Algorithm (this package)

**Naïve.** $s_0=0$, $s_i = s_{i-1} + x_i$. Fast, but when
$|x_i|\ll |s_{i-1}|$ the low-order bits of $x_i$ are lost to rounding.

**Kahan.** Keep a correction $c$ for bits not assimilated into $s$:

$$
\begin{aligned}
y &\leftarrow x - c \\
t &\leftarrow s + y \\
c &\leftarrow (t - s) - y \\
s &\leftarrow t
\end{aligned}
$$

Algebraically $c$ is zero; in floating point it stores the lost low part
so the next iteration can reinstate it via $y \leftarrow x - c$.

**Neumaier (improved Kahan–Babuška).** Form $t = s + x$; if
$|s|\ge |x|$ accumulate $(s-t)+x$ into $c$, else $(x-t)+s$; finally
return $s+c$ once. Handles the Peters example where $|x|\gg |s|$.

**Pairwise.** Recursively sum left and right halves (leaf: short naïve
block). Same arithmetic count as naïve, better typical error growth
$\sim\log n$.

**Worked decimal intuition** (six-digit float): with $s=10000$ and next
terms $3.14159$, $2.71828$, plain summation rounds to $10005.8$;
compensated summation recovers the correctly rounded $10005.9$.

## API summary

| Symbol | Role |
| --- | --- |
| `Float_Array` | Input terms (`1 .. n`) |
| `Max_Length` | Hard cap ($10\,000$) |
| `Near`, `Abs_Error`, `Abs_Error_Exact` | Numeric helpers (Float / vs `Long_Float` oracle) |
| `Sum_Naive` | Left-to-right sum |
| `Sum_Kahan` | Compensated summation |
| `Sum_Neumaier` | Improved Kahan–Babuška |
| `Sum_Pairwise` | Recursive pairwise sum |
| `Accumulator` | Online Kahan state (`Sum`, $c$, `Count`) |
| `Make_Empty`, `Reset` | Accumulator lifecycle |
| `Add`, `Add_Many` | Feed terms |
| `Total`, `Count`, `Compensation` | Inspect state |
| `Make_Constant` | $n$ copies of a value |
| `Make_Large_Then_Small` | $[L,s,s,\ldots]$ pathological builder |
| `Make_Neumaier_Peters` | $[A,H,A,-H]$ demo |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  multiprecision kernel. Tests use `Long_Float` as an oracle.
- **Cap** — arrays longer than `Max_Length` raise `Invalid_Argument`.
- **Kahan ≠ exact** — still subject to ill-conditioned sums; Neumaier
  helps when a large term arrives mid-stream.
- **Compiler caution** — aggressive FP reassociation can break
  compensated summation; this package writes the textbook parenthesised
  form so $c$ is meaningful.
- **Pairwise leaf** — short blocks use naïve sum to amortise recursion.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pkahan_summation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `kahan_summation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
kahan_summation.ads
kahan_summation.adb
kahan_summation.gpr
tests.adb
```

## References

1. [Wikipedia: Kahan summation algorithm](https://en.wikipedia.org/wiki/Kahan_summation_algorithm)
2. Kahan, W. (1965). Further remarks on reducing truncation errors.
3. Neumaier, A. (1974). Rundungsfehleranalyse einiger Verfahren zur
   Summation endlicher Summen.
4. Siblings upcoming: Binary splitting, nth root, square roots,
   Alpha max plus beta min, Spigot; related:
   [Ada-Algorithms-For-Calculating-Variance](https://github.com/RobertBoettcherSF/Ada-Algorithms-For-Calculating-Variance).
