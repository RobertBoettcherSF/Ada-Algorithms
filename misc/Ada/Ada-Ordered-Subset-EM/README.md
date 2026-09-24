# Ordered Subset Expectation Maximization (OSEM) — Ada 2023

Educational, self-contained Ada 2023 package implementing
[Wikipedia: Ordered subset expectation maximization](https://en.wikipedia.org/wiki/Ordered_subset_expectation_maximization)
(**OSEM**) — an iterative reconstruction method that **accelerates**
maximum-likelihood expectation maximization (**MLEM**) by updating the image
on **ordered subsets** of the projection data.

The canonical reference is **Hudson & Larkin (1994)**:

> H. M. Hudson and R. S. Larkin, “Accelerated image reconstruction using
> ordered subsets of projection data,” *IEEE Transactions on Medical Imaging*,
> vol. 13, no. 4, pp. 601–609, 1994. doi:[10.1109/42.363108](https://doi.org/10.1109/42.363108)

In medical imaging, OSEM is widely used for
[positron emission tomography](https://en.wikipedia.org/wiki/Positron_emission_tomography)
(**PET**) and
[single-photon emission computed tomography](https://en.wikipedia.org/wiki/Single-photon_emission_computed_tomography)
(**SPECT**), and is related to X-ray CT iterative reconstruction. It is a
practical acceleration of the Poisson **MLEM** algorithm of
**Shepp & Vardi** (emission tomography), itself an instance of the statistical
[expectation–maximization (EM)](https://en.wikipedia.org/wiki/Expectation%E2%80%93maximization_algorithm)
method. OSEM is also related (as an iterative alternative) to classical
[filtered back projection](https://en.wikipedia.org/wiki/Filtered_back_projection)
(**FBP**).

A sibling **Expectation maximization** survey package is planned (related,
not a dependency of this repo).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **MLEM** | Shepp–Vardi Poisson update with full sensitivity $s_j=\sum_i a_{ij}$ | 1 subset = all bins |
| **OSEM** | Hudson subset-normalized form per ordered subset $S_m$ | One iter = one pass over subsets |
| **System matrix** | Dense $A\in\mathbb{R}^{I\times J}$, $a_{ij}\ge 0$ | Educational (not sparse clinical) |
| **Subsets** | Contiguous blocks or interleaved | Partition covers every bin once |
| **Monitors** | Poisson NLL, KL divergence, RMSE | Convergence / recovery checks |
| **Toy geometry** | 1-D strip integrals; 2-D parallel beam | Small nonnegative phantoms |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Pixels`, `Max_Bins`, `Max_Subsets` | Fixed educational limits |
| Types | `Image`, `Projection`, `System_Matrix`, `Subset_Map` | Domain vectors / dense $A$ |
| Helpers | `Near`, `Enforce_Nonnegative`, `Zero_*`, `Ones_Image` | Numerics |
| Project | `Forward_Project`, `Back_Project`, `Back_Project_Subset` | $Ax$, $A^\mathsf{T}y$ |
| Sens. | `Sensitivity`, `Sensitivity_Subset` | $s_j$, $s_j^{(m)}$ |
| MLEM | `MLEM_Step`, `MLEM_Iterate` | Full-data EM update |
| OSEM | `Make_Ordered_Subsets`, `OSEM_Step_Subset`, `OSEM_Iterate` | Hudson OSEM |
| Monitors | `Poisson_NLL`, `KL_Divergence`, `RMSE` | Fit / error |
| Geometry | `Make_1D_Strip_Matrix`, `Make_2D_Parallel_Beam_Matrix`, phantoms | Toys |

Strong typing uses domain types (`Real` digits 12, …).
Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Formula summary

### Forward model (emission tomography)

Pixels $j=1..J$, bins $i=1..I$, nonnegative system matrix $A=(a_{ij})$:

$$
\hat y_i = \sum_{j=1}^{J} a_{ij}\, x_j,
\qquad
s_j = \sum_{i=1}^{I} a_{ij}.
$$

### MLEM (Shepp–Vardi)

$$
x_j \;\leftarrow\;
\frac{x_j}{s_j}
\sum_{i=1}^{I} a_{ij}\,\frac{y_i}{\hat y_i}
\quad\text{(care when $\hat y_i=0$; $s_j=0$ leaves $x_j$ unchanged).}
$$

### OSEM — classic Hudson form (this package)

Partition $\{1..I\}$ into $M$ disjoint ordered subsets $S_1,\ldots,S_M$.
For each subset $m$ in order, using **subset-normalized** sensitivity
$s_j^{(m)}=\sum_{i\in S_m} a_{ij}$:

$$
x_j \;\leftarrow\;
\frac{x_j}{\sum_{i\in S_m} a_{ij}}
\sum_{i\in S_m} a_{ij}\,\frac{y_i}{\hat y_i},
\qquad
\hat y = A x
\text{ (full current image).}
$$

One **OSEM iteration** = one pass through all subsets. With $M=1$
(all bins in one subset), OSEM reduces exactly to MLEM.

**Variant note:** some implementations keep the **full** sensitivity $s_j$
in the denominator while summing only over $i\in S_m$ (subset backprojection).
Hudson & Larkin use the **subset-normalized** denominator above; that is what
`OSEM_Step_Subset` implements. Document which variant you mean when comparing
papers / vendors.

### MLEM vs OSEM vs FBP

| Method | Idea | Typical use |
| --- | --- | --- |
| **FBP** | Analytic filtered backprojection | Fast analytic CT; noise/artifact tradeoffs |
| **MLEM** | Full-data Poisson EM | Statistically motivated; slow convergence |
| **OSEM** | EM on ordered subsets | ≈$M\times$ fewer full iterations for similar early progress |

OSEM is an **acceleration heuristic**: it does not in general maximize the
same objective each subset step, but empirically reaches useful images much
sooner than MLEM in PET/SPECT.

## Usage

```ada
with Ordered_Subset_EM; use Ordered_Subset_EM;

procedure Demo is
   A     : constant System_Matrix := Make_1D_Strip_Matrix (8, 16);
   Truth : constant Image := Make_Box_Phantom_1D (8);
   Y     : constant Projection := Forward_Project (A, Truth);
   X     : Image := Ones_Image (8, 1.0);
   Subs  : constant Subset_Map :=
     Make_Ordered_Subsets (16, 4, Interleaved);
begin
   OSEM_Iterate (X, A, Y, Subs, M => 4, Iterations => 5);
   --  Compare with MLEM_Iterate (X, A, Y, Iterations => 20);
end Demo;
```

## Building

```bash
cd /workspace/ada-ordered-subset-em
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pordered_subset_em.gpr`. Expect **zero**
errors and **zero** warnings.

## Testing

```bash
make test
```

Standalone `tests.adb` (≥13 sections, Check-based assertions,
`pragma Assert (Fail_Count = 0)`). Covers forward/back adjoint consistency,
MLEM ≡ OSEM($M=1$), nonnegativity, NLL decrease, early OSEM vs MLEM,
zero-sensitivity handling, invalid dimensions, phantom RMSE recovery, and
subset partition coverage.

## Layout

Root-only (no `src/`, no `main.adb`):

- `ordered_subset_em.ads` / `.adb` / `.gpr`
- `Makefile`, `tests.adb`, `README.md`, `.gitignore`

## References

1. H. M. Hudson and R. S. Larkin, “Accelerated image reconstruction using
   ordered subsets of projection data,” *IEEE Trans. Med. Imaging*, 13(4),
   601–609, 1994. doi:10.1109/42.363108
2. L. A. Shepp and Y. Vardi, “Maximum likelihood reconstruction for emission
   tomography,” *IEEE Trans. Med. Imaging*, 1(2), 113–122, 1982.
3. A. P. Dempster, N. M. Laird, and D. B. Rubin, “Maximum likelihood from
   incomplete data via the EM algorithm,” *JRSS B*, 39(1), 1–38, 1977.
4. Wikipedia:
   [Ordered subset expectation maximization](https://en.wikipedia.org/wiki/Ordered_subset_expectation_maximization),
   [Expectation–maximization algorithm](https://en.wikipedia.org/wiki/Expectation%E2%80%93maximization_algorithm),
   [Filtered back projection](https://en.wikipedia.org/wiki/Filtered_back_projection).

## License

Educational / reference implementation. No warranty.
