# Multiplicative Inverse Algorithms — Ada 2023

Educational, self-contained Ada 2023 **survey** of algorithms for
**multiplicative inverses** (reciprocals), focusing on the modular and
Newton sketches from
[Wikipedia: Multiplicative inverse § Algorithms](https://en.wikipedia.org/wiki/Multiplicative_inverse#Algorithms),
[Modular multiplicative inverse](https://en.wikipedia.org/wiki/Modular_multiplicative_inverse),
and the
[Extended Euclidean algorithm](https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm).

This package implements:

1. **Extended Euclidean** modular inverse — find $x$ with
   $a x \equiv 1 \pmod{m}$ when $\gcd(a,m)=1$.
2. **Fermat / Euler** inverse for prime modulus —
   $a^{p-2} \bmod p$ via binary modular exponentiation.
3. **Tiny Newton–Raphson real reciprocal** — self-contained Float sketch
   $x\leftarrow x(2-ax)$ (does **not** `with` the sibling Newton package).
4. Explicit **status** when no inverse exists ($\gcd\neq 1$).

Educational `Long_Integer` / `Float`. Keep moduli and bases in a safe
classroom range (`Max_Educational_Modulus`).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages:

- **[Ada-Newton-Multiplicative-Inverse](https://github.com/RobertBoettcherSF/Ada-Newton-Multiplicative-Inverse)** — full Newton–Raphson reciprocal / series inverse (this survey’s Float Newton is a tiny stand-alone sketch; do not `with` the sibling)
- **Toom–Cook** — upcoming
- **Schönhage–Strassen** — upcoming
- **Karatsuba** — upcoming
- **Fürer** — upcoming
- **Booth** — upcoming
- **Multiplication survey** — upcoming
- **Montgomery** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Modular inverse (general)** | Extended Euclidean | Bézout $ax+my=\gcd$; inverse when $\gcd=1$ |
| **Modular inverse (prime $p$)** | Fermat $a^{p-2}\bmod p$ | Binary `Mod_Pow`; compare with EEA |
| **Real reciprocal** | Newton $x\leftarrow x(2-ax)$ | Tiny Float sketch; oracle `Exact_Reciprocal` |
| **No inverse** | `Status = Not_Invertible` | $\gcd(a,m)\neq 1$ or $a\equiv 0\pmod p$ |
| **Invalid input** | `Status = Invalid_Input` | $m\le 1$ / $p\le 1$ |
| **Helpers** | `Gcd`, `Extended_Gcd`, `Is_Prime`, `Mod_Pow` | Teaching / tests |
| **Exceptions** | `Invalid_Argument`, `No_Inverse` | Convenience wrappers only |

## Brief history

Dividing by $b$ is multiplying by the reciprocal $1/b$. For integers
modulo $m$, a multiplicative inverse of $a$ exists precisely when $a$ and
$m$ are coprime; the extended Euclidean algorithm recovers Bézout
coefficients and thus the inverse in $O(\log^2 m)$ arithmetic steps.
When the modulus is a known prime $p$, Fermat’s little theorem supplies
the closed form $a^{p-2}\equiv a^{-1}\pmod p$, evaluated by binary
exponentiation. Over the reals, Newton’s method on $f(x)=1/x-a$ collapses
to the multiply–subtract iteration $x(2-ax)$ used in Newton–Raphson
division hardware and software. This survey packages those three textbook
routes side by side for Ada 2023 study.

## Algorithms (this package)

### Extended Euclidean modular inverse

**Goal.** Given integers $a$ and $m>1$, find $x$ with
$a x \equiv 1 \pmod{m}$, if it exists.

The extended Euclidean algorithm yields integers $x,y$ satisfying Bézout’s
identity

$$
a x + m y = \gcd(a,m).
$$

If $\gcd(a,m)=1$, then $a x \equiv 1 \pmod{m}$, so $x \bmod m$ (normalized
to $\{0,\ldots,m-1\}$) is the modular inverse. If $\gcd\neq 1$, no inverse
exists (`Not_Invertible`).

**Worked check.** $a=3$, $m=7$: $3\cdot 5=15\equiv 1\pmod 7$.
Wikipedia’s $a=15$, $m=34$: $15\cdot 25\equiv 1\pmod{34}$.

### Fermat / Euler inverse (prime modulus)

**Goal.** For prime $p$ and $a\not\equiv 0\pmod p$,

$$
a^{p-2}\equiv a^{-1}\pmod p
$$

by Fermat’s little theorem ($a^{p-1}\equiv 1\pmod p$). Implemented with
binary modular exponentiation (`Mod_Pow`). On composite moduli the same
formula need not yield an inverse; this package verifies
$a\cdot\mathrm{inv}\equiv 1\pmod p$ and reports `Not_Invertible` otherwise.
Prefer EEA for general $m$.

**Worked check.** $a=3$, $p=7$: $3^{5}=243\equiv 5\pmod 7$, and
$3\cdot 5\equiv 1\pmod 7$ — same as EEA.

### Newton real reciprocal (tiny Float sketch)

**Goal.** For nonzero real $a$, compute $x\approx 1/a$ by Newton on
$f(x)=1/x-a$:

$$
x_{n+1}=x_n(2-a x_n).
$$

A simple dyadic seed keeps the sketch self-contained. For a fuller
Newton–Raphson reciprocal / series package see the sibling
**Ada-Newton-Multiplicative-Inverse** (linked above; not imported here).

**Worked check.** $a=17$, seed near $0.1$, iterates toward
$1/17\approx 0.0588$ (Wikipedia Algorithms example).

## API summary

| Symbol | Role |
| --- | --- |
| `Inverse_Result` | `(Value, Status, G)` — modular inverse + gcd |
| `Extended_Gcd_Result` | `(G, X, Y)` — Bézout $A X + B Y = G$ |
| `Reciprocal_Result` | `(Value, Iterations, Status)` — Float Newton |
| `Status_Kind` | `Found`, `Not_Invertible`, `Invalid_Input`, `Converged`, `Bad_Domain`, `Max_Iterations_Reached` |
| `Gcd(A,B)` | Classical Euclidean gcd ($\ge 0$) |
| `Extended_Gcd(A,B)` | Extended Euclidean / Bézout |
| `Inverse_Mod_EEA(A,M)` | Modular inverse via EEA; never raises |
| `Inverse_EEA(A,M)` | Convenience; raises `No_Inverse` / `Invalid_Argument` |
| `Inverse_Mod_Fermat(A,P)` | Fermat inverse for (prime) $P$; never raises |
| `Inverse_Fermat(A,P)` | Convenience; raises on failure |
| `Mod_Pow(Base,Exp,M)` | Binary modular exponentiation |
| `Is_Prime(N)` | Trial-division primality (educational) |
| `Reciprocal_Newton(A,...)` | Tiny Float Newton reciprocal |
| `Reciprocal(A)` / `Exact_Reciprocal(A)` | Convenience / oracle $1/A$ |
| `Is_Modular_Inverse(A,Inv,M)` | Check $A\cdot\mathrm{Inv}\equiv 1\pmod M$ |
| `Near`, `Mod_Nonneg`, `Abs_LI` | Helpers |
| `Invalid_Argument`, `No_Inverse` | Exceptions from convenience APIs |

## Limits and caveats

- **Educational range** — keep $|a|$, $m$, $p$ modest so products fit
  comfortably in `Long_Integer` (see `Max_Educational_Modulus`).
- **Fermat assumes prime $p$** — primality is not proven inside
  `Inverse_Mod_Fermat`; use `Is_Prime` / prefer EEA for general moduli.
- **Float Newton** is a classroom sketch, not a multiprecision or IEEE
  division replacement; the sibling Newton package goes further.
- **No** big-integer, CRT batch inverses, or Montgomery form here —
  those belong to upcoming related packages.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pmultiplicative_inverse_algorithms.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `multiplicative_inverse_algorithms.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
multiplicative_inverse_algorithms.ads
multiplicative_inverse_algorithms.adb
multiplicative_inverse_algorithms.gpr
tests.adb
```

## References

1. [Wikipedia: Multiplicative inverse — Algorithms](https://en.wikipedia.org/wiki/Multiplicative_inverse#Algorithms)
2. [Wikipedia: Modular multiplicative inverse](https://en.wikipedia.org/wiki/Modular_multiplicative_inverse)
3. [Wikipedia: Extended Euclidean algorithm](https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm)
4. [Wikipedia: Fermat's little theorem](https://en.wikipedia.org/wiki/Fermat's_little_theorem)
5. [Wikipedia: Newton’s method — Multiplicative inverses](https://en.wikipedia.org/wiki/Newton's_method#Multiplicative_inverses_of_numbers_and_power_series)
