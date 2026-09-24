# Minimum Degree — Ada 2023

Educational, self-contained Ada 2023 package for the **classical minimum
degree** fill-reducing ordering on an undirected graph (adjacency of a
sparse symmetric positive-definite pattern) before **Cholesky**
factorization. Explicit boolean adjacency ($n\le 32$); no AMD/MMD
quotient-graph machinery — Approximate Minimum Degree is *Forthcoming*.

Based on [Wikipedia: Minimum degree algorithm](https://en.wikipedia.org/wiki/Minimum_degree_algorithm).
Related: [Cholesky decomposition](https://en.wikipedia.org/wiki/Cholesky_decomposition),
[Sparse matrix](https://en.wikipedia.org/wiki/Sparse_matrix),
[Cuthill–McKee algorithm](https://en.wikipedia.org/wiki/Cuthill%E2%80%93McKee_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Cuthill-McKee](https://github.com/RobertBoettcherSF/Ada-Cuthill-McKee)** —
  bandwidth-reducing RCM ordering (*forthcoming*)
- **[Ada-Sparse-Matrix](https://github.com/RobertBoettcherSF/Ada-Sparse-Matrix)** —
  sparse storage patterns (*forthcoming*)
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** —
  iterative SPD solver (incomplete Cholesky preconditioning context)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: $n\le 32$ vertices, dense boolean adjacency, classical
MD only (tie → lowest index). Production AMD/MMD/METIS-scale orderings
are intentionally out of scope.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Boolean adjacency `Graph` | Caps $n\le 32$ |
| **Ordering** | Classical minimum degree | Min current degree; tie = lowest id |
| **Fill** | `Fill_In_Count` / `Natural_Fill` / `MD_Fill` | Simulated elimination |
| **Cholesky** | `Symbolic_Cholesky_Nnz` | $n +$ filled undirected edges |
| **Builders** | Path / Cycle / Star / Clique / Band | Tiny textbooks |
| **Taxonomy** | `Method_Kind` | Only classical MD implemented |

## Fill reduction for Cholesky

Given a sparse SPD system $A x = b$, the Cholesky factor $L$ of $A$
typically has **fill-in** (more nonzeros than the lower triangle of $A$).
A permutation $P$ yields the reordered system

$$
(P^{T} A P)\,(P^{T} x) = P^{T} b,
$$

chosen so that the Cholesky factor of $P^{T} A P$ has far fewer nonzeros.
Finding a minimum-fill ordering is NP-complete; **minimum degree** is a
classical greedy heuristic (Tinney–Walker / Rose graph version of the
symmetric Markowitz idea).

Interpret $A$'s sparsity as an undirected graph $G=(V,E)$ with an edge
$\{i,j\}$ whenever $a_{ij}\neq 0$ ($i\neq j$). Eliminating a vertex $v$
**cliques** its remaining neighbors (adding any missing edges as fill)
and removes $v$. The **degree** used by MD is the current degree in this
evolving elimination graph.

## Classical minimum degree

While vertices remain:

1. Pick a remaining vertex $v$ of **minimum current degree** (ties →
   lowest index).
2. Append $v$ to the elimination order.
3. Add fill edges among the remaining neighbors of $v$.
4. Remove $v$ (and its incident edges) from the working graph.

This package simulates that process on an explicit adjacency matrix. It
does **not** implement multiple minimum degree (MMD) or approximate
minimum degree (AMD) quotient-graph compressions; those appear in the
taxonomy as *Forthcoming* (MATLAB’s historical `symmmd` / current
`symamd` lineage).

Complexity of naive classical MD on an explicit graph is fine for
$n\le 32$; AMD has a much better practical bound ($O(nm)$ vs a tight
$O(n^{2}m)$ style bound for MMD on large graphs).

## Tiny examples

**Path $P_n$.** Natural order and MD both produce **zero** fill (always
eliminate a degree-$1$ endpoint).

**Star (center $=1$).** Natural order eliminates the center first and
creates $\binom{n-1}{2}$ fill edges among the leaves. MD eliminates
leaves first → **zero** fill.

**Clique $K_n$.** Already dense → fill count $0$ for every order.

**Branched tree** (e.g. edges $1$—$2$, $2$—$3$, $2$—$4$). Natural order
can create a fill when eliminating the hub early; MD prefers leaves and
stays at zero fill.

## API (`Minimum_Degree`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Vertices` ($=32$) | Educational bound |
| Types | `Graph`, `Order`, `Bool_Matrix`, `Vertex_Id` | Pattern + permutation |
| Build | `Empty_Graph`, `Clear`, `Add_Edge` | Construct graphs |
| Query | `Has_Edge`, `Degree`, `Edge_Count`, `Is_Symmetric_Pattern` | Inspect |
| Textbooks | `Path_Graph`, `Cycle_Graph`, `Star_Graph`, `Clique_Graph`, `Band_Graph` | Generators |
| Order | `Natural_Order`, `Reverse_Natural_Order`, `Minimum_Degree_Order`, `Is_Valid_Order` | Permutations |
| Fill | `Fill_In_Count`, `Filled_Edge_Count`, `Natural_Fill`, `MD_Fill`, `Fill_Reduction` | Compare orders |
| Cholesky | `Symbolic_Cholesky_Nnz` | $n +$ filled $|E|$ |
| Taxonomy | `Method_Kind`, `Method_Name`, `Implemented`, `Forthcoming` | Survey map |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

`Method_Kind` values: `Classical_Minimum_Degree` (**Implemented**);
`Multiple_Minimum_Degree`, `Approximate_Minimum_Degree`,
`Nested_Dissection` (**Forthcoming** in this repo).

Symbolic Cholesky nonzero count used here:

$$
\mathrm{nnz}(L) = n + |E_{\mathrm{filled}}|,
$$

where $|E_{\mathrm{filled}}| = |E| + \mathrm{fill}$ for the undirected
filled graph after elimination (each undirected edge → one strict lower
entry of $L$, plus $n$ diagonal entries).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: Minimum degree algorithm](https://en.wikipedia.org/wiki/Minimum_degree_algorithm)
- [Wikipedia: Cholesky decomposition](https://en.wikipedia.org/wiki/Cholesky_decomposition)
- [Wikipedia: Cuthill–McKee algorithm](https://en.wikipedia.org/wiki/Cuthill%E2%80%93McKee_algorithm)
- George, A.; Liu, J. (1989). “The evolution of the minimum degree ordering algorithm.” *SIAM Review* 31 (1): 1–19
- Tinney, W. F.; Walker, J. W. (1967). “Direct solution of sparse network equations…” *Proc. IEEE* 55 (11): 1801–1809
- Rose, D. J. (1972). “A graph-theoretic study of the numerical solution of sparse positive definite systems…”
- Sibling: [Ada-Cuthill-McKee](https://github.com/RobertBoettcherSF/Ada-Cuthill-McKee)
- Sibling: [Ada-Sparse-Matrix](https://github.com/RobertBoettcherSF/Ada-Sparse-Matrix)
- Sibling: [Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
