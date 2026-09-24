# Gosper's algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Gosper's algorithm** — a
decision procedure that finds a **hypergeometric antidifference** $S$ for a
hypergeometric term $t$ when one exists:

$$
S(n+1) - S(n) = t(n).
$$

Equivalently, $S$ is a closed form for the **indefinite sum** of $t$. A term
$t$ is **hypergeometric** when the consecutive ratio

$$
R(n) = \frac{t(n+1)}{t(n)}
$$

is a **rational function** of $n$. See
[Wikipedia: Gosper's algorithm](https://en.wikipedia.org/wiki/Gosper's_algorithm).

This package implements a **classroom subset**: dense univariate polynomials
over $\mathbb{Q}$ (exact `Rational` Num/Den), Gosper normal form of a rational
ratio, a polynomial certificate $X$, and numeric telescoping checks on sample
integers. It is a teaching sketch, **not** a production computer-algebra
system (no Pochhammer symbols, factorials, or multivariate WZ automation).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Educational subset

| Supported | Representation |
| --- | --- |
| Polynomial terms | $t(n) = P(n)$ with dense $P \in \mathbb{Q}[n]$ |
| Geometric terms | $t(n) = r^{n}$ for rational $r$ |
| Rational-ratio terms | $t(n+1)/t(n) = A(n)/B(n)$ with polynomials $A,B$ and a seed $t(n_0)$ |
| Soft degree bound | `Max_Degree = 12` |
| Not included | Full factorial / Pochhammer CAS, Zeilberger / WZ pairing engine |

When the input is a polynomial $P$, the algorithm reduces to solving
$X(n+1)-X(n)=P(n)$ (discrete integration over $\mathbb{Q}[n]$), which always
succeeds inside the degree bound. Classic non-summable example in this subset:
$t(n)=1/n$ (ratio $n/(n+1)$) — the antidifference would be harmonic and is
**not** hypergeometric, so `Try_Gosper_Sum` returns `Found => False`.

## Outline of Gosper's steps (Wikipedia)

Following the
[Wikipedia outline](https://en.wikipedia.org/wiki/Gosper's_algorithm#Outline_of_the_algorithm)
and the standard Petkovšek–Wilf–Zeilberger normal form:

1. **Rewrite the ratio into Gosper form.** Given
   $R(n)=A(n)/B(n)$, compute polynomials $a,b,c$ such that

   $$
   R(n) = \frac{a(n)}{b(n)}\cdot\frac{c(n+1)}{c(n)}
   $$

   and $\gcd\bigl(a(n), b(n+j)\bigr)=1$ for every integer $j\ge 0$.

2. **Solve for a polynomial certificate $X$.** Find $X\in\mathbb{Q}[n]$
   (or prove none exists within the degree bound) satisfying

   $$
   a(n)\,X(n+1) - b(n-1)\,X(n) = c(n).
   $$

   This is a linear system on the unknown coefficients of $X$.

3. **Build the antidifference.** If $X$ exists,

   $$
   S(n) = \frac{b(n-1)\,X(n)}{c(n)}\,t(n)
   $$

   and $S(n+1)-S(n)=t(n)$. For pure polynomial terms with $a=b=1$ and
   $c=P$, one has simply $S=X$.

## Contrast with siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Gospers-Algorithm`) | Indefinite hypergeometric summation |
| **[Ada-Polynomial-Long-Division](https://github.com/RobertBoettcherSF/Ada-Polynomial-Long-Division)** | Euclidean poly division over $\mathbb{Q}$ |
| **[Ada-Extended-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Extended-Euclidean-Algorithm)** | Integer extended $\gcd$ |
| **[Ada-Kahan-Summation](https://github.com/RobertBoettcherSF/Ada-Kahan-Summation)** | Compensated floating-point summation |

README links only — **no** package `with` of siblings.

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Field** | `Rational` (Num/Den) | Lowest terms; `Den > 0` |
| **Polynomial** | Dense `Coeffs(0 .. Max_Degree)` | `Coeffs(I)` = coeff of $n^{I}$ |
| **Normal form** | `Gosper_Normal_Form` | Strip $a(n)$ vs $b(n+j)$ factors |
| **Certificate** | `Solve_Certificate` | Gaussian elimination over $\mathbb{Q}$ |
| **Entry** | `Try_Gosper_Sum` | `Found` + antidifference spec |
| **Check** | `Verify_Telescoping` | $S(n+1)-S(n)=t(n)$ at integer $n$ |
| **Errors** | `Invalid_Argument`, `Division_By_Zero` | Zero dens; degree overflow |
| **Bound** | `Max_Degree = 12` | Classroom only — not a CAS |

## Classic examples

| Term $t(n)$ | Antidifference idea |
| --- | --- |
| $n$ | $S(n)=n(n-1)/2$ |
| $1$ | $S(n)=n$ |
| $n(n+1)$ | cubic polynomial $S$ |
| $r^{n}$ ($r\neq 1$) | $S(n)=r^{n}/(r-1)$ |
| $1/n$ | **not** Gosper-summable |

## API sketch

| Operation | Role |
| --- | --- |
| `Make_Rational` / poly `Add`/`Mul`/`Shift`/`Poly_GCD` | Exact $\mathbb{Q}[n]$ toolkit |
| `Make_Polynomial_Term` / `Make_Geometric_Term` / `Make_Ratio_Term` | Build `Term_Spec` |
| `Gosper_Normal_Form` | Step 1: $A/B \mapsto (a,b,c)$ |
| `Solve_Certificate` | Step 2: solve for $X$ |
| `Try_Gosper_Sum` | Full decision: `Gosper_Result` |
| `Verify_Telescoping` / `Eval_Term` / `Eval_Antidifference` | Numeric checks |

## Build & test

```bash
make
make test
```

`gnatmake -gnatwa -gnat2022 -Pgospers_algorithm.gpr` must be warning-clean.
The test driver prints `Results: N PASS, 0 FAIL` and covers rationals,
polynomials, shifts/GCD, polynomial and geometric summability, ratio terms,
a non-summable case ($1/n$), and invalid inputs.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
gospers_algorithm.ads
gospers_algorithm.adb
gospers_algorithm.gpr
tests.adb
```

## References

1. [Wikipedia: Gosper's algorithm](https://en.wikipedia.org/wiki/Gosper's_algorithm)
2. Gosper, R. W. (1978). Decision procedure for indefinite hypergeometric summation. *PNAS* 75(1):40–42.
3. Petkovšek, Wilf, Zeilberger. *A = B*. (Gosper normal form / certificate.)

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
