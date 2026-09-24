# Eigenvalue Algorithms — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Eigenvalue algorithm](https://en.wikipedia.org/wiki/Eigenvalue_algorithm):
finding eigenvalues (and often eigenvectors) of a square matrix $A$, with a
**taxonomy** of power / inverse / Rayleigh-quotient iteration, dense Jacobi and
unshifted QR sketches, and thin Lanczos / Arnoldi Krylov builds.

Given $A\in\mathbb{R}^{n\times n}$, an eigenpair $(\lambda,v)$ satisfies

$$
Av=\lambda v,\qquad v\neq 0,
$$

or equivalently $(A-\lambda I)v=0$. Algorithms are almost always **iterative**
for $n>4$ (Abel–Ruffini): there is no finite radical formula for a general
characteristic polynomial.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages are
**independent** — this repo does **not** `with` them; it re-implements short
educational sketches. Full packages live in the siblings linked below.

## Caveats

- **Sketches only** — not production LAPACK / ARPACK / dense QR with shifts.
- Educational **Float**; cap $n\le 12$ (`Max_N`).
- Prefer **symmetric** tiny cases for Jacobi / unshifted QR reliability.
- **Divide_And_Conquer** is catalogued in `Method_Kind` but not implemented
  (`Not_Implemented` when dispatched).
- Lanczos requires symmetric $A$; Arnoldi accepts general $A$.
- Power / Inverse / RQI return a **single** approximate eigenpair; Jacobi / QR
  return a **spectrum** sketch.

## Method taxonomy

Wikipedia highlights Francis–Kublanovskaya **QR**, shift strategies, Hessenberg /
tridiagonal reductions, and Krylov methods. This survey organizes runnable
sketches as:

| Family | Uses | Sketch in this package | Typical when |
| --- | --- | --- | --- |
| **Power** | Multiply–normalize | `Power_Dominant` | Dominant $\|\lambda\|_{\max}$; clear gap |
| **Inverse** | Solve $(A-\mu I)y=x$ | `Inverse_Near(Mu)` | Eigenvalue near fixed shift $\mu$ |
| **Rayleigh quotient iteration** | Update $\mu\leftarrow R(A,x)$ | `Rayleigh_Quotient_Iterate` | Fast local convergence near a simple eigenpair |
| **Dense Jacobi** | Plane rotations | `Jacobi_Diagonalize` | Small **symmetric** full spectrum |
| **QR iteration** | $A\leftarrow RQ$ (unshifted MGS) | `QR_Unshifted` | Tiny diagonalizable / symmetric cases |
| **Lanczos** | Three-term Krylov | `Lanczos_Build` | Symmetric; few extremal Ritz values |
| **Arnoldi** | MGS Krylov → Hessenberg | `Arnoldi_Build` | Nonsymmetric; few extremal Ritz values |
| **Divide & conquer** | Cuppen / tridiagonal DAC | catalogue only | Symmetric tridiagonal (see LAPACK) |

### Dispatcher / taxonomy helpers

| Helper | Role |
| --- | --- |
| `Classify_Matrix` | Flags: symmetric?, tridiagonal?, diagonal? |
| `Recommend_Method` | Heuristic: dominant→Power; near shift→Inverse/RQI; full spectrum→Jacobi/QR; extremal few→Lanczos/Arnoldi |
| `Run_Eigenpair` / `Run_Spectrum` / `Run_Auto_Eigenpair` | Explicit `Method_Kind` dispatch or classify-then-run |
| `Classify_Method` / `Method_Name` | Metadata catalog (needs symmetric? uses shift? Krylov? runnable?) |

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Helpers** | `Near`, `Vec_Near`, `Norm2`, `Dot`, `Add`/`Sub`/`Scale`, `Mat_Vec`, `Normalize`, `Identity`, `Off_Diag_Norm`, `Column` | Dense $n\le 12$ |
| **Predicates** | `Is_Symmetric`, `Is_Tridiagonal`, `Is_Diagonal`, `Is_Square` | Property tests |
| **Eigen helpers** | `Rayleigh_Quotient`, `Eigen_Residual`, `Eigen_Residual_Norm` | $R(A,x)=(x^\top Ax)/(x^\top x)$, $\|Ax-\lambda x\|_2$ |
| **Builders** | `Make_Diagonal`, `Make_Poisson_1D`, `Make_Known_Spectrum_Symmetric`, `Make_Nonsymmetric`, `Make_Ones_Vector`, `Make_Unit_Vector`, `Make_Perturbed_Basis`, `Poisson_Eigenvalue` | Teaching matrices |
| **Eigenpair sketches** | `Power_Dominant`, `Inverse_Near`, `Rayleigh_Quotient_Iterate` | Single pair |
| **Spectrum sketches** | `Jacobi_Diagonalize`, `QR_Unshifted` | Full tiny spectrum |
| **Krylov builds** | `Lanczos_Build`, `Arnoldi_Build` | $\alpha,\beta$ / Hessenberg $H_m$ |
| **Taxonomy** | `Method_Kind`, `Classify_*`, `Recommend_Method`, `Run_*` | Survey glue |

