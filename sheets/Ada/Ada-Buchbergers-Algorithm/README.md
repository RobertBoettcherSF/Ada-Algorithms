# Buchberger's algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Buchberger's algorithm**:
transforming a generating set of a bivariate ideal over the rationals into a
[Gröbner basis](https://en.wikipedia.org/wiki/Gr%C3%B6bner_basis). See
[Wikipedia: Buchberger's algorithm](https://en.wikipedia.org/wiki/Buchberger's_algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Part of the **RobertBoettcherSF** Ada algorithm series.

## Gröbner bases and the Buchberger criterion

Fix a monomial order $\le$ on $\mathbb{Q}[x,y]$ (here **Lex** with $x > y$, or
**Grevlex**). For a nonzero polynomial $f$, write $\mathrm{LT}(f)$,
$\mathrm{LM}(f)$, $\mathrm{LC}(f)$ for its leading term, monomial, and
coefficient. A finite set $G = \{g_1,\ldots,g_t\}$ is a **Gröbner basis** of
the ideal $I = \langle G\rangle$ when

$$
\langle \mathrm{LT}(g_1),\ldots,\mathrm{LT}(g_t)\rangle
  = \langle \mathrm{LT}(I)\rangle,
$$

equivalently: every $f\in I$ reduces to $0$ by multivariate division by $G$.

Buchberger's **criterion**: $G$ is a Gröbner basis iff for every pair
$g_i,g_j$ the **S-polynomial**

$$
S(g_i,g_j)
  = \frac{t}{\mathrm{LT}(g_i)}\,g_i
  - \frac{t}{\mathrm{LT}(g_j)}\,g_j,
\qquad
t = \mathrm{LCM}\bigl(\mathrm{LM}(g_i),\mathrm{LM}(g_j)\bigr)
$$

reduces to zero modulo $G$. The algorithm starts from the generators, reduces
S-polynomials one pair at a time, and adds nonzero remainders until the
criterion holds. Termination follows from Dickson's lemma (ascending chains of
monomial ideals stabilize).

Special cases: univariate Euclidean GCD, and Gaussian elimination when all
degrees are one.

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Field** | `Rational` (Num/Den) | GCD-reduced; `Den > 0` |
| **Polynomial** | Sparse `Term` list | $\mathrm{Coeff}\cdot x^{e_x} y^{e_y}$ |
| **Orders** | `Monomial_Order` | `Lex`, `Grevlex` ($x > y$) |
| **S-polynomial** | `S_Polynomial` | From LCM of leading monomials |
| **Reduction** | `Normal_Form` | Multivariate remainder (self-contained) |
| **Driver** | `Groebner_Basis` | Classic pair loop + optional first criterion |
| **Check** | `Is_Groebner` | All S-pairs reduce to $0$ |
| **Errors** | `Invalid_Argument`, `Division_By_Zero`, `Incomplete_Computation` | Bad input / capacity |
| **Bounds** | `Max_Degree=8`, `Max_Terms=48`, `Max_Polys=16`, `Max_Pairs=128` | Classroom only |

## Algorithm sketch

Input: generators $F$; output: Gröbner basis $G$.

1. $G \leftarrow F$; form all critical pairs $(g_i,g_j)$.
2. While a pair remains: pick $(f_i,f_j)$; optionally **skip** if
   $\mathrm{LM}(f_i)$ and $\mathrm{LM}(f_j)$ share no variables (first
   Buchberger criterion — those S-polys always reduce to $0$).
3. Compute $S = S(f_i,f_j)$ and reduce by multivariate division relative to
   $G$. If the remainder $r\neq 0$, set $G \leftarrow G\cup\{r\}$ and enqueue
   new pairs involving $r$.
4. Repeat until no pairs remain. Then Buchberger's criterion holds.

### Tiny textbook ideal

For
$$
I = \langle x^{2}-y,\ xy-1\rangle \subset \mathbb{Q}[x,y]
$$
under Grevlex, Buchberger recovers a Gröbner basis whose leading-term ideal
contains generators such as $x-y^{2}$ and $y^{3}-1$ (up to units). Ideal
membership is decided by `Normal_Form(f, GB) = 0`.

## Siblings (do not `with`)

| Package | Role |
| --- | --- |
| [Ada-Multivariate-Division-Algorithm](https://github.com/RobertBoettcherSF/Ada-Multivariate-Division-Algorithm) | Division / remainder subroutine (ideas reused, self-contained here) |
| [Ada-Faugere-F4](https://github.com/RobertBoettcherSF/Ada-Faugere-F4) | Batch S-poly reduction via linear algebra |
| Knuth–Bendix completion | Analogous completion for rewrite systems (see Wikipedia “See also”) |

## Educational limits

- Two variables only; coefficients in $\mathbb{Q}$ (machine `Integer` numerators /
  denominators — overflow possible on huge intermediates).
- Absolute caps: degree $\le 8$ per variable, $\le 16$ basis polynomials,
  $\le 128$ critical pairs, $\le 48$ terms per poly.
- `Max_Steps` may stop early (`Complete=False`); hard capacity raises
  `Incomplete_Computation`.
- Not F4/F5 / FGb / Maple / Magma / SageMath performance; sugar strategy and
  advanced criteria are optional and only the first (coprime LT) criterion is
  implemented.

## API (brief)

```text
Make_Rational, Reduce_Q, + - * / on Rational
Compare_Monomials, Monomial_Divides, Monomial_LCM
Normalize, LT / LM / LC, Add, Sub, Scale, Mul, Mul_Term
S_Polynomial, Normal_Form, LT_In_Ideal
Groebner_Basis (Generators, N, Order, Basis, Basis_N, Complete,
                Max_Steps => 256)
Is_Groebner (Basis, N, Order)
```

## Build and test

```bash
make
make test
make clean
```

Requires GNAT with Ada 2022/2023 support
(`gnatmake -gnatwa -gnat2022 -Pbuchbergers_algorithm.gpr`).
Expected summary line: `Results:  N PASS, 0 FAIL` with $N \ge 50$.
