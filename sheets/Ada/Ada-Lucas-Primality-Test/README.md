# Lucas primality test — Ada 2023

Educational, self-contained Ada 2023 package for the **Lucas primality test**
on unsigned 64-bit integers: the deterministic test that needs the **prime
factors of $N-1$** (Pratt certificate basis). See
[Wikipedia: Lucas primality test](https://en.wikipedia.org/wiki/Lucas_primality_test).

**Not** the same as:

- **Lucas–Lehmer** (Mersenne numbers $2^p-1$)
- **Baillie–PSW** / extra-strong **Lucas PRP** (probable-prime family)

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Miller-Rabin](https://github.com/RobertBoettcherSF/Ada-Miller-Rabin)** —
  strong probable-prime test (no $N-1$ factorisation required)
- **Fermat primality test** — next number-theoretic primality row in the series

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Mul** | `Mul_Mod` | Overflow-safe via `Interfaces.Unsigned_128` |
| **Pow** | `Mod_Pow` | Binary exponentiation |
| **Factors** | `Factors_Of_N_Minus_1` | Distinct primes of $N-1$ (trial, $N\le 10^6$) |
| **Witness** | `Lucas_Witness` | One base $A$ under Lucas conditions |
| **Search** | `Find_Lucas_Witness` | Try $A=2,3,\ldots$ up to a bound |
| **Prime** | `Is_Prime_Lucas` | Witness exists given factors |
| **Auto** | `Is_Prime_Lucas_Auto` | Factor then search (small $N$ only) |
| **Domain** | `Invalid_Argument` | Bad $N$, empty/bad factors, $N>$ auto limit |

## Algorithm

Given odd $N>2$ and the complete list of **distinct prime factors** $Q$ of
$N-1$: if there exists a base $A$ with $1 < A < N$ such that

$$
A^{N-1} \equiv 1 \pmod{N}
$$

and for every prime factor $Q$ of $N-1$

$$
A^{(N-1)/Q} \not\equiv 1 \pmod{N},
$$

then $N$ is **prime**. This is a **sufficient** condition: success proves
primality. It is the arithmetic core of a **Pratt certificate**.

Reason (sketch): the first congruence means $\operatorname{ord}(A)\mid(N-1)$.
Surviving every $(N-1)/Q$ check forces $\operatorname{ord}(A)=N-1$, so
$|(\mathbb{Z}/N\mathbb{Z})^{*}|=N-1$ and $N$ is prime. Conversely, every prime
$N$ has a primitive root, which is a Lucas witness.

Without the prime factors of $N-1$, the classical Lucas test **cannot run**.
`Is_Prime_Lucas_Auto` / `Is_Prime_Small` only factor $N-1$ for
$N \le \mathtt{Max\_Auto\_N}$ ($10^6$) via trial division — demos and
classroom cross-checks, not a general factoring engine.

### Wikipedia example: $N=71$

$N-1=70=2\cdot5\cdot7$. Base $A=17$ satisfies $17^{70}\equiv 1\pmod{71}$ but
fails because $17^{10}\equiv 1\pmod{71}$. Base $A=11$ satisfies all three
non-congruences and certifies that $71$ is prime.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Factor_List` | array of distinct prime factors of $N-1$ |
| `Mul_Mod` | $(A\cdot B)\bmod M$ without overflow |
| `Mod_Pow` | $(B^{E})\bmod M$ |
| `Factors_Of_N_Minus_1` | trial-factor $N-1$ ($2\le N\le 10^6$) |
| `Lucas_Witness` | `True` if base $A$ certifies primality |
| `Find_Lucas_Witness` | first witness in search bound, else $0$ |
| `Is_Prime_Lucas` | witness exists (`Is_Prime_With_Factors`) |
| `Is_Prime_Lucas_Auto` | factor + search (`Is_Prime_Small`) |
| `Invalid_Argument` | domain error |
| `Max_Auto_N` | educational auto-factor limit ($10^6$) |

Notes: $N=2$ is treated as prime (no base in $(1,2)$). Even $N>2$ is
composite. Empty factor lists raise when $N>2$. Listed factors must be
$\ge 2$ and divide $N-1$.

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Plucas_primality_test.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no `with` of sibling packages).

## Limits and caveats

- Domain helpers use unsigned 64-bit words; auto-factoring is capped at
  $N\le 10^6$.
- Supplying wrong or incomplete factors voids the certificate (the package
  checks that each listed $Q$ divides $N-1$, but does not prove the list is
  complete).
- Do **not** confuse this package with Lucas–Lehmer or Lucas PRP tests.
- For probable primes without factoring $N-1$, see **Ada-Miller-Rabin**.
- Next educational row: Fermat primality test.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
