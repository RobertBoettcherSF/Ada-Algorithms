# Sieve of Eratosthenes — Ada 2023

Educational, self-contained Ada 2023 package for the classical
**Sieve of Eratosthenes**: find all prime numbers up to a limit $N$ by
marking composite multiples on a boolean array. See
[Wikipedia: Sieve of Eratosthenes](https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes).

This is an **integer** algorithm package (`Natural` / `Positive`), not a
`Real` / ODE teaching sketch. Language: **Ada 2023** (ISO/IEC 8652:2023),
compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Sieve-Of-Sundaram](https://github.com/RobertBoettcherSF/Ada-Sieve-Of-Sundaram)** —
  Sundaram sieve (note sheet marked skip/x; may already exist)
- **Sieve of Atkin** — next number-theoretic sieve in the series
- Miller–Rabin and other primality tests — upcoming

Note-sheet typo: **“Erastothenes”** → **Eratosthenes**.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Flags** | `Flag_Array` | Index = candidate; `True` = still prime |
| **Core** | `Sieve` | Mark composites from $p^2$ step $p$ |
| **Count** | `Count_Primes` | $\pi(N)$ |
| **List** | `Primes_Up_To` | Unconstrained secondary-stack `Prime_List` |
| **Fill** | `Fill_Primes` | Bounded `Prime_Buffer` + `Last` |
| **Lookup** | `Is_Prime_In_Sieve` | Query a computed flag array |
| **Bonus** | `Sieve_Odds` | Odds-only marking; same full result |
| **Domain** | `Invalid_Argument` | $N<2$ or $N>\texttt{Max\_N}$ |

Educational cap: `Max_N = 200_000` (keeps tests fast; $\pi(200\,000)=17\,984$).

## Algorithm

1. Allocate a boolean array `Is_Prime(0 .. N)` and set every entry `True`
   for indices $\ge 2$ (set `0` and `1` to `False`).
2. For each $p$ from $2$ to $\lfloor\sqrt{N}\rfloor$: if `Is_Prime(p)`, mark
   multiples $p^2,\ p^2+p,\ p^2+2p,\ \ldots$ as composite.
3. Remaining `True` entries are the primes $\le N$.

Starting at $p^2$ is enough: smaller multiples of $p$ were already marked
by smaller prime factors.

Time complexity of the basic sieve is

$$
O(N \log\log N),
$$

with $O(N)$ space for the flag array.

### Optimizations (educational)

- **Odds-only / wheel:** after handling $2$, store and mark only odd
  candidates (`Sieve_Odds` in this package returns a full `0 .. N` view for
  easy comparison).
- **Segmented sieve:** process the range in blocks so large $N$ fits in
  cache / memory. Mentioned here for reading; not required for the
  classroom `Max_N` cap.

## Known values (tests)

| $N$ | $\pi(N)$ |
| --- | --- |
| 10 | 4 |
| 100 | 25 |
| 1 000 | 168 |
| 10 000 | 1 229 |
| 100 000 | 9 592 |
| 200 000 | 17 984 |

First primes: $2,3,5,7,11,13,17,19,23$. Composites checked: $9,15,25,49$.
$0$ and $1$ are not prime; $97$ is prime.

## API summary

| Symbol | Role |
| --- | --- |
| `Max_N` / `Limit` | Educational cap $200\,000$; subtype `0 .. Max_N` |
| `Flag_Array` | `array (Natural range <>) of Boolean` |
| `Prime_List` / `Prime_Buffer` | Unconstrained / bounded lists of primes |
| `Sieve` | Full Is_Prime flags for $0 .. N$ |
| `Count_Primes` | $\pi(N)$ |
| `Primes_Up_To` | All primes $\le N$ (secondary stack) |
| `Fill_Primes` | Write primes into a buffer; set `Last` |
| `Nth_Prime` | $K$-th prime $\le N$ (1-based) |
| `Is_Prime_In_Sieve` | Lookup in an existing flag array |
| `Sieve_Odds` | Odds-only internal marking |
| `Floor_Sqrt` | Integer $\lfloor\sqrt{N}\rfloor$ (no `Float`) |
| `Ensure_Valid_N` | Raise if $N\notin[2,\texttt{Max\_N}]$ |
| `Invalid_Argument` | Domain error |

Public entry points take `Natural` so $N>\texttt{Max\_N}$ raises
`Invalid_Argument` (a `Limit` parameter would raise `Constraint_Error`
before the call).

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Psieve_of_eratosthenes.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- $N$ must satisfy $2\le N\le\texttt{Max\_N}$.
- Unconstrained `Primes_Up_To` uses the secondary stack; for very large
  lists prefer `Fill_Primes`.
- Segmented / parallel sieves are out of scope for this teaching package.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
