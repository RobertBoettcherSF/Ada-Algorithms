# SMAWK Algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **SMAWK algorithm**:
finding the **row minima** (leftmost argmin) of an **implicitly defined
totally monotone** matrix in far fewer than $nm$ comparisons. Caps
$n,m\le 64$. Named after its five inventors: **S**hor, **M**oran,
**A**ggarwal, **W**ilber, and **K**lawe.

Based on [Wikipedia: SMAWK algorithm](https://en.wikipedia.org/wiki/SMAWK_algorithm).
Related: [Monge array](https://en.wikipedia.org/wiki/Monge_array),
[Dynamic programming](https://en.wikipedia.org/wiki/Dynamic_programming),
[Hungarian algorithm](https://en.wikipedia.org/wiki/Hungarian_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Dynamic-Programming](https://github.com/RobertBoettcherSF/Ada-Dynamic-Programming)** —
  Bellman DP survey (SMAWK accelerates some DP recurrences)
- **[Ada-Chain-Matrix-Multiplication](https://github.com/RobertBoettcherSF/Ada-Chain-Matrix-Multiplication)** —
  matrix-chain ordering (concave/convex DP cousin)
- **[Ada-Hungarian-Method](https://github.com/RobertBoettcherSF/Ada-Hungarian-Method)** —
  assignment on dense cost matrices
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: dense checkers on tiny matrices, classical
reduce/interpolate SMAWK, leftmost ties. Production concave-DP /
RNA-folding / paragraph-breaking stacks are intentionally out of scope.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Input** | Dense matrix **or** `Matrix_Lookup` | $A(i,j)$ in $O(1)$ |
| **Property** | Totally monotone (TM) | Every submatrix is monotone |
| **Stronger** | Monge $\Rightarrow$ TM | Builders use Monge forms |
| **Baseline** | `Naive_Row_Minima` | $O(nm)$ scans |
| **SMAWK** | Reduce + interpolate recursion | Educational $O(n+m)$ |
| **Checkers** | `Is_Totally_Monotone`, `Is_Monge` | Small dense only |
| **Caps** | $n\le 64$, $m\le 64$ | `Max_N`, `Max_M` |

## Totally monotone and Monge

A matrix is **monotone** (for row minima) when the column of each row’s
minimum is **nondecreasing** down the rows. It is **totally monotone**
when every submatrix (arbitrary row/column subsets) is monotone.
Equivalently: there is **no** $2\times 2$ submatrix whose row minima sit
at the **top-right** and **bottom-left**.

With a leftmost-tie policy, total monotonicity for minima is often stated
as: for all $i<i'$ and $j<j'$,

$$
A(i,j)>A(i,j') \implies A(i',j)\ge A(i',j').
$$

A matrix is **Monge** when for all $i<i'$, $j<j'$,

$$
A(i,j)+A(i',j') \le A(i,j')+A(i',j).
$$

Every Monge matrix is totally monotone (for row minima), but not
conversely. A standard Monge construction used here is

$$
A(i,j)=f(i)+g(j)+c\,i\,j,\qquad c\le 0
$$

(with textbook defaults $f(i)=i$, $g(j)=j$, $c=-1$). Squared distances
$A(i,j)=(i-j)^2$ are also Monge.

## SMAWK idea (reduce / interpolate)

SMAWK follows a **prune-and-search** strategy:

1. **Reduce** — a stack-based column prune (Graham-scan / all-nearest-smaller
   values style) deletes columns that cannot contain any remaining row
   minimum. After reduce, the number of surviving columns is at most the
   number of rows.
2. **Recurse** — solve the even-positioned rows of the current row list
   on the reduced column set.
3. **Interpolate** — fill each odd-positioned row by a linear scan of the
   (few) columns between the argmins of its neighboring even rows.

When $A(i,j)$ is $O(1)$, the classic analysis gives $O\bigl(m(1+\log(n/m))\bigr)$
evaluations for $n$ rows and $m$ columns (often quoted as linear $O(n+m)$
in the balanced / reduced regime). The naive scan is $\Theta(nm)$.

## API (`Smawk`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_N`, `Max_M`, `Dim_N`, `Dim_M` | Educational bounds |
| Dense | `Dense_Matrix`, `Zero_Dense`, `Get`, `Set`, `Near` | Tiny matrices |
| Lookup | `Matrix_Lookup`, `Bind_Dense`, `Bound_Lookup` | Implicit $A(i,j)$ |
| Checkers | `Is_Totally_Monotone`, `Is_Monge`, `Is_Row_Minima_Monotone` | Validate examples |
| Baseline | `Naive_Row_Minima` (dense / lookup) | $O(nm)$ reference |
| SMAWK | `SMAWK_Row_Minima` (dense / lookup) | Reduce + interpolate |
| Builders | `Build_Monge_Product`, `Build_Squared_Distance`, `Build_Antitone_Product`, `Build_Non_Monotone_Example` | TM / reject fixtures |

Exceptions: `Invalid_Argument` (reserved for callers).

Result type: `Argmin_Array` — for each row, the **leftmost** column index of
that row’s minimum.

## Build & test

```bash
make        # gnatmake -gnatwa -gnat2022 -Psmawk.gpr
make test   # runs bin/tests; expect Fail_Count = 0
make clean
```

Root layout (exactly seven files; **no** `main.adb`):

`.gitignore`, `Makefile`, `README.md`, `smawk.ads`,
`smawk.adb`, `smawk.gpr`, `tests.adb`.

## Caveats

- **Totally monotone precondition** — `SMAWK_Row_Minima` assumes the matrix
  is totally monotone. On non-TM inputs the answer may be wrong; use
  `Is_Totally_Monotone` / `Is_Monge` on small dense examples, or compare to
  `Naive_Row_Minima`.
- **Leftmost ties** — both naive and SMAWK break ties toward the smaller
  column index.
- **Dense scratch adapter** — the dense overload copies into a package-level
  scratch buffer (educational, not re-entrant / not task-safe).
- **Caps** — $n,m\le 64$; TM/Monge checkers are $O(n^2 m^2)$ and intended
  only for tiny matrices.
- Sibling repos are linked for the series; this package has **no** Ada
  `with` dependencies on them.

## License

Educational code for the RobertBoettcherSF Ada algorithm series.
