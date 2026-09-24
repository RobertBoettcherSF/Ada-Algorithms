# Matrix Multiplication Algorithms — Ada 2023

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Matrix multiplication algorithm](https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm):
taxonomy of classical, Strassen, Coppersmith–Winograd, Cannon, Freivalds,
SUMMA, and laser-family methods, with **runnable sketches** for Classical,
Strassen (seven-product), Cannon (sequential $P\times P$ mesh simulation),
and Freivalds verification (exact `Integer`).

**Caveats:** sketches only; CW / laser are **galactic**; Cannon here is a
**sequential** simulation of the systolic mesh (not a real distributed run);
SUMMA / CW / Laser are catalogue-only (`Not_Implemented` / `Galactic_Only`).

Cap $n\le 32$, educational `Float` for multiply; Freivalds uses `Integer`.

Based on:

- [Wikipedia: Matrix multiplication algorithm](https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm)
- [Wikipedia: Computational complexity of matrix multiplication](https://en.wikipedia.org/wiki/Computational_complexity_of_matrix_multiplication)
- [Wikipedia: Strassen algorithm](https://en.wikipedia.org/wiki/Strassen_algorithm)
- [Wikipedia: Cannon's algorithm](https://en.wikipedia.org/wiki/Cannon's_algorithm)
- [Wikipedia: Freivalds' algorithm](https://en.wikipedia.org/wiki/Freivalds'_algorithm)
- [Wikipedia: Coppersmith–Winograd algorithm](https://en.wikipedia.org/wiki/Coppersmith%E2%80%93Winograd_algorithm)

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (README links only — **no** `with` deps):

- **[Ada-Strassen](https://github.com/RobertBoettcherSF/Ada-Strassen)** — runnable seven-product multiply
- **[Ada-Freivalds](https://github.com/RobertBoettcherSF/Ada-Freivalds)** — probabilistic product verification
- **[Ada-Coppersmith-Winograd](https://github.com/RobertBoettcherSF/Ada-Coppersmith-Winograd)** — CW / $\omega$ survey
- **[Ada-Cannons-Algorithm](https://github.com/RobertBoettcherSF/Ada-Cannons-Algorithm)** — Cannon mesh multiply
- **[Ada-System-of-Linear-Equations](https://github.com/RobertBoettcherSF/Ada-System-of-Linear-Equations)** — survey of $Ax=b$ solvers

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **$\omega$** | Exponent in $O(n^\omega)$ | Lower is asymptotically better |
| **Classical** | Triple loop | $\omega=3$, practical baseline |
| **Strassen** | $7$ products / $2\times 2$ | $\omega=\log_2 7\approx 2.807$ |
| **CW (1990)** | Catalogue only | $\omega\approx 2.3755$, galactic |
| **Cannon** | Sequential mesh sim | $\omega=3$, parallel communication |
| **Freivalds** | Monte Carlo verify | $O(kn^2)$, one-sided error $\le 2^{-k}$ |
| **SUMMA** | Catalogue only | Scalable distributed classical |
| **Laser family** | Catalogue placeholder | $\omega\approx 2.373$, galactic |
| **Runnable** | Classical + Strassen + Cannon + Freivalds | $n\le 32$ |
| **Estimator** | `Estimated_Ops` | $N^{\mathrm{Exponent\_Of}(M)}$ |
| **Cap** | $n\le 32$ | `Max_N = 32` |

## Brief history

Naive square matrix multiplication costs $\Theta(n^3)$ arithmetic operations.
**Strassen** (1969) showed $\omega\le\log_2 7\approx 2.807$. **Cannon** (1969)
organized the same cubic work on a $2$-D processor mesh with neighbour shifts.
**Freivalds** (1979) gave a Monte Carlo test that $AB=C$ in $O(kn^2)$ with
error probability $\le 2^{-k}$. Algebraic / tensor constructions then drove
$\omega$ down; **Coppersmith and Winograd** (1990) obtained

$$
\omega < 2.375477
$$

(often cited as $\approx 2.3755$). Later **laser-method** refinements
(Stothers, Vassilevska Williams, Le Gall, Alman–Williams, …) shave further
digits. **SUMMA** (mid-1990s) is a practical scalable distributed classical
algorithm. Asymptotically better CW / laser algorithms remain **galactic**
because of enormous hidden constants.

## Method taxonomy (this package)

| `Method_Kind` | $\omega$ / cost used here | Runnable? | Practical? |
| --- | --- | --- | --- |
| `Classical` | $3.0$ | Yes | Yes |
| `Strassen` | $\log 7/\log 2\approx 2.807355$ | Yes | Borderline / sometimes |
| `Coppersmith_Winograd` | $2.3755$ (1990 classic cite) | **No** | **No** (galactic) |
| `Cannon` | $3.0$ (arith.; parallel I/O) | Yes (seq. sim) | Yes (parallel setting) |
| `Freivalds_Verify` | $2.0$ (verification $O(kn^2)$) | Yes (verify) | Yes (verification) |
| `SUMMA` | $3.0$ | **No** (catalogue) | Yes (HPC concept) |
| `Laser_Family` | $2.373$ (placeholder) | **No** | **No** (galactic) |

### Milestone table (queryable)

| Year | Exponent / cost | Label |
| --- | --- | --- |
| $1969$ | $\approx 2.807$ | Strassen seven-product recursion |
| $1969$ | $3.0$ | Cannon systolic $2$-D-mesh multiply |
| $1979$ | $2.0$ | Freivalds probabilistic verify |
| $1981$ | $\approx 2.522$ | Schönhage / Pan era improvements |
| $1990$ | $2.3755$ | Coppersmith–Winograd classic bound |
| $1995$ | $3.0$ | SUMMA scalable universal MM |
| $2010$ | $\approx 2.3737$ | Stothers laser-method refinement |
| $2014$ | $\approx 2.37286$ | Le Gall further laser improvement |

Exact record values evolve; the package stores a **teaching** table.

## Runnable sketches

### Classical

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
$T(n)=7\,T(n/2)+\Theta(n^2)$ yields $T(n)=\Theta(n^{\log_2 7})$.

### Cannon (sequential mesh simulation)

Educational single-threaded simulation of Cannon (1969) on a $P\times P$ PE
mesh (`Grid_P`; default $P=n$):

1. Partition into $P\times P$ blocks of size $\mathrm{BS}=n/P$.
2. Initial alignment: circular-shift row $i$ of $A$ left by $i$ blocks;
   circular-shift column $j$ of $B$ up by $j$ blocks.
3. For $s=1..P$: local block MAC $C_{ij}\mathrel{+}=A_{ij}B_{ij}$; then
   shift $A$ left / $B$ up by one block (toroidal).

This is **not** a distributed runtime — shifts are explicit in-memory copies.

### Freivalds (Integer verification)

Given claimed $C$, draw $r\in\{0,1\}^n$ and check $A(Br)=Cr$. One-sided:
if $AB=C$ the test always passes; if $AB\neq C$ then
$P(\text{miss})\le 2^{-k}$ after $k$ independent trials. Use
`Verify_Freivalds` on `Int_Matrix` (not `Multiply`).

### CW / SUMMA / Laser: catalogue only

Calling `Multiply (A, B, Coppersmith_Winograd)`, `SUMMA`, or `Laser_Family`
returns `Success=False` with `Stat` in `{Not_Implemented, Galactic_Only}`.
`Freivalds_Verify` via `Multiply` is also rejected — use `Verify_Freivalds`.

### Recommend_Method

`Recommend_Method(N, Prefer_Parallel)`:

- `Prefer_Parallel` and $N\ge 2$ $\rightarrow$ `Cannon`
- $N\ge 16$ $\rightarrow$ `Strassen`
- else $\rightarrow$ `Classical`

Never recommends CW / SUMMA / Laser / Freivalds.

## API summary

| Symbol | Role |
| --- | --- |
| `Matrix` / `Int_Matrix` | Float multiply / Integer Freivalds arrays |
| `Max_N` | Hard dimension cap ($32$) |
| `Method_Kind` | Classical, Strassen, CW, Cannon, Freivalds_Verify, SUMMA, Laser_Family |
| `Exponent_Of` | Teaching $\omega$ / cost exponent |
| `Is_Practical` / `Supports_Runnable` | Practicality / sketch flags |
| `Recommend_Method` | Heuristic Classical / Strassen / Cannon |
| `Estimated_Ops` | $N^\omega$ estimator |
| `Get_Milestone` / `Milestone_Label` | Historical table |
| `Multiply_Classical` | Runnable $O(n^3)$ product |
| `Multiply_Strassen` | Runnable $7$-product recursion + pad/trim |
| `Multiply_Cannon` | Runnable sequential mesh simulation |
| `Multiply` | Dispatch; catalogue methods rejected |
| `Verify_Freivalds` | Monte Carlo $AB\stackrel{?}{=}C$ (Integer) |
| `Multiply_Classical_Int` | Exact Integer oracle for Freivalds tests |
| `Status` | `Ok`, `Dimension_Error`, `Ill_Started`, `Not_Implemented`, `Galactic_Only` |
| `Near` / `Mat_Near` | Scalar / matrix proximity |
| `Zeros`, `Ones`, `Identity`, `Sequential_Fill`, `Deterministic`, `Make_Hilbert` | Float builders |
| `Int_Zeros`, `Int_Ones`, `Int_Identity`, … | Integer builders |

## Limits and caveats

- **Sketches**, not production GEMM / MPI.
- **Galactic CW / laser** — no tensor recursion coded.
- **Cannon** is a **sequential** PE-mesh simulation.
- **$n\le 32$**, educational `Float` / `Integer`.
- Strassen has the usual **stability / workspace** caveats versus classical.
- `Estimated_Ops` ignores astronomical CW / laser leading constants.
- Inputs are **not** modified.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pmatrix_multiplication.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `matrix_multiplication.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
matrix_multiplication.ads
matrix_multiplication.adb
matrix_multiplication.gpr
tests.adb
```

## References

1. [Wikipedia: Matrix multiplication algorithm](https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm)
2. [Wikipedia: Computational complexity of matrix multiplication](https://en.wikipedia.org/wiki/Computational_complexity_of_matrix_multiplication)
3. Strassen, V. (1969). *Gaussian elimination is not optimal.* Numerische Mathematik.
4. Cannon, L. E. (1969). *A cellular computer to implement the Kalman filter algorithm.*
5. Freivalds, R. (1979). *Fast probabilistic algorithms.*
6. Coppersmith, D.; Winograd, S. (1990). *Matrix multiplication via arithmetic progressions.*
7. Sibling READMEs: Ada-Strassen, Ada-Freivalds, Ada-Coppersmith-Winograd,
   Ada-Cannons-Algorithm, Ada-System-of-Linear-Equations.
