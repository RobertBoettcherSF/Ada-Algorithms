# Strassen Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **Strassen's
algorithm** for fast square matrix multiplication: the classic **seven-product**
recursive $2\times 2$ block scheme (Volker Strassen, 1969). Asymptotic cost

$$
O(n^{\log_2 7})\approx O(n^{2.807})
$$

versus classical

$$
O(n^3).
$$

Cap $n\le 32$, dense educational `Float`, with **pad-and-trim** for sizes that
are not powers of two. `Multiply_Classical` is provided as a baseline /
residual oracle. Optional counters report leaf scalar multiplies and recursion
depth for teaching.

Based on [Wikipedia: Strassen algorithm](https://en.wikipedia.org/wiki/Strassen_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (README links only — **no** `with` deps):

- **[Ada-Coppersmith-Winograd](https://github.com/RobertBoettcherSF/Ada-Coppersmith-Winograd)** — upcoming; further asymptotic improvements
- **[Ada-Freivalds](https://github.com/RobertBoettcherSF/Ada-Freivalds)** — upcoming; probabilistic product verification
- **[Ada-System-of-Linear-Equations](https://github.com/RobertBoettcherSF/Ada-System-of-Linear-Equations)** — survey of $Ax=b$ solvers

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Fewer block multiplies | $7$ instead of $8$ per $2\times 2$ |
| **Recursion** | Halve $n$ each level | Prefer power-of-2 blocks |
| **Base** | Classical when $n\le$ `Leaf` | Default `Leaf = 1` |
| **Padding** | Zero-pad to next $2^k$ | Then trim product |
| **Oracle** | `Multiply_Classical` | $O(n^3)$ residual checks |
| **Counters** | Scalar mults / depth | Educational telemetry |
| **Cap** | $n\le 32$ | `Max_N = 32` |

## Brief history

Volker **Strassen** (1969) showed that the $\Theta(n^3)$ arithmetic complexity of
the naive algorithm is **not optimal**, by multiplying $2\times 2$ blocks with
**seven** multiplications (and more additions). That opened the modern line of
fast matrix-multiplication research (Pan, Coppersmith–Winograd, and later
improvements). For practical sizes, highly tuned classical kernels often win;
Strassen becomes attractive past a **crossover** dimension that depends on
hardware and implementation. Wikipedia notes reduced numerical stability and
extra workspace relative to the naive method.

## Method (this package)

### Block partition

For even $n$ (after padding), write

$$
A=\begin{bmatrix}A_{11}&A_{12}\\A_{21}&A_{22}\end{bmatrix},\quad
B=\begin{bmatrix}B_{11}&B_{12}\\B_{21}&B_{22}\end{bmatrix},\quad
C=\begin{bmatrix}C_{11}&C_{12}\\C_{21}&C_{22}\end{bmatrix}.
$$

Naive block multiply needs **eight** half-size products. Strassen needs
**seven**.

### Seven products (classic)

$$
\begin{align*}
M_1 &= (A_{11}+A_{22})(B_{11}+B_{22}),\\
M_2 &= (A_{21}+A_{22})B_{11},\\
M_3 &= A_{11}(B_{12}-B_{22}),\\
M_4 &= A_{22}(B_{21}-B_{11}),\\
M_5 &= (A_{11}+A_{12})B_{22},\\
M_6 &= (A_{21}-A_{11})(B_{11}+B_{12}),\\
M_7 &= (A_{12}-A_{22})(B_{21}+B_{22}).
\end{align*}
$$

### Combine into $C$

$$
\begin{align*}
C_{11} &= M_1+M_4-M_5+M_7,\\
C_{12} &= M_3+M_5,\\
C_{21} &= M_2+M_4,\\
C_{22} &= M_1-M_2+M_3+M_6.
\end{align*}
$$

Each $M_k$ is computed by the **same** algorithm recursively. When the block
size is $\le$ `Leaf`, the package falls back to classical $O(n^3)$ multiply.

### Pad-and-trim

If $n$ is not a power of two, both factors are **zero-padded** to the next
power of two $P=2^{\lceil\log_2 n\rceil}$ (with $P\le\texttt{Max\_N}$), Strassen
runs on the $P\times P$ matrices, and the leading $n\times n$ of the product is
returned. This matches the Wikipedia conceptual description; production codes
often avoid full padding.

### Complexity sketch

With `Leaf = 1`, the recurrence $T(n)=7\,T(n/2)+\Theta(n^2)$ yields

$$
T(n)=\Theta(n^{\log_2 7}).
$$

Leaf scalar-multiply counts in this package: $7^{\log_2 n}$ for pure power-of-2
$n$ (e.g. $n=4\to 49$, $n=8\to 343$), versus $n^3$ classical.

## API summary

| Symbol | Role |
| --- | --- |
| `Matrix` | 1-based educational `Float` 2-D array |
| `Max_N` | Hard dimension cap ($32$) |
| `Default_Leaf` | Recursion leaf size (default $1$) |
| `Status` | `Ok`, `Dimension_Error`, `Ill_Started` |
| `Multiply_Result` | `C`, `N`, `Stat`, `Success`, counters, `Padded_N` |
| `Multiply_Classical` | Standard $O(n^3)$ product |
| `Multiply_Strassen` | Pad → 7-product recursion → trim |
| `Product_Matrix` | Extract leading $N\times N$ from a result |
| `Near` / `Mat_Near` | Scalar / matrix proximity |
| `Norm_Frobenius` / `Diff_Frobenius` | $\|A\|_F$ and $\|A-B\|_F$ |
| `Mat_Add` / `Mat_Sub` / `Mat_Scale` | Dense helpers |
| `Is_Square` / `Is_Power_Of_Two` / `Next_Power_Of_Two` | Structure |
| `Pad_To_Power_Of_Two` / `Trim` | Explicit padding helpers |
| `Zeros`, `Ones`, `Identity`, `Sequential_Fill`, `Deterministic`, `Make_Hilbert` | Builders |

## Limits and caveats

- **$n\le 32$**, educational `Float` — not BLAS, not blocked / Strassen–Winograd
  production kernels.
- **Numerical stability** is weaker than classical multiply (more additions,
  cancellation); compare residuals with `Multiply_Classical` /
  `Diff_Frobenius`.
- **Crossover**: for small $n$, classical (and especially tuned GEMM) is
  usually faster; Strassen’s win is asymptotic / large-$n$.
- **Padding** stores up to the next power of two and allocates seven temporary
  half-size products per recursion level — clarity over micro-optimality.
- Pure recursion with `Leaf = 1` maximizes educational fidelity; raise `Leaf`
  to illustrate practical hybrid cutoffs.
- Inputs are **not** modified.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pstrassen.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `strassen.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
strassen.ads
strassen.adb
strassen.gpr
tests.adb
```

## References

1. [Wikipedia: Strassen algorithm](https://en.wikipedia.org/wiki/Strassen_algorithm)
2. Strassen, V. (1969). *Gaussian elimination is not optimal.* Numerische Mathematik.
3. Higham, N. J. *Accuracy and Stability of Numerical Algorithms* (stability of
   fast MM).
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
