# Faugère F4 algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Faugère's F4 algorithm**:
computing a [Gröbner basis](https://en.wikipedia.org/wiki/Gr%C3%B6bner_basis)
of a bivariate ideal over the rationals by reducing many S-polynomials at once
with linear algebra. See
[Wikipedia: Faugère F4 algorithm](https://en.wikipedia.org/wiki/Faug%C3%A8re_F4_algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Part of the **RobertBoettcherSF** Ada algorithm series.

## Buchberger vs F4

Both algorithms rest on the same Buchberger criterion: a set $G$ is a Gröbner
basis when every S-polynomial $S(g_i,g_j)$ reduces to zero modulo $G$.

| | Buchberger | F4 (this package) |
| --- | --- | --- |
| Reduction | One $S(g_i,g_j)$ at a time | Many critical pairs in one batch |
| Engine | Multivariate division | Sparse Macaulay-style matrix + Gaussian elimination over $\mathbb{Q}$ |
| Selection | Pair queue (various strategies) | Degree batches: all pairs of minimal $\deg\mathrm{LCM}(\mathrm{LM}(g_i),\mathrm{LM}(g_j))$ |
| New basis elements | Remainders of single S-polys | Nonzero rows whose leading terms enlarge $\langle\mathrm{LT}(G)\rangle$ |

F4 (Faugère, 1999) forms rows that are monomial multiples of current basis
polynomials covering the terms needed for the selected pairs, row-reduces that
matrix, and reads off new polynomials. The related **F5** algorithm (signature
criteria that avoid many reductions to zero) is **not** implemented here — see
the Wikipedia page for F5 and systems such as cyclic-$n$.

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Field** | `Rational` (Num/Den) | GCD-reduced; `Den > 0` |
| **Polynomial** | Sparse `Term` list | $\mathrm{Coeff}\cdot x^{e_x} y^{e_y}$ |
| **Orders** | `Monomial_Order` | `Lex`, `Grevlex` ($x > y$) |
| **S-polynomial** | `S_Polynomial` | $S(f,g)=(t/\mathrm{LT}(f))f-(t/\mathrm{LT}(g))g$ |
| **Reduction** | `Normal_Form` | Multivariate remainder |
| **F4 driver** | `Groebner_Basis_F4` | Pair batch → matrix → row reduce → extract |
| **Errors** | `Invalid_Argument`, `Division_By_Zero`, `Incomplete_Computation` | Bad input / capacity |
| **Bounds** | `Max_Degree=8`, `Max_Terms=48`, `Max_Polys=16`, `Max_Matrix=48` | Classroom only |

## Algorithm sketch

Fix a monomial order. Start from generators $G$ and the set of critical pairs.

1. **Select** all active pairs whose LCM of leading monomials has minimal total
   degree (subject to `Max_Deg`).
2. **Rows**: for each selected pair $(f,g)$ with
   $t=\mathrm{LCM}(\mathrm{LM}(f),\mathrm{LM}(g))$, insert the multiples
   $(t/\mathrm{LT}(f))\,f$ and $(t/\mathrm{LT}(g))\,g$.
3. **Symbolic preprocessing**: while some monomial $m$ appearing in a row is
   divisible by $\mathrm{LM}(h)$ for $h\in G$, add the multiple
   $(m/\mathrm{LM}(h))\,h$ if it is not already a row.
4. **Linear algebra**: build the coefficient matrix with columns ordered by the
   monomial order (descending) and compute a reduced row echelon form over
   $\mathbb{Q}$.
5. **Update**: each nonzero row whose leading term is **not** in
   $\langle\mathrm{LT}(G)\rangle$ becomes a new basis element; form new pairs.
6. Repeat until no pairs remain (or `Max_Steps` / capacity bounds intervene).
   Optionally auto-reduce the basis with `Normal_Form`.

When the loop finishes inside bounds, Buchberger's criterion holds for the
returned set (verified in tests by reducing all S-pairs to zero).

### Tiny textbook ideal

For
$$
I = \langle x^{2}-y,\ xy-1\rangle \subset \mathbb{Q}[x,y]
$$
under Grevlex, F4 recovers a Gröbner basis whose leading-term ideal contains
$x$ and $y^{3}$ (equivalently generators such as $x-y^{2}$ and $y^{3}-1$ up to
units). Ideal membership is decided by `Normal_Form(f, GB) = 0`.

## Educational limits

- Two variables only; coefficients in $\mathbb{Q}$ (machine `Integer` numerators /
  denominators — overflow possible on huge intermediates).
- Absolute caps: degree $\le 8$ per variable, $\le 16$ basis polynomials,
  $\le 48$ matrix rows/columns, $\le 64$ critical pairs.
- `Max_Deg` / `Max_Steps` parameters stop early: `Complete=False`, or
  `Incomplete_Computation` when a hard capacity is exceeded.
- Not FGb / Maple / Magma / SageMath performance; no F5 signatures.

## API (brief)

```text
Make_Rational, Reduce_Q, + - * / on Rational
Compare_Monomials, Monomial_Divides, Monomial_LCM
Normalize, LT / LM / LC, Add, Sub, Scale, Mul, Mul_Term
S_Polynomial, Normal_Form, LT_In_Ideal
Groebner_Basis_F4 (Generators, N, Order, Basis, Basis_N, Complete,
                   Max_Deg => 6, Max_Steps => 32)
```

## Build and test

```bash
make
make test
make clean
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022 -Pfaugere_f4.gpr`).
Expected summary line: `Results:  N PASS, 0 FAIL` with $N \ge 40$.
