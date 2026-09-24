# Lenstra–Lenstra–Lovász (LLL) lattice basis reduction — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Lenstra–Lenstra–Lovász (LLL)** lattice basis reduction algorithm: given an
integer lattice basis, produce a shorter, nearly orthogonal LLL-reduced basis
in polynomial time via floating Gram–Schmidt, size-reduction, and Lovász
condition swaps.

Based on
[Wikipedia: Lenstra–Lenstra–Lovász lattice basis reduction algorithm](https://en.wikipedia.org/wiki/Lenstra%E2%80%93Lenstra%E2%80%93Lov%C3%A1sz_lattice_basis_reduction_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling / related rows:

- **[Ada-Gram-Schmidt](https://github.com/RobertBoettcherSF/Ada-Gram-Schmidt)** — classical / modified orthonormalization
- **[Ada-Integer-Linear-Programming](https://github.com/RobertBoettcherSF/Ada-Integer-Linear-Programming)** — ILP / lattice-adjacent integer programming survey
- **[Ada-Modular-Square-Root](https://github.com/RobertBoettcherSF/Ada-Modular-Square-Root)** — prior number-theory survey (README “Next: LLL”)

**Next:** Trial division.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Approximate short / nearly-orthogonal basis | Poly-time; not exact SVP |
| **δ** | Lovász parameter, default $3/4$ | Require $1/4 < \delta \le 1$ |
| **GS** | Floating `Real` (`digits 15`), unnormalized | Classroom path (not exact $\mu$) |
| **Size-reduce** | $\| \mu_{i,j} \| \le 1/2$ via $\lfloor\mu\rceil$ | Integer lattice stays integer |
| **Swap** | Lovász failure $\Rightarrow$ swap $b_k,b_{k-1}$ | Then $k \leftarrow \max(k-1,2)$ |
| **Storage** | Row-oriented `Basis` / `Matrix` | Cap `Max_Dim = 8` |
| **Domain** | `Invalid_Argument` | Empty basis or $\delta \le 1/4$ |

## Brief history

**Arjen Lenstra, Hendrik Lenstra, and László Lovász** introduced LLL in 1982.
It gave the first polynomial-time algorithm for factoring rational polynomials,
simultaneous Diophantine approximation, and fixed-dimension integer linear
programming, and remains a workhorse in cryptanalysis (knapsacks, RSA with
extra structure, NTRU, …) and MIMO detection.

## Algorithm (this package)

INPUT: basis rows $b_1,\ldots,b_n\in\mathbb{Z}^m$ and parameter
$\delta\in(1/4,1]$ (default $\delta=3/4$).

1. Compute (unnormalized) Gram–Schmidt $b_i^*$ and coefficients
   $$
   \mu_{i,j}=\frac{\langle b_i,b_j^*\rangle}{\langle b_j^*,b_j^*\rangle}.
   $$
2. Set $k\leftarrow 2$. While $k\le n$:
   - **Size-reduce** $b_k$ against $b_{k-1},\ldots,b_1$: if
     $|\mu_{k,j}|>1/2$, replace
     $b_k\leftarrow b_k-\lfloor\mu_{k,j}\rceil\,b_j$ and refresh GS.
   - **Lovász condition**
     $$
     \delta\,\|b_{k-1}^*\|^2
     \le
     \|b_k^*\|^2+\mu_{k,k-1}^2\|b_{k-1}^*\|^2.
     $$
     If it holds, $k\leftarrow k+1$; else swap $b_k$ with $b_{k-1}$, refresh
     GS, and $k\leftarrow\max(k-1,2)$.
3. Return the LLL-reduced basis.

A basis is **LLL-reduced** when it is size-reduced ($|\mu_{i,j}|\le 1/2$) and
the Lovász inequalities hold for every $k$.

### Floating Gram–Schmidt caveat

This package uses `type Real is digits 15` for $b_i^*$ and $\mu_{i,j}$. That
is ideal for **small classroom dimensions** ($n,m\le 8$) but is **not** an
exact-arithmetic / rational-$\mu$ implementation. Deep lattices, crypto-scale
bit sizes, or certified reduction need exact or multiprecision GS (e.g. fpLLL).
Treat float tolerances (`Mu_Tol`, `Lovasz_Tol`) as educational slacks.

## API summary

| Symbol | Role |
| --- | --- |
| `Real` | `digits 15` working field for GS |
| `Vector` / `Fixed_Vector` / `Basis` | Integer lattice vectors; row basis |
| `Matrix` / `Basis_Bundle` | Dense rows + `(N,M)` bundle |
| `Dot`, `Norm2`, `Euclidean_Norm`, `Near` | Helpers |
| `Nearest_Integer` | $\lfloor x\rceil$ via `Real'Rounding` |
| `Make_Basis`, `To_Matrix`, `Slice` | Construction / views |
| `Gram_Schmidt` | Floating unnormalized GS + $\mu$ |
| `Is_Size_Reduced`, `Satisfies_Lovasz`, `Is_LLL_Reduced` | Predicates |
| `Volume` | $\prod_i\|b_i^*\|$ (educational parallelepiped volume) |
| `LLL_Reduce` | Bundle / Matrix / Basis overloads; `Reduction_Delta` default $0.75$ |
| `Invalid_Argument` | Empty basis or invalid $\delta$ |

## Example (Wikipedia $\mathbb{Z}^3$)

Basis vectors (rows) $(1,1,1)$, $(-1,0,2)$, $(3,5,6)$ reduce to a short
LLL-reduced basis such as $(0,1,0)$, $(1,0,1)$, $(-1,0,2)$ (signs / order may
vary among LLL-equivalent outputs; the package checks size-reduction and
Lovász).

## Build and test

Requires GNAT with Ada 2022 support (`-gnat2022`).

```bash
make        # gnatmake -gnatwa -gnat2022 -Plenstra_lenstra_lovasz.gpr
make test   # run bin/tests (≥80 PASS, zero warnings/errors)
make clean
```

`SPARK_Mode => Off`; self-contained (no sibling `with`).

## Limits and caveats

- **Float GS** — educational only; not production lattice crypto.
- **Dim** — $n,m\le$ `Max_Dim` ($8$); tests focus on $2$–$4$.
- **Exact SVP** — LLL is approximate; shortest-vector guarantees are
  exponential in dimension ($\delta$-dependent).
- **Next:** Trial division.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
