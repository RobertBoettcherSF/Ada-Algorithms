# Cannon's Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **Cannon's
algorithm** for distributed matrix multiplication on a two-dimensional
processor mesh (Lynn Elliot Cannon, 1969). This package is a **sequential
simulation** of the classic $P\times P$ PE systolic scheme: initial circular
alignment of $A$ (left by row) and $B$ (up by column), then $P$ steps of local
multiply-accumulate plus neighbour shifts. Cap $n\le 32$, dense educational
`Float`. `Multiply_Classical` is the $O(n^3)$ residual oracle.

Based on [Wikipedia: Cannon's algorithm](https://en.wikipedia.org/wiki/Cannon's_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (README links only — **no** `with` deps):

- **[Ada-Strassen](https://github.com/RobertBoettcherSF/Ada-Strassen)** — fast $7$-product matrix multiply
- **[Ada-Freivalds](https://github.com/RobertBoettcherSF/Ada-Freivalds)** — probabilistic product verification
- **[Ada-Coppersmith-Winograd](https://github.com/RobertBoettcherSF/Ada-Coppersmith-Winograd)** — upcoming; further asymptotic MM
- **Matrix Multiplication survey** (upcoming) — broader MM algorithm survey

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Systolic $P\times P$ mesh MM | Local MAC + shifts |
| **Alignment** | Skew $A$ left / $B$ up | $k=(i+j)\bmod P$ start |
| **Steps** | $P$ MAC rounds | Then shift neighbours |
| **Blocks** | Tiles of size $n/P$ | Or element-per-PE ($P=n$) |
| **Storage** | Constant per PE | Independent of $P$ count |
| **Oracle** | `Multiply_Classical` | $O(n^3)$ residual checks |
| **Sibling** | SUMMA (README only) | More practical in HPC |
| **Cap** | $n\le 32$ | `Max_N = 32` |

## Brief history

Lynn Elliot **Cannon** (1969) described a distributed algorithm for multiplying
two $n\times n$ matrices on an $N\times N$ mesh of processing elements. The
main advantage is that **storage requirements remain constant** and independent
of the number of processors: after the initial distribution, each PE only needs
its current $A$ tile, $B$ tile, and running $C$ sum. The algorithm is a classic
example of **systolic** communication (circular left / up shifts) in parallel
numerical linear algebra courses.

A closely related practical sibling is **SUMMA** (Scalable Universal Matrix
Multiplication Algorithm), used by ScaLAPACK, PLAPACK, and Elemental: it needs
less workspace and does not require a square 2D grid. This package documents
SUMMA only in the README; it does **not** implement SUMMA.

## Method (this package)

### Mesh and blocks

Given square $A,B\in\mathbb{R}^{n\times n}$ and a mesh side $P$ with
$P\mid n$, let the block size be

$$
B_S = n / P.
$$

Partition $A$ and $B$ into a $P\times P$ grid of $B_S\times B_S$ tiles. PE
$(i,j)$ (0-based) owns tile $C_{ij}$ of the product and, after alignment,
holds one tile of $A$ and one of $B$ at a time.

`Grid_P = 0` in the API defaults to **element-per-PE** mode: $P=n$, $B_S=1$.

### Initial alignment

Skew so that PE $(i,j)$ starts with

$$
A_{i,\,(i+j)\bmod P}
\quad\text{and}\quad
B_{(i+j)\bmod P,\,j}.
$$

Equivalently: circular-shift **row** $i$ of the $A$ tile grid **left** by $i$
positions, and circular-shift **column** $j$ of the $B$ tile grid **up** by $j$
positions. This matches the Wikipedia selection $k:=(i+j)\bmod N$ so that
processors in the same row/column begin with different $k$.

### Systolic loop

For $s = 1,\ldots,P$:

1. **Local MAC** at every PE: $C_{ij} \mathrel{+}= A_{ij}\, B_{ij}$
   (classical dense multiply of the current $B_S\times B_S$ tiles).
2. **Shift**: pass $A$ cyclically one PE to the **left**; pass $B$ cyclically
   one PE **up** (toroidal wrap).

After $P$ steps, every PE has accumulated all contributions

$$
C_{ij} = \sum_{k=0}^{P-1} A_{i k}\, B_{k j}
$$

(in block arithmetic), which equals the classical product $AB$.

### Complexity sketch (parallel view)

With $p=P^2$ processors and tile width $B_S=n/P$, each PE performs $P$ local
$O(B_S^3)$ multiplies and $O(P)$ neighbour exchanges of $O(B_S^2)$ words.
Wikipedia’s runtime sketch separates collective setup, sequential tile work,
and per-hop start/byte costs. This Ada package **simulates** that schedule on
one thread for teaching; wall-clock parallelism is not claimed.

### Explicit storage (teaching)

Working arrays `Loc_A`, `Loc_B`, `Loc_C` are full $n\times n$ layouts whose
$P\times P$ tiles represent what each PE currently holds. Shifts are
implemented by copying tiles toroidally (`Shift_A_Left`, `Shift_B_Up`) so the
communication pattern stays visible in the source.

## API summary

| Symbol | Role |
| --- | --- |
| `Matrix` | 1-based educational `Float` 2-D array |
| `Max_N` | Hard dimension cap ($32$) |
| `Default_Grid_P` | $0$ → default $P=n$ (element-per-PE) |
| `Status` | `Ok`, `Dimension_Error`, `Ill_Started` |
| `Multiply_Result` | `C`, `N`, `Stat`, `Success`, `Grid_P`, `Block_Size`, `Shift_Count` |
| `Multiply_Classical` | Standard $O(n^3)$ product (oracle) |
| `Multiply_Cannon` | Simulated Cannon mesh MM ($A$, $B$, optional `Grid_P`) |
| `Product_Matrix` | Extract leading $N\times N$ from a result |
| `Near` / `Mat_Near` | Scalar / matrix proximity |
| `Norm_Frobenius` / `Diff_Frobenius` | $\|A\|_F$ and $\|A-B\|_F$ |
| `Mat_Add` / `Mat_Sub` / `Mat_Scale` | Dense helpers |
| `Is_Square` / `Divides` / `Is_Valid_Grid` | Structure / mesh checks |
| `Zeros`, `Ones`, `Identity`, `Sequential_Fill`, `Deterministic`, `Make_Hilbert` | Builders |

## Limits and caveats

- **Sequential simulation** of a parallel algorithm — one Ada task, educational
  clarity over distributed runtime or MPI/OpenMP.
- **$n\le 32$**, educational `Float` — not BLAS, not a production mesh runtime.
- **`Grid_P` must divide $n$** (or be $0$ for default $P=n$); otherwise
  `Dimension_Error`.
- **SUMMA** is more practical in modern HPC (less workspace, non-square grids);
  documented here only as a sibling, not implemented.
- Cannon extends poorly to **heterogeneous** 2D grids (Wikipedia caveat).
- Compare residuals with `Multiply_Classical` / `Diff_Frobenius`.
- Inputs are **not** modified.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pcannons_algorithm.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `cannons_algorithm.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
cannons_algorithm.ads
cannons_algorithm.adb
cannons_algorithm.gpr
tests.adb
```

## References

1. [Wikipedia: Cannon's algorithm](https://en.wikipedia.org/wiki/Cannon's_algorithm)
2. Cannon, L. E. (1969). *A cellular computer to implement the Kalman filter
   algorithm.* Ph.D. thesis, Montana State University.
3. SUMMA / ScaLAPACK literature (practical 2D MM sibling; not implemented here).
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
