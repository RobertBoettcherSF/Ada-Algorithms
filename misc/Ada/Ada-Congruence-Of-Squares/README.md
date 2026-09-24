# Congruence of squares — Ada 2023

Educational, self-contained Ada 2023 **classroom sketch** of the
**congruence of squares** integer-factorization primitive — the shared
core behind Fermat, Dixon, the quadratic sieve, and related methods.
See
[Wikipedia: Congruence of squares](https://en.wikipedia.org/wiki/Congruence_of_squares).

This is **not** a production Dixon / QS / NFS implementation. There is
**no** factor-base linear algebra and no sieving — only `U64` helpers,
the CoS predicate / gcd extraction, and tiny Fermat-style /
random-square **search demos** for classroom $N\le 10^{6}$.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Dixon](https://github.com/RobertBoettcherSF/Ada-Dixon)** —
  random squares + factor base + GF(2) dependency → CoS
- **[Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve)** —
  systematic scan near $\sqrt{N}$ (QS optimization of Dixon)
- **[Ada-Fermat-Factorization](https://github.com/RobertBoettcherSF/Ada-Fermat-Factorization)** —
  classical $x^{2}-y^{2}=N$ search near $\sqrt{N}$

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Gcd`, `Floor_Sqrt`, `Ceil_Sqrt` | Self-contained |
| **Trial** | `Is_Prime_Trial`, `Smallest_Prime_Factor` | Peel / fallback |
| **Predicates** | `Squares_Congruent`, `Is_Trivial_Pair`, `Is_Nontrivial_Congruence` | CoS checks |
| **Extract** | `Factor_From_Congruence` / `Factors_From_Congruence` | gcd → factor |
| **Demos** | `Find_Fermat_Style_Congruence`, `Find_Random_Square_Congruence` | $N\le 10^{6}$ |
| **Driver** | `Factor` | CoS search + trial SPF |
| **Domain** | `Invalid_Argument` | Bad moduli / out-of-range |

## Brief derivation

Given a positive integer $n$, Fermat's method looks for

$$
x^{2}-y^{2}=n=(x+y)(x-y).
$$

A weaker (and far more useful) condition is a **congruence of squares**:

$$
x^{2}\equiv y^{2}\pmod{n},\qquad x\not\equiv\pm y\pmod{n}.
$$

From the first congruence,

$$
x^{2}-y^{2}\equiv 0\pmod{n}\implies (x+y)(x-y)\equiv 0\pmod{n},
$$

so $n$ divides the product $(x+y)(x-y)$. The nontriviality condition
$x\not\equiv\pm y\pmod{n}$ guarantees that $n$ divides neither factor
alone. Therefore

$$
\gcd(|x-y|,n)\quad\text{and}\quad\gcd(x+y,n)
$$

are nontrivial factors of $n$ (computable with the Euclidean algorithm).

Most search algorithms only make nontriviality *likely*; a trivial hit
means continue searching. Conversely, finding square roots modulo a
composite is probabilistic-polynomial-time equivalent to factoring, so
any factorizer can also produce a congruence of squares.

### Relation to Fermat / Dixon / QS

| Method | How a congruence is found | Notes |
| --- | --- | --- |
| **Fermat** | Hope $a^{2}-N$ is a perfect square | Equality $x^{2}-y^{2}=N$; fast only for close factors |
| **This package** | Direct CoS extract + toy Fermat / random-square search | Shared primitive, no factor base |
| **Dixon** | Random $a$; collect $B$-smooth $a^{2}\bmod N$; GF(2) dependency | Builds a CoS from many relations |
| **Quadratic sieve** | Systematic $a$ near $\sqrt{N}$ + sieving | Same CoS idea, smaller residues |

Dixon, CFRAC, QS, and NFS all **construct** a congruence of squares
(often via a factor base and linear algebra over $\mathrm{GF}(2)$). This
package isolates the **extract** step and adds only educational
searchers that look for a single pair where $a^{2}\bmod N$ is already a
square.

### Worked Wikipedia examples

**Factorize $35$.** $6^{2}=36\equiv 1=1^{2}\pmod{35}$, and $6\not\equiv\pm 1$, so

$$
\gcd(6-1,35)\cdot\gcd(6+1,35)=5\cdot 7=35.
$$

**Factorize $1649$.** From Dixon-style smooth residues one obtains
$114^{2}\equiv 80^{2}\pmod{1649}$, and

$$
\gcd(114-80,1649)\cdot\gcd(114+80,1649)=17\cdot 97=1649.
$$

## What the code actually does

### Predicates

- `Squares_Congruent(X,Y,N)` — $X^{2}\equiv Y^{2}\pmod{N}$.
- `Is_Trivial_Pair(X,Y,N)` — $X\equiv Y$ or $X\equiv -Y\pmod{N}$.
- `Is_Nontrivial_Congruence(X,Y,N)` — both of the above conditions for a
  usable CoS.

### Extraction

`Factor_From_Congruence(X,Y,N)` returns a nontrivial factor via
$\gcd(|X-Y|,N)$ (falling back to $\gcd(X+Y,N)$), or the sentinel `0`
when the congruence is missing / trivial. `Factors_From_Congruence`
returns the ordered pair $(F_{1},F_{2})$.

### Search demos / `Factor`

- `Find_Fermat_Style_Congruence` walks $a=\lceil\sqrt{N}\rceil,a+1,\ldots$
  and accepts either a classical Fermat hit ($a^{2}-N$ square) or any
  $a^{2}\bmod N$ that is a square forming a nontrivial CoS.
- `Find_Random_Square_Congruence` samples a seeded LCG of $A$ values and
  checks the same square-residue condition.
- `Factor` tries those demos, then trial `Smallest_Prime_Factor`. Even
  $N>2$ returns $2$; primes / failure → `1`. Rejects
  $N>\texttt{Factor\_Search\_Max}$ ($10^{6}$).

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $15=3\cdot 5$ | CoS with $4^{2}\equiv 1$; `Factor` |
| $35=5\cdot 7$ | Wikipedia $6^{2}\equiv 1^{2}$ |
| $91=7\cdot 13$ | CoS with $10^{2}\equiv 3^{2}$ |
| $143=11\cdot 13$ | CoS with $12^{2}\equiv 1$ |
| $1649=17\cdot 97$ | Wikipedia $114^{2}\equiv 80^{2}$ |
| $8051=83\cdot 97$ | close-factor Fermat-style |
| $221=13\cdot 17$ | `Factor` |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` / `Gcd` / `Floor_Sqrt` / `Ceil_Sqrt` | arithmetic |
| `Is_Perfect_Square` / `Is_Prime_Trial` / `Smallest_Prime_Factor` | trial helpers |
| `Squares_Congruent` / `Is_Trivial_Pair` / `Is_Nontrivial_Congruence` | CoS predicates |
| `Factor_From_Congruence` / `Factors_From_Congruence` | gcd extract |
| `Find_Fermat_Style_Congruence` / `Find_Random_Square_Congruence` | toy search |
| `Factor` | educational driver for $N\le 10^{6}$ |
| `Invalid_Argument` | domain error |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pcongruence_of_squares.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Classroom sketch only — **not** suitable for cryptographic sizes.
- `Factor` / search demos reject $N>\texttt{Factor\_Search\_Max}$ ($10^{6}$).
- No factor-base / GF(2) matrix (see **Ada-Dixon** / **Ada-Quadratic-Sieve**
  for that layer).
- Random sampling uses a seeded LCG, not a production RNG.
- Trivial congruences return sentinel `0` — callers must keep searching.

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
