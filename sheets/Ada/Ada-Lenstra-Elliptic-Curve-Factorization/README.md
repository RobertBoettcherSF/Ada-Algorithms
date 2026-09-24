# Lenstra elliptic-curve factorization (ECM) — Ada 2023

Educational, self-contained Ada 2023 package for **Lenstra elliptic-curve
factorization** (Hendrik Lenstra, 1987): a special-purpose algebraic-group
method that finds a prime factor $p$ of $N$ when the order of a random
elliptic curve modulo $p$ is $B$-smooth. See
[Wikipedia: Lenstra elliptic-curve factorization](https://en.wikipedia.org/wiki/Lenstra_elliptic_curve_factorization).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Pollards-P-1](https://github.com/RobertBoettcherSF/Ada-Pollards-P-1)** —
  algebraic-group method on $(\mathbb{Z}/p\mathbb{Z})^{\times}$ (needs smooth $p-1$)
- **[Ada-Pollards-Rho](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho)** —
  birthday / cycle factorization
- **[Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve)** —
  general-purpose CoS classroom sketch
- **Next (general-purpose):** **GNFS** (General Number Field Sieve) — README pointer only

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Gcd`, `Mul_Mod`, `Add_Mod`, `Sub_Mod`, `Try_Mod_Inv`, `Floor_Sqrt`, `Is_Prime_Trial`, `Primes_Up_To` | Self-contained |
| **Curve** | Affine `Point` + `Infinity`; short Weierstrass `Curve` | Over $\mathbb{Z}/N\mathbb{Z}$ |
| **Group law** | `Add`, `Double`, `Scalar_Mult` | Fail → `Factor_Found` via gcd |
| **Stage 1** | `Factor_ECM_Stage1` / `ECM_Stage1_Once` | $k=\operatorname{lcm}(1..B)$ |
| **Domain** | `Invalid_Argument` | $N<2$, $B<2$, `Curves=0`, $M=0$ |

## Algorithm

Pick a random elliptic curve

$$
y^{2}=x^{3}+ax+b\pmod{N}
$$

together with a point $P=(x_{0},y_{0})$ on it (choose $a,x_{0},y_{0}$ at random
and set $b=y_{0}^{2}-x_{0}^{3}-ax_{0}$). Compute $k\cdot P$ on the curve
modulo $N$, where

$$
k=\operatorname{lcm}(1,2,\ldots,B)=\prod_{q\le B}q^{\lfloor\log_{q}B\rfloor}.
$$

Elliptic-curve addition needs a modular slope $u/v$, hence an inverse of $v$
modulo $N$. If $\gcd(v,N)=d$ with $1<d<N$, addition fails — and $d$ is a
**nontrivial factor** of $N$.

This succeeds when, for some prime factor $p\mid N$, the group order
$\#E(\mathbb{F}_{p})$ is **$B$-powersmooth** (so $k\cdot P\equiv\mathcal{O}\pmod{p}$
while the same computation modulo another factor $q$ of $N$ does not hit
infinity at the same step). Heuristically one tries many random curves until
some curve has smooth order modulo $p$.

### Contrast with $p-1$, rho, QS

| Method | Group / idea | Best when |
| --- | --- | --- |
| **Pollard's $p-1$** | $(\mathbb{Z}/p\mathbb{Z})^{\times}$ | $p-1$ is smooth |
| **Pollard's rho** | birthday collision in a poly walk | smallest $p$ not too large ($\sim\sqrt{p}$) |
| **ECM (this package)** | $E(\mathbb{F}_{p})$ for a *random* curve | some curve order is smooth (many tries) |
| **Quadratic sieve** | congruence of squares | general-purpose mid-size $N$ |
| **GNFS** | number-field sieving | largest general-purpose $N$ |

ECM improves on $p-1$ because you are not stuck with a single group of order
$p-1$: each new curve gives a fresh chance at a smooth group order near $p$.
Runtime is dominated by the **size of the smallest factor** $p$, not by $N$ —
so ECM is still the method of choice for stripping medium factors (tens of
digits in production ECM) before handing a hard cofactor to QS / GNFS.

### Complexity

Heuristic Stage-1 cost per curve is on the order of

$$
O\bigl(B\log B\cdot M(N)\bigr)
$$

bit operations for modular arithmetic cost $M(N)$, times the number of curves
tried. Optimal $B$ grows with the target factor size (Hasse: group order lies
in $[p+1-2\sqrt{p},\,p+1+2\sqrt{p}]$).

### Stage 2 (README only)

Production ECM continues with a **Stage 2**: after computing $Q=[k]P$ with
$k=\operatorname{lcm}(1..B_{1})$, continue so that a single large prime factor
of $\#E(\mathbb{F}_{p})$ up to $B_{2}\gg B_{1}$ still yields a split (baby-step
giant-step / prime pairing / polynomial variants; see GMP-ECM). This
educational package implements **Stage 1 only**.

## What the code actually does

### Helpers

`Mul_Mod` multiplies via `Unsigned_128`. `Add_Mod` / `Sub_Mod` are overflow-safe
residue ops. `Try_Mod_Inv` runs extended Euclid and returns `Factor_Found`
when $\gcd(A,M)>1$. `Is_Prime_Trial` uses a $2/3$ wheel. `Primes_Up_To`
returns primes $\le$ Limit by trial (educational sizes).

### Curve law

`Double` / `Add` implement the affine short-Weierstrass group law. A
non-invertible denominator becomes `Op_Result'(Factor_Found, Factor => d)`.
`Scalar_Mult` is binary double-and-add and propagates `Factor_Found`.

### `ECM_Stage1_Once` / `Factor_ECM_Stage1`

For each prime $q\le B$, raise the running point to $q^{e}$ (largest power
$\le B$) via `Scalar_Mult`. Optional early split via
$\gcd(4a^{3}+27b^{2},\,N)$. The dispatcher draws random $(a,x_{0},y_{0})$ from a
deterministic LCG seeded by `Seed`, builds $b$, and retries up to `Curves`
times. Even $N\to 2$; primes $\to 1$; failure $\to 1$.

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $35=5\times 7$ | tiny semiprime |
| $91=7\times 13$ | tiny semiprime |
| $8051=83\times 97$ | classic classroom ECM example |
| $455839=599\times 761$ | larger educational semiprime |
| $143$, $187$, $1147$, $2047$, … | more smooth-order-friendly composites |
| primes ($97$, $101$, $7919$, …) | return $1$ |
| even | peel $2$ |
| $N<2$, $B<2$, `Curves=0` | `Invalid_Argument` |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Point` | affine $(X,Y)$ + `Infinity` flag |
| `Curve` | short Weierstrass $(A,B)$ over modulus $N$ |
| `Op_Result` / `Inv_Result` | `Ok` vs `Factor_Found` outcomes |
| `Gcd` | Euclidean gcd |
| `Mul_Mod` / `Add_Mod` / `Sub_Mod` | residue arithmetic |
| `Try_Mod_Inv` | inverse or gcd factor |
| `Floor_Sqrt` | $\lfloor\sqrt{N}\rfloor$ |
| `Is_Prime_Trial` | trial primality |
| `Primes_Up_To` | primes $\le$ Limit |
| `Double` / `Add` / `Scalar_Mult` | curve group law mod $N$ |
| `ECM_Stage1_Once` | Stage 1 on one curve / point |
| `Factor_ECM_Stage1` | multi-curve Stage-1 ECM |
| `Factor` | convenience wrapper (default $B$, curves) |
| `Default_B` / `Default_Curves` | educational defaults ($50$ / $40$) |
| `Invalid_Argument` | domain error |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Plenstra_elliptic_curve_factorization.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Educational `U64` toy — **not** cryptographic / GMP-ECM production code.
- Stage 1 only; no Montgomery curves, no Stage 2, no projective speed tricks
  beyond the pedagogical affine law.
- Keep $N$ and $B$ modest so random curves find factors reliably in tests.
- For huge $N$, strip small factors with ECM then finish with **QS** or **GNFS**.

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
