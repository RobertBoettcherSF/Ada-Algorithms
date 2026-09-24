# Polynomial long division — Ada 2023

Educational, self-contained Ada 2023 package for **polynomial long division** —
the algorithm that implements **Euclidean division** of univariate polynomials.
Given dividend $A$ and nonzero divisor $B$, it produces unique quotient $Q$ and
remainder $R$ such that

$$
A = BQ + R
$$

with either $R = 0$ or $\deg R < \deg B$. See
[Wikipedia: Polynomial long division](https://en.wikipedia.org/wiki/Polynomial_long_division).

Coefficients live in $\mathbb{Q}$ (exact `Rational` records reduced by GCD).
Dense storage uses **index = power**: `Coeffs(I)` is the coefficient of
$x^{I}$ (`Coeffs(0)` = constant term). `Trim` / `Normalize` strip leading
zeros; the zero polynomial has `Degree = -1`. Soft classroom bound:
`Max_Degree = 32`. This is a teaching sketch, **not** a production computer
algebra system.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Polynomial-Long-Division`) | Euclidean poly division over $\mathbb{Q}$ |
| **[Ada-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Euclidean-Algorithm)** | Integer $\gcd$ by successive remainders |
| **[Ada-Long-Division](https://github.com/RobertBoettcherSF/Ada-Long-Division)** | Integer long division (decimal digits) |
| **[Ada-Polynomial-Interpolation](https://github.com/RobertBoettcherSF/Ada-Polynomial-Interpolation)** | Lagrange / Newton / Neville |
| **[Ada-Goldschmidt-Division](https://github.com/RobertBoettcherSF/Ada-Goldschmidt-Division)** | Iterative floating-point division |
| **[Ada-Karatsuba](https://github.com/RobertBoettcherSF/Ada-Karatsuba)** | Fast multiply (digit / poly teaching) |
| **[Ada-Risch-Algorithm](https://github.com/RobertBoettcherSF/Ada-Risch-Algorithm)** | Symbolic integration decision procedure |

README links only — **no** package `with` of siblings.

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Field** | `Rational` (Num/Den) | Lowest terms; `Den > 0` |
| **Polynomial** | Dense `Coeffs(0 .. Max_Degree)` | `Coeffs(I)` = coeff of $x^{I}$ |
| **Normalize** | `Trim` / `Normalize` | Drop leading zeros |
| **Division** | `Divide` | Classic long-division loop |
| **Identity** | $A = BQ + R$ | $\deg R < \deg B$ or $R=0$ |
| **Errors** | `Division_By_Zero`, `Invalid_Argument` | Zero divisor; degree overflow |
| **Bound** | `Max_Degree = 32` | Classroom only — not a CAS |

## Classic long-division loop

Write $A$ and $B$ with leading coefficients $\mathrm{LC}(A)$ and $\mathrm{LC}(B)$.
Initialize $Q \leftarrow 0$ and work on a mutable copy $f \leftarrow A$. While
$\deg(f) \ge \deg(B)$:

1. Form the monomial term
   $$
   t = \frac{\mathrm{LC}(f)}{\mathrm{LC}(B)}\, x^{\deg(f)-\deg(B)}.
   $$
2. Update $f \leftarrow f - t\cdot B$ and $Q \leftarrow Q + t$.

When the loop ends, $R := f$ is the remainder and $Q$ is the quotient. Over a
field (here $\mathbb{Q}$) every nonzero leading coefficient is invertible, so
the step is always defined when $B \ne 0$. The pair $(Q,R)$ is unique.

### Wikipedia example

Divide $A = x^{3}-2x^{2}-4$ by $B = x-3$:

$$
Q = x^{2}+x+3,\qquad R = 5,
$$

and the Euclidean identity holds:

$$
(x^{2}+x+3)(x-3)+5 = x^{3}-2x^{2}-4.
$$

Another classroom check: $(x^{2}-1)/(x-1) = x+1$ with remainder $0$ (exact
factorization).

## API sketch

| Operation | Role |
| --- | --- |
| `Make_Rational` / `Reduce` / `Equal` | Exact $p/q$ in lowest terms |
| `Degree` / `Trim` / `Normalize` / `Is_Zero` | Degree and canonical form |
| `Leading_Coefficient` | $\mathrm{LC}(p)$ |
| `Add` / `Sub` / `Mul` / `Scale` | Polynomial ring operations over $\mathbb{Q}$ |
| `Monomial` / `Constant_Poly` / `From_Coeffs` | Constructors |
| `Divide (A, B, Q, R)` | Long division; raises on $B=0$ |

## Build & test

```bash
make
make test
```

`gnatmake -gnatwa -gnat2022 -Ppolynomial_long_division.gpr` must be
warning-clean. The test driver prints `Results: N PASS, 0 FAIL` and covers
rationals, degree/trim, ring ops, the Wikipedia example, exact division,
$\deg R < \deg B$, the reconstruct identity $A=BQ+R$, and `Division_By_Zero`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
polynomial_long_division.ads
polynomial_long_division.adb
polynomial_long_division.gpr
tests.adb
```

## References

1. [Wikipedia: Polynomial long division](https://en.wikipedia.org/wiki/Polynomial_long_division)
2. [Wikipedia: Euclidean division of polynomials](https://en.wikipedia.org/wiki/Polynomial_greatest_common_divisor#Euclidean_division)
3. [Wikipedia: Long division](https://en.wikipedia.org/wiki/Long_division)

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
