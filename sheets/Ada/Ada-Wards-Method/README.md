# Ward's Method — Ada 2023 (Minimum Variance Hierarchical Clustering)

Educational, self-contained Ada 2023 package for
[Wikipedia: Ward's method](https://en.wikipedia.org/wiki/Ward%27s_method):
**Ward's minimum variance** agglomerative hierarchical clustering
(Joe H. Ward, Jr., 1963). At each step the algorithm merges the pair of
clusters that minimizes the increase in total within-cluster
**error sum of squares** (ESS / SSE). Initial singleton distances are
**squared Euclidean**; pairwise distances are maintained by the
**Lance–Williams** recursion with Ward coefficients.

Ward suggested a general agglomerative procedure where the merge criterion
optimizes an objective function; the celebrated special case that minimizes
within-cluster variance is known as *Ward's method* or *Ward's minimum
variance method*.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Initial distance** | $d_{ij}=\|X_i-X_j\|^2$ | Squared Euclidean on singletons |
| **Merge cost** | $\Delta=\frac{n_i n_j}{n_i+n_j}\,\|\mu_i-\mu_j\|^2$ | ESS increase |
| **Update** | Lance–Williams Ward $\alpha_i,\alpha_j,\beta,\gamma=0$ | $d=2\Delta$ under this init |
| **Dendrogram** | $N-1$ merges `(Left, Right, Height=`$\Delta$`)` | Leaves `1..N`; merge $m \to$ id $N+m$ |
| **Cut** | First $N-K$ merges $\to K$ labels | Compact labels `1..K` |
| **Complexity** | Naive $O(n^3)$ | Educational; $n \le 64$ |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Point`, `Dataset` | Fixed educational limits |
| Helpers | `Near`, `Squared_Euclidean`, `Centroid` | Geometry |
| Criterion | `Ward_Delta`, `Ward_Delta_From_Dist` | ESS increase $\Delta$ |
| Recursion | `Lance_Williams_Ward` | Distance update after a merge |
| Clustering | `Ward_Linkage`, `Cut_Dendrogram` | Full tree + flat partition |
| Quality | `Within_Cluster_SSE` | Total within-cluster SSE |

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Post` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Formula summary

### Initial distances and merge cost

$$
d_{ij}=d(\{X_i\},\{X_j\})=\|X_i-X_j\|^2,
\qquad
\Delta(i,j)=\frac{n_i n_j}{n_i+n_j}\,\|\mu_i-\mu_j\|^2.
$$

For two singletons, $\Delta=\tfrac12\|X_i-X_j\|^2$. With squared-Euclidean
initialization, the Lance–Williams quantity satisfies $d_{ij}=2\Delta(i,j)$.

### Lance–Williams (Ward)

After merging clusters $i$ and $j$ into $(ij)$, for any other cluster $k$:

$$
\begin{aligned}
\alpha_i&=\frac{n_i+n_k}{n_i+n_j+n_k},\quad
\alpha_j=\frac{n_j+n_k}{n_i+n_j+n_k},\\
\beta&=-\frac{n_k}{n_i+n_j+n_k},\quad
\gamma=0,\\
d_{(ij)k}&=\alpha_i\,d_{ik}+\alpha_j\,d_{jk}+\beta\,d_{ij}.
\end{aligned}
$$

### Cutting the dendrogram

A full tree has $N-1$ merges. Partitioning into $K$ clusters applies the
first $N-K$ merges (equivalently: stops $K-1$ merges before the root).

## Usage

```ada
with Wards_Method; use Wards_Method;

procedure Demo is
   Data : constant Dataset :=
     [[0.0, 0.0],
      [0.1, 0.0],
      [5.0, 5.0],
      [5.1, 5.0]];
   Tree : constant Dendrogram := Ward_Linkage (Data);
   Lab  : constant Labels := Cut_Dendrogram (Tree, N => 4, K => 2);
   SSE  : constant Real := Within_Cluster_SSE (Data, Lab);
begin
   null;  -- Lab(1)=Lab(2), Lab(3)=Lab(4), distinct across blobs
end Demo;
```

Tie-breaking is deterministic: among equally cheap pairs, the algorithm
selects the lowest left index, then the lowest right index.

## Building

```bash
cd /workspace/ada-wards-method
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pwards_method.gpr`. Expect **zero**
errors and **zero** warnings.

## Testing

```bash
make test
```

`tests.adb` is the main program (≥13 sections, 90+ assertions). Success
requires `Fail_Count = 0` (`pragma Assert`).

## Layout

Root-only sources (no `src/`, no separate `main.adb`):

- `wards_method.ads` / `wards_method.adb` — package
- `wards_method.gpr` — GNAT project
- `tests.adb` — test main
- `Makefile`, `README.md`, `.gitignore`

## Related notes (not dependencies)

Other classical agglomerative schemes also fit the Lance–Williams family:

| Method | Idea | Contrast with Ward |
| --- | --- | --- |
| **Single linkage** | $\min$ inter-point distance | Chaining; not variance |
| **Complete linkage** | $\max$ inter-point distance | Compact clusters; different objective |
| **UPGMA / average** | Average pairwise distance | No ESS guarantee |

Ward uniquely targets **minimum increase in within-cluster variance**. The
nearest-neighbor chain algorithm can compute the same clustering faster; this
package keeps the transparent $O(n^3)$ loop for clarity.

## References

- Ward, J. H., Jr. (1963), "Hierarchical Grouping to Optimize an Objective
  Function", *Journal of the American Statistical Association*, 58, 236–244.
- Wikipedia: [Ward's method](https://en.wikipedia.org/wiki/Ward%27s_method)
- Lance, G. N. & Williams, W. T. (1967), "A general theory of classificatory
  sorting strategies", *Computer Journal*.
- Murtagh, F. & Legendre, P. (2014), "Ward's Hierarchical Agglomerative
  Clustering Method: Which Algorithms Implement Ward's Criterion?"