Caps: `Max_N = 12`. Status values include `Ok`, `Converged`, `Iteration_Limit`,
`Breakdown`, `Singular_Shift`, `Not_Symmetric`, `Ill_Started`,
`Dimension_Error`, `Not_Implemented`. Public subprograms carry `Pre` / `Global`
where meaningful (`SPARK_Mode => Off`).

## Formula summary

### Eigenproblem

$$
\det(A-\lambda I)=0,\qquad
R(A,x)=\frac{x^\top A x}{x^\top x}.
$$

### Power iteration

Normalize $x_0$; repeat $y\leftarrow Ax$, $x\leftarrow y/\|y\|_2$,
$\lambda\leftarrow R(A,x)$ until $\|Ax-\lambda x\|_2$ is small. Converges to the
eigenpair with largest $|\lambda|$ when the gap is favorable.

### Inverse iteration (fixed shift)

With shift $\mu$, repeatedly solve $(A-\mu I)y=x$ and normalize. Targets the
eigenvalue of $A$ nearest $\mu$.

### Rayleigh quotient iteration

Same linear solve, but update $\mu\leftarrow R(A,x)$ each step. Local
convergence is typically cubic for simple eigenpairs of symmetric matrices.

### Jacobi (symmetric)

Apply plane rotations $G(i,j,\theta)$ so $S\leftarrow G^\top S G$ drives
off-diagonal Frobenius mass to zero; accumulate $V\leftarrow VG$.

### Unshifted QR

Factor $A_k=Q_k R_k$ (Modified Gram–Schmidt here) and set
$A_{k+1}=R_k Q_k$. Diagonal entries approach eigenvalues for suitable matrices.

### Lanczos / Arnoldi

Build an orthonormal Krylov basis. Lanczos yields a symmetric tridiagonal
$T_m$ (coefficients $\alpha_j,\beta_j$); Arnoldi yields upper Hessenberg $H_m$.
Ritz values are eigenvalues of $T_m$ / $H_m$ (extraction left thin here).

