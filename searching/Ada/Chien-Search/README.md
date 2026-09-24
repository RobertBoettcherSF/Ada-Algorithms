# Chien search — Ada 2023

Educational, self-contained Ada 2023 package for the **Chien search**: find
roots of a univariate polynomial over the binary extension field
$\mathrm{GF}(2^{m})$ by evaluating along the powers of a primitive element
with a cheap recurrence. See
[Wikipedia: Chien search](https://en.wikipedia.org/wiki/Chien_search).

**Primary field:** $\mathrm{GF}(2^{m})$ for $m\in\{2,\ldots,8\}$, elements as
bitmasks (`Field_Element` / `Unsigned_16`), multiplication by polynomial
reduction modulo a fixed irreducible. Soft classroom bound:
`Max_Degree = 16`. Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with
GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling / related rows (README links only — **no** package `with`):

- **[Ada-Cantor-Zassenhaus](https://github.com/RobertBoettcherSF/Ada-Cantor-Zassenhaus)** — factoring over odd $\mathbb{F}_{p}$
- **[Ada-Berlekamp-Root-Finding](https://github.com/RobertBoettcherSF/Ada-Berlekamp-Root-Finding)** — probabilistic roots in $\mathbb{F}_{p}$
- **BCH / Reed–Solomon decoding** — Chien search finishes the pipeline after the error-locator polynomial is known

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Field** | $\mathrm{GF}(2^{m})$, $m\le 8$ | Built-ins via `Make_GF2(M)` |
| **Element** | Bitmask, bit $i$ = coeff of $x^{i}$ | Add = XOR |
| **Mul** | Schoolbook + reduce mod irreducible | Constant×variable in the Chien step |
| **Polynomial** | Dense `Coeffs(0 .. Max_Degree)` | Index = power |
| **Search** | Chien recurrence on $\alpha^{i}$ | Plus explicit $x=0$ test |
| **Oracle** | `Find_Roots_Brute` | Horner at every field element |
| **Errors** | `Invalid_Argument` | Bad $m$, zero poly, inconsistent irr |

## Role in RS / BCH decoding

In classical decoding of **BCH** and **Reed–Solomon** codes one computes an
**error-locator polynomial** $\Lambda(x)$ (e.g. via Berlekamp–Massey or
Euclidean algorithm). The error locations are the reciprocals (or the values
themselves, depending on convention) of the roots of $\Lambda$ in
$\mathrm{GF}(q)$. Chien search is the standard way to list those roots by
scanning the multiplicative group of the field in generator order — especially
attractive in hardware, where each step needs only multiplications by fixed
constants $\alpha^{j}$.

## Algorithm

Given $\Lambda(x)=\lambda_{0}+\lambda_{1}x+\cdots+\lambda_{t}x^{t}$ over
$\mathrm{GF}(q)$ with primitive element $\alpha$, write

$$
\Lambda(\alpha^{i})=\sum_{j=0}^{t}\gamma_{j,i},\qquad
\gamma_{j,0}=\lambda_{j},\qquad
\gamma_{j,i+1}=\gamma_{j,i}\,\alpha^{j}.
$$

Whenever the sum is zero, $\alpha^{i}$ is a root. Starting from $i=0$ through
$i=q-2$ covers every non-zero field element. Separately, $x=0$ is a root iff
$\lambda_{0}=0$.

### Chien recurrence vs naive evaluation

| Method | Per field element | Multiplies |
| --- | --- | --- |
| Brute / Horner | $O(t)$ general multiplies | Variable × variable |
| **Chien** | $O(t)$ updates $\gamma_{j}\leftarrow\gamma_{j}\alpha^{j}$ | Variable × **constant** $\alpha^{j}$ |

Both need $O(t)$ additions. Horner may evaluate elements in any order; Chien
commits to the generator order so that each register update is a constant
multiply — cheaper in hardware and competitive in software for small $t$.

## Built-in fields

| $m$ | Irreducible | $\alpha$ |
| --- | --- | --- |
| 2 | $x^{2}+x+1$ | $x$ |
| 3 | $x^{3}+x+1$ | $x$ |
| 4 | $x^{4}+x+1$ | $x$ |
| 5 | $x^{5}+x^{2}+1$ | $x$ |
| 6 | $x^{6}+x+1$ | $x$ |
| 7 | $x^{7}+x+1$ | $x$ |
| 8 | $x^{8}+x^{4}+x^{3}+x^{2}+1$ (AES) | $x$ |

## Build and test

```bash
make
make test
```

Equivalent:

```bash
gnatmake -gnatwa -gnat2022 -Pchien_search.gpr
./bin/tests
```

Expect `Results:  N PASS, 0 FAIL` with $N\ge 40$ and zero `-gnatwa` warnings.

## API sketch

```ada
F : constant Field_Desc := Make_GF2 (4);  -- GF(16)
P : constant Polynomial := ...;           -- error locator / any poly
Roots : Root_Array;
Count : Natural;

Find_Roots (F, P, Roots, Count);          -- or Chien_Search (...)
-- Roots(1 .. Count) are the distinct roots in GF(2^m)

Y : Field_Element := Eval (P, X, F);
Z : Field_Element := Mul (A, B, F);
```

Raises `Invalid_Argument` on bad field parameters, the zero polynomial, or
coefficients outside the field bitmask width.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
