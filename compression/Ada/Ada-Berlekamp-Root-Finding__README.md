# Berlekamp's root finding algorithm (Berlekamp–Rabin) — Ada 2023

Educational, self-contained Ada 2023 package for **Berlekamp's root finding
algorithm** (also called **Berlekamp–Rabin**): find all roots of a univariate
polynomial over the prime field $\mathbb{F}_{p}$, on unsigned 64-bit integers.
See
[Wikipedia: Berlekamp's root finding algorithm](https://en.wikipedia.org/wiki/Berlekamp's_root_finding_algorithm).

This is an **integer / finite-field** algorithm package (`U64` + dense
polynomials), not a `Real` teaching sketch. Language: **Ada 2023**
(ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **Tonelli–Shanks** / **Cipolla** — modular square root over $\mathbb{F}_{p}$
  (degree-$2$ special case of root finding)
- **Modular square root survey** — when to use Tonelli–Shanks vs Cipolla vs
  Berlekamp (next sheet)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain; small/medium primes in tests |
| **Mul / Pow** | `Mul_Mod` / `Mod_Pow` | Overflow-safe via `Interfaces.Unsigned_128` |
| **Poly** | Dense `Poly` (low degree first) | Add / Sub / Mul / Mod / Gcd / Mod_Pow |
| **Square-free** | `Poly_Square_Free` | $F/\gcd(F,F')$ — distinct roots |
| **Split** | Random shift $z$ | $\gcd\bigl(x^{(p-1)/2}\pm 1,\,f(x-z)\bigr)$ |
| **Oracle** | `Find_Roots_Deterministic_Small` | Brute eval for $P\le$ `Max_Brute_P` |
| **Primality** | `Is_Prime_Trial` | Enforced for $P\le$ `Max_Trial_Prime` |
| **Domain** | `Invalid_Argument` | Empty poly, composite small $P$, $P>Max_Brute_P$ (oracle) |

## Algorithm

Given odd prime $p$ and $f\in\mathbb{F}_{p}[x]$, find all $\lambda\in\mathbb{F}_{p}$
with $f(\lambda)=0$.

### Square-free reduction

Multiple roots are reduced first:

$$
f_{\mathrm{sf}} = \frac{f}{\gcd(f,f')}.
$$

The package returns **distinct** roots of $f$ (the roots of $f_{\mathrm{sf}}$).
Squared factors such as $(x-1)^{2}$ therefore yield a single reported root.

### Randomization (Berlekamp–Rabin)

For square-free $f$ of degree $\ge 2$, pick a random shift $z\in\mathbb{F}_{p}$
and set $f_{z}(x)=f(x-z)$. By Euler's criterion, each linear factor
$(x-\lambda)$ of $f_{z}$ divides exactly one of

$$
g_{0}(x)=x^{(p-1)/2}-1,\qquad
g_{1}(x)=x^{(p-1)/2}+1
$$

(unless $\lambda=0$, handled separately). Compute

$$
x^{(p-1)/2} \bmod f_{z}
$$

by polynomial modular exponentiation, then

$$
\gcd\bigl(x^{(p-1)/2}-1,\,f_{z}\bigr)
\quad\text{or}\quad
\gcd\bigl(x^{(p-1)/2}+1,\,f_{z}\bigr).
$$

A non-trivial GCD splits $f_{z}$; mapping factors back by $+z$ yields a
factorization of $f$. Recurse until all linear factors (roots) are collected.
Irreducible factors of degree $>1$ contribute no $\mathbb{F}_{p}$-roots and
are abandoned after `Max_Attempts` failed splits.

For the modular-square-root special case $f(x)=x^{2}-a$, this is the same
splitting idea that underlies Cipolla / related methods; Tonelli–Shanks and
Cipolla are faster purpose-built solvers for degree $2$.

### Complexity (schoolbook)

Each split costs $O(n^{2}\log p)$ with schoolbook poly arithmetic
($n=\deg f$). Expected number of random $z$ trials is small when $f$ has
several distinct roots.

### $p=2$

Handled by direct evaluation at $\{0,1\}$ (the formal derivative often vanishes
in characteristic $2$, so square-free reduction via $\gcd(f,f')$ is skipped).

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Poly` | dense coeffs, low degree first |
| `Root_List` | distinct roots in $0..P-1$ |
| `Mul_Mod` / `Mod_Pow` / `Gcd` / `Mod_Inv` | field helpers |
| `Is_Prime_Trial` | educational trial primality |
| `Poly_Add` / `Poly_Sub` / `Poly_Mul` / `Poly_Mod` | poly ring |
| `Poly_Gcd` / `Poly_Mod_Pow` / `Poly_Quotient` | Euclidean / exp |
| `Poly_Derivative` / `Poly_Eval` / `Poly_Shift` | helpers |
| `Poly_Square_Free` | distinct-root kernel |
| `Find_Roots` | probabilistic Berlekamp–Rabin |
| `Find_Roots_Deterministic_Small` | brute oracle ($P\le$ `Max_Brute_P`) |
| `Invalid_Argument` | domain error |

`Find_Roots` takes optional `Max_Attempts` (default `Default_Max_Attempts`)
and `Seed` (LCG) for reproducible random shifts.

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pberlekamp_root_finding.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`).

## Limits and caveats

- Domain is unsigned 64-bit. No big-integer path.
- Educational sizes: degrees $\lesssim 8$, primes up to $\sim 10^{6}$ for the
  algorithm; brute oracle capped at `Max_Brute_P` ($10^{4}$).
- **Probabilistic**: very unlucky seeds may miss a split; raise
  `Max_Attempts` or change `Seed`. Tests cross-check against the brute oracle
  for $p\le 97$, $\deg\le 4$.
- Composite moduli are rejected (trial check when $P\le$ `Max_Trial_Prime`).
- Sibling special cases: Tonelli–Shanks / Cipolla. Next: Modular square root
  survey.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
