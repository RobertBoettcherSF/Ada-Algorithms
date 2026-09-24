# Cuthill–McKee / Reverse Cuthill–McKee — Ada 2023

Educational, self-contained Ada 2023 package for the **Cuthill–McKee (CM)**
and **Reverse Cuthill–McKee (RCM)** bandwidth-reducing orderings on an
undirected graph (adjacency of a sparse matrix with a **symmetric**
sparsity pattern). Explicit boolean adjacency ($n\le 32$).

Based on [Wikipedia: Cuthill–McKee algorithm](https://en.wikipedia.org/wiki/Cuthill%E2%80%93McKee_algorithm).
Related: [Graph bandwidth](https://en.wikipedia.org/wiki/Graph_bandwidth),
[Sparse matrix](https://en.wikipedia.org/wiki/Sparse_matrix),
[Minimum degree algorithm](https://en.wikipedia.org/wiki/Minimum_degree_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Minimum-Degree](https://github.com/RobertBoettcherSF/Ada-Minimum-Degree)** —
  classical fill-reducing ordering before Cholesky
- **[Ada-Sparse-Matrix](https://github.com/RobertBoettcherSF/Ada-Sparse-Matrix)** —
  sparse storage patterns (*forthcoming*)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: $n\le 32$ vertices, dense boolean adjacency, classical
CM/RCM with a simple George–Liu-style pseudo-peripheral start. Production
Sloan / nested-dissection / METIS-scale orderings are intentionally out of
scope.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Boolean adjacency `Graph` | Caps $n\le 32$ |
| **CM** | BFS level structure, neighbors by ↑ degree | From (pseudo-)peripheral start |
| **RCM** | Reverse the CM permutation | Often better envelope / fill |
| **Metrics** | `Bandwidth`, `Profile` | Before / after permutation |
| **Start** | `Pseudo_Peripheral_Vertex` | Farthest-from-farthest heuristic |
| **Builders** | Path / Cycle / Star / Clique / Band / Grid | Tiny textbooks |
| **Taxonomy** | `Method_Kind` | CM + RCM implemented |

## Bandwidth and the level structure

Interpret a symmetric sparsity pattern as an undirected graph $G=(V,E)$.
Under a labeling (permutation) $\pi:V\to\{1,\ldots,n\}$, the **bandwidth** is

$$
\beta(\pi)=\max_{\{u,v\}\in E}\,|\pi(u)-\pi(v)|.
$$

The **profile** (envelope) of the lower triangle under the same labeling is

$$
\mathrm{profile}(\pi)=\sum_{i=1}^{n}\bigl(i-\min\{j:a_{ij}\neq 0\text{ or }j=i\}\bigr)
$$

after rows/columns are reordered by $\pi$. Reducing $\beta$ and the profile
shrinks the dense band / envelope that a banded direct solver must store.

**Cuthill–McKee** builds a breadth-first **level structure**
$R_0,R_1,R_2,\ldots$ rooted at a peripheral (or pseudo-peripheral) vertex
$x$: $R_0=\{x\}$ and each $R_{i+1}$ is the set of unnumbered neighbors of
vertices in $R_i$. Vertices are numbered level by level; within the
adjacency list of each already-numbered vertex, **unnumbered neighbors are
appended in increasing degree order** (ties → lowest index). Equivalently,
while $|R|<n$, for the next vertex $R_i$ in the order one forms

$$
A_i=\operatorname{Adj}(R_i)\setminus R,
$$

sorts $A_i$ by ascending degree, and appends it to $R$.

**Reverse Cuthill–McKee** is the same permutation written backwards:

$$
\pi_{\mathrm{RCM}}(v)=n+1-\pi_{\mathrm{CM}}(v)
\quad\text{(as position arrays: reverse the CM order)}.
$$

Reversal does not change bandwidth, but typically improves the **profile**
and reduces fill when Gaussian elimination / Cholesky is applied to the
reordered matrix (George–Liu observation; MATLAB `symrcm`, SciPy
`reverse_cuthill_mckee`).

## Pseudo-peripheral start

A true peripheral vertex maximizes eccentricity. This package uses a short
George–Liu-style heuristic: start from a low-degree vertex, BFS to a
minimum-degree vertex in the last level, and iterate while eccentricity
grows (a few passes). That vertex seeds CM when `Start = 0` (default).

## Tiny examples

**Path $P_n$.** Already has $\beta=1$; CM/RCM keep bandwidth $1$.

**Scrambled path.** Same graph with a bad labeling can have large natural
$\beta$; CM restores $\beta=1$.

**Grid.** Row-major $r\times c$ labeling has vertical bandwidth $c$; RCM
typically shrinks $\beta$ toward a more mesh-friendly numbering.

**Band graph.** Edges $|i-j|\le w$ already have $\beta=w$; CM/RCM preserve it.

## API (`Cuthill_Mckee`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Vertices` ($=32$) | Educational bound |
| Types | `Graph`, `Order`, `Bool_Matrix`, `Vertex_Id` | Pattern + permutation |
| Build | `Empty_Graph`, `Clear`, `Add_Edge` | Construct graphs |
| Query | `Has_Edge`, `Degree`, `Edge_Count`, `Is_Symmetric_Pattern` | Inspect |
| Textbooks | `Path_Graph`, `Cycle_Graph`, `Star_Graph`, `Clique_Graph`, `Band_Graph`, `Grid_Graph` | Generators |
| Metrics | `Bandwidth`, `Profile` (natural + with `Order`) | Compare labelings |
| Order | `Natural_Order`, `Reverse_Natural_Order`, `Reverse_Order`, `Is_Valid_Order` | Permutations |
| CM/RCM | `Pseudo_Peripheral_Vertex`, `Cuthill_Mckee_Order`, `Reverse_Cuthill_Mckee_Order` | Main algorithms |
| Taxonomy | `Method_Kind`, `Method_Name`, `Implemented`, `Forthcoming` | Survey map |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

`Method_Kind` values: `Classical_CM`, `Classical_RCM`
(**Implemented**); `Sloan`, `Nested_Dissection` (**Forthcoming** in this
repo).

`Cuthill_Mckee_Order` / `Reverse_Cuthill_Mckee_Order` take optional
`Start : Natural := 0`. Zero selects the pseudo-peripheral heuristic;
a value in $1..n$ forces that root. Disconnected graphs restart per
component.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: Cuthill–McKee algorithm](https://en.wikipedia.org/wiki/Cuthill%E2%80%93McKee_algorithm)
- [Wikipedia: Graph bandwidth](https://en.wikipedia.org/wiki/Graph_bandwidth)
- [Wikipedia: Sparse matrix](https://en.wikipedia.org/wiki/Sparse_matrix)
- Cuthill, E.; McKee, J. (1969). “Reducing the bandwidth of sparse symmetric matrices.” *Proc. 24th Nat. Conf. ACM*
- George, A.; Liu, J. W. H. (1981). *Computer Solution of Large Sparse Positive Definite Systems.* Prentice-Hall
- Sibling: [Ada-Minimum-Degree](https://github.com/RobertBoettcherSF/Ada-Minimum-Degree)
- Sibling: [Ada-Sparse-Matrix](https://github.com/RobertBoettcherSF/Ada-Sparse-Matrix)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
