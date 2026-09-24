# Dixon's factorization method — Ada 2023

Educational, self-contained Ada 2023 **classroom sketch** of
**Dixon's factorization method** (also Dixon's *random squares* method) —
the prototypical factor-base integer factorization algorithm, published by
John D. Dixon in 1981. See
[Wikipedia: Dixon's factorization method](https://en.wikipedia.org/wiki/Dixon's_factorization_method).

This is **not** a production Dixon / QS / NFS implementation. There is
**no** sieving array and no large-prime variants — only `U64` helpers, a
plain prime factor base, $B$-smoothness of random $a^{2}\bmod N$, and a
**congruence-of-squares** core (GF(2) linear algebra) for tiny $N$.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve)** —
  systematic scan near $\sqrt{N}$ (QS optimization of Dixon)
- **[Ada-Fermat-Factorization](https://github.com/RobertBoettcherSF/Ada-Fermat-Factorization)** —
  classical $x^{2}-y^{2}$ search near $\sqrt{N}$
- **Next (educational sketch):** **Congruence of squares** — shared CoS /
  GF(2) dependency core across Dixon / QS / SNFS-style sketches

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Floor_Sqrt` | Self-contained |
| **Trial** | `Is_Prime_Trial`, `Smallest_Prime_Factor` | Peel / fallback |
| **Smooth** | `Primes_Up_To`, `Dixon_Factor_Base`, `Is_B_Smooth` | All primes $\le B$ |
| **CoS core** | `Factor_Via_Congruence_Of_Squares` | GF(2) dependency → factor |
| **Toy Dixon** | `Factor_Dixon` / `Factor` | Random $a$ + smooth + CoS for $N\le 10^{7}$ |
| **Domain** | `Invalid_Argument` | Bad moduli / out-of-range |

## Dixon vs Quadratic Sieve vs Fermat

| Method | How $a$ is chosen | Smooth target | Notes |
| --- | --- | --- | --- |
| **Fermat** | Near $\lceil\sqrt{N}\rceil$ | Hope $a^{2}-N$ is a perfect square | Fast only for close factors |
| **Dixon (this package)** | **Random** $a\in\{1,\ldots,N-1\}$ | $a^{2}\bmod N$ is $B$-smooth | Prototypical factor-base method; rigorous complexity |
| **Quadratic sieve** | **Systematic** $a=\lceil\sqrt{N}\rceil+t$ | Same CoS idea, smaller residues | Optimization of Dixon; sieves $\log p$ |

Dixon replaces Fermat's "is a perfect square?" with the much weaker
"is $B$-smooth over a fixed factor base?". Once enough smooth relations
exist, linear algebra over $\mathrm{GF}(2)$ builds a congruence of squares
$x^{2}\equiv y^{2}\pmod{N}$, and $\gcd(|x-y|,N)$ may split $N$.

Heuristic / proven Dixon complexity (Wikipedia / Dixon 1981):

$$
O\Bigl(\exp\bigl(2\sqrt{2}\,\sqrt{\ln n\ln\ln n}\bigr)\Bigr)
= L_{n}\bigl[1/2,\,2\sqrt{2}\bigr]
$$

QS improves the constant by keeping residues small (systematic $a$ near
$\sqrt{N}$) and by sieving; this package keeps Dixon's **random** sampling
explicit so students can contrast the two.

### Basic Dixon pipeline (this package)

1. **Choose smoothness bound $B$.** Factor base = all primes $p\le B$
   (no Legendre filter — contrast QS).
2. **Collect relations.** Sample pseudo-random $a$; compute
   $b=a^{2}\bmod N$. Keep those $b$ that are $B$-smooth.
3. **Linear algebra over $\mathrm{GF}(2)$.** Exponent-parity matrix;
   find a nonempty dependency so every total exponent is even →
   congruence of squares $x^{2}\equiv y^{2}\pmod{N}$.
4. **GCD.** Return $\gcd(|x-y|,N)$ when nontrivial.

### Worked Wikipedia sketch ($N=84923$)

With factor base $\{2,3,5,7\}$, the smooth residues

$$
513^{2}\equiv 8400=2^{4}\cdot 3\cdot 5^{2}\cdot 7,\qquad
537^{2}\equiv 33600=2^{6}\cdot 3\cdot 5^{2}\cdot 7
\pmod{84923}
$$

combine (equal parity vectors) to $x=513\cdot 537$, $y=2^{5}\cdot 3\cdot 5^{2}\cdot 7$,
and $\gcd(x-y,N)=163$ (or $\gcd(x+y,N)=521$), so $84923=163\cdot 521$.

## What the code actually does

### Factor base / smoothness

`Dixon_Factor_Base(B)` is `Primes_Up_To(B)`.
`Is_B_Smooth(N, Base)` trial-divides by every prime in `Base` and requires
the cofactor to be $1$.

### Congruence of squares

Given relations $(A_{i},B_{i})$ with $B_{i}=A_{i}^{2}\bmod N$ $B$-smooth,
build the $\mathrm{GF}(2)$ matrix of exponent parities, find a dependency,
form $X=\prod A_{i}$ and $Y=\prod p^{e/2}$, then return
$\gcd(|X-Y|,N)$ when nontrivial.

### `Factor_Dixon` / `Factor`

For $N\le\texttt{Factor\_Dixon\_Max}$ ($10^{7}$): build the Dixon factor
base, sample a seeded LCG of $A$ values, collect smooth $B=A^{2}\bmod N$,
run the CoS solver, and fall back to trial SPF if needed so classroom
demos still finish. Even $N>2$ returns $2$. Primes / failure → `1`.
Raises `Invalid_Argument` for $N=0$ or $N>\texttt{Factor\_Dixon\_Max}$.
`Factor` is an alias of `Factor_Dixon`.

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $15=3\cdot 5$ | CoS with $4^{2}\equiv 1$; `Factor_Dixon` |
| $91=7\cdot 13$ | CoS with $10^{2}\equiv 9$ |
| $143=11\cdot 13$ | CoS with $12^{2}\equiv 1$ |
| $8051=83\cdot 97$ | classic classroom semiprime |
| $84923=163\cdot 521$ | Wikipedia Dixon step-by-step ($513$, $537$) |
| $1649=17\cdot 97$ | product of smooth residues |
| $455839=599\cdot 761$ | larger educational semiprime |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` / `Mod_Pow` / `Gcd` / `Floor_Sqrt` | arithmetic |
| `Is_Prime_Trial` / `Smallest_Prime_Factor` | trial helpers |
| `Factor_Base` / `Primes_Up_To` / `Dixon_Factor_Base` | factor base |
| `Is_B_Smooth` / `Smooth_Exponents` | smoothness |
| `Relation` / `Relation_List` | $(A,B)$ with $A^{2}\equiv B\pmod{N}$ |
| `Factor_Via_Congruence_Of_Squares` | GF(2) CoS factor |
| `Factor_Dixon` / `Factor` | educational Dixon for $N\le 10^{7}$ |
| `Invalid_Argument` | domain error |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pdixon.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Classroom sketch only — **not** suitable for cryptographic sizes.
- `Factor_Dixon` rejects $N>\texttt{Factor\_Dixon\_Max}$ ($10^{7}$).
- Factor-base / relation matrices are capped at 64 rows/columns.
- Random sampling (seeded LCG), not a production sieve.
- Unconstrained `Factor_Base` / `Relation_List` returns use the secondary
  stack (fine for educational sizes).

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
