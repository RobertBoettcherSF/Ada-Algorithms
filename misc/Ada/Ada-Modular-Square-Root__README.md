# Modular square root — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Modular square root](https://en.wikipedia.org/wiki/Modular_square_root)
(redirects to
[Quadratic residue](https://en.wikipedia.org/wiki/Quadratic_residue)):
algorithms that solve

$$
x^{2} \equiv n \pmod{m}.
$$

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages are
**independent** — this repo does **not** `with` them; it re-implements short
educational sketches. Full packages live in the siblings linked below.

## Caveats

- **Sketches only** — not production crypto / factoring code.
- Domain is educational `U64` (`mod 2**64`).
- **Prime moduli** are the main story: $p=2$, the $p\equiv 3\pmod{4}$ fast
  path, and a self-contained **Tonelli–Shanks** sketch for general odd primes.
- **Cipolla** is catalogue-only here (`Is_Implemented = False`); see
  **Ada-Cipolla**.
- **Composite moduli** with unknown factorization are hard (related to
  factoring / quadratic residuosity). This survey documents CRT + Hensel in
  the README and ships a tiny educational `Combine_Roots_CRT` for
  $m=pq$ when roots modulo $p$ and $q$ are already known. Full composite /
  Hensel pipelines are catalogue-only.

## When to use which method

| Situation | Method | This survey |
| --- | --- | --- |
| $p=2$ | Trivial ($0^{2}\equiv 0$, $1^{2}\equiv 1$) | Inside `Sqrt_Mod_Prime` |
| Odd prime $p\equiv 3\pmod{4}$ | $r \equiv n^{(p+1)/4}\pmod{p}$ | Fast path + `Sqrt_P_Congruent_3_Mod_4` |
| General odd prime | Tonelli–Shanks | `Sqrt_Mod_Prime` / `Sqrt_Tonelli_Shanks` |
| Prefer $\mathbb{F}_{p^{2}}$ arithmetic | Cipolla | Sibling **Ada-Cipolla** (catalogue here) |
| Tiny any modulus (incl. composite) | Exhaustive search | `Brute_Force_Sqrt` ($M\le$ `Max_Brute_Modulus`) |
| Known factorization $m=\prod p_{i}^{e_{i}}$ | Roots mod prime powers + CRT (+ Hensel) | Documented; `Combine_Roots_CRT` for $pq$ |
| Higher-degree polynomials over $\mathbb{F}_{p}$ | Berlekamp root finding | Sibling **Ada-Berlekamp-Root-Finding** |

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Taxonomy** | `Method_Kind`, `Method_Name`, `Is_Implemented` | Survey glue |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Mod_Inv`, `Is_Prime_Trial` | Self-contained |
| **Legendre** | `Legendre`, `Is_Quadratic_Residue_Prime`, `Find_Quadratic_Non_Residue` | Euler criterion |
| **Dispatcher** | `Sqrt_Mod_Prime` | $p=2$ / $p\equiv 3\pmod{4}$ / Tonelli |
| **Fast path** | `Sqrt_P_Congruent_3_Mod_4` | Explicit $p\equiv 3\pmod{4}$ |
| **Tonelli** | `Sqrt_Tonelli_Shanks` | Same core as dispatcher for odd $p$ |
| **Brute** | `Brute_Force_Sqrt` | Tiny $M$ oracle |
| **CRT sketch** | `Combine_Roots_CRT` | One sign-pair $\bmod\,pq$ |

## Formula summary

### Legendre symbol (Euler’s criterion)

For odd prime $p$:

$$
\left(\frac{n}{p}\right) \equiv n^{\frac{p-1}{2}} \pmod{p}
\in \{0,\ 1,\ p-1\}
\quad\mapsto\quad \{0,\ 1,\ -1\}.
$$

Symbol $-1$ ⇒ no square root; $0$ ⇒ $n\equiv 0$ and $r=0$; $1$ ⇒ a root exists.

### Fast path: $p \equiv 3 \pmod{4}$

$$
r \equiv n^{\frac{p+1}{4}} \pmod{p}.
$$

### Tonelli–Shanks (general odd prime)

1. Write $p-1 = Q\cdot 2^{S}$ with $Q$ odd.
2. Find a quadratic non-residue $z$.
3. Set $M\leftarrow S$, $c\leftarrow z^{Q}$, $t\leftarrow n^{Q}$,
   $R\leftarrow n^{(Q+1)/2}$.
4. Loop: if $t=1$ return $R$; else find least $i$ with $t^{2^{i}}=1$, set
   $b\leftarrow c^{2^{M-i-1}}$, then update $M,c,t,R$.

### Composite moduli (CRT sketch)

If $m=pq$ with distinct primes and $r_{p}^{2}\equiv n\pmod{p}$,
$r_{q}^{2}\equiv n\pmod{q}$, the Chinese Remainder Theorem combines each
sign choice $(\pm r_{p},\pm r_{q})$ into up to **four** roots modulo $m$.
`Combine_Roots_CRT` builds one root from one pair $(r_{p},r_{q})$. Lifting
to prime powers uses **Hensel**; unknown factorization is out of scope.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Method_Kind` | Tonelli / Cipolla / $p\equiv 3\pmod{4}$ / Brute / Composite CRT |
| `Method_Name` / `Is_Implemented` | Taxonomy helpers |
| `Mul_Mod` / `Mod_Pow` / `Gcd` / `Mod_Inv` | Modular helpers |
| `Legendre` | Legendre symbol $-1,0,1$ (odd prime $P$) |
| `Is_Quadratic_Residue_Prime` | Residue test (incl. $P=2$) |
| `Sqrt_Mod_Prime` | Main dispatcher (procedure + function) |
| `Sqrt_P_Congruent_3_Mod_4` | Explicit fast path |
| `Sqrt_Tonelli_Shanks` | Explicit Tonelli entry |
| `Brute_Force_Sqrt` | Tiny-modulus search |
| `Combine_Roots_CRT` | Educational CRT for $pq$ |
| `Invalid_Argument` | Domain error |
| `Max_Trial_Prime` / `Max_Brute_Modulus` | Educational bounds |

Procedure form: when `Found = True`, `Root^2 ≡ N (mod P)`; the other root is
`P - Root` when `Root ≠ 0`. Function form raises `Invalid_Argument` when no
root exists or $P$ is invalid.

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pmodular_square_root.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`).

## Siblings and next

- **Ada-Tonelli-Shanks** — full Tonelli–Shanks focus package
- **Ada-Cipolla** — Cipolla via $\mathbb{F}_{p^{2}}$
- **Ada-Berlekamp-Root-Finding** — roots of higher-degree polynomials over $\mathbb{F}_{p}$

**Next:** LLL (Lenstra–Lenstra–Lovász) lattice basis reduction.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
