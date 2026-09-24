# Baillie–PSW primality test — Ada 2023

Educational, self-contained Ada 2023 package for the **Baillie–PSW**
(Baillie–Pomerance–Selfridge–Wagstaff) probable-prime test on unsigned
64-bit integers. See
[Wikipedia: Baillie–PSW primality test](https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test).

Note-sheet typo: **“Bailie-PSW”** → **Baillie–PSW**.

This is an **integer** algorithm package (`U64` / modular arithmetic), not a
`Real` / ODE teaching sketch. Language: **Ada 2023** (ISO/IEC 8652:2023),
compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Miller-Rabin](https://github.com/RobertBoettcherSF/Ada-Miller-Rabin)** —
  strong probable prime (this package embeds the base-$2$ case)
- **[Ada-Fermat-Primality-Test](https://github.com/RobertBoettcherSF/Ada-Fermat-Primality-Test)** —
  classical Fermat $a^{N-1}\equiv 1$
- **[Ada-Lucas-Primality-Test](https://github.com/RobertBoettcherSF/Ada-Lucas-Primality-Test)** —
  **classical Lucas primality test** ($N-1$ fully factored + Lucas witnesses) —
  a different algorithm from the **Lucas probable-prime** sequences used here
- **AKS primality test** — next deterministic polynomial-time row in the series

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain: all $N < 2^{64}$ |
| **Mul** | `Mul_Mod` | Overflow-safe via `Interfaces.Unsigned_128` |
| **Pow** | `Mod_Pow` | Binary exponentiation |
| **Gcd** | `Gcd` | Euclidean algorithm |
| **Jacobi** | `Jacobi` | $(A/N)$ for odd positive $N$ |
| **Square** | `Is_Perfect_Square` | Integer square-root check |
| **SPRP2** | `Is_Strong_PRP_Base_2` | Miller–Rabin strong test, $A=2$ |
| **Selfridge** | `Choose_Selfridge_D` | $D\in\{5,-7,9,-11,\ldots\}$, $(D/N)=-1$ |
| **Lucas** | `Is_Strong_Lucas_PRP` | Strong Lucas PRP, $P=1$, $Q=(1-D)/4$ |
| **BPSW** | `Is_Baillie_PSW_Prime` | Main entry: square + SPRP2 + strong Lucas |
| **Domain** | `Invalid_Argument` / `Composite_Signal` | Bad modulus / factor found via Jacobi |

## Algorithm

For odd $N > 2$ the standard Baillie–PSW outline is:

1. If $N$ is a perfect square → **composite**.
2. Strong probable prime to base $2$: write $N-1=2^{S}\cdot D$ ($D$ odd) and
   run the Miller–Rabin strong test with $A=2$. Fail → **composite**.
3. **Selfridge discriminant:** take the first
   $$
   D \in \{5,-7,9,-11,13,-15,\ldots\}
   $$
   with Jacobi symbol $(D/N)=-1$. If some candidate has
   $\gcd(|D|,N)\in(1,N)$ → **composite**.
4. **Strong Lucas PRP** with $P=1$ and $Q=(1-D)/4$: write
   $N+1=d\cdot 2^{s}$ ($d$ odd). Accept iff
   $$
   U_{d}\equiv 0\pmod{N}
   $$
   or
   $$
   V_{d\cdot 2^{r}}\equiv 0\pmod{N}
   $$
   for some $0\le r<s$ (Baillie–Wagstaff strong Lucas conditions).

No counterexample is known below enormous bounds; the test is still formally
**probabilistic**.

Lucas $U_k,V_k$ are advanced with the doubling / “add-one” chain
(modulo $N$), using overflow-safe `Mul_Mod` and an odd-modulus “divide by 2”
step.

### Classical Lucas vs Lucas PRP

The sibling **Lucas primality test** proves primality when a complete
factorization of $N-1$ is known. Baillie–PSW instead uses **Lucas sequences**
$U_k(P,Q)$, $V_k(P,Q)$ as a *probable-prime* filter — related name, different
certificate.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` / `I64` | unsigned word / signed discriminant |
| `Mul_Mod` | $(A\cdot B)\bmod M$ without overflow |
| `Mod_Pow` | $(B^{E})\bmod M$ |
| `Gcd` | $\gcd(A,B)$ |
| `Jacobi` | Jacobi symbol $(A/N)$ |
| `Is_Perfect_Square` | integer square check |
| `Is_Strong_PRP_Base_2` | strong PRP, base $2$ |
| `Choose_Selfridge_D` | Selfridge $D$ (or `Composite_Signal`) |
| `Is_Strong_Lucas_PRP` | strong Lucas PRP for given $D$ |
| `Is_Baillie_PSW_Prime` | full BPSW entry point |
| `Invalid_Argument` | domain error |
| `Composite_Signal` | factor exposed while choosing $D$ |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pbaillie_psw.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with` of Miller–Rabin).

## Limits and caveats

- Domain is unsigned 64-bit: $0\le N\le 2^{64}-1$. No big-integer path.
- BPSW is a **compositeness** / probable-prime test: a `True` result is
  overwhelmingly strong evidence of primality, not a proof for arbitrary $N$.
- Distinguish from the classical Lucas primality sibling (factored $N-1$).
- Next educational row: **AKS primality test**.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
