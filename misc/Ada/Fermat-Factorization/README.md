# Fermat's factorization method — Ada 2023

Educational, self-contained Ada 2023 package for **Fermat's factorization
method** (Pierre de Fermat): represent an odd integer as a difference of
squares $N=a^{2}-b^{2}=(a-b)(a+b)$. Start from $a=\lceil\sqrt{N}\rceil$ and
increment until $a^{2}-N$ is square. See
[Wikipedia: Fermat's factorization method](https://en.wikipedia.org/wiki/Fermat's_factorization_method).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Trial-Division](https://github.com/RobertBoettcherSF/Ada-Trial-Division)** —
  classical $\sqrt{N}$ factorization / primality
- **[Ada-Prime-Factorization](https://github.com/RobertBoettcherSF/Ada-Prime-Factorization)** —
  survey taxonomy (includes a short Fermat sketch)
- **[Ada-Pollards-Rho](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho)** —
  special-purpose when a small prime factor exists
- **[Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve)** —
  general-purpose congruence-of-squares classroom sketch
- **Next (educational sketch):** **Dixon's algorithm**

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Gcd`, `Floor_Sqrt`, `Ceil_Sqrt`, `Is_Perfect_Square`, `Is_Prime_Trial` | Self-contained |
| **Core** | `Factor` → `Factor_Pair` | Classic Fermat $a:=\lceil\sqrt{N}\rceil$ loop |
| **Domain** | `Invalid_Argument` | $N<2$; even $N>2$ peeled as $(2,N/2)$ |

## Algorithm

Every odd $N$ can be written

$$
N=a^{2}-b^{2}=(a-b)(a+b).
$$

If $N=cd$ with $c\le d$ both odd, then

$$
a=\frac{c+d}{2},\qquad b=\frac{d-c}{2}.
$$

Fermat searches upward from $a=\lceil\sqrt{N}\rceil$ until $a^{2}-N=b^{2}$ is a
perfect square, then returns the factors $a\pm b$.

Wikipedia's running example: $N=5959$, first $a=78$, after a few increments
$a=80$, $b=21$, factors $59\times 101$.

### Complexity

The number of steps is roughly $(c+d)/2-\sqrt{N}$, i.e. proportional to how
**far apart** the factors are. When $c\approx d$ (close factors / $N$ near a
square) Fermat is extremely fast — often a handful of increments. In the
worst case (a tiny factor) it can be slower than trial division. Space is
$O(1)$.

## What the code actually does

### Helpers

`Floor_Sqrt` / `Ceil_Sqrt` are overflow-safe binary searches (no `Float`).
`Is_Perfect_Square` checks $r^{2}=N$. `Gcd` is ordinary Euclidean.
`Is_Prime_Trial` uses a $2/3$ wheel up to $\lfloor\sqrt{N}\rfloor$.

### `Factor`

1. $N<2$ → `Invalid_Argument`.
2. Even $N=2$ → $(1,2)$; even $N>2$ → $(2,N/2)$ (Fermat needs odd $N$).
3. Perfect square → $(\sqrt{N},\sqrt{N})$.
4. Else classic loop: $a:=\lceil\sqrt{N}\rceil$; while $a^{2}-N$ is not square,
   $a:=a+1$ (capped by `Max_Steps`); return $(a-b,a+b)$.
5. Exhaustion → $(0,0)$ failure sentinel. A prime eventually yields $(1,N)$
   after $\sim(N-1)/2$ steps.

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $5959$ | $59\times 101$ (Wikipedia) |
| $455839$ | $599\times 761$ |
| $8051$ | $83\times 97$ |
| $10007\times 10009$ | close factors (fast) |
| $2345678901$ | odd composite split |
| primes ($3$, $97$, …) | $(1,N)$ with enough steps |
| even / squares | peel $2$ / $(\sqrt{N},\sqrt{N})$ |
| $N<2$ | `Invalid_Argument` |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Factor_Pair` | record `F1`, `F2` |
| `Gcd` | Euclidean gcd |
| `Floor_Sqrt` | $\lfloor\sqrt{N}\rfloor$ |
| `Ceil_Sqrt` | $\lceil\sqrt{N}\rceil$ |
| `Is_Perfect_Square` | $N$ is a square? |
| `Is_Prime_Trial` | trial primality |
| `Factor` | Fermat → `Factor_Pair` |
| `Invalid_Argument` | domain error ($N<2$) |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pfermat_factorization.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Educational `U64` toy — **not** cryptographic factorization.
- Special-purpose: excellent for **close** factors; weak when a factor is
  tiny relative to $N$.
- Failure sentinel $(0,0)$ on `Max_Steps` exhaustion (primes need a large
  budget to reach the trivial $1\times N$ split).
- Next educational row: **Dixon's algorithm** (random congruence of
  squares → QS / NFS family).

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
