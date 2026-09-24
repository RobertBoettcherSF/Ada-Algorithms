# Trial division — Ada 2023

Educational, self-contained Ada 2023 package for **trial division**:
integer factorization and primality testing by trying candidate divisors
up to $\lfloor\sqrt{N}\rfloor$. See
[Wikipedia: Trial division](https://en.wikipedia.org/wiki/Trial_division).

This is an **integer** algorithm package (`U64` / modular arithmetic), not a
`Real` / ODE teaching sketch. Language: **Ada 2023** (ISO/IEC 8652:2023),
compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Sieve-Of-Eratosthenes](https://github.com/RobertBoettcherSF/Ada-Sieve-Of-Eratosthenes)** —
  classical sieve (list / count primes up to a bound)
- **[Ada-Miller-Rabin](https://github.com/RobertBoettcherSF/Ada-Miller-Rabin)** —
  strong probable-prime test (faster primality for large $N$)
- **[Ada-Primality-Test](https://github.com/RobertBoettcherSF/Ada-Primality-Test)** —
  survey taxonomy (includes a trial-division sketch)
- **Next (educational sketch):** special / general number field sieve
  (**SNFS** / **GNFS**) — modern practical factoring of large integers
- **[Shor’s algorithm](https://github.com/RobertBoettcherSF)** — quantum
  polynomial-time factoring already exists elsewhere in the GitHub org;
  this package stays classical and elementary

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain; overflow-safe $D\le N/D$ |
| **Prime?** | `Is_Prime` | Trial up to $\lfloor\sqrt{N}\rfloor$; wheel after 2 |
| **Least factor** | `Smallest_Prime_Factor` | First successful trial divisor (or $N$) |
| **Factor** | `Factorize` | Complete prime-power factorization |
| **Shape** | `Prime_Power` / `Factor_List` | `(Prime, Exponent)` array, ascending primes |
| **Sqrt** | `Floor_Sqrt` | Integer $\lfloor\sqrt{N}\rfloor$ (no `Float`) |
| **Domain** | `Invalid_Argument` | $N=0$ on core ops; SPF also rejects $N=1$ |

## Algorithm

Given $N>1$, trial division systematically tests candidate divisors
$2,3,5,\ldots$ up to $\lfloor\sqrt{N}\rfloor$. If a divisor $d$ is found,
peel all powers of $d$ from $N$ and continue on the cofactor. Any remaining
cofactor $>1$ after the loop is itself prime.

Wikipedia’s running example: $70 = 2\times 5\times 7$ (try $2$, then odds;
$35/5=7$, and $7$ is prime).

A composite $N$ has at least one prime factor $\le\sqrt{N}$, so stopping at
the floor square root is enough for both primality and complete factorization
(with recursive / iterative peeling of quotients).

This package uses a simple **even wheel**: handle $2$ (and $3$) specially,
then try candidates congruent to $\pm 1\pmod{6}$ (pairs $5,7$ then step $+6$).
That skips multiples of $2$ and $3$ without needing a full prime table.

### Complexity

Worst-case time is

$$
O(\sqrt{N})
$$

division steps (or about $\pi(\sqrt{N})$ if only primes are tried). For a
random $N$, a small factor is often found quickly — Wikipedia notes that
about $88\%$ of positive integers have a factor under $100$. Cryptographic
semiprimes with two large prime factors remain hard for trial division alone;
practical large-integer factoring then moves to quadratic sieve / NFS methods.

## Known examples (tests)

| $N$ | Result |
| --- | --- |
| $0$ | `Invalid_Argument` |
| $1$ | not prime; empty `Factor_List`; SPF raises |
| $70$ | $2\cdot 5\cdot 7$ |
| $97$ | prime |
| $100$ | $2^{2}\cdot 5^{2}$ |
| $2047$ | $23\cdot 89$ |
| many $N\le 1000$ | `Is_Prime` vs independent reference |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Prime_Power` | record `Prime`, `Exponent` |
| `Factor_List` | unconstrained array of `Prime_Power` |
| `Is_Prime` | trial primality; $N=0$ raises |
| `Smallest_Prime_Factor` | least prime divisor; $N\in\{0,1\}$ raises |
| `Factorize` | complete factorization; $N=0$ raises; $N=1\to()$ |
| `Floor_Sqrt` | $\lfloor\sqrt{N}\rfloor$ via binary search |
| `Invalid_Argument` | domain error |

Comparisons in the trial loop use $D \le N/D$ (never $D\cdot D$) so the full
unsigned 64-bit range is safe; classroom demos usually stay near $2^{63}$
and below.

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Ptrial_division.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- $N=0$ is rejected on `Is_Prime`, `Smallest_Prime_Factor`, and `Factorize`.
- $N=1$ is not prime and has an empty factorization; SPF raises.
- Trial division is educational / small-$N$ practical; for cryptographic
  sizes prefer NFS-family methods (and Shor’s algorithm on a quantum
  computer — see the sibling note above).
- Unconstrained `Factor_List` uses the secondary stack; $\omega(N)$ for
  $N<2^{64}$ is tiny (at most about 15 distinct primes).

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
