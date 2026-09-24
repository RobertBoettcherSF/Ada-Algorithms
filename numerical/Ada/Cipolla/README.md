# Cipolla's algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Cipolla's algorithm**:
solve $x^{2} \equiv n \pmod{p}$ for odd prime $p$ via arithmetic in the
quadratic extension $\mathbb{F}_{p^{2}}$, on unsigned 64-bit integers. See
[Wikipedia: Cipolla's algorithm](https://en.wikipedia.org/wiki/Cipolla's_algorithm).

This is an **integer** algorithm package (`U64` / modular arithmetic), not a
`Real` / ODE teaching sketch. Language: **Ada 2023** (ISO/IEC 8652:2023),
compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **Tonelli–Shanks** — alternate modular square root over $\mathbb{F}_{p}$
  (sibling package)
- **Berlekamp root finding** — roots of polynomials over finite fields (next)
- **Modular square root survey** — when to use Tonelli–Shanks vs Cipolla vs
  special moduli

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain; small/medium primes in tests |
| **Mul** | `Mul_Mod` | Overflow-safe via `Interfaces.Unsigned_128` |
| **Pow** | `Mod_Pow` | Binary exponentiation in $\mathbb{F}_{p}$ |
| **Gcd** | `Gcd` | Euclidean |
| **Legendre** | Euler criterion | $n^{(p-1)/2} \bmod p \in \{0,1,p-1\}$ |
| **Step 1** | `Find_Omega` | $\omega$ with $\bigl(\frac{\omega^{2}-n}{p}\bigr)=-1$ |
| **Step 2** | Fp2 `Mul` / `Mod_Pow` | $( \omega + \sqrt{\omega^{2}-n} )^{(p+1)/2}$ |
| **Primality** | `Is_Prime_Trial` | Trial division; enforced for $P \le$ `Max_Trial_Prime` |
| **Domain** | `Invalid_Argument` | $P<2$, even $P\neq 2$, composite small $P$, no-root (function form) |

**Not for composite moduli.** Finding square roots modulo a composite is
equivalent (in hardness) to integer factorization; this package rejects
even $P\neq 2$ and composites up to `Max_Trial_Prime`.

## Algorithm

Given odd prime $p$ and $n$ with Legendre symbol $\bigl(\frac{n}{p}\bigr)=1$,
solve

$$
x^{2} \equiv n \pmod{p}.
$$

### Step 1 — find $\omega$

Search for $\omega \in \mathbb{F}_{p}$ such that

$$
\left(\frac{\omega^{2}-n}{p}\right) = -1
$$

(i.e. $\omega^{2}-n$ is a quadratic non-residue). About half of random
candidates work; expected trials $\approx 2$.

### Step 2 — exponentiate in $\mathbb{F}_{p^{2}}$

Work in the field extension

$$
\mathbb{F}_{p^{2}} = \mathbb{F}_{p}\bigl[\sqrt{\omega^{2}-n}\bigr].
$$

Compute

$$
\bigl(\omega + \sqrt{\omega^{2}-n}\bigr)^{\frac{p+1}{2}}
= x + 0\cdot\sqrt{\omega^{2}-n}.
$$

The $\mathbb{F}_{p}$ component $x$ is a square root of $n$. The other root is
$-x \bmod p$.

Ring multiplication (with $W = \omega^{2}-n$):

$$
(x_{1}+y_{1}\sqrt{W})(x_{2}+y_{2}\sqrt{W})
=
\bigl(x_{1}x_{2}+y_{1}y_{2}W\bigr)
+
\bigl(x_{1}y_{2}+y_{1}x_{2}\bigr)\sqrt{W}.
$$

Raise to power $(p+1)/2$ by binary exponentiation using that product.

### Trivial cases

- $p = 2$: $0^{2} \equiv 0$, $1^{2} \equiv 1 \pmod{2}$.
- $n \equiv 0$: root $0$.
- Legendre $= -1$: no root (`Found = False`).

Classic Wikipedia check: $n=10$, $p=13$, $\omega=2$,
$(2+\sqrt{7})^{7} = 6$ in $\mathbb{F}_{13^{2}}$, and $6^{2} \equiv 10
\pmod{13}$.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` | $(A\cdot B)\bmod M$ without overflow |
| `Mod_Pow` | $(B^{E})\bmod M$ |
| `Gcd` | greatest common divisor |
| `Is_Prime_Trial` | educational trial-division primality |
| `Legendre` | Legendre symbol $-1,0,1$ (odd prime $P$) |
| `Is_Quadratic_Residue` | residue test (incl. $P=2$, $N\equiv 0$) |
| `Find_Omega` | Cipolla step 1: $\omega$ with Legendre$(\omega^{2}-N)=-1$ |
| `Modular_Sqrt` (procedure) | `Root` + `Found` out parameters |
| `Modular_Sqrt` (function) | one root; raises if none / invalid $P$ |
| `Invalid_Argument` | domain error |
| `Max_Trial_Prime` | primality enforced for $P\le$ this bound |

Procedure form: when `Found = True`, `Root^2 ≡ N (mod P)`; the other root is
`P - Root` when `Root ≠ 0`. When `Found = False`, there is no root (do not
use `Root`). Function form raises `Invalid_Argument` when no root exists or
$P$ is invalid.

Caller contract: pass a prime $P$. For $P \le$ `Max_Trial_Prime` the package
verifies primality by trial division; larger odd $P$ are assumed prime
(still rejecting $P<2$ and even $P\neq 2$).

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pcipolla.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`).

## Limits and caveats

- Domain is unsigned 64-bit. No big-integer path.
- **Composite moduli are out of scope** — use factorization-aware methods
  elsewhere.
- Educational trial primality is intended for classroom sizes; for huge $P$
  supply a known prime.
- Sibling: Tonelli–Shanks. Next: Berlekamp root finding.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
