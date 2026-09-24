# System of Linear Equations — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: System of linear equations](https://en.wikipedia.org/wiki/System_of_linear_equations):
solving square dense systems $Ax=b$ with a **taxonomy** of direct, structured,
stationary iterative, and Krylov sketches.

A linear system of $n$ equations in $n$ unknowns has the matrix form

$$
Ax=b,\qquad
A\in\mathbb{R}^{n\times n},\quad
x,b\in\mathbb{R}^n.
$$

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling solvers are
**independent** — this repo does **not** `with` them; it re-implements short
educational sketches of Gaussian elimination (GEPP), Thomas (tridiagonal),
Jacobi, Gauss–Seidel, and conjugate gradient (CG). Full packages live in the
siblings linked below.

## Caveats

- **Sketches only** — not production LAPACK / sparse solvers.
- Educational **Float**; cap $n\le 16$ (`Max_N`).
- CG assumes **SPD**; Jacobi / Gauss–Seidel need **nonzero diagonals** (strict
  diagonal dominance is a common sufficient condition).
- **BiCG** is catalogued in `Method_Kind` but not implemented here (see sibling).
- `SPD_Heuristic` = symmetric ∧ positive diagonal ∧ row-DD — a teaching proxy,
  **not** a true SPD certificate.

## Method taxonomy

Wikipedia contrasts elimination / row reduction with iterative approaches for
large systems, and notes structured / sparse specializations:

| Family | Uses | Sketch in this package | Typical when |
| --- | --- | --- | --- |
| **Direct dense** | Factor / eliminate $A$ | `Solve_GE` (GEPP + back-sub) | Small dense $n$; general nonsingular |
| **Direct structured** | Band / Toeplitz structure | `Solve_Thomas` (tridiagonal) | Tridiagonal $A$ (e.g. 1-D Poisson) |
| **Stationary iterative** | Fixed splitting $A=M-N$ | `Solve_Jacobi`, `Solve_Gauss_Seidel` | Strictly diagonally dominant |
| **Krylov** | Krylov subspace $K_k(A,r_0)$ | `Solve_CG` (SPD); BiCG noted | SPD (CG); nonsymmetric → BiCG sibling |

### Dispatcher / taxonomy helpers

| Helper | Role |
| --- | --- |
| `Classify_Matrix` | Flags: symmetric?, DD?, SPD heuristic, tridiagonal?, singular heuristic |
| `Recommend_Method` | Heuristic pick: singular→GE, tridiagonal→Thomas, SPD+$n\ge4$→CG, strict DD→GS, else GE |
| `Solve` / `Solve_Auto` | Explicit `Method_Kind` dispatch, or classify-then-solve |
| `Classify_Method` / `Method_Name` | Metadata catalog (direct? iterative? needs SPD/DD?) |

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Helpers** | `Near`, `Vec_Near`, `Norm2`, `Dot`, `Add`/`Sub`/`Scale`, `Mat_Vec` | Dense $n\le 16$ |
| **Predicates** | `Is_Symmetric`, `Is_Diagonally_Dominant`, `Is_Tridiagonal`, … | Property tests |
| **Residuals** | `Residual`, `Residual_Norm` | $r=b-Ax$, $\|r\|_2$ |
| **Builders** | `Identity`, `Make_Diagonally_Dominant`, `Make_Poisson_1D`, `Make_Nonsymmetric_DD`, `Make_Singular`, `Make_Diagonal_Plus_Ones` | Teaching matrices |
| **Direct** | `Solve_GE`, `Solve_Thomas` | GEPP; Thomas band |
| **Iterative** | `Solve_Jacobi`, `Solve_Gauss_Seidel`, `Solve_CG` | Stationary + Krylov |
| **Taxonomy** | `Method_Kind`, `Classify_*`, `Recommend_Method`, `Solve`/`Solve_Auto` | Survey glue |

Caps: `Max_N = 16`. Status values include `Ok`, `Converged`, `Singular`,
`Zero_Pivot`, `Zero_Diagonal`, `Iteration_Limit`, `Breakdown`,
`Not_Tridiagonal`, `Ill_Started`. Public subprograms carry `Pre` / `Global`
where meaningful (`SPARK_Mode => Off`).

## Formula summary

### Matrix equation

$$
\begin{bmatrix}
a_{11} & \cdots & a_{1n} \\
\vdots & \ddots & \vdots \\
a_{n1} & \cdots & a_{nn}
\end{bmatrix}
\begin{bmatrix} x_1 \\ \vdots \\ x_n \end{bmatrix}
=
\begin{bmatrix} b_1 \\ \vdots \\ b_n \end{bmatrix}.
$$

### Gaussian elimination (partial pivoting)

Permute rows so the pivot $|a_{kk}|$ is maximal in column $k$, eliminate below,
then back-substitute on the upper-triangular system $Ux=c$.

### Thomas (tridiagonal)

For $a_i x_{i-1}+b_i x_i+c_i x_{i+1}=d_i$, a forward sweep modifies $b,d$;
back-substitution recovers $x$ in $O(n)$.

### Jacobi / Gauss–Seidel

With $A=D+L+U$ (diagonal / strict lower / strict upper),

$$
x^{(k+1)}=D^{-1}\bigl(b-(L+U)x^{(k)}\bigr)
\quad\text{(Jacobi)},
$$

