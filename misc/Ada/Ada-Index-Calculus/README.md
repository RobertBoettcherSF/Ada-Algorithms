# Index calculus algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **index calculus
algorithm**: compute discrete logarithms in $(\mathbb{Z}/q\mathbb{Z})^{*}$ by
collecting $B$-smooth relations among powers of a generator, solving for the
discrete logs of a factor base of small primes via linear algebra modulo the
group order, then descending an individual target. See
[Wikipedia: Index calculus algorithm](https://en.wikipedia.org/wiki/Index_calculus_algorithm).

This is a **classroom sketch** for tiny primes — **not** a production NFS-DL /
function-field sieve / Coppersmith implementation.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows (README links only — **no** package `with`):

- **[Ada-Pohlig-Hellman](https://github.com/RobertBoettcherSF/Ada-Pohlig-Hellman)** —
  DLP when the order is smooth (CRT of prime-power subgroups)
- **[Ada-Pollards-Rho-Logarithms](https://github.com/RobertBoettcherSF/Ada-Pollards-Rho-Logarithms)** —
  Pollard's rho for discrete logarithms ($O(\sqrt{n})$ expected)
- **Baby-step giant-step (BSGS)** — deterministic $O(\sqrt{n})$ generic DLP
- **[Ada-Dixon](https://github.com/RobertBoettcherSF/Ada-Dixon)** —
  factor-base / $B$-smoothness ideas (integer factorization sibling)

Empty GitHub repo:
[Ada-Index-Calculus](https://github.com/RobertBoettcherSF/Ada-Index-Calculus).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Sub_Mod`, `Modular_Inverse` | Self-contained |
| **Trial** | `Floor_Sqrt`, `Is_Prime_Trial` | Factor-base build |
| **Smooth** | `Primes_Up_To`, `Is_B_Smooth`, `Smooth_Exponents` | Factor base of primes $\le B$ |
| **Relations** | `Collect_Relations` | $B$-smooth $g^{k}\bmod q$ |
| **LinAlg** | `Solve_Factor_Base_Logs` | Gaussian elimination mod `Order` |
| **IC DLP** | `Discrete_Log_Index_Calculus` | Full pipeline + seed / bound |
| **Failure** | return `Order` | Documented sentinel |
| **Domain** | `Invalid_Argument` | Bad modulus / order / $g,h$ |

## Algorithm

Given a prime modulus $q$, a generator $g\in(\mathbb{Z}/q\mathbb{Z})^{*}$, and
a target $h$, index calculus finds $x$ with

$$
g^{x}\equiv h\pmod{q}.
$$

The educational pipeline (Wikipedia stages, omitting $-1$ from the factor
base because residues are taken in $\{1,\ldots,q-1\}$):

1. **Choose a factor base.** The first primes $p\le B$ (smoothness bound).
2. **Collect relations.** Search exponents $k$ (sequential, then seeded LCG)
   such that $g^{k}\bmod q$ is $B$-smooth:
   $$
   g^{k}\equiv\prod_{i}p_{i}^{e_{i}}\pmod{q}
   \quad\Rightarrow\quad
   k\equiv\sum_{i}e_{i}\log_{g}p_{i}\pmod{\mathrm{ord}(g)}.
   $$
3. **Linear algebra.** Solve the system for $\log_{g}p_{i}$ by Gaussian
   elimination **modulo `Order`** (typically $q-1$). This sketch uses
   **invertible pivots only** ($\gcd(\mathrm{pivot},\mathrm{Order})=1$). When
   `Order` is composite, columns without an invertible pivot cause failure
   (documented gcd care — not a full Smith / CRT lattice solver). Each
   candidate log is **verified** by $g^{\log}\equiv p_{i}$.
4. **Individual logarithm.** Find $s$ with $h\cdot g^{s}$ $B$-smooth:
   $$
   h\cdot g^{s}\equiv\prod_{i}p_{i}^{f_{i}}
   \quad\Rightarrow\quad
   x\equiv\sum_{i}f_{i}\log_{g}p_{i}-s\pmod{\mathrm{Order}}.
   $$

Heuristic complexity (Wikipedia $L$-notation) is of the form

$$
L_{n}\bigl[1/2,\,\sqrt{2}+o(1)\bigr],
$$

far better than generic $O(\sqrt{n})$ methods for large prime fields — but
this package only targets tiny classroom $q\le\texttt{Max\_Educational\_Modulus}$.

### Classroom examples

| Instance | Demo |
| --- | --- |
| $6^{x}\equiv 11\pmod{41}$, order $40$ | $x=3$ |
| $6^{x}\equiv 36\pmod{41}$ | $x=2$ |
| $2^{x}\equiv 5\pmod{29}$, order $28$ | $x=22$ |
| $5^{x}\equiv 8\pmod{23}$, order $22$ | $x=6$ |
| $2^{x}\equiv 13\pmod{19}$, order $18$ | $x=5$ |
| $h=1$ | $x=0$ |

## What the code actually does

### Helpers

`Mul_Mod` multiplies via `Unsigned_128`. `Mod_Pow` is binary exponentiation.
`Gcd` / `Modular_Inverse` / `Sub_Mod` support elimination and verification
(self-contained extended Euclidean on `Long_Long_Integer`).

### Smoothness

`Primes_Up_To(B)` builds the factor base. `Is_B_Smooth` / `Smooth_Exponents`
trial-divide over that base (same spirit as Ada-Dixon, but for DLP residues
rather than $a^{2}\bmod N$).

### `Collect_Relations` / `Solve_Factor_Base_Logs`

Relation search prefers sequential $k$, then a seeded LCG. The solver builds
an augmented matrix of exponent rows $\|k$, reduces with invertible pivots
modulo `Order`, and verifies each factor-base log.

### `Discrete_Log_Index_Calculus`

Runs the full pipeline for $q\le\texttt{Max\_Educational\_Modulus}$
($50\,000$). Escalates the smoothness bound on failure. Returns
$\gamma\in\{0,\ldots,n-1\}$ or the failure sentinel $n$ (`Order`).
`Seed` selects the LCG stream; `Smoothness` is the initial bound $B$.
Raises `Invalid_Argument` for bad inputs.

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Mul_Mod` / `Mod_Pow` | modular multiply / power |
| `Gcd` / `Sub_Mod` / `Modular_Inverse` | arithmetic / inverse |
| `Floor_Sqrt` / `Is_Prime_Trial` | trial helpers |
| `Factor_Base` / `Primes_Up_To` | factor base |
| `Is_B_Smooth` / `Smooth_Exponents` | smoothness |
| `Relation` / `Collect_Relations` | smooth $g^{k}$ relations |
| `Solve_Factor_Base_Logs` | logs of factor-base primes |
| `Verify_Discrete_Log` | check $g^{\log}\equiv h$ |
| `Discrete_Log_Index_Calculus` | educational index-calculus DLP |
| `Invalid_Argument` | domain error |
| `Max_Educational_Modulus` | classroom cap on $q$ ($5\cdot 10^{4}$) |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pindex_calculus.gpr
make test   # run bin/tests (≥70 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`).

## Limits and caveats

- Classroom `U64` toy — **not** suitable for cryptographic sizes or NFS-DL.
- Linear algebra uses invertible pivots only; composite `Order` may force the
  failure sentinel when a column has no unit pivot (gcd care).
- Factor-base / relation buffers capped at `Max_Factor_Base` / `Max_Relations`.
- Omits $-1$ from the Wikipedia factor base (positive residues only).
- Distinct from Pohlig–Hellman (smooth **order**), Pollard's rho DLP, and BSGS.

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
