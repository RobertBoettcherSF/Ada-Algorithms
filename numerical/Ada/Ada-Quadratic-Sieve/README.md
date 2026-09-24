# Quadratic sieve (QS) — Ada 2023

Educational, self-contained Ada 2023 **classroom sketch** of the
**quadratic sieve** — a general-purpose integer factorization algorithm
invented by Carl Pomerance (1981). See
[Wikipedia: Quadratic sieve](https://en.wikipedia.org/wiki/Quadratic_sieve).

This is **not** a production QS or MPQS. There is **no** logarithmic
sieving array, no large-prime variants, and no multiple polynomials in
code — only `U64` helpers, a Legendre-filtered factor base, $B$-smoothness
of $Q(x)=x^{2}-N$, and a **congruence-of-squares** core (GF(2) linear
algebra) for tiny $N$.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Trial-Division](https://github.com/RobertBoettcherSF/Ada-Trial-Division)** —
  classical $\sqrt{N}$ factorization / primality
- **[Ada-Special-Number-Field-Sieve](https://github.com/RobertBoettcherSF/Ada-Special-Number-Field-Sieve)** —
  SNFS-like CoS sketch for special-form $N$
- **Next (educational sketch):** **prime factorization algorithm survey**
  (taxonomy sheet across trial / QS / NFS / ECM / …)
- **[Shor’s algorithm](https://github.com/RobertBoettcherSF)** — quantum
  polynomial-time factoring already exists elsewhere (`Ada-Shors-Algorithm`);
  this package stays classical (**skipped** here)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Floor_Sqrt`, `Ceil_Sqrt` | Self-contained |
| **Trial** | `Is_Prime_Trial`, `Smallest_Prime_Factor` | Peel / fallback |
| **Legendre** | `Legendre(A,P)` | Euler criterion; FB filter |
| **Smooth** | `Primes_Up_To`, `QS_Factor_Base`, `Is_B_Smooth` | $(N/p)=1$ primes |
| **Poly** | `Q_Of(X,N)=X^{2}\bmod N` | Single-polynomial QS |
| **CoS core** | `Factor_Via_Congruence_Of_Squares` | GF(2) dependency → factor |
| **Toy QS** | `Factor_QS` | Scan + smooth + CoS for $N\le 10^{7}$ |
| **Domain** | `Invalid_Argument` | Bad moduli / out-of-range |

## QS vs trial division / SNFS / GNFS

| Method | Strength | Heuristic cost (sketch) |
| --- | --- | --- |
| **Trial division** | Tiny $N$; complete factorization | $O(\sqrt{N})$ |
| **Quadratic sieve** | General $N$; historically best under ~100 digits | $L_{N}[1/2,1]=e^{(1+o(1))\sqrt{\ln N\ln\ln N}}$ |
| **SNFS** | Special form $r^{e}\pm s$ | $L_{N}[1/3,(32/9)^{1/3}]$ |
| **GNFS** | General large $N$ (RSA-scale) | $L_{N}[1/3,(64/9)^{1/3}]$ |

QS is still simpler than NFS and remains the fastest practical choice for
many integers below roughly 100 decimal digits. For cryptographic sizes,
GNFS (or SNFS when a sparse polynomial exists) dominates. Trial division
wins only for very small $N$ or when peeling tiny factors first.

Heuristic QS complexity:

$$
e^{(1+o(1))\sqrt{\ln N\ln\ln N}}
= L_{N}\bigl[1/2,1\bigr]
$$

### Basic QS pipeline (this package)

1. **Choose smoothness bound $B$.** Build a factor base of primes $p\le B$
   with Legendre symbol $(N/p)=1$ (so $x^{2}\equiv N\pmod{p}$ is solvable —
   the classical sieving precondition). Always include $2$ for educational
   even smooth values.
2. **Collect relations.** For $x=\lceil\sqrt{N}\rceil+t$ ($t=0,1,2,\ldots$),
   compute $Q(x)=x^{2}\bmod N$ (equals $x^{2}-N$ while $x^{2}<2N$). Keep
   those $Q$ that are $B$-smooth over the factor base.
3. **Linear algebra over $\mathrm{GF}(2)$.** Exponent-parity matrix;
   find a nonempty dependency so every total exponent is even →
   congruence of squares $X^{2}\equiv Y^{2}\pmod{N}$.
4. **GCD.** Return $\gcd(|X-Y|,N)$ when nontrivial.

Production QS replaces the naive scan in step 2 by a **sieve** (accumulate
$\log p$ along arithmetic progressions of roots of $x^{2}\equiv N\pmod{p}$).
This package uses trial smoothness instead — same mathematics, tiny $N$.

### Multiple-polynomial QS (MPQS) — README only

Wikipedia’s **multiple polynomial** variant (MPQS) sieves with several
polynomials $Q_{a,b}(x)=(ax+b)^{2}-N$ (with $a\mid(b^{2}-N)$) so each
polynomial stays small on a short interval. That is ideal for
parallelization and larger $N$. **Not implemented here** — only documented
so the next survey sheet can point at it.

## What the code actually does

### Legendre / factor base

`Legendre(A,P)` uses Euler’s criterion $A^{(P-1)/2}\bmod P$.
`QS_Factor_Base(N,B)` keeps primes $p\le B$ with $(N/p)=1$, plus $2$.

### Smoothness

`Is_B_Smooth(N, Base)` trial-divides by every prime in `Base` and requires
the cofactor to be $1$.

### Congruence of squares

Given relations $(X_{i},Q_{i})$ with $Q_{i}=X_{i}^{2}\bmod N$ $B$-smooth,
build the $\mathrm{GF}(2)$ matrix of exponent parities, find a dependency,
form $X=\prod X_{i}$ and $Y=\prod p^{e/2}$, then return
$\gcd(|X-Y|,N)$ when nontrivial.

### `Factor_QS`

For $N\le\texttt{Factor\_QS\_Max}$ ($10^{7}$): build the QS factor base,
scan $X\ge\lceil\sqrt{N}\rceil$, collect smooth $Q$, run the CoS solver,
and fall back to trial SPF if needed so classroom demos still finish.
Even $N>2$ returns $2$. Primes / failure → `1`. Raises
`Invalid_Argument` for $N=0$ or $N>\texttt{Factor\_QS\_Max}$.

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $15=3\cdot 5$ | CoS with $4^{2}\equiv 1$; `Factor_QS` |
| $91=7\cdot 13$ | CoS with $10^{2}\equiv 9$ |
| $143=11\cdot 13$ | CoS with $12^{2}\equiv 1$ |
| $1649=17\cdot 97$ | Wikipedia product $32\cdot 200=80^{2}$ |
| $8051=83\cdot 97$ | classic QS classroom semiprime ($90^{2}-8051=49$) |
| $455839=599\cdot 761$ | larger educational semiprime |
| $10403=101\cdot 103$ | close primes |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` / `Mod_Pow` / `Gcd` / `Floor_Sqrt` / `Ceil_Sqrt` | arithmetic |
| `Is_Prime_Trial` / `Smallest_Prime_Factor` | trial helpers |
| `Legendre` | $(A/P)\in\{-1,0,+1\}$ |
| `Factor_Base` / `Primes_Up_To` / `QS_Factor_Base` | factor base |
| `Is_B_Smooth` / `Smooth_Exponents` | smoothness |
| `Q_Of` | $X^{2}\bmod N$ |
| `Relation` / `Relation_List` | $(X,Q)$ with $X^{2}\equiv Q\pmod{N}$ |
| `Factor_Via_Congruence_Of_Squares` | GF(2) CoS factor |
| `Factor_QS` | educational QS for $N\le 10^{7}$ |
| `Invalid_Argument` | domain error |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pquadratic_sieve.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Classroom sketch only — **not** suitable for cryptographic sizes.
- `Factor_QS` rejects $N>\texttt{Factor\_QS\_Max}$ ($10^{7}$).
- Factor-base / relation matrices are capped at 64 rows/columns.
- No sieving array, no large-prime variants, no MPQS in code.
- Unconstrained `Factor_Base` / `Relation_List` returns use the secondary
  stack (fine for educational sizes).

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
