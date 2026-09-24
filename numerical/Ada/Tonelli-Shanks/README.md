# Tonelli–Shanks modular square root — Ada 2023

Educational, self-contained Ada 2023 package for the **Tonelli–Shanks**
algorithm: solve $r^{2} \equiv n \pmod{p}$ for prime $p$ on unsigned 64-bit
integers. See
[Wikipedia: Tonelli–Shanks algorithm](https://en.wikipedia.org/wiki/Tonelli%E2%80%93Shanks_algorithm).

This is an **integer** algorithm package (`U64` / modular arithmetic), not a
`Real` / ODE teaching sketch. Language: **Ada 2023** (ISO/IEC 8652:2023),
compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows (upcoming or nearby):

- **Cipolla’s algorithm** — alternate modular square root over $\mathbb{F}_{p}$
- **Berlekamp root finding** — roots of polynomials over finite fields
- **Modular square root survey** — when to use Tonelli–Shanks vs Cipolla vs
  special moduli
- Sheet **multiplication** rows (Toom–Cook, Karatsuba, etc.) — already on
  GitHub; skipped here

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain; small/medium primes in tests |
| **Mul** | `Mul_Mod` | Overflow-safe via `Interfaces.Unsigned_128` |
| **Pow** | `Mod_Pow` | Binary exponentiation |
| **Gcd** | `Gcd` | Euclidean |
| **Legendre** | Euler criterion | $n^{(p-1)/2} \bmod p \in \{0,1,p-1\}$ |
| **Fast path** | $p \equiv 3 \pmod{4}$ | $r = n^{(p+1)/4} \bmod p$ |
| **General** | Tonelli–Shanks | $p-1 = 2^{S}Q$, non-residue $z$, lift loop |
| **Primality** | `Is_Prime_Trial` | Trial division; enforced for $P \le$ `Max_Trial_Prime` |
| **Domain** | `Invalid_Argument` | $P<2$, even $P\neq 2$, composite small $P$, no-root (function form) |

**Not for composite moduli.** Finding square roots modulo a composite is
equivalent (in hardness) to integer factorization; this package rejects
even $P\neq 2$ and composites up to `Max_Trial_Prime`.

## Algorithm

Given prime $p$ and $n$, decide whether solutions to

$$
r^{2} \equiv n \pmod{p}
$$

exist, and if so return one root $r$ (the other is $-r \bmod p$).

### Legendre symbol (Euler’s criterion)

For odd prime $p$:

$$
\left(\frac{n}{p}\right) \equiv n^{\frac{p-1}{2}} \pmod{p}
\in \{0,\ 1,\ p-1\}
\quad\mapsto\quad \{0,\ 1,\ -1\}.
$$

If the symbol is $-1$, there is **no** square root. If $0$, then $n \equiv 0$
and $r = 0$. If $1$, a root exists.

Handle $p = 2$ separately: $0^{2} \equiv 0$, $1^{2} \equiv 1 \pmod{2}$.

### Fast path: $p \equiv 3 \pmod{4}$

$$
r \equiv n^{\frac{p+1}{4}} \pmod{p}.
$$

### Tonelli–Shanks (general odd prime)

1. Write $p-1 = Q\cdot 2^{S}$ with $Q$ odd.
2. Find a quadratic non-residue $z$ (e.g. search $z = 2,3,\ldots$ until
   $\bigl(\frac{z}{p}\bigr) = -1$).
3. Set

$$
\begin{aligned}
M &\leftarrow S, \\
c &\leftarrow z^{Q}, \\
t &\leftarrow n^{Q}, \\
R &\leftarrow n^{\frac{Q+1}{2}}.
\end{aligned}
$$

4. Loop: if $t = 0$ return $0$; if $t = 1$ return $R$. Otherwise find the
   least $i$ with $0 < i < M$ and $t^{2^{i}} = 1$. Set
   $b \leftarrow c^{2^{M-i-1}}$, then

$$
\begin{aligned}
M &\leftarrow i, \\
c &\leftarrow b^{2}, \\
t &\leftarrow t\,b^{2}, \\
R &\leftarrow R\,b.
\end{aligned}
$$

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
| `Find_Quadratic_Non_Residue` | smallest $z$ with Legendre $-1$ |
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
make        # gnatmake -gnatwa -gnat2022 -Ptonelli_shanks.gpr
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
- Upcoming siblings: Cipolla, Berlekamp, modular square-root survey.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
