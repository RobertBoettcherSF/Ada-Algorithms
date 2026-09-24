# Spigot Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **spigot
algorithms** that emit decimal digits of $e$ and $\pi$ **left-to-right**
with a bounded integer remainder array — no `Float` in the core digit
generation. Caps $N\le\mathrm{Max\_Digits\_E}=80$ and
$N\le\mathrm{Max\_Digits\_Pi}=50$ so schoolbook `Integer` arithmetic stays
small and testable.

Based on [Wikipedia: Spigot algorithm](https://en.wikipedia.org/wiki/Spigot_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (related numeric helpers):

- **[Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting)** — recursive $(P,Q)$ products for $\sum 1/n!$
- **[Ada-Alpha-Max-Plus-Beta-Min](https://github.com/RobertBoettcherSF/Ada-Alpha-Max-Plus-Beta-Min)** — $\alpha\,\mathbf{Max}+\beta\,\mathbf{Min}$ magnitude
- **Rounding functions** — upcoming
- **Newton multiplicative inverse** — upcoming
- **Toom–Cook** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Digits drip left-to-right | Bounded remainders; contrast full-precision series |
| **$e$** | Sale / factorial mixed radix | Radices $2,3,4,\ldots$; init remainders $=1$ |
| **$\pi$** | Rabinowitz–Wagon | Series form with predigit / nines carry buffer |
| **Core type** | `Integer` arrays | No `Float` in digit generation |
| **API** | `Digits_Of_E(N)`, `Digits_Of_Pi(N)` | Digit string (no radix point) or `Digit_Array` |
| **Caps** | $N\le 80$ ($e$), $N\le 50$ ($\pi$) | `Max_Digits_*`; guards for truncation |
| **Oracle** | Known prefixes | Compare against tabulated digits |

## Brief history

Interest in spigot methods grew under extreme memory limits. Sale (1968)
gave a digit-by-digit algorithm for $e$; Abdali (1970) generalised series
whose consecutive-term ratios are rational functions of the index. The
name **spigot algorithm** is associated with Rabinowitz and Wagon’s
bounded algorithm for $\pi$. Streaming variants drop the fixed-ahead
term bound; digit-extraction formulae such as BBP compute a single base-$16$
digit of $\pi$ without the preceding ones. This package stays with the
classic **bounded** remainder-array presentations.

## Algorithm (this package)

### $e$ (Sale / factorial radix)

Write

$$
e = \sum_{k=0}^{\infty}\frac{1}{k!}
= 2 + \sum_{k=2}^{\infty}\frac{1}{k!}
= 2 + \frac{1}{2}\Bigl(1 + \frac{1}{3}\Bigl(1 + \frac{1}{4}\bigl(1+\cdots\bigr)\Bigr)\Bigr).
$$

Maintain remainders $a_j$ ($j=2..M$) in mixed radix $(2,3,\ldots,M)$,
initially $a_j=1$. For each new fractional digit: multiply by $10$, then
renormalise from the right —

$$
x \leftarrow 10\,a_j + q,\qquad
a_j \leftarrow x \bmod j,\qquad
q \leftarrow \lfloor x/j\rfloor
$$

— and emit the outgoing carry $q$ as the next digit after the leading
$2$. Array length $M=N+\mathrm{E\_Term\_Guard}$ keeps early digits exact
under truncation.

### $\pi$ (Rabinowitz–Wagon)

Using the mixed-radix form of

$$
\pi = 2\sum_{i=0}^{\infty}\frac{i!}{(2i+1)!!}
$$

(equivalently the nested product form in their paper), initialise
$a_i=2$ on an array of length $\lfloor 10\cdot T/3\rfloor+1$ for
$T=N+\mathrm{Pi\_Digit\_Guard}$ steps. Each step multiplies by $10$,
reduces with odd denominators $2i+1$, and feeds a **predigit / nines**
buffer so a later carry of $10$ can turn a run of nines into zeros. Extra
guard steps ensure a pending nines-run resolves before returning the
first $N$ digits.

**Worked check.** `Digits_Of_E(5)="27182"`, `Digits_Of_Pi(5)="31415"`.

## API summary

| Symbol | Role |
| --- | --- |
| `Max_Digits_E` / `Max_Digits_Pi` | Hard caps ($80$ / $50$) |
| `E_Term_Guard` / `Pi_Digit_Guard` | Extra terms / steps for exact prefixes |
| `Digit_Value`, `Digit_Array` | Digits $0..9$ as integers |
| `Digits_Of_E(N)` | First $N$ digits of $e$ as `String` |
| `Digits_Of_E_Array(N)` | Same as `Digit_Array` |
| `Digits_Of_Pi(N)` | First $N$ digits of $\pi$ as `String` |
| `Digits_Of_Pi_Array(N)` | Same as `Digit_Array` |
| `Known_E_Prefix` / `Known_Pi_Prefix` | Tabulated oracle prefixes |
| `Matches_Known_E` / `Matches_Known_Pi` | Compare a digit string to the oracle |
| `E_Term_Count` / `Pi_Term_Count` | Remainder-array sizing helpers |
| `Is_Digit_String` | Validate `'0'..'9'` strings |
| `Invalid_Argument` | Raised on $N=0$ or $N>\mathrm{Max\_Digits\_*}$ |

## Limits and caveats

- **Educational `Integer` remainders** — not a multiprecision kernel. Raise
  the caps only with bigger element types and more guard margin.
- **Bounded spigot** — term count is fixed from $N$ in advance (Wikipedia’s
  contrast with unbounded *streaming* spigots).
- **Last-digit sensitivity ($\pi$)** — the classic predigit buffer needs
  `Pi_Digit_Guard` extra steps; do not drop the guard without re-testing
  edges such as $N=32$.
- **No `Float` in the core** — floating conversion is intentionally absent
  from digit generation (contrast binary-splitting’s final `Long_Float`
  ratio).
- **Base $10$ only** — BBP-style hex extraction is out of scope.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pspigot_algorithm.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `spigot_algorithm.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
spigot_algorithm.ads
spigot_algorithm.adb
spigot_algorithm.gpr
tests.adb
```

## References

1. [Wikipedia: Spigot algorithm](https://en.wikipedia.org/wiki/Spigot_algorithm)
2. Sale, A.H.J. — The calculation of $e$ to many significant digits (1968).
3. Rabinowitz, S. & Wagon, S. — A spigot algorithm for the digits of $\pi$
   (*Amer. Math. Monthly*, 1995).
4. Abdali, S.K. — A spigot-style algorithm for series (1970).
5. Arndt, J. & Haenel, C. — $\pi$ unleashed (Springer).
6. Weisstein, E.W. — “Spigot algorithm”, MathWorld.
7. Siblings: [Ada-Binary-Splitting](https://github.com/RobertBoettcherSF/Ada-Binary-Splitting),
   [Ada-Alpha-Max-Plus-Beta-Min](https://github.com/RobertBoettcherSF/Ada-Alpha-Max-Plus-Beta-Min);
   upcoming Rounding, Newton multiplicative inverse, Toom–Cook.
