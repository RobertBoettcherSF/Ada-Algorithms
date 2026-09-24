# AKS primality test — Ada 2023

Educational, self-contained Ada 2023 package for the **AKS**
(Agrawal–Kayal–Saxena) primality test — the first general, deterministic,
unconditionally correct **polynomial-time** primality algorithm (**PRIMES
is in P**). See
[Wikipedia: AKS primality test](https://en.wikipedia.org/wiki/AKS_primality_test).

This is an **integer** algorithm package (`U64` / modular arithmetic + dense
polynomials), not a `Real` / ODE teaching sketch. Language: **Ada 2023**
(ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Baillie-PSW](https://github.com/RobertBoettcherSF/Ada-Baillie-PSW)** —
  practical deterministic-for-64-bit probable-prime test
- **[Ada-Miller-Rabin](https://github.com/RobertBoettcherSF/Ada-Miller-Rabin)** —
  strong probable prime / deterministic 64-bit bases
- **Primality test survey** — next overview row in the series

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Cap** | `Max_Educational_N` | Dense poly AKS; keep tests fast |
| **Mul** | `Mul_Mod` | Overflow-safe via `Interfaces.Unsigned_128` |
| **Step 1** | `Is_Perfect_Power` | $n=a^b$ ($b>1$) → composite |
| **Step 2** | `Find_AKS_R` | smallest $r$ with $\operatorname{ord}_r(n)>(\log_2 n)^2$ |
| **Step 3–4** | gcd / $n\le r$ | trial factors up to $r$; tiny $n$ |
| **Step 5** | poly congruence | $(X+a)^n$ in $(\mathbb{Z}/n\mathbb{Z})[X]/(X^r-1)$ |
| **API** | `Is_Prime_AKS` | raises `Invalid_Argument` if $n<2$ or $n>$ max |

## Algorithm

Classical AKS (2002/2004 / Wikipedia form), input $n>1$:

1. If $n$ is a perfect power $a^b$ with $b>1$, output **composite**.
2. Find the smallest $r$ such that
   $\operatorname{ord}_r(n)>(\log_2 n)^2$
   (skip $r$ not coprime to $n$).
3. For $a=2,\ldots,\min(r,n-1)$: if $1<\gcd(a,n)<n$, output **composite**.
4. If $n\le r$, output **prime**.
5. For $a=1$ to $\bigl\lfloor\sqrt{\varphi(r)}\,\log_2 n\bigr\rfloor$, check

$$
(X+a)^n \equiv X^n+a \pmod{X^r-1,\,n}.
$$

   If any congruence fails, output **composite**; otherwise **prime**.

The identity

$$
(X+a)^n \equiv X^n+a \pmod{n}
$$

in $(\mathbb{Z}/n\mathbb{Z})[X]$ characterises primes (with $\gcd(a,n)=1$), but
expanding degree-$n$ polynomials is exponential. AKS reduces the work to the
quotient ring modulo $X^r-1$ for a carefully chosen small $r$, which is enough
to prove primality in polynomial time.

### Educational implementation

- Polynomials are **dense** coefficient arrays of length $r$ (coeffs mod $n$).
- Multiplication modulo $X^r-1$ is a **cyclic convolution**.
- $(X+a)^n$ uses **binary exponentiation** (`Poly_Mod_Pow`).
- Right-hand side $X^n+a$ reduces to $X^{n\bmod r}+a$.

### Theory vs practice

AKS proves **PRIMES $\in$ P**, but the polynomial degree is high enough that
AKS is a **galactic algorithm**: correct, yet far slower than
Miller–Rabin / Baillie–PSW / ECPP for every practical size. This package
therefore caps $n$ at `Max_Educational_N` so students can run a full
cross-check in seconds. For real primality testing use the sibling
**Ada-Miller-Rabin** / **Ada-Baillie-PSW** packages.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Max_Educational_N` | domain cap for `Is_Prime_AKS` / `Find_AKS_R` |
| `Mul_Mod` | $(A\cdot B)\bmod M$ without overflow |
| `Gcd` | Euclidean gcd |
| `Floor_Log2` | $\lfloor\log_2 N\rfloor$ |
| `Floor_Log2_Squared` | $\lfloor(\log_2 N)^2\rfloor$ (order threshold) |
| `Totient` | Euler $\varphi(R)$ |
| `Is_Perfect_Power` | step 1 predicate |
| `Find_AKS_R` | step 2 (exposed for teaching) |
| `Is_Prime_AKS` | full educational AKS |
| `Invalid_Argument` | $N<2$, $N>$ max, or modulus $0$ |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Paks_primality_test.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

## License

Educational series package; see repository license if present.
