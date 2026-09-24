# Pollard's $p-1$ algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Pollard's $p-1$** integer
factorization (John Pollard, 1974): a special-purpose algebraic-group method
that finds a prime factor $p$ of $N$ when $p-1$ is $B$-powersmooth. See
[Wikipedia: Pollard's $p-1$ algorithm](https://en.wikipedia.org/wiki/Pollard's_p_%E2%88%92_1_algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Pollards-Rho](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho)** —
  birthday / cycle factorization (different special-purpose method)
- **[Ada-Trial-Division](https://github.com/RobertBoettcherSF/Ada-Trial-Division)** —
  classical $\sqrt{N}$ factorization / primality
- **[Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve)** —
  general-purpose CoS classroom sketch
- **Next (educational sketch):** **Lenstra elliptic-curve factorization (ECM)**

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Floor_Sqrt`, `Is_Prime_Trial`, `Primes_Up_To` | Self-contained |
| **Stage 1** | `Factor_Stage1` | $a^{M}\bmod N$, $M=\mathrm{lcm}(1..B)$ |
| **Hybrid** | `Factor` | Try several bases with Stage 1 |
| **Domain** | `Invalid_Argument` | $N<2$ or $B<2$ |

## Algorithm

Let $N$ be composite with prime factor $p$. By Fermat's little theorem,
$a^{K(p-1)}\equiv 1\pmod{p}$ for $\gcd(a,p)=1$. If the exponent $M$ is a
multiple of $p-1$, then $a^{M}\equiv 1\pmod{p}$, so

$$
g=\gcd(a^{M}-1,\,N)
$$

is divisible by $p$. Stage 1 chooses a smoothness bound $B$ and takes

$$
M=\prod_{q\le B}q^{\lfloor\log_{q}B\rfloor}=\operatorname{lcm}(1,2,\ldots,B)
$$

(the product of highest prime powers $q^{k}\le B$). Compute $R=a^{M}\bmod N$
by successive modular exponentiation (never materializing huge $M$ as an
integer), then $g=\gcd(R-1,N)$. If $1<g<N$, $g$ is a nontrivial factor.

This succeeds when some prime factor $p$ has $p-1$ **$B$-powersmooth**
(every prime-power factor of $p-1$ is $\le B$). It fails (returns $1$) when
no such factor exists, or when every prime factor of $N$ is $B$-powersmooth
at once ($g=N$).

Wikipedia's running example: $N=299$, $B=5$, $a=2$ yields factor $13$
($299=13\times 23$; $12=2^{2}\cdot 3$ is $5$-powersmooth, while $22=2\cdot 11$ is not).

### Complexity

Heuristic Stage-1 cost is on the order of

$$
O(B\log B\cdot\log^{2} N)
$$

modular operations (larger $B$ is slower but more likely to hit a smooth
$p-1$). Space is tiny beyond a short prime list up to $B$.

### Stage 2 (README only)

In practice one continues with a **Stage 2**: require all but one prime
factor of $p-1$ to be $\le B_{1}$, and the remaining prime factor $\le B_{2}\gg B_{1}$.
Pollard / Montgomery prime-pairing and polynomial Stage-2 variants avoid
building a full $\operatorname{lcm}(1..B_{2})$. This educational package
implements **Stage 1 only**; Stage 2 is left as a pointer toward ECM / GMP-ECM.

## What the code actually does

### Helpers

`Mul_Mod` multiplies via `Unsigned_128`. `Mod_Pow` is binary
exponentiation. `Gcd` is Euclidean. `Is_Prime_Trial` uses a $2/3$ wheel.
`Primes_Up_To` returns primes $\le$ Limit by trial (educational sizes).

### `Factor_Stage1`

For each prime $q\le B$, raise the running residue to $q^{k}$ (largest
power $\le B$). Intermediate $\gcd(R-1,N)$ may exit early. Even $N\to 2$;
primes $\to 1$; failure $\to 1$.

### `Factor`

Tries bases $\{2,3,5,7,11,13,17,19,23\}$ with the given bound (default
`Default_B = 100`) until a nontrivial factor appears.

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $299$ | $13\times 23$ (Wikipedia, $B=5$) |
| $481$ | $13\times 37$ ($B=4$) |
| $91$, $143$, … | smooth $p-1$ semiprimes |
| primes ($97$, $101$, …) | return $1$ |
| even | peel $2$ |
| $B$ too small | failure sentinel $1$ |
| $N<2$ or $B<2$ | `Invalid_Argument` |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `U64_Array` | ordered prime / word list |
| `Gcd` | Euclidean gcd |
| `Mul_Mod` | $(A\cdot B)\bmod M$ via 128-bit product |
| `Mod_Pow` | $(B^{E})\bmod M$ |
| `Floor_Sqrt` | $\lfloor\sqrt{N}\rfloor$ |
| `Is_Prime_Trial` | trial primality |
| `Primes_Up_To` | primes $\le$ Limit |
| `Factor_Stage1` | Pollard's $p-1$ Stage 1 |
| `Factor` | multi-base Stage-1 dispatcher |
| `Default_B` | default smoothness bound ($100$) |
| `Invalid_Argument` | domain error ($N<2$, $B<2$, `Mul_Mod`/`Mod_Pow` with $M=0$) |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Ppollards_p_1.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Educational `U64` toy — **not** cryptographic factorization.
- Special-purpose: excellent only when some $p-1$ is smooth; weak on
  strong primes / safe primes and on balanced cryptographic semiprimes.
- Modern practice prefers **ECM** (Lenstra) once factors are moderately
  large; $p-1$ remains historically and pedagogically important.
- Next educational row: **Lenstra ECM**.

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
