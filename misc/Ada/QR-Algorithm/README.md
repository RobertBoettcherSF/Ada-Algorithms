# QR Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the **QR algorithm**
(QR iteration) for eigenvalues of real dense matrices. Prefer **symmetric**
test cases so the spectrum is real. Each step factors $A_k=Q_k R_k$ by
**Modified Gram–Schmidt**, then forms the similar iterate

$$
A_{k+1}=R_k Q_k=Q_k^\top A_k Q_k.
$$

Under mild conditions $A_k$ tends to (block-)triangular / diagonal form; the
eigenvalues are read from the diagonal. Cap $n\le 16$, dense educational
`Float`.

Based on [Wikipedia: QR algorithm](https://en.wikipedia.org/wiki/QR_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Gram-Schmidt](https://github.com/RobertBoettcherSF/Ada-Gram-Schmidt)** — classical / modified orthonormalization
- **[Ada-Rayleigh-Quotient-Iteration](https://github.com/RobertBoettcherSF/Ada-Rayleigh-Quotient-Iteration)** — cubic local eigenpair iteration
- **Power method** — upcoming
- **Lanczos algorithm** — upcoming
- **Arnoldi iteration** — upcoming
- **Jacobi eigenvalue algorithm** — upcoming
- **Inverse iteration** — upcoming
- **Eigenvalue methods survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Iterate $A_{k+1}=R_k Q_k$ | Similar to $A_k$; spectrum preserved |
| **QR** | Modified Gram–Schmidt | `QR_Factor` → $(Q,R)$ |
| **Stop** | $\mathrm{OffDiag}(A_k)\le$ `Tol` | Frobenius off-diagonal norm |
| **Readout** | Diagonal of final $A_k$ | Real eigenvalues (symmetric cases) |
| **Status** | `Converged` … `Rank_Issue` | Incl. `Iteration_Limit` |
| **Extras** | `Wilkinson_Shift`, `QR_Step` | Explicit-shift sketch; `Accumulate_Q` |
| **Builders** | Diagonal / Poisson / Hilbert / known | Known spectra for tests |
| **Dim** | $n\le 16$ | `Max_N = 16` |

## Brief history

The QR algorithm was developed in the late 1950s independently by
**John G. F. Francis** and **Vera N. Kublanovskaya**. It became the workhorse
dense eigensolver once combined with Hessenberg reduction, implicit shifts, and
deflation. This package teaches the **basic unshifted** iteration on small dense
matrices — the conceptual core — not a production LAPACK-style driver.

## Algorithm (this package)

Given a real $n\times n$ matrix $A$ (preferably symmetric):

1. Set $A_0:=A$.
2. For $k=0,1,2,\ldots$ until the off-diagonal mass is small or the budget is
   spent:
   - Factor $A_k=Q_k R_k$ by Modified Gram–Schmidt (`QR_Factor`).
   - Set $A_{k+1}:=R_k Q_k$.
3. Read approximate eigenvalues from $\mathrm{diag}(A_k)$.
4. Optionally accumulate $V\approx Q_0 Q_1\cdots Q_{k-1}$ when
   `Accumulate_Q` is True (eigenvector sketch: $A V\approx V\Lambda$).

Similarity:

$$
A_{k+1}=R_k Q_k=Q_k^{-1}(Q_k R_k)Q_k=Q_k^\top A_k Q_k.
$$

**Wilkinson shift sketch.** `Wilkinson_Shift` returns the eigenvalue of the
trailing $2\times 2$ block closer to the corner entry; `QR_Step (A, σ)`
performs one explicit shifted step $(A-\sigma I)=QR$, then
$A'=RQ+\sigma I$. Full `Iterate` stays **unshifted** for reliability with
dense MGS + educational `Float` (explicit shifts often stall on this path).

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($16$) |
| `Parameters` | `Tol`, `Max_Iter`, `Use_Shift`, `Accumulate_Q` |
| `Status` | `Converged` / `Iteration_Limit` / `Ill_Started` / `Dimension_Error` / `Rank_Issue` |
| `QR_Factor` | MGS QR: $A=QR$ |
| `QR_Step` | One (optional shifted) QR similarity step |
| `Iterate` / `Eigenvalues` | Unshifted QR iteration |
| `Wilkinson_Shift` | Trailing $2\times 2$ shift sketch |
| `Off_Diag_Norm`, `Mat_Mul`, `Near`, `Is_Symmetric` | Helpers |
| `Make_Diagonal`, `Make_Symmetric_Known`, … | Teaching matrices |

## Limits and caveats

- **Unshifted may be slow** — without Hessenberg reduction / implicit shifts /
  deflation, iteration counts grow for poorly separated spectra.
- **Educational `Float`** — no extended precision; ill-conditioned Hilbert
  examples need looser tolerances.
- **Dense only** — $O(n^3)$ per step; fine for $n\le 16$, not a sparse
  production eigensolver.
- **Complex / non-symmetric** — real Schur form / complex conjugate pairs are
  **not** fully handled; prefer symmetric / SPD test cases for real $\lambda$.
- **Explicit Wilkinson** via `QR_Step` is a sketch; `Iterate` uses the safe
  unshifted path.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pqr_algorithm.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `qr_algorithm.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
qr_algorithm.ads
qr_algorithm.adb
qr_algorithm.gpr
tests.adb
```

## References

1. [Wikipedia: QR algorithm](https://en.wikipedia.org/wiki/QR_algorithm)
2. Francis, J. G. F. — The QR Transformation (parts I & II), *Comput. J.*, 1961–62.
3. Kublanovskaya, V. N. — On some algorithms for the solution of the complete
   eigenvalue problem, 1961.
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
