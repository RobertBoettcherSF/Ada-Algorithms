# Cantor–Zassenhaus algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Cantor–Zassenhaus**
algorithm: factor univariate polynomials over an **odd prime field**
$\mathbb{F}_{p}$ via distinct-degree factorization (DDF) followed by
equal-degree factorization (EDF) with random splitting. See
[Wikipedia: Cantor–Zassenhaus algorithm](https://en.wikipedia.org/wiki/Cantor–Zassenhaus_algorithm).

Dense monic polynomials store coefficients in $0..p-1$ with **index = power**:
`Coeffs(I)` is the coefficient of $x^{I}$. Soft classroom bound:
`Max_Degree = 24`. Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with
GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows (README links only — **no** package `with`):

- **[Ada-Berlekamp-Root-Finding](https://github.com/RobertBoettcherSF/Ada-Berlekamp-Root-Finding)** — roots in $\mathbb{F}_{p}$ (Berlekamp–Rabin)
- **[Ada-Polynomial-Long-Division](https://github.com/RobertBoettcherSF/Ada-Polynomial-Long-Division)** — Euclidean division over $\mathbb{Q}$
- **Berlekamp (1967)** — earlier matrix / Q-matrix factoring over finite fields

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Field** | Odd prime $p$ | Validated by trial division for $p\le$ `Max_Trial_Prime` |
| **Polynomial** | Dense `Coeffs(0 .. Max_Degree)` | Values reduced into $0..p-1$ |
| **Arithmetic** | `Add` / `Sub` / `Mul` / `Div_Mod` / `GCD` / `Mod_Exp` | All mod $p$ |
| **Square-free** | `Square_Free` = $f/\gcd(f,f')$ | Kernel; multiplicities dropped |
| **DDF** | Repeated Frobenius $x\mapsto x^{p}$ | Groups equal-degree irreducibles |
| **EDF** | Cantor–Zassenhaus random split | $\gcd\!\bigl(f,\,v^{(p^{d}-1)/2}-1\bigr)$ |
| **API** | `Factor (P, Poly, Factors, Count, Seed)` | Monic irreducible factors |
| **RNG** | LCG on `U64` Seed | Deterministic tests with fixed seed |
| **Errors** | `Invalid_Argument` | Even/composite $p$, zero poly, … |

## Educational scope (odd characteristic)

This package targets **odd** $p\ge 3$. Characteristic-$2$ needs a different
splitting polynomial (trace-style); that case is omitted on purpose for a
clear classroom presentation. Inputs may be non-monic (they are normalized
with `Make_Monic`); the zero polynomial is rejected.

`Factor` returns irreducible factors of the **square-free kernel**. Squared
factors such as $(x-a)^{2}(x-b)$ yield the distinct irreducibles $x-a$ and
$x-b$ once each — the product of reported factors recovers
`Square_Free(Poly)`, not necessarily the original polynomial with
multiplicities.

## Algorithm pipeline

### 1. Square-free kernel

$$
f_{\mathrm{sf}} = \frac{f}{\gcd(f,f')}.
$$

### 2. Distinct-degree factorization (DDF)

For square-free monic $f\in\mathbb{F}_{p}[x]$, compute (iteratively)
$h_{i} \equiv x^{p^{i}}\pmod{f}$ and

$$
g_{i} = \gcd(h_{i}-x,\,f).
$$

Each $g_{i}$ is the product of all monic irreducible factors of $f$ of
degree $i$. Divide those out and continue on the cofactor.

### 3. Equal-degree factorization (Cantor–Zassenhaus)

Suppose $f$ is square-free of degree $rd$ and is a product of $r\ge 2$
irreducibles of common degree $d$. Pick a random $v$ of degree less than
$\deg f$, set

$$
m = \frac{p^{d}-1}{2},
$$

and compute $w \equiv v^{m}\pmod{f}$. With good probability

$$
\gcd(f,\,w-1)
\quad\text{or}\quad
\gcd(f,\,w+1)
$$

is a nontrivial factor. Recurse on both pieces until every factor has
degree $d$ (hence is irreducible).

The split is **probabilistic**; a fixed `Seed` makes runs reproducible.
`Max_Attempts` (default 64) bounds unlucky draws.

## Contrast with Berlekamp

| | **Cantor–Zassenhaus** | **Berlekamp (1967)** |
| --- | --- | --- |
| Core linear algebra | None (GCD + modular poly pow) | Nullspace of $Q-I$ matrix |
| Randomness | Random $v$ for EDF splits | Random combination of Berlekamp algebra basis |
| Typical use | Dominant practical finite-field factoring | Classic textbook / small fields |
| This package | DDF + CZ EDF over odd $\mathbb{F}_{p}$ | See sibling root-finding package |

## Build and test

```bash
make
make test
```

Equivalent:

```bash
gnatmake -gnatwa -gnat2022 -Pcantor_zassenhaus.gpr
./bin/tests
```

Expect `Results:  N PASS, 0 FAIL` with $N\ge 50$ and zero `-gnatwa` warnings.

## API sketch

```ada
procedure Factor
  (P            :        Natural;
   Poly         :        Polynomial;
   Factors      :    out Factor_Array;
   Count        :    out Natural;
   Seed         : in out U64;
   Max_Attempts :        Positive := Default_Max_Attempts);
```

Helpers: `Add`, `Sub`, `Mul`, `Div_Mod`, `GCD`, `Mod_Exp`, `Square_Free`,
`Make_Monic`, `Normalize`, `Degree`, `From_Coeffs`, `Is_Prime_Trial`.

## License / intent

Teaching sketch for the Wikipedia algorithm — **not** a production computer
algebra system. Odd-characteristic educational scope only.
