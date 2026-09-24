# Buzen's algorithm (Ada 2023)

Educational, self-contained Ada 2023 package implementing
[Wikipedia: Buzen's algorithm](https://en.wikipedia.org/wiki/Buzen%27s_algorithm)
(also called the **convolution algorithm**) for computing Gordon–Newell
normalizing constants $G(0),\ldots,G(N)$ in **closed queueing networks**,
plus derived marginal probabilities and means.

Buzen's method was introduced in Jeffrey P. Buzen's 1971 PhD dissertation and
published in *Communications of the ACM* (1973). It evaluates $G(N)$ with
only $NM$ multiplications and $NM$ additions instead of enumerating all
$\binom{N+M-1}{M-1}$ states required by a naïve sum.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Normalizing constants** | In-place column convolution | Wikipedia Pascal loop |
| **Full table** | $g(n,m)$ recurrence | Pedagogical matrix |
| **Marginals** | $P(n_i\ge k)$, $P(n_i=k)$ | Buzen identities |
| **Means** | $E[n_i]=\sum_k X_i^k G(N-k)/G(N)$ | Closed network |
| **Utilization** | $U_i=X_i\,G(N-1)/G(N)$ | Load-independent servers |
| **Traffic helpers** | `Make_X_Cyclic`, `Make_X_From_Rates` | Educational $X_i=V_i/\mu_i$ |

## Features

| Area | Subprograms | Role |
| --- | --- | --- |
| Convolution | `Compute_G` | $G(0)..G(N)$ via Buzen |
| Pedagogy | `Compute_G_Matrix` | Full $g(n,m)$ table |
| Marginals | `Prob_Ni_At_Least`, `Prob_Ni_Equals` | Wikipedia formulas |
| Means | `Expected_Ni` | Mean queue length |
| Utilization | `Station_Utilization` | Single-server FCFS/PS/LCFS |
| States | `State_Probability` | $\prod X_i^{n_i}/G(N)$ |
| Traffic | `Make_X_Cyclic`, `Make_X_From_Rates` | Build loadings from $\mu,V$ |
| Helpers | `Near`, `Power` | Tolerant compare / $x^k$ |

Strong typing uses domain types (`Real` digits 12, bounded `X_Vector`,
`G_Vector`, `G_Matrix`, `Customer_Vector`). Public subprograms carry `Pre` /
`Post` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry` /
`Singular_System`, `Capacity_Exceeded`, `Empty_Sample` (parity with sibling
packages; unused slots are harmless).

## Algorithm

Given relative loadings $X_1,\ldots,X_M>0$ (solutions of the traffic
equations $\mu_j X_j=\sum_i \mu_i X_i p_{ij}$), define $g(n,m)$ as the
normalizing constant for the first $m$ stations and $n$ customers:

$$
g(n,m)=g(n,m-1)+X_m\,g(n-1,m)
$$

with $g(0,m)=1$ and $g(n,1)=X_1^n$. Then $G(n)=g(n,M)$.

### Wikipedia Pascal (in-place column)

```pascal
C[0] := 1
for n := 1 step 1 until N do
   C[n] := 0;

for m := 1 step 1 until M do
  for n := 1 step 1 until N do
     C[n] := C[n] + X[m]*C[n-1];
```

At completion, $C[n]=G(n)$ for $n=0..N$. Note $C[0]$ remains $1$.

## Marginals (Gordon–Newell / Buzen)

Stationary state probabilities:

$$
\mathbb{P}(n_1,\ldots,n_M)=\frac{1}{G(N)}\prod_{i=1}^{M} X_i^{n_i}
\quad(\textstyle\sum_i n_i=N).
$$

Efficient marginals from the $G(\cdot)$ sequence alone:

$$
\begin{aligned}
P(n_i\ge k)&=X_i^k\,\frac{G(N-k)}{G(N)},\\
P(n_i=k)&=\frac{X_i^k}{G(N)}\bigl[G(N-k)-X_i\,G(N-k-1)\bigr]
\quad(k=0..N-1),\\
P(n_i=N)&=\frac{X_i^N}{G(N)},\\
E[n_i]&=\sum_{k=1}^{N} X_i^k\,\frac{G(N-k)}{G(N)}.
\end{aligned}
$$

For load-independent single servers, utilization
$U_i=X_i\,G(N-1)/G(N)$ (textbook identity; documented carefully in the
API). In a closed network, $\sum_i E[n_i]=N$.

## Usage

```ada
with Buzens_Algorithm; use Buzens_Algorithm;

procedure Demo is
   X : constant X_Vector := Make_X_Cyclic ([2.0, 1.0]);  -- μ=(2,1)
   N : constant Natural := 5;
   G : constant G_Vector := Compute_G (X, N);
   E1 : constant Real := Expected_Ni (X (1), G);
   U2 : constant Real := Station_Utilization (X (2), G);
begin
   null;  -- G(0)..G(N), means, utilizations available
end Demo;
```

Validate inputs: $X'Length\ge 1$, each $X(i)>0$, $N\le$ `Max_Customers`,
and $G(N)>0$ before forming probabilities.

## Building

```bash
cd /workspace/ada-buzens-algorithm
make clean && make
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## Testing

```bash
make test
```

The `tests.adb` main program runs a rich suite (≥13 sections) covering
trivial $M=1$, brute-force equivalence, Pascal invariance, matrix vs
vector, marginal summation, $\sum_i E[n_i]=N$, state enumeration,
invalid / capacity edges, cyclic utilization identities, and monotonicity
sanity checks. Exit status is nonzero if any check fails
(`pragma Assert (Fail_Count = 0)`).

## Layout

Root-only sources (no `src/`, no separate `main.adb`):

- `buzens_algorithm.ads` / `.adb` — package
- `buzens_algorithm.gpr` — GPR (`Main = tests.adb`)
- `Makefile` — `gnatmake -Pbuzens_algorithm.gpr`
- `tests.adb` — test main
- `README.md`, `.gitignore`

## References

1. Buzen, J. P. (1971). *Queueing Network Models of Multiprogramming*
   (PhD dissertation). DTIC AD0731575.
2. Buzen, J. P. (1973). Computational algorithms for closed queueing
   networks with exponential servers. *Communications of the ACM*,
   16(9), 527–531. https://doi.org/10.1145/362342.362345
3. Gordon, W. J., & Newell, G. F. (1967). Closed Queuing Systems with
   Exponential Servers. *Operations Research*, 15(2), 254–265.
   https://doi.org/10.1287/opre.15.2.254
4. Wikipedia: [Buzen's algorithm](https://en.wikipedia.org/wiki/Buzen%27s_algorithm)
5. Jain, R. — *The Convolution Algorithm* (class handout).
6. Menasce, D. — *Convolution Approach to Queueing Algorithms* (slides).