## Sibling packages (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-Power-Iteration](https://github.com/RobertBoettcherSF/Ada-Power-Iteration) | Full power method package |
| [Ada-Inverse-Iteration](https://github.com/RobertBoettcherSF/Ada-Inverse-Iteration) | Fixed-shift inverse iteration |
| [Ada-Rayleigh-Quotient-Iteration](https://github.com/RobertBoettcherSF/Ada-Rayleigh-Quotient-Iteration) | Updating-shift RQI |
| [Ada-QR-Algorithm](https://github.com/RobertBoettcherSF/Ada-QR-Algorithm) | QR eigenvalue iteration |
| [Ada-Jacobi-Eigenvalue](https://github.com/RobertBoettcherSF/Ada-Jacobi-Eigenvalue) | Jacobi diagonalization |
| [Ada-Lanczos](https://github.com/RobertBoettcherSF/Ada-Lanczos) | Lanczos + Ritz extraction |
| [Ada-Arnoldi](https://github.com/RobertBoettcherSF/Ada-Arnoldi) | Arnoldi + Ritz extraction |
| [Ada-System-of-Linear-Equations](https://github.com/RobertBoettcherSF/Ada-System-of-Linear-Equations) | Survey of $Ax=b$ solvers (GEPP used inside Inverse/RQI sketches) |
| [Ada-Matrix-Multiplication](https://github.com/RobertBoettcherSF/Ada-Matrix-Multiplication) | Survey of matmul algorithms |
| [Ada-Coppersmith-Winograd](https://github.com/RobertBoettcherSF/Ada-Coppersmith-Winograd) | Fast matmul / CW family notes |

## Public API (summary)

**Types:** `Vector`, `Matrix`, `Parameters`, `Status`, `Eigenpair_Result`,
`Spectrum_Result`, `Krylov_Result`, `Method_Kind`, `Goal_Kind`, `Method_Info`,
`Matrix_Properties`.

**Helpers:** `Near`, `Vec_Near`, `Dot`, `Norm2`, `Scale`, `Add`, `Sub`,
`Mat_Vec`, `Is_Square`, `Is_Symmetric`, `Is_Tridiagonal`, `Is_Diagonal`,
`Normalize`, `Identity`, `Off_Diag_Norm`, `Column`, `Rayleigh_Quotient`,
`Eigen_Residual`, `Eigen_Residual_Norm`.

**Builders:** `Make_Diagonal`, `Make_Poisson_1D`,
`Make_Known_Spectrum_Symmetric`, `Make_Nonsymmetric`, `Make_Ones_Vector`,
`Make_Unit_Vector`, `Make_Perturbed_Basis`, `Poisson_Eigenvalue`.

**Taxonomy:** `Classify_Matrix`, `Recommend_Method`, `Classify_Method`,
`Method_Name`, `Method_Count`.

**Sketches:** `Power_Dominant`, `Inverse_Near`, `Rayleigh_Quotient_Iterate`,
`Jacobi_Diagonalize`, `QR_Unshifted`, `Lanczos_Build`, `Arnoldi_Build`,
`Run_Eigenpair`, `Run_Spectrum`, `Run_Auto_Eigenpair`.

## Usage sketch

```ada
with Eigenvalue_Algorithms; use Eigenvalue_Algorithms;

procedure Demo is
   A  : constant Matrix := Make_Diagonal ([1.0, 2.0, 9.0]);
   X0 : constant Vector := Make_Ones_Vector (3);
   R  : Eigenpair_Result;
   S  : Spectrum_Result;
   P  : constant Matrix_Properties := Classify_Matrix (A);
begin
   R := Power_Dominant (A, X0);
   --  R.Eigenvalue ≈ 9, R.Stat = Converged

   R := Inverse_Near (A, 1.8, Make_Perturbed_Basis (3, 2));
   --  nearest to μ=1.8 → λ ≈ 2

   S := Jacobi_Diagonalize
          (Make_Known_Spectrum_Symmetric ([1.0, 2.0, 3.0]));

   pragma Assert (Recommend_Method (P, Want_Dominant) = Power);
end Demo;
```

## Building

```bash
cd /workspace/ada-eigenvalue-algorithms
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Peigenvalue_algorithms.gpr`. Expect
**zero** errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests` (18 sections, 100+ assertions). Exit status 0 and
`Fail_Count = 0` (`pragma Assert`).

## Layout

```
ada-eigenvalue-algorithms/
├── eigenvalue_algorithms.ads   # public API
├── eigenvalue_algorithms.adb   # implementation
├── eigenvalue_algorithms.gpr
├── tests.adb                   # main test program
├── Makefile
├── README.md
└── .gitignore
```

Exactly **seven** root files (no `main.adb`). Build artifacts go under `obj/`
and `bin/` (gitignored).

## References

1. [Wikipedia: Eigenvalue algorithm](https://en.wikipedia.org/wiki/Eigenvalue_algorithm)
2. [Wikipedia: Power iteration](https://en.wikipedia.org/wiki/Power_iteration)
3. [Wikipedia: Inverse iteration](https://en.wikipedia.org/wiki/Inverse_iteration)
4. [Wikipedia: Rayleigh quotient iteration](https://en.wikipedia.org/wiki/Rayleigh_quotient_iteration)
5. [Wikipedia: QR algorithm](https://en.wikipedia.org/wiki/QR_algorithm)
6. [Wikipedia: Jacobi eigenvalue algorithm](https://en.wikipedia.org/wiki/Jacobi_eigenvalue_algorithm)
7. [Wikipedia: Lanczos algorithm](https://en.wikipedia.org/wiki/Lanczos_algorithm)
8. [Wikipedia: Arnoldi iteration](https://en.wikipedia.org/wiki/Arnoldi_iteration)
9. Golub & Van Loan, *Matrix Computations*
10. Trefethen & Bau, *Numerical Linear Algebra*

## License

Educational / reference use.
