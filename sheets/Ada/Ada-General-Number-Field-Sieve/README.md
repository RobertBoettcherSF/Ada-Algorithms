# General Number Field Sieve (GNFS) — Ada 2023

Educational, self-contained Ada 2023 **classroom sketch** of the
**general number field sieve** — the asymptotically fastest classical
general-purpose integer factorization method for large $N$. See
[Wikipedia: General number field sieve](https://en.wikipedia.org/wiki/General_number_field_sieve).

This is **not** a production NFS. There are **no** algebraic number fields,
ideal lattices, or industrial sieves here — only `U64` helpers, a factoring
taxonomy / $L_{n}[1/3]$ complexity helper, pipeline-stage names, $B$-smoothness,
and a **congruence-of-squares** core that shows the NFS *idea* on tiny $N$.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows:

- **[Ada-Special-Number-Field-Sieve](https://github.com/RobertBoettcherSF/Ada-Special-Number-Field-Sieve)** —
  SNFS-like CoS sketch for special-form $N=r^{e}\pm s$
- **[Ada-Quadratic-Sieve](https://github.com/RobertBoettcherSF/Ada-Quadratic-Sieve)** —
  QS classroom CoS / factor-base sketch
- **[Ada-Elliptic-Curve-Method](https://github.com/RobertBoettcherSF/Ada-Elliptic-Curve-Method)** —
  ECM sibling (related classical factoring)
- **Next (educational sketch):** **Fermat’s factorization method**
  ($a^{2}-b^{2}$ near $\sqrt{N}$)
- **[Shor’s algorithm](https://github.com/RobertBoettcherSF)** — quantum
  polynomial-time factoring already exists elsewhere (`Ada-Shors-Algorithm`);
  this package stays classical

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Word** | `U64` (`mod 2**64`) | Educational domain |
| **Taxonomy** | `Factoring_Family`, `Heuristic_Complexity` | $L_{n}[1/3]$ docs |
| **SNFS↔GNFS** | `Nfs_Variant`, constant $64$ vs $32$ | API contrast flags |
| **Pipeline** | `Pipeline_Stage`, `Stage_Name` | Enumerated stages |
| **Helpers** | `Mul_Mod`, `Mod_Pow`, `Gcd`, `Floor_Sqrt` | Self-contained |
| **Trial** | `Is_Prime_Trial`, `Smallest_Prime_Factor` | Fallback / peel |
| **Smooth** | `Primes_Up_To`, `Is_B_Smooth`, `Smooth_Exponents` | Factor-base checks |
| **CoS core** | `Factor_Via_Congruence_Of_Squares` | GF(2) dependency → factor |
| **Toy GNFS** | `Toy_Factor` | Scan + smooth + CoS for $N\le 10^{6}$ |
| **Domain** | `Invalid_Argument` | Bad moduli / out-of-range toys |

## Complexity — $L_{n}[1/3]$ heuristic

Wikipedia: GNFS is the most efficient classical algorithm known for factoring
integers larger than about $10^{100}$. Heuristically, its complexity for
factoring an integer $n$ is

$$
\exp\Bigl(\bigl((64/9)^{1/3}+o(1)\bigr)(\log n)^{1/3}(\log\log n)^{2/3}\Bigr)
= L_{n}\bigl[1/3,(64/9)^{1/3}\bigr]
$$

SNFS uses the same $L_{n}[1/3,\cdot]$ shape with leading constant $32/9$
instead of $64/9$ when a sparse special-form polynomial exists. Quadratic
sieve sits in the older $L_{n}[1/2,1]$ class; trial division is $O(\sqrt{n})$.

| Method | Strength | Heuristic cost (sketch) |
| --- | --- | --- |
| **Trial division** | Tiny $N$; complete factorization | $O(\sqrt{N})$ |
| **Quadratic sieve** | General $N$; historically best under ~100 digits | $L_{N}[1/2,1]$ |
| **SNFS** | Special form $r^{e}\pm s$ | $L_{N}[1/3,(32/9)^{1/3}]$ |
| **GNFS** | General large $N$ (RSA-scale) | $L_{N}[1/3,(64/9)^{1/3}]$ |
| **ECM** | Medium factors of huge $N$ | $L_{p}[1/2,\sqrt{2}]$ (in $p$) |

`Heuristic_Complexity` / `Is_L_One_Third_Family` expose these sketches in the
API. `Complexity_Constant_Numerator` returns $64$ (GNFS) or $32$ (SNFS).

## Full GNFS pipeline (documented only — not coded)

Production GNFS (and SNFS) share a multi-stage pipeline. This package names
the stages as `Pipeline_Stage` / `Stage_Name` but implements only the
congruence-of-squares *idea* on rational smooth values:

1. **Polynomial selection.** Choose an irreducible $f\in\mathbb{Z}[x]$ of
   modest degree and an integer $m$ with $f(m)\equiv 0\pmod{N}$. For general
   $N$ this is a hard optimization problem (GNFS); for $N=r^{e}\pm s$ a
   natural sparse poly often has tiny coefficients (SNFS).
2. **Factor-base setup.** Build rational and algebraic factor bases of
   primes (and prime ideals) up to smoothness bounds.
3. **Sieving.** Search pairs $(a,b)$ so that both the rational side
   $a+bm$ and the algebraic side (norm of $a+b\alpha$) are smooth — the
   “sieve” that names the algorithm. Lattice sieving is industrial practice.
4. **Filtering.** Remove singletons / excess relations to shrink the matrix.
5. **Linear algebra.** Turn smooth relations into a matrix over
   $\mathrm{GF}(2)$ (exponent parities). Find a nonempty dependency so
   every exponent in the product is even → a congruence of squares
   $X^{2}\equiv Y^{2}\pmod{N}$.
6. **Square root.** Compute rational and algebraic square roots of the
   dependency product (hard in the number field; trivial on the rational
   side for this toy).
7. **GCD split.** Compute $X,Y$ and hope $\gcd(|X-Y|,N)$ is a nontrivial
   factor.

This package implements steps **5–7** on **pre-supplied** (or toy-scanned)
rational smooth values of $X^{2}\bmod N$. Algebraic sieving and number
fields are left to the README.

## What the code actually does

### Taxonomy / SNFS vs GNFS flags

- `Factoring_Family` + `Heuristic_Complexity` document trial / QS / SNFS /
  GNFS / ECM sketches.
- `Nfs_Variant` contrasts **general** vs **special**;
  `Recommended_Variant(Bits, Has_Special_Form)` returns `Special_Nfs` when
  a special form is claimed, else `General_Nfs`.
- `Prefer_Snfs_When_Special_Form` is always `True` (documenting the rule).

### Smoothness

`Is_B_Smooth(N, Base)` trial-divides $N$ by every prime in `Base` and
requires the cofactor to be $1$.

### Congruence of squares

Given relations $(X_{i},Q_{i})$ with $Q_{i}=X_{i}^{2}\bmod N$ $B$-smooth,
build the $\mathrm{GF}(2)$ matrix of exponent parities, find a dependency,
form $X=\prod X_{i}$ and $Y=\prod p^{e/2}$, then return
$\gcd(|X-Y|,N)$ when nontrivial.

### Toy factor

`Toy_Factor` (for $N\le 10^{6}$) scans $X>\lfloor\sqrt{N}\rfloor$,
collects smooth $X^{2}\bmod N$, runs the CoS solver, and falls back to
trial SPF if needed. Even $N>2$ returns $2$ immediately. Same spirit as
the SNFS package’s `Toy_Factor_SNFS_Like`.

## Known examples (tests)

| $N$ | Demo |
| --- | --- |
| $15=3\cdot 5$ | CoS with $4^{2}\equiv 1$; toy factor |
| $91=7\cdot 13$ | CoS with $10^{2}\equiv 9$; toy factor |
| $143=11\cdot 13$ | CoS with $12^{2}\equiv 1$ |
| $8051=83\cdot 97$ | classic QS classroom semiprime; toy GNFS-like |
| $187=11\cdot 17$, $221=13\cdot 17$ | toy factor |
| Taxonomy | GNFS $L_{n}[1/3,(64/9)^{1/3}]$ vs SNFS $32/9$ |

## API summary

| Symbol | Role |
| --- | --- |
| `U64` | `mod 2**64` word type |
| `Factoring_Family` / `Family_Name` | taxonomy |
| `Heuristic_Complexity` / `Is_L_One_Third_Family` | $L_{n}[1/3]$ helpers |
| `Nfs_Variant` / `Variant_Name` | SNFS vs GNFS flags |
| `Complexity_Constant_Numerator` | $64$ (GNFS) / $32$ (SNFS) |
| `Recommended_Variant` | special-form → SNFS else GNFS |
| `Pipeline_Stage` / `Stage_Name` | poly → sieve → LA → gcd |
| `Mul_Mod` / `Mod_Pow` / `Gcd` / `Floor_Sqrt` | arithmetic |
| `Is_Prime_Trial` / `Smallest_Prime_Factor` | trial helpers |
| `Factor_Base` / `Primes_Up_To` | factor base |
| `Is_B_Smooth` / `Smooth_Exponents` | smoothness |
| `Relation` / `Relation_List` | $(X,Q)$ with $X^{2}\equiv Q\pmod{N}$ |
| `Factor_Via_Congruence_Of_Squares` | GF(2) CoS factor |
| `Toy_Factor` | scan + CoS for $N\le 10^{6}$ |
| `Invalid_Argument` | domain error |

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Pgeneral_number_field_sieve.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no external math crates).

## Limits and caveats

- Classroom sketch only — **not** suitable for cryptographic sizes.
- `Toy_Factor` rejects $N>\texttt{Toy_Factor_Max}$ ($10^{6}$).
- Factor-base / relation matrices are capped at 64 rows/columns.
- No algebraic number fields, no lattice sieving, no multiprecision $N$.
- Unconstrained `Factor_Base` / `Relation_List` returns use the secondary
  stack (fine for educational sizes).

## License

Educational sample for the RobertBoettcherSF Ada algorithm series.
