# Multivariate division algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **multivariate division
algorithm** in two variables over the rationals. Fix a monomial order
$\le$ on $\mathbb{Q}[x,y]$ (here **Lex** with $x > y$, or **Grevlex**). For a
dividend $F$ and an ordered list of nonzero divisors $G_1,\ldots,G_s$, the
algorithm produces quotients $Q_1,\ldots,Q_s$ and a remainder $R$ such that

$$
F = Q_1 G_1 + \cdots + Q_s G_s + R
$$

and either $R = 0$ or **no term of** $R$ is divisible by any
$\mathrm{LT}(G_i)$. See
[Wikipedia: Multivariate division algorithm](https://en.wikipedia.org/wiki/Multivariate_division_algorithm)
(and the Gröbner-basis background page that some wiki links redirect to).

Unlike univariate Euclidean division, the remainder **depends on the order of
the divisors** unless $\{G_1,\ldots,G_s\}$ is a
[Gröbner basis](https://en.wikipedia.org/wiki/Gr%C3%B6bner_basis). This package
stops at division; Buchberger’s algorithm (which uses division as a subroutine)
is a natural follow-on, not implemented here.

Coefficients live in $\mathbb{Q}$ (exact `Rational` records reduced by GCD).
Polynomials are **sparse** lists of terms $(\mathrm{coeff},\,e_x,\,e_y)$ with
classroom bounds `Max_Degree = 8` per variable and `Max_Terms = 64`. This is a
teaching sketch, **not** a production computer algebra system.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with univariate long division

| | Univariate (`Ada-Polynomial-Long-Division`) | This package |
| --- | --- | --- |
| Ring | $\mathbb{Q}[x]$ | $\mathbb{Q}[x,y]$ |
| Order | Degree only | Lex / Grevlex on $\mathbb{N}^2$ |
| Storage | Dense coeff array | Sparse term list |
| Remainder | Unique; $\deg R < \deg G$ | Unique only for Gröbner bases |
| Identity | $F = QG + R$ | $F = \sum Q_i G_i + R$ |

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Field** | `Rational` (Num/Den) | Lowest terms; `Den > 0` |
| **Polynomial** | Sparse `Term` list | `Coeff · x^{Exp_X} y^{Exp_Y}` |
| **Orders** | `Monomial_Order` | `Lex`, `Grevlex` ($x > y$) |
| **Leading data** | `LT` / `LM` / `LC` | W.r.t. chosen order |
| **Normalize** | Combine like terms, drop zeros, sort | Descending by order |
| **Division** | `Divide` | Classic multivariate loop |
| **Identity** | $F = \sum Q_i G_i + R$ | No $\mathrm{LT}(G_i)$ divides a term of $R$ |
| **Errors** | `Division_By_Zero`, `Invalid_Argument` | Zero / empty divisors; degree overflow |
| **Bounds** | `Max_Degree = 8`, `Max_Terms = 64` | Classroom only |

## Algorithm steps

Write $\mathrm{LT}$, $\mathrm{LM}$, $\mathrm{LC}$ relative to the fixed monomial
order. Initialize $Q_i \leftarrow 0$, $R \leftarrow 0$, and a working polynomial
$P \leftarrow F$. While $P \ne 0$:

1. If some $\mathrm{LT}(G_i)$ divides $\mathrm{LT}(P)$, pick the **first** such
   $i$ (smallest index), set
   $$
   t = \frac{\mathrm{LT}(P)}{\mathrm{LT}(G_i)},
   $$
   then $Q_i \leftarrow Q_i + t$ and $P \leftarrow P - t\cdot G_i$.
2. Otherwise move the leading term into the remainder:
   $R \leftarrow R + \mathrm{LT}(P)$ and $P \leftarrow P - \mathrm{LT}(P)$.

When the loop ends, the identity above holds and no term of $R$ is divisible by
any $\mathrm{LT}(G_i)$.

### Textbook example (Cox–Little–O’Shea)

Divide
$F = x^{2}y + xy^{2} + y^{2}$ by
$G_1 = xy - 1$ and $G_2 = y^{2} - 1$ under Lex with $x > y$.

- Order $(G_1,G_2)$: $Q_1 = x+y$, $Q_2 = 1$, $R = x+y+1$.
- Order $(G_2,G_1)$: remainders differ — $R = 2x+1$.

Both satisfy the division identity; only a Gröbner basis would make $R$
independent of ordering.

## API sketch

```ada
type Monomial_Order is (Lex, Grevlex);

function LT (P : Polynomial; Order : Monomial_Order) return Term;
function LC (P : Polynomial; Order : Monomial_Order) return Rational;

procedure Divide
  (F         :     Polynomial;
   Divisors  :     Poly_Array;   -- slots 1 .. N
   N         :     Divisor_Count;
   Order     :     Monomial_Order;
   Quotients : out Poly_Array;
   Remainder : out Polynomial);
--  F = sum_i Quotients(i)*Divisors(i) + Remainder
--  Raises Invalid_Argument if N = 0;
--  Raises Division_By_Zero if any Divisors(1..N) is zero.
```

Helpers: `Make_Rational`, `Normalize`, `Add` / `Sub` / `Mul` / `Mul_Term`,
`Compare_Monomials`, `Monomial_Divides`, `Monomial`, `Uni_X`, `Uni_Y`.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pmultivariate_division_algorithm.gpr
make test   # prints "Results: N PASS, 0 FAIL"
make clean
```

Requires GNAT with Ada 2022/2023 support. Zero `-gnatwa` warnings expected.

## Siblings (README links only — no `with`)

| Package | Idea |
| --- | --- |
| **[Ada-Polynomial-Long-Division](https://github.com/RobertBoettcherSF/Ada-Polynomial-Long-Division)** | Univariate Euclidean division over $\mathbb{Q}$ |
| **[Ada-Euclidean-Algorithm](https://github.com/RobertBoettcherSF/Ada-Euclidean-Algorithm)** | Integer $\gcd$ |
| **This package** | Multivariate division in $\mathbb{Q}[x,y]$ |
| Follow-on (not here) | Buchberger / Gröbner bases |

## References

- [Multivariate division algorithm](https://en.wikipedia.org/wiki/Multivariate_division_algorithm)
- [Gröbner basis](https://en.wikipedia.org/wiki/Gr%C3%B6bner_basis)
- Cox, Little, O’Shea — *Ideals, Varieties, and Algorithms* (division algorithm chapter)

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