while Gauss–Seidel uses newly computed components immediately within the sweep
(successive displacement; ≡ SOR with $\omega=1$).

### Conjugate gradient (SPD)

Minimize $\tfrac12 x^\top A x - b^\top x$ for SPD $A$: residual $r_0=b-Ax_0$,
search directions $A$-conjugate; under exact arithmetic, terminates in at most
$n$ steps.

## Sibling solvers (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-Gaussian-Elimination](https://github.com/RobertBoettcherSF/Ada-Gaussian-Elimination) | Full GEPP / det / rank |
| [Ada-Gauss-Jordan](https://github.com/RobertBoettcherSF/Ada-Gauss-Jordan) | Gauss–Jordan reduction |
| [Ada-Gauss-Seidel](https://github.com/RobertBoettcherSF/Ada-Gauss-Seidel) | Full Gauss–Seidel package |
| [Ada-Successive-Over-Relaxation](https://github.com/RobertBoettcherSF/Ada-Successive-Over-Relaxation) | SOR ($\omega$ relaxation) |
| [Ada-Thomas-Algorithm](https://github.com/RobertBoettcherSF/Ada-Thomas-Algorithm) | Tridiagonal Thomas |
| [Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient) | Full CG (+ optional nonlinear FR) |
| [Ada-Biconjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Biconjugate-Gradient) | BiCG for nonsymmetric $A$ |
| [Ada-Stones-Method](https://github.com/RobertBoettcherSF/Ada-Stones-Method) | Stone’s method |
| [Ada-Sparse-Matrix](https://github.com/RobertBoettcherSF/Ada-Sparse-Matrix) | Sparse storage / ops |

## Public API (summary)

**Types:** `Vector`, `Matrix`, `Parameters`, `Status`, `Result`, `Method_Kind`,
`Method_Info`, `Matrix_Properties`.

**Helpers:** `Near`, `Vec_Near`, `Dot`, `Norm2`, `Scale`, `Add`, `Sub`,
`Mat_Vec`, `Is_Square`, `Is_Symmetric`, `Is_Diagonally_Dominant`,
`Is_Strictly_Diagonally_Dominant`, `Is_Tridiagonal`, `Has_Positive_Diagonal`,
`Residual`, `Residual_Norm`.

**Builders:** `Zero_Vector`, `Ones_Vector`, `Identity`,
`Make_Diagonally_Dominant`, `Make_Poisson_1D`, `Make_Nonsymmetric_DD`,
`Make_Singular`, `Make_Diagonal_Plus_Ones`, `Make_RHS_Ones`,
`Make_RHS_From_Solution`.

**Taxonomy:** `Classify_Matrix`, `Recommend_Method`, `Classify_Method`,
`Method_Name`, `Method_Count`.

**Solvers:** `Solve_GE`, `Solve_Thomas`, `Solve_Jacobi`, `Solve_Gauss_Seidel`,
`Solve_CG`, `Solve`, `Solve_Auto`.

## Usage sketch

```ada
with System_Of_Linear_Equations; use System_Of_Linear_Equations;

procedure Demo is
   A  : constant Matrix := Make_Poisson_1D (8);
   Xs : constant Vector (1 .. 8) :=
     [1.0, 2.0, 3.0, 4.0, 3.0, 2.0, 1.0, 0.5];
   B  : constant Vector := Make_RHS_From_Solution (A, Xs);
   R  : Result;
   P  : constant Matrix_Properties := Classify_Matrix (A);
begin
   R := Solve_Thomas (A, B);
   --  R.X ≈ Xs, R.Stat = Ok

   R := Solve_GE (Make_Diagonally_Dominant (4), Make_RHS_Ones (4));

   R := Solve_Auto (A, B);  --  Recommend_Method → Thomas for Poisson

   pragma Assert (P.Tridiagonal and then Recommend_Method (P) = Thomas);
end Demo;
```

## Building

```bash
cd /workspace/ada-system-of-linear-equations
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Psystem_of_linear_equations.gpr`. Expect
**zero** errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests` (14 sections, 100+ assertions). Exit status 0 and
`Fail_Count = 0` (`pragma Assert`).

## Layout

```
ada-system-of-linear-equations/
├── system_of_linear_equations.ads   # public API
├── system_of_linear_equations.adb   # implementation
├── system_of_linear_equations.gpr
├── tests.adb                        # main test program
├── Makefile
├── README.md
└── .gitignore
```

Root-only layout (no `src/`, no separate `main.adb`). Exactly **seven** root
files.

## References

1. [Wikipedia: System of linear equations](https://en.wikipedia.org/wiki/System_of_linear_equations)
   — definition, matrix form, elimination, iterative methods, homogeneous systems.
2. [Wikipedia: Gaussian elimination](https://en.wikipedia.org/wiki/Gaussian_elimination).
3. [Wikipedia: Tridiagonal matrix algorithm](https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm)
   (Thomas algorithm).
4. [Wikipedia: Jacobi method](https://en.wikipedia.org/wiki/Jacobi_method).
5. [Wikipedia: Gauss–Seidel method](https://en.wikipedia.org/wiki/Gauss%E2%80%93Seidel_method).
6. [Wikipedia: Conjugate gradient method](https://en.wikipedia.org/wiki/Conjugate_gradient_method).
7. Golub & Van Loan, *Matrix Computations*; Saad, *Iterative Methods for Sparse Linear Systems*.
