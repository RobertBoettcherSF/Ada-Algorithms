# Pollard's rho algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Pollard's rho** integer
factorization (John Pollard, 1975): iterate a polynomial
$f(x)=x^{2}+c\bmod N$ and recover a factor via $\gcd(|x-y|,N)$ when a
cycle appears modulo an unknown prime factor. See
[Wikipedia: Pollard's rho algorithm](https://en.wikipedia.org/wiki/Pollard's_rho_algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Trial-Division](https://github.com/RobertBoettcherSF/Ada-Trial-Division)** —
  classical $\sqrt{N}$ factorization / primality
- **[Ada-Prime-Factorization](https://github.com/RobertBoettcherSF/Ada-Prime-Factorization)** —
  survey taxonomy (includes a short rho sketch)
- **[Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve)** —
  general-purpose CoS classroom sketch
- **Next (educational sketch):** **Pollard's $p-1$** method
- **Later sibling (do not confuse):** Pollard's rho **for discrete
  logarithms** — same name / cycle idea, different problem (DLP, not
  integer factorization)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Gcd`, `Floor_Sqrt`, `Is_Prime_Trial` | Self-contained |
| **Floyd** | `Factor_Floyd` | Tortoise / hare on $f(x)=x^{2}+c$ |
| **Brent** | `Factor_Brent` | Brent cycle detection variant |
| **Hybrid** | `Factor` | Try several $(c,\mathrm{seed})$; last try Brent |
| **Domain** | `Invalid_Argument` | $N<2$ on factor entry points |

## Algorithm

Given composite $N=pq$ with unknown smallest prime factor $p$, Pollard's
rho builds a pseudorandom sequence $x_{i+1}=f(x_i)\bmod N$ (commonly
$f(x)=x^{2}+1$). The same sequence modulo $p$ has only $p$ residues, so
by the birthday paradox it is expected to cycle after $O(\sqrt{p})$
steps. Floyd's tortoise/hare (or Brent's method) detects a collision
$x\equiv y\pmod{p}$ while $x\not\equiv y\pmod{N}$; then

$$
d=\gcd(|x-y|,N)
$$

is a non-trivial factor with high probability.

Wikipedia's running example: $N=8051$, $f(x)=x^{2}+1$, start $x=y=2$
yields factor $97$ (the cofactor is $83$). Unlucky $(c,\mathrm{seed})$
may return failure ($1$); retry with another polynomial constant or seed.

### Complexity

Expected running time is proportional to the square root of the
**smallest** prime factor $p$:

$$
O(\sqrt{p})
$$

(not $O(\sqrt{N})$). That makes rho a **special-purpose** factoring
method: excellent when $N$ has a small prime factor, weak on balanced
cryptographic semiprimes. Space is tiny (a handful of $U64$ words).

Brent's 1980 cycle-finding variant typically needs fewer evaluations of
$f$ than Floyd for the same detection power; this package exposes both.

## What the code actually does

### Helpers

`Mul_Mod` multiplies via `Unsigned_128` to avoid wraparound.
`Gcd` is ordinary Euclidean. `Is_Prime_Trial` uses a $2/3$ wheel up to
$\lfloor\sqrt{N}\rfloor$.

### `Factor_Floyd`

Classic tortoise one step / hare two steps on $f(x)=x^{2}+C\bmod N$.
Peels $2$ and $3$; returns $N$ for primes; returns a proper divisor or
$1$ (failure / `Max_Steps`).

### `Factor_Brent`

Same $f$, Brent power-of-two backtracks instead of Floyd. Same return
conventions.

### `Factor`

Tries a short menu of $(\mathrm{Seed},C)$ pairs with Floyd, then one
Brent attempt, until a non-trivial factor appears (or $1$).

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $8051$ | $83\times 97$ (Wikipedia) |
| $455839$ | $599\times 761$ |
| primes ($97$, $599$, …) | return $1$ or $N$ |
| even / $\times 3$ | peel $2$ / $3$ |
| small semiprimes | proper divisor via `Factor` |
| $N<2$ | `Invalid_Argument` |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Gcd` | Euclidean gcd |
| `Mul_Mod` | $(A\cdot B)\bmod M$ via 128-bit product |
| `Floor_Sqrt` | $\lfloor\sqrt{N}\rfloor$ |
| `Is_Prime_Trial` | trial primality |
| `Factor_Floyd` | classic Pollard's rho (Floyd) |
| `Factor_Brent` | Brent cycle variant |
| `Factor` | multi-$(c,\mathrm{seed})$ dispatcher |
| `Invalid_Argument` | domain error ($N<2$, `Mul_Mod` with $M=0$) |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Ppollards_rho.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Educational `U64` toy — **not** cryptographic factorization.
- Expected $O(\sqrt{p})$ only in the heuristic / birthday sense; unlucky
  $c$ or seed can fail (sentinel $1$).
- Distinguishes **integer-factorization** rho from Pollard's rho for
  **discrete logarithms** (sibling topic later).
- Next educational row: **Pollard's $p-1$**.

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
