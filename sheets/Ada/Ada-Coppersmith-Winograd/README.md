# Coppersmith–Winograd Algorithm — Ada 2023

Educational, self-contained Ada 2023 **survey** package for the
**Coppersmith–Winograd (CW)** line of fast matrix-multiplication algorithms and
the asymptotic exponent $\omega$ in

$$
O(n^\omega).
$$

**This is not a real CW / laser-method implementation.** Full CW tensor
recursion and later laser-method constructions are **galactic** algorithms:
the asymptotic exponents improve on Strassen, but the **hidden constants are
so enormous** that the algorithms are not usable for any practical matrix size.
This package therefore:

1. Catalogues a **taxonomy** of methods and published $\omega$ milestones.
2. Ships **runnable sketches** only for **Classical** $O(n^3)$ and **Strassen**
   (seven-product recursion).
3. Rejects `Multiply` for `Coppersmith_Winograd` and `Laser_Family` with
   status `Not_Implemented` / `Galactic_Only`.

Cap $n\le 32$, educational `Float`.

Based on:

- [Wikipedia: Coppersmith–Winograd algorithm](https://en.wikipedia.org/wiki/Coppersmith%E2%80%93Winograd_algorithm)
- [Wikipedia: Computational complexity of matrix multiplication](https://en.wikipedia.org/wiki/Computational_complexity_of_matrix_multiplication)
- [Wikipedia: Matrix multiplication algorithm](https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm)

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (README links only — **no** `with` deps):

- **[Ada-Strassen](https://github.com/RobertBoettcherSF/Ada-Strassen)** — runnable seven-product multiply
- **[Ada-Freivalds](https://github.com/RobertBoettcherSF/Ada-Freivalds)** — probabilistic product verification
- **[Ada-System-of-Linear-Equations](https://github.com/RobertBoettcherSF/Ada-System-of-Linear-Equations)** — survey of $Ax=b$ solvers
- **Next:** Cannon’s algorithm (distributed / blocked MM survey)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **$\omega$** | Exponent in $O(n^\omega)$ | Lower is asymptotically better |
| **Classical** | Triple loop | $\omega=3$, practical baseline |
| **Strassen** | $7$ products / $2\times 2$ | $\omega=\log_2 7\approx 2.807$ |
| **CW (1990)** | Catalogue only | $\omega\approx 2.3755$, galactic |
| **Laser family** | Catalogue placeholder | $\omega\approx 2.373$, galactic |
| **Runnable** | Classical + Strassen | $n\le 32$ educational `Float` |
| **Estimator** | `Estimated_Ops` | $N^{\mathrm{Exponent\_Of}(M)}$ |
| **Cap** | $n\le 32$ | `Max_N = 32` |

## Brief history

Naive square matrix multiplication costs $\Theta(n^3)$ arithmetic operations.
**Strassen** (1969) showed $\omega\le\log_2 7\approx 2.807$ with a recursive
seven-product scheme. A long sequence of algebraic / tensor constructions then
drove $\omega$ down. **Coppersmith and Winograd** (1990) obtained the celebrated
bound

$$
\omega < 2.375477
$$

(often cited as $\approx 2.3755$). Later **laser-method** refinements
(Stothers, Vassilevska Williams, Le Gall, Alman–Williams, and others) shave
further digits; peer-reviewed history sits near $\omega<2.373$, with continuing
improvements in the literature. Wikipedia’s complexity page also notes that
even the best current algorithms remain **galactic** because of huge constants
and cannot be realized practically for ordinary sizes.

## Method taxonomy (this package)

| `Method_Kind` | $\omega$ used here | Runnable? | Practical? |
| --- | --- | --- | --- |
| `Classical` | $3.0$ | Yes | Yes |
| `Strassen` | $\log 7/\log 2\approx 2.807355$ | Yes | Borderline / sometimes |
| `Coppersmith_Winograd` | $2.3755$ (1990 classic cite) | **No** | **No** (galactic) |
| `Laser_Family` | $2.373$ (educational placeholder) | **No** | **No** (galactic) |

Sources for the constants: Strassen via $\log_2 7$; CW via the commonly cited
$2.3755$ rounding of the 1990 bound; laser-family $2.373$ as a compact
placeholder for the mid-2010s laser-method regime (see milestone table in
code / below — not a claim of the absolute latest record).

### Milestone table (queryable)

Educational survey milestones exposed as `Get_Milestone` /
`Milestone_Label`:

| Year | Exponent | Label |
| --- | --- | --- |
| $1969$ | $\approx 2.807$ | Strassen seven-product recursion |
| $1981$ | $\approx 2.522$ | Schönhage / Pan era improvements |
| $1990$ | $2.3755$ | Coppersmith–Winograd classic bound |
| $2010$ | $\approx 2.3737$ | Stothers laser-method refinement |
| $2012$ | $\approx 2.3729$ | Vassilevska Williams laser family |
| $2014$ | $\approx 2.37286$ | Le Gall further laser improvement |

Exact record values evolve; the package stores a **teaching** table, not a
live leaderboard.

## Runnable sketches

### Classical

Standard triple loop:

$$
C_{ij}=\sum_{k=1}^{n} A_{ik}B_{kj},
$$

cost $\Theta(n^3)$. Exposed as `Multiply_Classical`.

### Strassen (self-contained sketch)

For even $n$ (after zero-padding to the next power of two), the classic
seven products

$$
\begin{align*}
M_1 &= (A_{11}+A_{22})(B_{11}+B_{22}),\\
M_2 &= (A_{21}+A_{22})B_{11},\\
M_3 &= A_{11}(B_{12}-B_{22}),\\
M_4 &= A_{22}(B_{21}-B_{11}),\\
M_5 &= (A_{11}+A_{12})B_{22},\\
M_6 &= (A_{21}-A_{11})(B_{11}+B_{12}),\\
M_7 &= (A_{12}-A_{22})(B_{21}+B_{22}),
\end{align*}
$$

combine into the four quadrants of $C$. Recurrence
$T(n)=7\,T(n/2)+\Theta(n^2)$ yields $T(n)=\Theta(n^{\log_2 7})$. This sketch
mirrors the educational Ada-Strassen sibling lightly and is **fully
self-contained** (no `with` of sibling packages).

### CW / laser: catalogue only

`Supports_Runnable(Coppersmith_Winograd)=False` and likewise for
`Laser_Family`. Calling

```ada
Multiply (A, B, Coppersmith_Winograd)
```

returns `Success=False` with `Stat` in `{Not_Implemented, Galactic_Only}`.
No CW tensor / laser recursion is coded — by design.

### Complexity estimator

`Estimated_Ops(N, Method)` returns $N^{\mathrm{Exponent\_Of}(\mathrm{Method})}$
as educational `Float` (not a cycle count).

## Freivalds note (sibling)

To **verify** a claimed product $AB=C$ without trusting a galactic multiplier,
see **[Ada-Freivalds](https://github.com/RobertBoettcherSF/Ada-Freivalds)**:
Monte Carlo fingerprinting via $A(Br)\stackrel{?}{=}Cr$ in $O(kn^2)$ with
one-sided error $\le 2^{-k}$. Linked in README only.

## API summary

| Symbol | Role |
| --- | --- |
| `Matrix` | 1-based educational `Float` 2-D array |
| `Max_N` | Hard dimension cap ($32$) |
| `Method_Kind` | `Classical`, `Strassen`, `Coppersmith_Winograd`, `Laser_Family` |
| `Exponent_Of` | Teaching $\omega$ for each method |
| `Is_Practical` / `Supports_Runnable` | Practicality / sketch flags |
| `Method_Name` / `Method_Count` / `Describe` | Taxonomy strings |
| `Classify_Method` | Bundled `Method_Info` |
| `Get_Milestone` / `Milestone_Label` | Historical $\omega$ table |
| `Estimated_Ops` | $N^\omega$ estimator |
| `Multiply_Classical` | Runnable $O(n^3)$ product |
| `Multiply_Strassen` | Runnable $7$-product recursion + pad/trim |
| `Multiply` | Dispatch; galactic methods rejected |
| `Status` | `Ok`, `Dimension_Error`, `Ill_Started`, `Not_Implemented`, `Galactic_Only` |
| `Multiply_Result` | `C`, `N`, `Stat`, `Success`, counters, `Method` |
| `Near` / `Mat_Near` | Scalar / matrix proximity |
| `Norm_Frobenius` / `Diff_Frobenius` | $\|A\|_F$ and $\|A-B\|_F$ |
| `Mat_Add` / `Mat_Sub` / `Mat_Scale` | Dense helpers |
| `Pad_To_Power_Of_Two` / `Trim` | Strassen padding helpers |
| `Zeros`, `Ones`, `Identity`, `Sequential_Fill`, `Deterministic`, `Make_Hilbert` | Builders |

## Limits and caveats

- **No real CW implementation** — galactic constants; survey + sketches only.
- **$n\le 32$**, educational `Float` — not BLAS / production GEMM.
- Strassen sketch has the usual **stability / workspace** caveats versus
  classical multiply; compare with `Diff_Frobenius`.
- Laser-family exponent $2.373$ is a **placeholder** for teaching orderings,
  not the latest published record digit string.
- `Estimated_Ops` ignores the astronomical leading constants of CW / laser
  algorithms — those constants are why the methods are galactic.
- Inputs are **not** modified.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pcoppersmith_winograd.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `coppersmith_winograd.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
coppersmith_winograd.ads
coppersmith_winograd.adb
coppersmith_winograd.gpr
tests.adb
```

## References

1. [Wikipedia: Coppersmith–Winograd algorithm](https://en.wikipedia.org/wiki/Coppersmith%E2%80%93Winograd_algorithm)
2. [Wikipedia: Computational complexity of matrix multiplication](https://en.wikipedia.org/wiki/Computational_complexity_of_matrix_multiplication)
3. [Wikipedia: Matrix multiplication algorithm](https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm)
4. Coppersmith, D.; Winograd, S. (1990). *Matrix multiplication via arithmetic
   progressions.* Journal of Symbolic Computation.
5. Sibling READMEs: Ada-Strassen, Ada-Freivalds, Ada-System-of-Linear-Equations.
