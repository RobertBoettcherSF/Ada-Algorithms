# Maximum Parsimony (Phylogenetics) — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Maximum parsimony (phylogenetics)](https://en.wikipedia.org/wiki/Maximum_parsimony_(phylogenetics))
optimality criterion: prefer the phylogenetic tree that requires the **fewest
character-state changes** (minimum homoplasy).  Tree length is scored with the
classic **Fitch (1971)** leaf-to-root set algorithm.  For at most `Max_Taxa`
taxa (here 6), `Exhaustive_Search` enumerates all rooted binary topologies and
returns a shortest tree.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Data** | Character matrix taxa $\times$ sites | Discrete unordered states $0..S-1$ |
| **Score** | Fitch (1971) set intersection/union | $+1$ when child sets are disjoint |
| **Length** | $L(T)=\sum_{\text{sites}} \ell(T,s)$ | Sum of per-site Fitch costs |
| **Search** | Exhaustive rooted binary topologies | $(2N-3)!!$ trees for $N$ labelled leaves |
| **Limit** | `Max_Taxa = 6` | $945$ rooted trees — instant |
| **Not here** | Sankoff / branch-and-bound / NNI–TBR | README note only |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Character_Matrix`, `Tree`, `Node_Record`, `Edge`, `Search_Result` | Domain model |
| Matrix | `Make_Matrix`, `Set_State`, `Get_State`, `Hamming_Distance` | Alignment I/O |
| Trees | `Leaf_Tree`, `Join`, `Triplet_Tree`, `Quartet_Tree`, `Balanced_Quartet` | Build topologies |
| Fitch | `Fitch_Score_Site`, `Fitch_Score_Tree` | Site / tree length |
| Search | `Exhaustive_Search`, `Most_Parsimonious` | Minimum-length tree |
| Helpers | `Near`, `Count_Rooted_Topologies`, `Is_Leaf`, `Node_Count` | Utilities |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Parsimony criterion

Given a matrix of discrete characters for $N$ taxa, maximum parsimony selects a
tree $T^{*}$ minimising the total number of state changes:

$$
T^{*} \in \arg\min_{T} L(T), \qquad
L(T) = \sum_{s=1}^{m} \ell(T,s).
$$

Equivalently, among trees compatible with the data, parsimony maximises the
amount of observed similarity explained as homology (shared derived states)
and minimises assumed **homoplasy** (convergence, parallelism, reversal).

## Fitch algorithm (1971)

For unordered characters with equal change costs, Fitch computes $\ell(T,s)$
on a **rooted** binary tree by a post-order pass.  Each node $v$ carries a
state set $A(v)$:

- **Leaf** $v$ with observed state $\sigma$: $A(v)=\{\sigma\}$.
- **Internal** node with children $u,w$:
  - if $A(u)\cap A(w)\neq\emptyset$, set $A(v)=A(u)\cap A(w)$ and add **cost** $0$;
  - otherwise set $A(v)=A(u)\cup A(w)$ and add **cost** $+1$.

$$
\ell(T,s)
  = \#\{\text{internal nodes with empty child intersection at site } s\}.
$$

For unordered equal-cost characters the length is independent of the chosen
root, so scoring a rooted representative of an unrooted topology is valid.
This package implements Fitch only (not the weighted **Sankoff** dynamic
program for ordered / stepmatrix characters).

### Tiny example

Taxa $\{1,2,3\}$, one site with states $(A,A,C)$.  On $((1,2),3)$ the cherry
shares $\{A\}$, the root intersects $\{A\}\cap\{C\}=\emptyset$, so
$\ell=1$.  Any rooted binary resolution has length $1$ for this site.

## Exhaustive search vs heuristics

The number of rooted binary labelled topologies is the double factorial

$$
(2N-3)!! = 1\cdot 3\cdot 5\cdots(2N-3)
$$

($N=2,3,4,5,6 \Rightarrow 1,3,15,105,945$).  Unrooted binary counts are
$(2N-5)!!$.  Exhaustive search is feasible only for tiny $N$ (here $\le 6$).
For larger $N$, practice uses **branch-and-bound** or heuristics such as
nearest-neighbour interchange (NNI), tree bisection–reconnection (TBR), and
the parsimony ratchet — not implemented in this educational package.

## Long-branch attraction

Maximum parsimony is **not statistically consistent** under all substitution
regimes.  Felsenstein (1978) showed that when two long branches are separated
by short ones, parallel changes can be misread as synapomorphies, so parsimony
may prefer the wrong tree with probability $\to 1$ as more sites are added
(**long-branch attraction**).  Model-based likelihood / Bayesian methods can
avoid that bias when the model is adequate; cladists reply that any misspecified
model is likewise inconsistent, and that “shortest among examined trees” remains
an empirical claim.

## Usage

```ada
with Maximum_Parsimony; use Maximum_Parsimony;

procedure Demo is
   M : Character_Matrix := Make_Matrix (4, 3, Fill => 0);
   R : Search_Result;
   T : Tree;
begin
   --  Informative sites supporting split 12 | 34
   for S in 1 .. 3 loop
      Set_State (M, 3, S, 1);
      Set_State (M, 4, S, 1);
   end loop;
   T := Balanced_Quartet (1, 2, 3, 4);
   --  Fitch_Score_Tree (T, M, S => 2) = 3
   R := Exhaustive_Search (M, S => 2);
   --  R.Best_Length = 3
end Demo;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pmaximum_parsimony.gpr`.  Main program is
`tests.adb` (no `main.adb`).

## Layout

| File | Role |
| --- | --- |
| `maximum_parsimony.ads` | Package spec |
| `maximum_parsimony.adb` | Package body |
| `maximum_parsimony.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- Fitch, W. M. *Toward defining the course of evolution: minimum change for a
  specified tree topology.* Systematic Zoology 20 (1971), 406–416.
- Farris, J. S. *Methods for computing Wagner trees.* Systematic Biology 19
  (1970), 83–92.
- Felsenstein, J. *Cases in which parsimony and compatibility methods will be
  positively misleading.* Systematic Zoology 27 (1978), 401–410.
- Wikipedia: [Maximum parsimony (phylogenetics)](https://en.wikipedia.org/wiki/Maximum_parsimony_(phylogenetics)).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series.  Use and adapt freely for learning and research.
