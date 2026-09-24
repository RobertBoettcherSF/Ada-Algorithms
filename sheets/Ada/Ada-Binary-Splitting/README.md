# Binary Splitting — Ada 2023

Educational, self-contained Ada 2023 package implementing **binary
splitting** for a concrete rational series: the Taylor partial sums

$$
e_N = \sum_{n=0}^{N} \frac{1}{n!}.
$$

Recursive integer products $(P,Q)$ evaluate the sum as a single exact
ratio $(P+Q)/Q$ (with $Q = N!$), so only one floating conversion is
needed at the end — in contrast to naïve term-by-term `Long_Float`
summation. Cap $N\le \mathrm{Max\_N}=20$ so $N!$ and $e\cdot N!$ fit in
`Long_Integer` (typical 64-bit GNAT).

Based on [Wikipedia: Binary splitting](https://en.wikipedia.org/wiki/Binary_splitting).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (upcoming / related numeric helpers):

- **[Ada-Kahan-Summation](https://github.com/RobertBoettcherSF/Ada-Kahan-Summation)** — compensated summation
- **nth root** — upcoming
- **Square roots** — upcoming
- **Spigot** — upcoming
- **Karatsuba** — upcoming
- **Alpha max plus beta min** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Series** | $e_N=\sum_{n=0}^{N} 1/n!$ | Easy to verify vs known $e$ |
| **Split** | Recursive $(P,Q)$ on $(A,B]$ | Product-tree combine |
| **Iterative** | Left-to-right fold of same recurrence | Oracle for small $N$ |
| **Exact** | Num $=\sum_{k=0}^{N} N!/k!$, Den $=N!$ | Integer, no rounding |
| **Naïve** | Term-by-term `Long_Float` | Educational contrast |
| **Cap** | $N\le 20$ | `Max_N`; intermediates in `Long_Integer` |

## Brief history

Binary splitting (Haible–Papanikolaou, Chudnovsky, Gourdon–Sebah, and
others) speeds evaluation of hypergeometric and related rational series
by replacing many full-precision divisions with a divide-and-conquer
tree of integer multiplications, followed by **one** final division at
target precision. Asymptotic gains appear when fast multiplication
(Toom–Cook, Schönhage–Strassen, …) is used; with schoolbook $O(n^2)$
multiplication the method may not win, but the structure — and the
elimination of intermediate rounding — remains pedagogically valuable.

## Algorithm (this package)

**Goal.** For integers $0\le A\le B\le\mathrm{Max\_N}$, compute

$$
Q(A,B)=\frac{B!}{A!},\qquad
P(A,B)=\sum_{j=A+1}^{B}\frac{B!}{j!}
$$

(with $P(A,A)=0$, $Q(A,A)=1$), so that

$$
\frac{P(A,B)+Q(A,B)}{Q(A,B)}
=\sum_{n=A}^{B}\frac{A!}{n!}.
$$

In particular $A=0$ yields the partial sum $e_B=(P+Q)/Q$.

**Base cases.**

- Empty: $A=B$ $\Rightarrow$ $(P,Q)=(0,1)$.
- Single: $B=A+1$ $\Rightarrow$ $(P,Q)=(1,B)$.

**Combine.** With $m=\lfloor(A+B)/2\rfloor$, left $(P_L,Q_L)=P,Q(A,m)$ and
right $(P_R,Q_R)=P,Q(m,B)$:

$$
\begin{aligned}
Q(A,B) &= Q_L\cdot Q_R,\\
P(A,B) &= P_L\cdot Q_R + P_R.
\end{aligned}
$$

This is the Wikipedia left/right recurrence specialised to the factorial
product tree for $\sum 1/n!$ (the general rational series uses the same
tree shape with $P\leftarrow P_L Q_R+P_R Q_L$ when term numerators vary).

**Worked check.** $B=3$: recursion gives $(P,Q)=(10,6)$, so
$e_3=(10+6)/6=8/3=1+1+1/2+1/6$.

## API summary

| Symbol | Role |
| --- | --- |
| `Max_N` | Hard cap ($20$); $N!$ fits in `Long_Integer` |
| `Split_Result` | Record `(P, Q)` |
| `Binary_Split(A,B)` | Recursive product-tree $(P,Q)$ on $(A,B]$ |
| `Binary_Split_Iterative(A,B)` | Same $(P,Q)$ by iterative fold |
| `Exact_Numerator(N)` | $\sum_{k=0}^{N} N!/k!$ |
| `Exact_Denominator(N)` | $N!$ |
| `Approximate_E(N)` | `Long_Float` value of $e_N=(P+Q)/Q$ |
| `Sum_Naive_Float(N)` | Term-by-term `Long_Float` sum of $1/n!$ |
| `Ratio`, `Partial_Sum` | $P/Q$ and $(P+Q)/Q$ as `Long_Float` |
| `Factorial(N)` | Bounded $N!$ helper |
| `Near`, `Abs_Error` | Numeric helpers |
| `Invalid_Argument` | Raised on $A>B$ or $B>\mathrm{Max\_N}$ |

## Limits and caveats

- **Educational `Long_Integer`** — not a multiprecision kernel. For
  $N>\mathrm{Max\_N}$ intermediates overflow; raise the cap only with a
  big-integer type.
- **Cap** — `Max_N = 20` on 64-bit GNAT (`Long_Integer'Last =
  2^{63}-1`). Documented in the spec; `e\cdot 20!\approx 6.61\times 10^{18}`.
- **Final ratio in `Long_Float`** — exact integers are converted once;
  naïve summation accumulates rounding each step (still excellent for
  $N\le 20$ in double precision).
- **Speed** — with schoolbook multiplication this package prioritises
  clarity over asymptotics; production binary splitting pairs the tree
  with fast multiply and GCD content removal.
- **Series family** — fixed to $1/n!$ for verifiability; the same
  combine pattern extends to hypergeometric terms $p_n/q_n$.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pbinary_splitting.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `binary_splitting.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
binary_splitting.ads
binary_splitting.adb
binary_splitting.gpr
tests.adb
```

## References

1. [Wikipedia: Binary splitting](https://en.wikipedia.org/wiki/Binary_splitting)
2. Gourdon, X. & Sebah, P. — Binary splitting method.
3. Haible, B. & Papanikolaou, T. — Fast multiprecision evaluation of
   series of rational numbers (CLN).
4. Chudnovsky, D.V. & Chudnovsky, G.V. — Computer algebra in the service
   of mathematical physics and number theory.
5. Siblings: [Ada-Kahan-Summation](https://github.com/RobertBoettcherSF/Ada-Kahan-Summation);
   upcoming nth root, square roots, Spigot, Karatsuba.
