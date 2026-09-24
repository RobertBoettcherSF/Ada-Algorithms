# Special Number Field Sieve (SNFS) — Ada 2023

Educational, self-contained Ada 2023 **classroom sketch** of the
**special number field sieve** — a special-purpose integer factorization
algorithm for integers of the form $r^{e}\pm s$ (and similar sparse
polynomials). See
[Wikipedia: Special number field sieve](https://en.wikipedia.org/wiki/Special_number_field_sieve).

This is **not** a production NFS. There are **no** algebraic number fields,
ideal lattices, or industrial sieves here — only `U64` helpers, special-form
detectors, $B$-smoothness, and a **congruence-of-squares** core that shows
the NFS *idea* on tiny $N$.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Trial-Division](https://github.com/RobertBoettcherSF/Ada-Trial-Division)** —
  classical $\sqrt{N}$ factorization / primality
- **[Ada-Primality-Test](https://github.com/RobertBoettcherSF/Ada-Primality-Test)** —
  survey taxonomy of primality tests
- **Next (educational sketch):** **quadratic sieve** (same congruence-of-squares
  engine; polynomial $Q(x)=x^{2}-N$ instead of an SNFS poly)
- **[Shor’s algorithm](https://github.com/RobertBoettcherSF)** — quantum
  polynomial-time factoring already exists elsewhere in the GitHub org
  (`Ada-Shors-Algorithm`); this package stays classical

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Taxonomy** | `Special_Form_Kind`, `Is_Special_Form`, … | Tiny-parameter detectors |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Floor_Sqrt` | Self-contained |
| **Trial** | `Is_Prime_Trial`, `Smallest_Prime_Factor` | Fallback / peel |
| **Smooth** | `Primes_Up_To`, `Is_B_Smooth`, `Smooth_Exponents` | Factor-base checks |
| **CoS core** | `Factor_Via_Congruence_Of_Squares` | GF(2) dependency → factor |
| **Toy SNFS** | `Toy_Factor_SNFS_Like` | Scan + smooth + CoS for $N\le 10^{6}$ |
| **Domain** | `Invalid_Argument` | Bad moduli / out-of-range toys |

## SNFS vs GNFS (prose pipeline)

Wikipedia: SNFS is efficient for integers of special form $r^{e}\pm s$
(e.g. Mersenne / Cunningham numbers). The **general** number field sieve
(GNFS) handles arbitrary $N$ but with a worse constant in the complexity.

Heuristic SNFS complexity (O / $L$-notation):

$$
\exp\Bigl((1+o(1))\bigl(\tfrac{32}{9}\log N\bigr)^{1/3}(\log\log N)^{2/3}\Bigr)
= L_{N}\bigl[1/3,(32/9)^{1/3}\bigr]
$$

GNFS replaces $32/9$ by $64/9$ (same $L_{N}[1/3,\cdot]$ shape, larger leading
constant). Both dominate trial division / quadratic sieve for large $N$;
SNFS wins when a **sparse** polynomial with small coefficients exists.

### Full SNFS pipeline (documented only — not coded)

1. **Polynomial selection.** Choose an irreducible $f\in\mathbb{Z}[x]$ of
   modest degree and an integer $m$ with $f(m)\equiv 0\pmod{N}$. For
   $N=r^{e}\pm s$, a natural SNFS poly often has tiny coefficients
   (example from Wikipedia: factoring $3^{479}+1$ with $f(x)=x^{6}+3$,
   $m=3^{80}$).
2. **Sieving.** Search pairs $(a,b)$ so that both the rational side
   $a+bm$ and the algebraic side (norm of $a+b\alpha$) are smooth over
   chosen factor bases — the “sieve” that names the algorithm.
3. **Linear algebra.** Turn smooth relations into a matrix over
   $\mathrm{GF}(2)$ (exponent parities). Find a nonempty dependency so
   every exponent in the product is even → a congruence of squares
   $X^{2}\equiv Y^{2}\pmod{N}$.
4. **Square root / gcd.** Compute $X,Y$ and hope
   $\gcd(|X-Y|,N)$ is a nontrivial factor.

This package implements step **3–4** on **pre-supplied** (or toy-scanned)
rational smooth values of $X^{2}\bmod N$, and step **1** only as
`Is_Special_Form` taxonomy. Algebraic sieving is left to the README.

## What the code actually does

### Special-form sketches

Detect (tiny parameters only):

- **Mersenne-like:** $N=2^{k}-1$ ($k\ge 2$)
- **Fermat-like:** $N=2^{2^{k}}+1$ for $k\le 5$
- **Power difference / sum:** $N=a^{e}\pm b^{e}$ with $e\le 12$, $a,b\le 32$

### Smoothness

`Is_B_Smooth(N, Base)` trial-divides $N$ by every prime in `Base` and
requires the cofactor to be $1$.

### Congruence of squares

Given relations $(X_{i},Q_{i})$ with $Q_{i}=X_{i}^{2}\bmod N$ $B$-smooth,
build the $\mathrm{GF}(2)$ matrix of exponent parities, find a dependency,
form $X=\prod X_{i}$ and $Y=\prod p^{e/2}$, then return
$\gcd(|X-Y|,N)$ when nontrivial.

### Toy factor

`Toy_Factor_SNFS_Like` (for $N\le 10^{6}$) scans $X>\lfloor\sqrt{N}\rfloor$,
collects smooth $X^{2}\bmod N$, runs the CoS solver, and falls back to
trial SPF if needed. Even $N>2$ returns $2$ immediately.

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $15=3\cdot 5$ | CoS with $4^{2}\equiv 1$; toy factor |
| $91=7\cdot 13$ | CoS with $10^{2}\equiv 9$; toy factor |
| $143=11\cdot 13$ | CoS with $12^{2}\equiv 1$ |
| $8051=83\cdot 97$ | classic QS classroom semiprime; toy SNFS-like |
| $2047=23\cdot 89$ | Mersenne-like $2^{11}-1$; toy factor |
| $31,127$ | Mersenne-like detectors |
| $17,65537$ | Fermat-like detectors |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Special_Form_Kind` / `Form_Name` | taxonomy |
| `Is_Special_Form` / `Classify_Special_Form` | detectors |
| `Is_Mersenne_Like` / `Is_Fermat_Like` | $2^{k}-1$, $2^{2^{k}}+1$ |
| `Is_Power_Difference` / `Is_Power_Sum` | tiny $a^{e}\pm b^{e}$ |
| `Mul_Mod` / `Mod_Pow` / `Gcd` / `Floor_Sqrt` | arithmetic |
| `Is_Prime_Trial` / `Smallest_Prime_Factor` | trial helpers |
| `Factor_Base` / `Primes_Up_To` | factor base |
| `Is_B_Smooth` / `Smooth_Exponents` | smoothness |
| `Relation` / `Relation_List` | $(X,Q)$ with $X^{2}\equiv Q\pmod{N}$ |
| `Factor_Via_Congruence_Of_Squares` | GF(2) CoS factor |
| `Toy_Factor_SNFS_Like` | scan + CoS for $N\le 10^{6}$ |
| `Invalid_Argument` | domain error |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pspecial_number_field_sieve.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Classroom sketch only — **not** suitable for cryptographic sizes.
- `Toy_Factor_SNFS_Like` rejects $N>\texttt{Toy_Factor_Max}$ ($10^{6}$).
- Factor-base / relation matrices are capped at 64 rows/columns.
- Special-form detectors use tiny parameter bounds; they do **not**
  certify SNFS suitability for cryptographic Cunningham numbers.
- Unconstrained `Factor_Base` / `Relation_List` returns use the secondary
  stack (fine for educational sizes).

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
