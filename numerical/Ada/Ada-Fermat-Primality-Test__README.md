# Fermat primality test — Ada 2023

Educational, self-contained Ada 2023 package for the **Fermat primality test**
on unsigned 64-bit integers. See
[Wikipedia: Fermat primality test](https://en.wikipedia.org/wiki/Fermat_primality_test).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Miller-Rabin](https://github.com/RobertBoettcherSF/Ada-Miller-Rabin)** —
  strong probable-prime test (stricter than Fermat; preferred in practice)
- **[Ada-Lucas-Primality-Test](https://github.com/RobertBoettcherSF/Ada-Lucas-Primality-Test)** —
  deterministic Lucas test given the prime factors of $N-1$
- **Baillie–PSW** — next probable-prime row in the series

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Mul** | `Mul_Mod` | Overflow-safe via `Interfaces.Unsigned_128` |
| **Pow** | `Mod_Pow` | Binary exponentiation |
| **Gcd** | `Gcd` | Euclidean algorithm |
| **Witness** | `Is_Fermat_Witness` | Classical Fermat witness + proper-gcd case |
| **Probable** | `Is_Fermat_Probable_Prime` | Fixed educational bases (not CSPRNG) |
| **Carmichael** | `Is_Carmichael_Example` | Small hard-coded demo table |
| **Domain** | `Invalid_Argument` | $N<2$ on witness; modulus $0$ on mod ops |

## Algorithm

Fermat's little theorem: if $P$ is prime and $\gcd(A,P)=1$, then

$$
A^{P-1} \equiv 1 \pmod{P}.
$$

**Test.** Pick a base $A$ with $1 < A < N-1$. If

$$
A^{N-1} \not\equiv 1 \pmod{N},
$$

then $N$ is **composite** and $A$ is a **Fermat witness**. If the congruence
holds, $N$ is a **Fermat probable prime** to base $A$ — it may still be
composite (a **Fermat pseudoprime** to base $A$, or a **Carmichael number**).

### Witness policy in this package

`Is_Fermat_Witness (N, A)` returns `True` when $A$ proves compositeness in
the **broad** educational sense:

1. $1 < \gcd(A,N) < N$ — proper common factor (composite);
2. $\gcd(A,N)=1$ and $A^{N-1} \not\equiv 1 \pmod{N}$ — classical Fermat
   witness.

It returns `False` when $\gcd(A,N)=N$ (base not usable), or when the
congruence holds (probable prime to that base — including Carmichael /
pseudoprime cases). Even $N>2$ is immediately a witness of compositeness.
$N=2$ is never a witness target (prime).

### Critical limitation: Carmichael numbers

**Carmichael numbers** (e.g. $561=3\cdot11\cdot17$, $1105$, $1729$) satisfy

$$
A^{N-1} \equiv 1 \pmod{N}
$$

for **every** $A$ coprime to $N$. Against those bases the Fermat test never
returns “composite”. Only a base that shares a factor with $N$ exposes them
via the gcd branch — which is essentially trial factoring. Prefer
**Miller–Rabin** or **Baillie–PSW** for serious probable-primality work.

Classic classroom facts encoded in the tests:

- $561$: `Is_Fermat_Witness(561, 2) = False` while $561$ is composite;
- $341 = 11\cdot31$: Fermat **pseudoprime to base 2**
  ($2^{340}\equiv 1\pmod{341}$), but base $3$ is a witness.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Base_List` | caller-supplied bases for the overload |
| `Mul_Mod` | $(A\cdot B)\bmod M$ without overflow |
| `Mod_Pow` | $(B^{E})\bmod M$ |
| `Gcd` | Euclidean $\gcd$ |
| `Is_Fermat_Witness` | `True` if base $A$ proves $N$ composite |
| `Is_Fermat_Probable_Prime` | fixed-base or explicit-base PRP |
| `Is_Carmichael_Example` | membership in a small Carmichael table |
| `Invalid_Argument` | domain error |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pfermat_primality_test.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`; `Mul_Mod` /
`Mod_Pow` copied in-tree from the Miller–Rabin style).

## Limits and caveats

- Domain is unsigned 64-bit: $0 \le N \le 2^{64}-1$. No big-integer path.
- Do **not** treat `Is_Fermat_Probable_Prime` as a cryptographic primality
  API (fixed bases; Carmichael numbers fool all coprime bases).
- For a stronger PRP without $N-1$ factorisation, use **Ada-Miller-Rabin**.
- Next educational row: **Baillie–PSW**.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
