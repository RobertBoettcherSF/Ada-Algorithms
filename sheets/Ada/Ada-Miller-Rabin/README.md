# Miller–Rabin primality test — Ada 2023

Educational, self-contained Ada 2023 package for the **Miller–Rabin**
(strong probable prime) test on unsigned 64-bit integers. See
[Wikipedia: Miller–Rabin primality test](https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test).

Note-sheet typo: **“Miler-Rabin”** → **Miller–Rabin**.

This is an **integer** algorithm package (`U64` / modular arithmetic), not a
`Real` / ODE teaching sketch. Language: **Ada 2023** (ISO/IEC 8652:2023),
compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Sieve-Of-Eratosthenes](https://github.com/RobertBoettcherSF/Ada-Sieve-Of-Eratosthenes)** —
  classical sieve (exact primes up to a bound)
- Other sieves (Sundaram, Atkin) — related primality / listing tools
- **Lucas primality test** — next number-theoretic primality row in the series

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain: all $N < 2^{64}$ |
| **Mul** | `Mul_Mod` | Overflow-safe via `Interfaces.Unsigned_128` |
| **Pow** | `Mod_Pow` | Binary exponentiation |
| **Split** | `Trial_Split_N_Minus_1` | $N-1 = 2^{S}\cdot D$, $D$ odd |
| **Witness** | `Is_Composite_Witness` | One Miller–Rabin base |
| **Probable** | `Is_Probable_Prime` | Fixed educational bases (not CSPRNG) |
| **Deterministic** | `Is_Prime_Deterministic_64` | Wikipedia bases for all 64-bit $N$ |
| **Domain** | `Invalid_Argument` | $N<2$ on split/witness; modulus $0$ on mod ops |

## Algorithm

Write $N-1 = 2^{S}\cdot D$ with $D$ odd. For each base $A$:

1. Compute $X := A^{D} \bmod N$.
2. If $X \in \{1,\ N-1\}$, the base **passes** (continue).
3. For $R = 1,\ldots,S-1$: set $X := X^{2} \bmod N$;
   - if $X = N-1$, the base **passes**;
   - if $X = 1$, declare **composite** (nontrivial square root of $1$).
4. If the loop ends without $N-1$, declare **composite**.

If every chosen base passes, $N$ is a **probable prime** (or a proven prime
when the base set is a known sufficient set for that size of $N$).

### Probabilistic vs deterministic bases

- **Probabilistic (educational):** `Is_Probable_Prime` uses the first
  `Rounds` primes from a **fixed** table $\{2,3,5,\ldots\}$. This is **not**
  a cryptographic RNG; it is for classroom reproducibility.
- **Error bound (sketch):** if $N$ is odd composite, at most $1/4$ of the
  bases in $(\mathbb{Z}/N\mathbb{Z})^{*}$ are strong liars, so $k$ independent
  random bases err with probability at most

$$
4^{-k}.
$$

  With fixed (non-random) bases the $4^{-k}$ bound is a useful teaching
  heuristic, not a formal claim for this package’s table.

- **Deterministic 64-bit:** `Is_Prime_Deterministic_64` uses the Wikipedia /
  OEIS A014233 set

$$
\{2,3,5,7,11,13,17,19,23,29,31,37\},
$$

  which is sufficient for **every** $N < 2^{64}$. Smaller thresholds (e.g.
  $\{2,3,5,7\}$ for $N < 3\,215\,031\,751$) are documented on Wikipedia; this
  package always runs the full 64-bit set for simplicity and correctness.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` | $(A\cdot B)\bmod M$ without overflow |
| `Mod_Pow` | $(B^{E})\bmod M$ |
| `Trial_Split_N_Minus_1` | factor $N-1=2^{S}D$ |
| `Is_Composite_Witness` | `True` if base $A$ proves $N$ composite |
| `Is_Probable_Prime` | fixed-base probable prime (`Rounds` default 8) |
| `Is_Prime_Deterministic_64` | correct for all 64-bit $N$ |
| `Invalid_Argument` | domain error |

Witness notes: $N<2$ raises `Invalid_Argument`; even $N>2$ is immediately a
witness of compositeness; if $A \bmod N = 0$ the base is invalid for the
congruence test and the function returns `False` (does not by itself prove
compositeness when $\gcd(A,N)=N$).

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pmiller_rabin.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Classic example: $2047 = 23 \cdot 89$

$2047$ is a **strong pseudoprime to base 2** ($2^{1023} \equiv 1 \pmod{2047}$),
so base $2$ is a *liar*, not a Miller–Rabin witness. Base $3$ (and the
deterministic set) correctly proves compositeness. Sheet notes that say
“$a=2$ proves $2047$ composite” are mixing this up with a weaker Fermat
story — keep the strong-probable-prime definition in mind.

## Limits and caveats

- Domain is unsigned 64-bit: $0 \le N \le 2^{64}-1$. No big-integer path.
- Do **not** treat `Is_Probable_Prime` as a cryptographic primality API
  (fixed bases; no CSPRNG).
- For exact primes in a small range, prefer a sieve sibling package.
- Next educational row: Lucas primality test.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
