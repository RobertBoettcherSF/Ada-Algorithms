# Freivalds' Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **Freivalds'
algorithm** for probabilistic verification of matrix products: given square
matrices $A$, $B$, and $C$, decide whether

$$
AB = C
$$

without forming the full product $AB$. Draw a random vector $r\in\{0,1\}^n$,
compute $Br$, then $A(Br)$ and $Cr$, and compare. Cap $n\le 32$, educational
**Integer** arithmetic (exact), with a seeded LCG for reproducible tests.
`Multiply_Classical` is the exact $O(n^3)$ oracle used by the test suite.

Based on [Wikipedia: Freivalds' algorithm](https://en.wikipedia.org/wiki/Freivalds'_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (README links only — **no** `with` deps):

- **[Ada-Strassen](https://github.com/RobertBoettcherSF/Ada-Strassen)** — fast $7$-product matrix multiply
- **[Ada-Coppersmith-Winograd](https://github.com/RobertBoettcherSF/Ada-Coppersmith-Winograd)** — upcoming; further asymptotic MM
- **[Ada-System-of-Linear-Equations](https://github.com/RobertBoettcherSF/Ada-System-of-Linear-Equations)** — survey of $Ax=b$ solvers

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Fingerprint $AB$ vs $C$ via $r$ | Check $A(Br)=Cr$ |
| **Probe** | $r\in\{0,1\}^n$ | One bit per coordinate |
| **Cost** | Three mat–vec multiplies | $O(n^2)$ per trial |
| **Error** | One-sided Monte Carlo | $\le 1/2$ if $AB\neq C$ |
| **$k$ trials** | Independent repeats | Failure $\le 2^{-k}$ |
| **Oracle** | `Multiply_Classical` | Exact Integer $O(n^3)$ |
| **PRNG** | Seeded educational LCG | Reproducible tests |
| **Cap** | $n\le 32$ | `Max_N = 32` |

## Brief history

**Rūsiņš Mārtiņš Freivalds** introduced this fingerprinting idea for verifying
matrix multiplication (and related algebraic identities) with randomness.
Naive verification multiplies explicitly in $O(n^3)$ (or the best known
matrix-multiplication exponent, still super-quadratic). Freivalds reduces
*verification* to $O(kn^2)$ with failure probability at most $2^{-k}$ when
the claimed product is wrong, and **never** falsely rejects a true product.
That one-sided error makes it a classic **Monte Carlo** algorithm in
randomized algorithms courses.

## Method (this package)

### Single trial

1. Draw $r\in\{0,1\}^n$ from the seeded LCG (each coordinate an independent
   educational bit).
2. Compute $u = Br$, then $v = Au$, and $w = Cr$ (all exact Integer
   mat–vec).
3. If $v\neq w$, report **`Unequal`** ($AB\neq C$ for sure).
4. If $v=w$, this trial is consistent with $AB=C$.

Equivalently,

$$
\vec{P} = A(Br) - Cr = (AB-C)r.
$$

The trial accepts when $\vec{P}=\mathbf{0}$.

### Error (one-sided)

- If $AB=C$, then $(AB-C)r=\mathbf{0}$ for every $r$, so the algorithm
  **always** returns **`Equal_Probably`** (no false negatives for equality).
- If $AB\neq C$, then for $r$ uniform in $\{0,1\}^n$ over a field (here
  educational exact Integer with $0/1$ probes),

$$
\Pr[\,(AB-C)r = \mathbf{0}\,] \le \tfrac{1}{2}.
$$

Repeating $k$ independent trials and accepting only if all succeed yields

$$
\Pr[\text{false ``Equal\_Probably''}] \le 2^{-k},
$$

in $O(kn^2)$ arithmetic operations.

### Wikipedia $2\times 2$ example

$$
A=\begin{bmatrix}2&3\\3&4\end{bmatrix},\quad
B=\begin{bmatrix}1&0\\1&2\end{bmatrix},\quad
C=\begin{bmatrix}6&5\\8&7\end{bmatrix}.
$$

The true product is $AB=\begin{bmatrix}5&6\\7&8\end{bmatrix}\neq C$. With
$r=\begin{bmatrix}1\\1\end{bmatrix}$ one obtains $A(Br)\neq Cr$, so Freivalds
correctly reports inequality.

### Why Integer?

Educational **Integer** matrices (small entries, exact arithmetic) keep the
probability statement clean: there is no floating-point noise that could
mimic or hide a mismatch. `Multiply_Classical` is the exact oracle for
building true products and deliberately corrupted $C$ matrices in tests.

## API summary

| Symbol | Role |
| --- | --- |
| `Matrix` / `Vector` | 1-based educational `Integer` arrays |
| `Max_N` | Hard dimension cap ($32$) |
| `Verdict` | `Equal_Probably`, `Unequal`, `Dimension_Error` |
| `Verify_Result` | `Stat`, `N`, `Trials_Used`, `Failures`, `Seed_Final` |
| `Verify` | $k$-trial Freivalds check ($A,B,C$, `Trials`, `Seed`) |
| `Verify_Once` | Single trial; updates `Seed` in place |
| `Multiply_Classical` | Exact $O(n^3)$ product (oracle) |
| `Product_Matrix` | Extract leading $N\times N$ from a multiply result |
| `Mat_Vec` / `Mat_Add` / `Mat_Sub` / `Mat_Scale` | Dense helpers |
| `Mat_Equal` / `Vec_Equal` / `Matrices_Equal` | Exact equality |
| `LCG_Next` / `LCG_Bit` / `Random_01_Vector` | Seeded teaching PRNG |
| `Zeros`, `Ones`, `Identity`, `Sequential_Fill`, `Deterministic` | Builders |
| `Corrupt_Entry` | Deliberate wrong $C$ for negative tests |
| `Default_Trials` / `Default_Seed` | $8$ / $1$ |

## Limits and caveats

- **Monte Carlo, one-sided error**: `Equal_Probably` is never wrong when
  $AB=C$, but when $AB\neq C$ a short run of trials can still miss the
  difference (probability $\le 2^{-k}$ under the ideal model).
- **Educational PRNG**: the package LCG is for **reproducible tests**, not
  cryptography or production randomness.
- **$n\le 32$**, dense `Integer` — not a BLAS / blocked production verifier;
  prefer small entry ranges so products stay inside `Integer`.
- Accumulators in `Mat_Vec` / `Multiply_Classical` use `Long_Integer`
  intermediates before storing `Integer` entries.
- Early exit on the first failing trial (`Unequal`); `Trials_Used` may be
  less than the requested budget.
- Inputs are **not** modified (`Verify` copies a local seed).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pfreivalds.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `freivalds.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
freivalds.ads
freivalds.adb
freivalds.gpr
tests.adb
```

## References

1. [Wikipedia: Freivalds' algorithm](https://en.wikipedia.org/wiki/Freivalds'_algorithm)
2. Freivalds, R. (1977). Probabilistic machines can use less running time.
3. Motwani & Raghavan, *Randomized Algorithms* (fingerprinting / Freivalds).
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
