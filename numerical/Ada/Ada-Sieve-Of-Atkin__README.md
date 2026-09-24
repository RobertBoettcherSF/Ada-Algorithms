# Sieve of Atkin — Ada 2023

Educational, self-contained Ada 2023 package for the **Sieve of Atkin**: find
all prime numbers up to a limit $N$ via quadratic residue toggles and
square-free culling. See
[Wikipedia: Sieve of Atkin](https://en.wikipedia.org/wiki/Sieve_of_Atkin).

This is an **integer** algorithm package (`Natural` / `Positive`), not a
`Real` / ODE teaching sketch. Language: **Ada 2023** (ISO/IEC 8652:2023),
compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Sieve-Of-Eratosthenes](https://github.com/RobertBoettcherSF/Ada-Sieve-Of-Eratosthenes)** —
  classical marking sieve (previous sibling; same API shape)
- **Miller–Rabin** — next primality topic (note-sheet typo **“Miler-Rabin”** →
  **Miller–Rabin**)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Flags** | `Flag_Array` | Index = candidate; `True` = prime |
| **Core** | `Sieve` | Mod-12 quadratic toggles + square cull |
| **Count** | `Count_Primes` | $\pi(N)$ |
| **List** | `Primes_Up_To` | Unconstrained secondary-stack `Prime_List` |
| **Fill** | `Fill_Primes` | Bounded `Prime_Buffer` + `Last` |
| **Lookup** | `Is_Prime_In_Sieve` | Query a computed flag array |
| **Domain** | `Invalid_Argument` | $N<2$ or $N>\texttt{Max\_N}$ |

Educational cap: `Max_N = 200_000` (keeps tests fast; $\pi(200\,000)=17\,984$).

## Algorithm

Educational **mod-12** form (clear Wikipedia / Atkin–Bernstein teaching
variant; equivalent known-$\pi(N)$ results to the mod-60 wheel write-up):

1. Allocate `Is_Prime(0 .. N)` all `False`.
2. For integers $x,y\ge 1$ with $n=4x^2+y^2\le N$: if $n\bmod 12\in\{1,5\}$,
   **toggle** `Is_Prime(n)`.
3. For $x,y\ge 1$ with $n=3x^2+y^2\le N$: if $n\bmod 12=7$, toggle.
4. For $x>y\ge 1$ with $n=3x^2-y^2\le N$: if $n\bmod 12=11$, toggle.
5. For each $r\ge 5$ with $r^2\le N$: if `Is_Prime(r)`, mark all
   $k\cdot r^2$ ($k\ge 1$) as composite (`False`).
6. Hardcode $2$ and $3$ as prime (when $\le N$). For $n\ge 5$,
   `Is_Prime(n)=True` means $n$ is prime.

Contrast with **Eratosthenes**: Eratosthenes marks multiples of each prime
$p$ from $p^2$; Atkin does preliminary quadratic work, then only culls
multiples of **squares** of primes. Theoretically the optimized page-segmented
Atkin sieve can reach $O(N)$ operations (vs Eratosthenes $O(N\log\log N)$),
though practical constant factors often favour a well-wheeled Eratosthenes.

This classroom package uses the clear $O(N)$ educational loops (with
$x,y$ bounded by $\lfloor\sqrt{N}\rfloor$), not a page-segmented production
sieve.

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
| `Floor_Sqrt` | Integer $\lfloor\sqrt{N}\rfloor$ (no `Float`) |
| `Ensure_Valid_N` | Raise if $N\notin[2,\texttt{Max\_N}]$ |
| `Invalid_Argument` | Domain error |

Public entry points take `Natural` so $N>\texttt{Max\_N}$ raises
`Invalid_Argument` (a `Limit` parameter would raise `Constraint_Error`
before the call).

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Psieve_of_atkin.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates). No `main.adb` —
`tests.adb` is the project main.

## Limits and caveats

- $N$ must satisfy $2\le N\le\texttt{Max\_N}$.
- Unconstrained `Primes_Up_To` uses the secondary stack; for very large
  lists prefer `Fill_Primes`.
- Page-segmented / lattice-point Atkin variants are out of scope for this
  teaching package.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
