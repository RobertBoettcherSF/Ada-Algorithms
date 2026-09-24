# Chinese Whispers Clustering — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Chinese whispers (clustering method)](https://en.wikipedia.org/wiki/Chinese_whispers_(clustering_method)):
**Chinese Whispers** graph clustering by Chris Biemann and Sven Teresniak
(2005; Biemann, *“Chinese Whispers — an Efficient Graph Clustering Algorithm
and its Applications to Natural Language Processing Problems,”* 2006).

Named after the children’s whispering game (**Telephone**): nodes “whisper”
class labels along edges until communities emerge. The method is a **hard
partitioning**, **randomized**, **flat** (non-hierarchical) clustering
algorithm on **undirected weighted or unweighted** graphs. It runs in
**linear time** in the number of edges and is widely used in **NLP**
(word-sense induction, multiword-expression detection, and related graph
tasks).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Graph** | Weighted adjacency lists | `Add_Undirected_Edge` |
| **Init** | One class per node | `Labels(N) := N` |
| **Sweep** | Random node order | LCG Fisher–Yates or fixed permutation |
| **Update** | Adopt max neighbor-class score | Sum of edge weights; ties random |
| **Stop** | `Max_Iters` or no changes | Optional early convergence |
| **Output** | Hard partition | Optional contiguous relabel |

## Algorithm

1. Assign each node a distinct class (label = node id).
2. Select nodes in random order; for each node, change its label to the class
   with which it has the most connections (sum of edge weights to neighbors
   sharing that label; unweighted ⇒ count). On ties, pick randomly among the
   tied labels.
3. Repeat step 2 for a fixed number of iterations or until labels are stable
   (no changes in a full sweep).

Randomness means runs can differ; a fixed **Seed** (LCG) or an explicit
**node permutation** makes results reproducible for tests.

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Nodes`, `Max_Degree`, `Max_Edges` | Fixed educational limits |
| Graph | `Empty_Graph`, `Add_Undirected_Edge`, `Degree`, `Edge_Weight` | Topology |
| Scores | `Init_Labels`, `Neighbor_Label_Score` | Class affinity |
| RNG | `Init_RNG`, `Next_Random`, `Shuffle_Nodes`, `Default_Order` | Determinism |
| Update | `Update_Node_Label` | One-node plurality step |
| Driver | `Run_Chinese_Whispers` (Seed or fixed `Order`) | Full algorithm |
| Post | `Cluster_Count`, `Relabel_Contiguous` | Partition summary |

Strong typing uses domain types (`Real` digits 12, `Weight`, `Node_Id`, …).
Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Usage

```ada
with Chinese_Whispers; use Chinese_Whispers;

declare
   G : Graph := Empty_Graph (6);
   P : Parameters :=
     (Max_Iters => 40, Seed => 1, Relabel_Clusters => True);
   R : Result (1, 6);
begin
   --  Two triangles
   Add_Undirected_Edge (G, 1, 2);
   Add_Undirected_Edge (G, 2, 3);
   Add_Undirected_Edge (G, 3, 1);
   Add_Undirected_Edge (G, 4, 5);
   Add_Undirected_Edge (G, 5, 6);
   Add_Undirected_Edge (G, 6, 4);
   R := Run_Chinese_Whispers (G, P);
   --  R.Labels, R.Cluster_Count, R.Converged, R.Iters
end;
```

Deterministic order (no reshuffle each sweep):

```ada
Order : constant Node_Array := [1, 2, 3, 4, 5, 6];
R := Run_Chinese_Whispers (G, Order, P);
```

## Building

```bash
make            # gnatmake -gnatwa -gnat2022 -Pchinese_whispers.gpr
make test       # build + run tests
make clean
```

Requires GNAT with Ada 2022 support. Root layout only (no `src/`). No
`main.adb` — `tests.adb` is the sole main.

## Testing

`tests.adb` uses a local `Check` helper (no `Ada.Assertions` for test logic)
and ends with `pragma Assert (Fail_Count = 0)`. Coverage includes empty /
singleton graphs, weighted bias, two disjoint cliques, tie-breaking with
fixed-seed reproducibility, convergence / `Max_Iters` stop, Wikipedia-style
plurality smoke, invalid edges, shuffle determinism, and contiguous relabel.

## Strengths and caveats

- **Linear time** — practical for large graphs; especially effective on
  small-world networks.
- **Non-deterministic** on small graphs — starting order and ties matter more;
  use Seed / fixed `Order` when reproducibility is required.
- Prefer other methods for tiny networks if stability across runs is critical.

## References

1. Chris Biemann, “Chinese Whispers — an Efficient Graph Clustering Algorithm
   and its Applications to Natural Language Processing Problems,” 2006.
2. Wikipedia:
   [Chinese whispers (clustering method)](https://en.wikipedia.org/wiki/Chinese_whispers_(clustering_method)).
3. Antonio Di Marco & Roberto Navigli, “Clustering and Diversifying Web Search
   Results with Graph-Based Word Sense Induction,” 2013.
4. Ioannis Korkontzelos & Suresh Manandhar, “Detecting Compositionality in
   Multi-Word Expressions,” 2009.

## License

Educational / reference implementation. Not affiliated with the original
authors. Part of the RobertBoettcherSF Ada algorithm series.
