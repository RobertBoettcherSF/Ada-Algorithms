# Nearest Neighbor Search — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Nearest neighbor search](https://en.wikipedia.org/wiki/Nearest_neighbor_search):
dissimilarity / distance helpers, **exact linear** 1-NN and $k$-NN, **radius
search**, a compact **k-d tree** exact NN (recursive splitting-plane prune),
and a tiny **$k$-NN majority-vote** classifier. A **method taxonomy** flags
Linear / Exact_KD_Tree (display name KD_Tree) / Best_Bin_First / LSH (BBF and LSH are metadata only).

Formally, given a set $S$ of points in a space $M$ and a query $q\in M$, find
the closest point in $S$ to $q$ (Knuth’s *post-office problem*). A direct
generalization is **$k$-NN**: return the $k$ closest points. Most commonly
$M=\mathbb{R}^d$ with Euclidean, Manhattan, or Chebyshev distance.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling **approximate**
priority-bin search lives in
[Ada-Best-Bin-First](https://github.com/RobertBoettcherSF/Ada-Best-Bin-First)
(link only — **not** a build dependency). This survey implements exact linear /
kd-tree methods; it does **not** copy the BBF package.

Educational limits: $d\le 8$, $n\le 256$.

## Curse of dimensionality (caveat)

Wikipedia’s informal **curse of dimensionality**: there is no general-purpose
exact NNS in high-dimensional Euclidean space with polynomial preprocessing and
polylogarithmic query time. Space-partition trees (k-d trees, etc.) degrade
toward linear scan as $d$ grows; naive linear search can be competitive in high
$d$. Approximate methods (BBF, LSH, HNSW, …) trade exactness for speed — see
the sibling BBF repo and taxonomy flags here.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Distances** | Euclidean², Manhattan, Chebyshev | `Near` helpers; metric checks |
| **Linear 1-NN / $k$-NN** | Brute-force scan | Sorted partial $k$-NN list |
| **Radius** | Brute-force within $R$ | All hits $\le R$ |
| **k-d tree** | Median-split + plane prune | Exact NN; **not** BBF |
| **Classify** | $k$-NN majority vote | Tiny labeled sketch |
| **Taxonomy** | `Method_Kind` | BBF / LSH = metadata flags |

## Formula summary

### Distances

Squared Euclidean (preferred for comparisons — omit $\sqrt{\,\cdot\,}$):

$$
\|u-v\|_2^2=\sum_{i=1}^{d}(u_i-v_i)^2.
$$

Manhattan ($L_1$) and Chebyshev ($L_\infty$):

$$
\|u-v\|_1=\sum_{i=1}^{d}|u_i-v_i|,\qquad
\|u-v\|_\infty=\max_{1\le i\le d}|u_i-v_i|.
$$

$L_1$ and $L_\infty$ are metrics (symmetry, identity, triangle). **Squared**
Euclidean is *not* a metric: triangle can fail (e.g. points $0,1,2$ on a line:
$d^2(0,2)=4\not\le 1+1$).

### Linear scan

For each database point compute $d(q,x)$; keep the minimum (1-NN) or a sorted
partial list of size $k$ ($k$-NN). Radius search returns $\{x\in S:d(q,x)\le R\}$.
Complexity $O(dn)$ with no auxiliary index.

### k-d tree exact NN

Build a binary tree by cycling axis $a=(depth\bmod d)+1$ and median-splitting.
Query: recurse into the **near** child first; visit the **far** child only if
the splitting-plane gap can beat the best distance so far:

$$
(q_a-s)^2 < d_{\mathrm{best}}^2
$$

(with $s$ the split value). Average $O(\log n)$ on random low-$d$ data; worst
case nearer to linear (Wikipedia / Friedman–Bentley–Finkel).

**Not** Best Bin First: BBF expands bins by min distance to AABB via a priority
queue and stops after $E_{\max}$ leaves (approximate). See
[Ada-Best-Bin-First](https://github.com/RobertBoettcherSF/Ada-Best-Bin-First).

### $k$-NN classification

Predict the majority label among the $k$ nearest labeled neighbors (ties →
smallest label id). Educational sketch only.

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Limits | `Max_Dim`, `Max_Points`, `Max_K`, `Max_Nodes`, … | Caps |
| Types | `Point`, `Cloud`, `Labels`, `Config`, `NN_Result`, `KNN_Result` | Domain |
| Distances | `Distance2`, `Manhattan`, `Chebyshev`, `Distance` | Metrics |
| Checks | `Is_Metric`, `Check_Symmetry` / `Triangle` / … | Pedagogy |
| Cloud | `Make_Cloud`, `Add_Point`, `Make_Point`, `Cloud_Count`/`Dim` | Point set |
| Labels | `Make_Labels`, `Set_Label`, `Get_Label` | Classification |
| Linear | `Linear_NN`, `Linear_KNN`, `Radius_Search` | Exact brute force |
| Tree | `Build_Tree`, `Tree_NN`, accessors | Exact kd-tree NN |
| Classify | `Classify_KNN`, `Majority_Vote` | Majority sketch |
| Taxonomy | `Method_Kind`, `Classify_Method`, `Method_Name` | Metadata |

Strong typing uses `Real` (digits 12) and capacity subtypes. Public
subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Empty_Cloud`.

## Usage

```ada
with Nearest_Neighbor_Search; use Nearest_Neighbor_Search;

declare
   C : Cloud := Make_Cloud (2);
   T : KD_Tree;
   Q : Point;
   R : NN_Result;
   K : KNN_Result;
begin
   Add_Point (C, Make_Point (2, (1.0, 2.0, others => 0.0)));
   -- ... more points ...
   R := Linear_NN (C, Q);
   K := Linear_KNN (C, Q, 3);
   T := Build_Tree (C);
   R := Tree_NN (T, Q);  -- exact; Euclidean² prune
end;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pnearest_neighbor_search.gpr`. Main program
is `tests.adb` (no `main.adb`). Expect **zero** warnings and `Fail_Count = 0`
with `Pass_Count ≥ 100`.

## Layout

| File | Role |
| --- | --- |
| `nearest_neighbor_search.ads` | Package spec |
| `nearest_neighbor_search.adb` | Package body |
| `nearest_neighbor_search.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## References

- Wikipedia: [Nearest neighbor search](https://en.wikipedia.org/wiki/Nearest_neighbor_search).
- Wikipedia: [k-d tree](https://en.wikipedia.org/wiki/K-d_tree).
- Wikipedia: [k-nearest neighbors algorithm](https://en.wikipedia.org/wiki/K-nearest_neighbors_algorithm).
- Friedman, J. H.; Bentley, J. L.; Finkel, R. A. *An Algorithm for Finding Best
  Matches in Logarithmic Expected Time*. ACM TOMS, 1977.
- Beis & Lowe BBF (approximate) — sibling
  [Ada-Best-Bin-First](https://github.com/RobertBoettcherSF/Ada-Best-Bin-First).

## Related packages

- **[Ada-Best-Bin-First](https://github.com/RobertBoettcherSF/Ada-Best-Bin-First)** —
  approximate NN via priority-bin k-d search ($E_{\max}$). Link only; not a
  dependency.
- Style siblings: `ada-nonlinear-optimization`, `ada-estimation-theory`
  (survey layout).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
