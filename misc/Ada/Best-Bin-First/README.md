# Best Bin First (BBF) — Ada 2023

Educational, self-contained Ada 2023 package implementing
[Wikipedia: Best Bin First](https://en.wikipedia.org/wiki/Best_Bin_First)
approximate nearest-neighbor search (Beis & Lowe style) over a **k-d tree**
in $\mathbb{R}^d$.

**Best bin first** expands unexplored tree cells (*bins*) in increasing order
of **min distance from the query to the axis-aligned bin boundary**, using a
min-priority queue, and stops after examining at most $E_{\max}$ leaves
(approximate). With a large $E_{\max}$ the search is effectively exact on
small educational clouds.

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling note: see
**Ada-Nearest-Neighbor-Search** when that repository exists later (exact /
other ANN methods). Style sibling: `ada-bloom-filter`.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Educational limits: $d \le 8$, $n \le 256$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Index** | Median-split k-d tree | Axes cycle $1..d$; one point per leaf |
| **Bin** | Axis-aligned cell AABB | Stored on each node |
| **Priority** | Min-heap on $d^2(\mathrm{query},\mathrm{bin})$ | Dist to box boundary |
| **Stop** | At most $E_{\max}$ leaves | Approximate NN |
| **Exact** | Linear scan `Exact_NN` | Oracle for tests |
| **k-NN** | Same BBF, keep best $k$ | Small $k\le 8$ |

## Algorithm (Beis & Lowe / Wikipedia)

### k-d tree

Given points $x_1,\ldots,x_n \in \mathbb{R}^d$, build a binary tree by
repeatedly choosing axis $a = (depth \bmod d)+1$, partitioning the index
range about a median coordinate on axis $a$, and recursing on both sides.
Each node stores an axis-aligned bounding box (bin) for its subset.

### Distance to a bin

For query $q$ and box $[\ell,h]$, the squared distance to the bin is

$$
d^2(q,B)=\sum_{i=1}^{d}
\begin{cases}
(\ell_i-q_i)^2 & q_i<\ell_i \\
(q_i-h_i)^2 & q_i>h_i \\
0 & \text{otherwise.}
\end{cases}
$$

Inside the box the distance is $0$; outside it is the Euclidean distance to
the closest point on the boundary (Wikipedia: *minimal distance to any point
of its boundary*).

### Best-bin-first search

Maintain a min-priority queue of unexplored bins ordered by $d^2(q,B)$:

1. Push the root bin.
2. While the queue is nonempty and fewer than $E_{\max}$ leaves have been
   examined: pop the closest bin.
3. If it is a leaf, compare its point to the current best neighbor (update
   best / top-$k$).
4. If internal, push both children with their bin distances.

Bins are therefore visited **in increasing order of distance from the query
point**. Stopping after a fixed number of candidates yields a large typical
speedup in high dimension while still returning the true nearest neighbor for
a large fraction of queries (and a close neighbor otherwise).

Point–point distance used for candidates is squared Euclidean:

$$
\|u-v\|_2^2=\sum_{i=1}^{d}(u_i-v_i)^2.
$$

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Limits | `Max_Dim`, `Max_Points`, `Max_Nodes`, `Max_K`, `Max_PQ` | Capacities |
| Types | `Point`, `Point_Cloud`, `Config`, `NN_Result`, `KNN_Result`, `KD_Tree` | Domain |
| Cloud | `Make_Cloud`, `Add_Point`, `Make_Point`, `Cloud_Count`/`Dim` | Point set |
| Helpers | `Near`, `Near_Point`, `Distance2`, `Dist2_To_AABB` | Metrics |
| Build | `Build_Tree`, `Tree_Empty`/`Count`/`Dim`/`Root`, leaf accessors | k-d tree |
| Search | `Approximate_NN`, `Query_NN`, `Approximate_KNN`, `Exact_NN` | BBF / exact |
| Config | `Default_Config` | $E_{\max}$ etc. |
| PQ | `Bin_Heap`, `Heap_Push`/`Pop`/`Peek`, `Empty_Heap` | Bin priority |

Strong typing uses `Real` (digits 12) and capacity subtypes.
Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Empty_Cloud`.

## Usage

```ada
with Best_Bin_First; use Best_Bin_First;

declare
   Cloud : Point_Cloud := Make_Cloud (2);
   Tree  : KD_Tree;
   Q     : Point := P2;  -- your query
   R     : NN_Result;
   Cfg   : constant Config := Default_Config (E_Max => 32);
begin
   Add_Point (Cloud, Make_Point (2, (1.0, 2.0, others => 0.0)));
   -- ... more points ...
   Tree := Build_Tree (Cloud);
   R := Approximate_NN (Tree, Q, E_Max => 32);
   R := Query_NN (Tree, Q, Cfg);
   R := Exact_NN (Cloud, Q);  -- brute-force oracle
end;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pbest_bin_first.gpr`. Main program is
`tests.adb` (no `main.adb`).

## Layout

| File | Role |
| --- | --- |
| `best_bin_first.ads` | Package spec |
| `best_bin_first.adb` | Package body |
| `best_bin_first.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- Beis, J. S.; Lowe, D. G. *Shape Indexing Using Approximate Nearest-Neighbour
  Search in High-Dimensional Spaces*. CVPR 1997.
- Wikipedia: [Best Bin First](https://en.wikipedia.org/wiki/Best_Bin_First).
- Wikipedia: [k-d tree](https://en.wikipedia.org/wiki/K-d_tree).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
