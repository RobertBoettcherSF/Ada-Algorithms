# Alpha–Beta Pruning — Ada 2023

Educational, self-contained Ada 2023 package implementing **alpha–beta
pruning**: an adversarial search that returns the **same** root value and
move as **minimax** while discarding branches that cannot influence the
final decision. The package exposes explicit numeric game trees with
`Nodes_Visited` / `Cutoffs` counters, a minimax baseline for comparison,
and optional **Tic-Tac-Toe** $3\times 3$ perfect play.

Based on [Wikipedia: Alpha–beta pruning](https://en.wikipedia.org/wiki/Alpha–beta_pruning).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Minimax](https://github.com/RobertBoettcherSF/Ada-Minimax)** —
  alternate-moves minimax / maximin context, TTT fixture
- **[Ada-Branch-and-Bound](https://github.com/RobertBoettcherSF/Ada-Branch-and-Bound)** —
  tree search with optimistic bounds and pruning (knapsack)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Prune minimax branches | Same root decision |
| **Baseline** | `Minimax` | Counts every node |
| **Core** | `Alpha_Beta` ($\alpha$, $\beta$ window) | Cutoffs when $\beta\le\alpha$ |
| **Policy** | `Best_Move` / `Best_Move_*` | Argmax / argmin at root |
| **Tree fixture** | `Leaf` / `Branch` nodes | Children arrays + leaf scores |
| **Stats** | `Result.Nodes_Visited`, `Cutoffs` | Teaching / tests |
| **Concrete game** | Tic-Tac-Toe $3\times 3$ | Optional perfect play |

## Brief history

John McCarthy proposed alpha–beta ideas around the 1956 Dartmouth Workshop;
Allen Newell, Herbert Simon, Arthur Samuel, and others reinvented related
techniques. Alexander Brudno published independently (1963). Donald Knuth
and Ronald Moore refined the formulation (1975); Judea Pearl analyzed
optimality for random trees.

## Minimax reminder

With perfect information and alternate turns, associate a scalar score with
each position from the **maximizing** player’s view. Depth-unlimited
pseudocode on a finite tree:

$$
\mathrm{minimax}(n,\mathrm{max})=
\begin{cases}
\mathrm{leaf}(n) & n\text{ terminal},\\\\
\max_{c\in\mathrm{ch}(n)}\mathrm{minimax}(c,\mathrm{false}) & \mathrm{max},\\\\
\min_{c\in\mathrm{ch}(n)}\mathrm{minimax}(c,\mathrm{true}) & \mathrm{min}.
\end{cases}
$$

Example (Wikipedia-style shallow tree):

$$
\max\bigl(\min(3,5),\min(2,9)\bigr)=3.
$$

## Alpha–beta windows

Maintain a window $(\alpha,\beta)$:

- $\alpha$ — best already guaranteed score for the **maximizer**
- $\beta$ — best already guaranteed score for the **minimizer**

Initially $\alpha=-\infty$, $\beta=+\infty$. After exploring a child at a
max node, raise $\alpha$; at a min node, lower $\beta$. Whenever
$\beta\le\alpha$, remaining siblings are **pruned** (a cutoff): they cannot
change the root decision.

$$
\begin{aligned}
&\textbf{max-value}(n,\alpha,\beta):\\
&\quad v \leftarrow -\infty\\
&\quad \textbf{for } c \in \mathrm{ch}(n):\\
&\quad\quad v \leftarrow \max(v,\textbf{min-value}(c,\alpha,\beta))\\
&\quad\quad \alpha \leftarrow \max(\alpha,v)\\
&\quad\quad \textbf{if } \beta \le \alpha:\ \textbf{break}\\
&\quad \textbf{return } v
\end{aligned}
$$

(and symmetrically for min-value). On every finite tree in this package,
`Alpha_Beta` matches `Minimax` root `Value` (within `Near`); on **ordered**
trees it reports strictly fewer `Nodes_Visited` and `Cutoffs > 0`.

### Complexity intuition

With branching factor $b$ and depth $d$, naive minimax examines
$\Theta(b^{d})$ leaves. With optimal move ordering, alpha–beta examines about
$O(b^{d/2})$ leaves — roughly twice the searchable depth for the same work.
Pessimal ordering yields little or no pruning ($O(b^{d})$ again).

## Explicit numeric tree fixture

Build heap trees with `Leaf (V)` and `Branch ([...])`. A crafted pruning
demo: left min child of the max root establishes $\alpha=5$ via leaves
$10,5$; the right min sees leaf $3\le\alpha$ and cuts siblings $99,100$.
Full minimax still visits those siblings; alpha–beta does not — same root
value $5$, fewer nodes, `Cutoffs >= 1`.

## Tic-Tac-Toe fixture

- Board: $3\times 3$ cells `Empty` / `X` / `O`; **X** maximizes ($+1$),
  **O** minimizes ($-1$); X moves first.
- Terminals: three-in-a-row or full board; `Evaluate` returns $+1/0/-1$.
- Perfect play from the empty board is a **draw** (value $0$).
- `Minimax_TTT` / `Alpha_Beta_TTT` return `Result` with node / cutoff stats;
  alpha–beta typically visits far fewer nodes from the empty board.

## API (`Alpha_Beta_Pruning`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Score`, `Node` / `Tree` / `Tree_Node`, `Result`, `Child_List` | Domain |
| Helpers | `Near`, `Max_Score`, `Min_Score` | Numerics |
| Tree | `Leaf`, `Branch` | Constructors |
| Search | `Minimax`, `Alpha_Beta` | Value + `Best_Child` + counters |
| Moves | `Best_Move_Minimax`, `Best_Move_Alpha_Beta`, `Best_Move` | Root policy |
| TTT | `Board`, `Move`, `Legal_Moves`, `Apply_Move`, `Evaluate`, … | $3\times 3$ |
| TTT search | `Minimax_TTT`, `Alpha_Beta_TTT`, `Best_Move_TTT` | Perfect play + stats |

`Result` fields: `Value`, `Best_Child` (1-based, or $0$ on a leaf),
`Nodes_Visited`, `Cutoffs`.

Named exceptions: `Invalid_Argument`, `No_Legal_Move`.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Palpha_beta_pruning.gpr
make test   # run bin/tests — expect ALL PASSED, Pass_Count ≥ 80
make clean
```

Root layout (exactly seven tracked source/project files; **no** `main.adb`):

`.gitignore`, `Makefile`, `README.md`, `alpha_beta_pruning.ads`,
`alpha_beta_pruning.adb`, `alpha_beta_pruning.gpr`, `tests.adb`.

## Caveats

- Educational trees and $3\times 3$ only — not a chess engine.
- Heap nodes from `Leaf` / `Branch` are not automatically freed.
- Pruning amount depends heavily on **child order**; bad order may visit
  as many nodes as minimax while still returning the same value.
- Depth-$0$ stubs on non-terminal TTT boards return $0$ (no heuristic
  evaluation beyond terminals).
- Floating `Score` comparisons in tests use `Near`; search uses plain
  $\le$ / $\ge$ on the $\alpha$/$\beta$ window.

## References

- [Wikipedia: Alpha–beta pruning](https://en.wikipedia.org/wiki/Alpha–beta_pruning)
- [Wikipedia: Minimax](https://en.wikipedia.org/wiki/Minimax)
- Knuth, D. E.; Moore, R. W. (1975). *An analysis of alpha–beta pruning*.
- Sibling packages: Ada-Minimax, Ada-Branch-and-Bound
