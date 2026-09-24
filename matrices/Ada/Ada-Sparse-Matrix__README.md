# Sparse Matrix (COO / CSR / CSC + SpMV) — Ada 2023

Educational, self-contained Ada 2023 package for **sparse matrix storage
formats** and **sparse matrix–vector multiplication (SpMV)**. Implements
**COO** (coordinate triplets), **CSR** (compressed sparse row / Yale), and
**CSC** (compressed sparse column), with conversions, density/sparsity
helpers, textbook builders, and SpMV $y = A x$. Caps $n\le 64$,
$\mathrm{nnz}\le 512$.

Based on [Wikipedia: Sparse matrix](https://en.wikipedia.org/wiki/Sparse_matrix).
Related: [Conjugate gradient method](https://en.wikipedia.org/wiki/Conjugate_gradient_method),
[Cuthill–McKee algorithm](https://en.wikipedia.org/wiki/Cuthill%E2%80%93McKee_algorithm),
[Minimum degree algorithm](https://en.wikipedia.org/wiki/Minimum_degree_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Minimum-Degree](https://github.com/RobertBoettcherSF/Ada-Minimum-Degree)** —
  classical fill-reducing ordering before Cholesky
- **[Ada-Cuthill-McKee](https://github.com/RobertBoettcherSF/Ada-Cuthill-McKee)** —
  bandwidth-reducing CM / RCM orderings
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** —
  iterative SPD solver (SpMV is the workhorse matvec)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: dense reference checks on tiny matrices, classical
COO/CSR/CSC only. DIA / ELL / blocked (BSR) formats are intentionally
*Forthcoming*. Production PETSc / SuiteSparse / MKL Sparse stacks are out
of scope.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Sparsity** | Most $a_{ij}=0$ | Store only nonzeros |
| **COO** | Triples $(i,j,v)$ | Build / convert |
| **CSR** | `Values`, `Col_Ind`, `Row_Ptr` | Fast row SpMV |
| **CSC** | `Values`, `Row_Ind`, `Col_Ptr` | Fast column ops |
| **SpMV** | $y=Ax$ | CSR primary; CSC/COO too |
| **Builders** | Diagonal / Tridiagonal / Random | Fixed-seed LCG |
| **Taxonomy** | `Format_Kind` | COO+CSR+CSC implemented |
| **Caps** | $n\le 64$, $\mathrm{nnz}\le 512$ | `Max_N`, `Max_Nnz` |

## Sparsity and density

A matrix is **sparse** when most entries are zero. With $m$ rows, $n$
columns and $\mathrm{nnz}$ nonzeros,

$$
\mathrm{density}=\frac{\mathrm{nnz}}{m n},\qquad
\mathrm{sparsity}=1-\mathrm{density}.
$$

Storing and multiplying a dense $m\times n$ array wastes work on zeros;
sparse formats keep only the structural nonzeros (and optionally drop
tiny values below a tolerance).

## Coordinate list (COO)

COO stores a list of triplets $(i,j,a_{ij})$ for each nonzero. It is ideal
for **incremental construction**. This package sorts and **coalesces**
duplicate $(i,j)$ positions (summing values) when converting to CSR/CSC.

## Compressed sparse row (CSR / Yale)

CSR represents an $m\times n$ matrix by three arrays (1-based Ada
convention in this repo):

- `Values(1 .. nnz)` — nonzero entries in row-major order
- `Col_Ind(1 .. nnz)` — column index of each nonzero
- `Row_Ptr(1 .. m+1)` — `Row_Ptr(i)` is the start index of row $i$;
  `Row_Ptr(m+1)=\mathrm{nnz}+1`

Row $i$ occupies indices $p\in[\mathrm{Row\_Ptr}(i),\,\mathrm{Row\_Ptr}(i+1))$.
CSR enables a simple, cache-friendly SpMV:

$$
y_i=\sum_{p=\mathrm{Row\_Ptr}(i)}^{\mathrm{Row\_Ptr}(i+1)-1}
\mathrm{Values}(p)\,x_{\mathrm{Col\_Ind}(p)}.
$$

## Compressed sparse column (CSC)

CSC is the column-oriented twin: `Values`, `Row_Ind`, `Col_Ptr`. SpMV
accumulates

$$
y \leftarrow y + A_{:j}\,x_j
$$

column by column. MATLAB’s `sparse` historically exposes a CSC layout.

## SpMV

**Sparse matrix–vector product** $y=Ax$ is the dominant kernel in Krylov
solvers (CG, GMRES, …). This package provides `SpMV_CSR`, `SpMV_CSC`, and
`SpMV_COO`, checked against a dense reference `Dense_Mat_Vec` on tiny
examples.

## Tiny examples

**Diagonal.** $\mathrm{diag}(d)$ stores only nonzero $d_i$ on the main
diagonal.

**Tridiagonal / 1-D Poisson.** Lower $-1$, main $2$, upper $-1$ yields the
classic discrete Laplacian stencil with $\mathrm{nnz}=3n-2$.

**Random (fixed seed).** `Random_COO` uses a deterministic LCG so tests
are reproducible.

## API (`Sparse_Matrix`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_N` ($=64$), `Max_Nnz` ($=512$) | Educational bounds |
| Types | `Triplet`, `COO`, `CSR`, `CSC`, `Dense_Matrix`, `Vector` | Formats |
| Density | `Density`, `Sparsity`, `Count_Nnz` | Dense + sparse overloads |
| Build | `From_Dense`, `To_Dense`, `Zero_Dense`, `Zero_Vector` | Dense bridge |
| Access | `Get` / `Set` (dense); `Get` (COO/CSR/CSC) | Inspect entries |
| Convert | `To_CSR`, `To_CSC`, `To_COO` | Format changes (+ coalesce) |
| Valid | `Is_Valid_CSR`, `Is_Valid_CSC` | Pointer / bound checks |
| SpMV | `SpMV_CSR`, `SpMV_CSC`, `SpMV_COO`, `Dense_Mat_Vec` | $y=Ax$ |
| Builders | `Diagonal`, `Diagonal_CSR`, `Tridiagonal`, `Tridiagonal_CSR`, `Identity`, `Random_COO` | Textbooks |
| Numeric | `Near`, `Vec_Near`, `Mat_Near` | Float compares |
| Taxonomy | `Format_Kind`, `Format_Name`, `Implemented`, `Forthcoming` | Survey map |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

`Format_Kind` values: `Coordinate_COO`, `Compressed_Row_CSR`,
`Compressed_Column_CSC` (**Implemented**); `Diagonal_DIA`,
`ELLPACK_ELL`, `Blocked_BSR` (**Forthcoming** in this repo).

CSR/CSC use **1-based** indices: `Row_Ptr(1)=1` and
`Row_Ptr(Rows+1)=Nnz+1` (empty matrix keeps both equal to $1$).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: Sparse matrix](https://en.wikipedia.org/wiki/Sparse_matrix)
- [Wikipedia: Sparse matrix–vector multiplication](https://en.wikipedia.org/wiki/Sparse_matrix-vector_multiplication)
- [Wikipedia: Conjugate gradient method](https://en.wikipedia.org/wiki/Conjugate_gradient_method)
- Saad, Y. (2003). *Iterative Methods for Sparse Linear Systems.* SIAM
- Sibling: [Ada-Minimum-Degree](https://github.com/RobertBoettcherSF/Ada-Minimum-Degree)
- Sibling: [Ada-Cuthill-McKee](https://github.com/RobertBoettcherSF/Ada-Cuthill-McKee)
- Sibling: [Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
