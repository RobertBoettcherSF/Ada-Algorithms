# Matrix Chain Multiplication — Ada 2023

Educational, self-contained Ada 2023 package for **matrix chain
multiplication** (matrix chain ordering): choose an **optimal
parenthesization** of a product $A_1 A_2 \cdots A_n$ so that the number of
**scalar multiplications** is minimized. The package implements the classic
$O(n^3)$ **dynamic programming** algorithm (cost table $m$ + split table
$s$), reconstructs a parenthesization string, and provides verification
helpers (cost of a given split; left- / right-associative baselines).

**Honest scope:** educational tables with cap $n\le 32$ matrices (dimension
array length $n+1$). Not a production solver; Hu–Shing $O(n\log n)$ and
approximate linear-time methods are out of scope.

Based on [Wikipedia: Matrix chain multiplication](https://en.wikipedia.org/wiki/Matrix_chain_multiplication).

Siblings (full GitHub URLs; README links only — **no** `with` deps):

| Package | Role |
| --- | --- |
| [Ada-Dynamic-Programming](https://github.com/RobertBoettcherSF/Ada-Dynamic-Programming) | DP survey (includes a matrix-chain demo) |

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Associativity of matrix multiply | Order changes cost, not product |
| **Fill** | Bottom-up tabulation | Increasing chain length |
| **Tables** | `Cost_Table` $m$, `Split_Table` $s$ | $s[i,j]=\arg\min$ |
| **Output** | `Optimal_Cost` / `Optimal_Order` | Cost + splits |
| **String** | `Parenthesize` / `Format_Order` | e.g. `((A1*A2)*A3)` |
| **Verify** | `Cost_Of_Split`, left/right assoc | Round-trip checks |

## Associativity

Matrix multiplication is **associative**: for conformable $A,B,C$,
$(AB)C=A(BC)$. The **product** is unchanged, but the **number of scalar
multiplications** depends on parenthesization.

Example (Wikipedia): $A$ is $10\times 30$, $B$ is $30\times 5$, $C$ is
$5\times 60$.

$$
\begin{align*}
(AB)C &= (10\cdot 30\cdot 5)+(10\cdot 5\cdot 60)=4500,\\
A(BC) &= (30\cdot 5\cdot 60)+(10\cdot 30\cdot 60)=27000.
\end{align*}
$$

The number of full parenthesizations of $n$ matrices is the $(n-1)$-th
Catalan number — exponential — so brute force is impractical. DP reuses
overlapping subchains in $O(n^3)$ time and $O(n^2)$ space.

## DP recurrence

Let dimensions be $p_0,p_1,\ldots,p_n$ so that matrix $A_i$ is
$p_{i-1}\times p_i$. Let $m[i,j]$ be the minimum cost of computing
$A_i\cdots A_j$ (1-based matrix indices), and let $s[i,j]$ store an
optimal split index $k$.

Base:

$$
m[i,i]=0.
$$

For length $\ell=j-i+1\ge 2$:

$$
m[i,j]=\min_{i\le k<j}\Bigl(m[i,k]+m[k+1,j]+p_{i-1}\,p_k\,p_j\Bigr),
$$

$$
s[i,j]=\arg\min_{i\le k<j}\Bigl(m[i,k]+m[k+1,j]+p_{i-1}\,p_k\,p_j\Bigr).
$$

The answer for the full chain is $m[1,n]$. Reconstruct by recursively
expanding $s[1,n]$.

CLRS classic dims $30,35,15,5,10,20,25$ (six matrices) give
$m[1,6]=15125$ with $s[1,6]=3$.

## API (`Chain_Matrix_Multiplication`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Matrices` ($=32$), `Matrix_Count` | Educational bound |
| Types | `Dimensions`, `Cost_Table`, `Split_Table`, `DP_Result` | Domain |
| DP | `Optimal_Cost`, `Optimal_Order`, `Compute_DP` | Fill / query |
| Format | `Parenthesize`, `Format_Order` | Parenthesization string |
| Verify | `Cost_Of_Split` (full / subchain) | Check a split table |
| Assoc | `Left_Associative_Cost`, `Right_Associative_Cost` | Baselines |
| Helper | `Matrix_Count_Of` | $n=$ length$-1$ |

`Dimensions` has length $n+1$ for $n$ matrices: entry $i$ (relative to
`Dims'First`) is $p_i$. Exception: `Invalid_Argument` (e.g. inconsistent
split in `Cost_Of_Split`).

## Limits

- At most $n=32$ matrices (`Max_Matrices`).
- Costs use `Natural`; keep dimension products inside that range for demos.
- When several $k$ tie, the first minimizing $k$ is stored in $s[i,j]$.
- Parenthesization strings use ASCII `*` and names `A1`..`An`.

## Build & test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pchain_matrix_multiplication.gpr
make test   # runs bin/tests; expect Fail_Count = 0
make clean
```

Root layout (exactly seven files; **no** `main.adb`):

`.gitignore`, `Makefile`, `README.md`, `chain_matrix_multiplication.ads`,
`chain_matrix_multiplication.adb`, `chain_matrix_multiplication.gpr`,
`tests.adb`.

## Caveats

- **Educational Integer DP** — not arbitrary-precision; large $p_i$ products
  can overflow `Natural` if you exceed the intended demo sizes.
- **One optimal split** — ties keep the first minimizing $k$; the
  reconstructed string is **a** valid optimum, not necessarily unique.
- **No Hu–Shing / polygon triangulation** — only the classic cubic DP.
- Sibling [Ada-Dynamic-Programming](https://github.com/RobertBoettcherSF/Ada-Dynamic-Programming)
  links here for the series; this package has **no** Ada `with` dependency
  on it.

## License

Educational / as-is.
