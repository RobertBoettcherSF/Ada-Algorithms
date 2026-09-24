# Integer factorization — Ada 2023

Educational, self-contained Ada 2023 **survey** of
**integer factorization** — the decomposition of a positive integer into
a product of integers (and, when continued to primes, unique prime
factorization by the fundamental theorem of arithmetic). See
[Wikipedia: Integer factorization](https://en.wikipedia.org/wiki/Integer_factorization).

This package is a **classroom sketch** of classical methods on `U64`:
trial division, Fermat factorization, Pollard's rho, and
congruence-of-squares factor extraction, plus a `Factor` / `Factorize`
driver with documented educational bounds ($N\le 10^{7}$). It is
**not** a production Dixon / QS / ECM / GNFS / RSA-breaking tool.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Related / sibling rows (README links only — **no** package `with`):

- **[Ada-Prime-Factorization](https://github.com/RobertBoettcherSF/Ada-Prime-Factorization)** —
  related survey focused on the “prime factorization algorithm” sheet row
- **[Ada-Congruence-Of-Squares](https://github.com/RobertBoettcherSF/Ada-Congruence-Of-Squares)** —
  CoS predicate / extract + toy search demos
- **[Ada-Dixon](https://github.com/RobertBoettcherSF/Ada-Dixon)** —
  random squares + factor base + GF(2) dependency
- **[Ada-Fermat-Factorization](https://github.com/RobertBoettcherSF/Ada-Fermat-Factorization)** —
  classical $x^{2}-y^{2}$ search near $\sqrt{N}$
- **[Ada-Pollards-Rho](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho)** —
  dedicated Floyd / Brent rho package
- **[Ada-Pollards-P-1](https://github.com/RobertBoettcherSF/Ada-Pollards-P-1)** —
  Pollard's $p-1$ method
- **[Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve)** —
  systematic scan near $\sqrt{N}$ (QS)
- **[Ada-Lenstra-Elliptic-Curve-Factorization](https://github.com/RobertBoettcherSF/Ada-Lenstra-Elliptic-Curve-Factorization)** —
  ECM sketch
- Catalogue / upcoming: **GNFS**, **SNFS**, **Shor** (quantum)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Gcd`, `Floor_Sqrt`, `Ceil_Sqrt` | Self-contained |
| **Trial** | `Is_Prime_Trial`, `Smallest_Prime_Factor`, `Factorize_Trial` | Peel / full list |
| **Fermat** | `Fermat_Factor` / `Fermat_Factor_Pair` | Nearby factors |
| **Rho** | `Pollard_Rho_Factor` | Floyd $x^{2}+c$ |
| **CoS** | `Factor_From_Congruence` / `Factors_From_Congruence` | gcd extract |
| **Driver** | `Factor` / `Factorize` | Trial → Fermat → rho → trial; $N\le 10^{7}$ |
| **Domain** | `Invalid_Argument` | Bad moduli / out-of-range |

## Why factoring matters

Every integer $n>1$ is either prime or a product of smaller integers $>1$.
Continuing until every factor is prime yields the unique prime factorization.
For tiny $n$, trial division up to $\lfloor\sqrt{n}\rfloor$ is enough. For
larger $n$ — especially balanced **semiprimes** used in RSA — no efficient
classical algorithm is known; presumed hardness underpins public-key crypto.

Wikipedia splits methods into **special-purpose** (runtime depends on the
unknown factors / form of $N$: trial, Fermat, Pollard's rho, Pollard's
$p-1$, ECM, SNFS) and **general-purpose** (depends only on the size of
$N$: Dixon, CFRAC, QS, GNFS — the Kraitchik / congruence-of-squares family).
**Shor's algorithm** is the quantum polynomial-time catalogue entry.

## What this package implements

### Trial division

Try candidate divisors $2,3,5,\ldots$ up to $\lfloor\sqrt{N}\rfloor$. The
first hit is a least prime factor; peel powers and continue for a complete
`Factor_List`.

### Fermat factorization

For odd $N$, set $a=\lceil\sqrt{N}\rceil$ and increment $a$ until
$a^{2}-N=b^{2}$ is a perfect square. Then

$$
N=(a-b)(a+b).
$$

Fast when the factors are close (small $a-\lceil\sqrt{N}\rceil$).

### Pollard's rho (Floyd)

Iterate $x\mapsto x^{2}+c\pmod{N}$ with tortoise/hare pointers. A collision
with $\gcd(|x-y|,N)=d$ often yields a nontrivial factor $d$. Expected time
scales like $\sqrt{p}$ for the smallest prime factor $p$.

### Congruence of squares

Given $x^{2}\equiv y^{2}\pmod{N}$ with $x\not\equiv\pm y\pmod{N}$,

$$
\gcd(|x-y|,N)\quad\text{and}\quad\gcd(x+y,N)
$$

are nontrivial factors of $N$. Dixon / QS / NFS **construct** such a pair;
this survey only **extracts** the factor once $(X,Y)$ is known.

### `Factor` / `Factorize`

For $N\le\texttt{Factor\_Max}$ ($10^{7}$): strip tiny trial factors
($\le 1000$), try Fermat (capped steps), try Pollard's rho with a few
$c$ values, then fall back to full trial SPF. `Factorize` peels repeatedly
into an ordered `Factor_List`. Raises `Invalid_Argument` for $N=0$,
$N=1$ (`Factor` only), or $N>\texttt{Factor\_Max}$.

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $15=3\cdot 5$ | trial; CoS $4^{2}\equiv 1$ |
| $35=5\cdot 7$ | Wikipedia CoS $6^{2}\equiv 1^{2}$ |
| $91=7\cdot 13$ | CoS $10^{2}\equiv 3^{2}$ |
| $143=11\cdot 13$ | CoS $12^{2}\equiv 1$ |
| $8051=83\cdot 97$ | rho / Fermat classroom semiprime |
| $455839=599\cdot 761$ | close-factor Fermat |
| $1649=17\cdot 97$ | CoS $114^{2}\equiv 80^{2}$ |
| $84923=163\cdot 521$ | Dixon Wikipedia example (trial / Factor) |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` / `Gcd` / `Floor_Sqrt` / `Ceil_Sqrt` | arithmetic |
| `Is_Perfect_Square` / `Is_Prime_Trial` / `Smallest_Prime_Factor` | trial helpers |
| `Trial_Division_Factor` / `Factorize_Trial` | trial factorization |
| `Fermat_Factor` / `Fermat_Factor_Pair` | Fermat sketch |
| `Pollard_Rho_Factor` | Floyd $x^{2}+c$ sketch |
| `Squares_Congruent` / `Is_Trivial_Pair` / `Is_Nontrivial_Congruence` | CoS predicates |
| `Factor_From_Congruence` / `Factors_From_Congruence` | CoS extract |
| `Factor` / `Factorize` | educational driver for $N\le 10^{7}$ |
| `Invalid_Argument` | domain error |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pinteger_factorization.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates; no `with` of
other Ada-* packages).

## Limits and caveats

- Classroom sketch only — **not** suitable for cryptographic sizes.
- `Factor` / `Factorize` reject $N>\texttt{Factor\_Max}$ ($10^{7}$).
- Fermat is efficient only for **close** factors; use `Max_Steps`.
- Pollard's rho may fail on unlucky `(Seed, C)` (returns $1`); the driver
  retries a few $c$ values then falls back to trial.
- Dixon, QS, ECM, GNFS, Pollard's $p-1$, and Shor are **documented only**
  (see sibling links above) — not implemented here.
- Unconstrained `Factor_List` returns use the secondary stack (fine for
  educational sizes).

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
