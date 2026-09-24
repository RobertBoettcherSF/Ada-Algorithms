# Monte Carlo Tree Search in Ada 2023

## Project Overview

**Monte Carlo tree search (MCTS)** is a heuristic tree-search method for
decision processes — most famously board games — that grows a search tree by
**random sampling** (playouts) rather than exhaustive expansion. Each
iteration of the classic algorithm has four phases:

1. **Selection** — from the root, walk already-expanded nodes by an
   exploration–exploitation rule until a leaf (or a node with untried moves)
   is reached.
2. **Expansion** — add one (or more) child nodes for a previously untried
   legal move.
3. **Simulation (rollout)** — play randomly (a *light* playout) to a terminal
   position.
4. **Backpropagation** — update visit counts and cumulative rewards along the
   path from the new node back to the root.

The usual selection rule is **UCT** (*Upper Confidence Bound applied to
Trees*, Kocsis & Szepesvári, 2006). At a node with $N$ visits, child $a$ with
$n_a$ visits and mean reward $\bar X_a$ is scored

$$
a^\star=\arg\max_a \bar X_a + C\sqrt{\frac{\ln N}{n_a}}
$$

(with the convention that $n_a=0$ scores $+\infty$, so every child is tried
once before deeper exploitation). The constant $C$ balances exploration and
exploitation; the theoretical default is $C=\sqrt{2}$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for small **deterministic** games — **Tic-Tac-Toe** ($3\times 3$)
and **Nim / subtraction** — with a **seeded** linear-congruential PRNG so
tests are reproducible. Rewards are from the **side-to-move** perspective at
the search root: $+1$ win, $0$ draw, $-1$ loss.

Primary source:
[Wikipedia — Monte Carlo tree search](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Backward Induction (README only)

| Concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Monte-Carlo-Tree-Search`) | Approximate search by sampling | Asymmetric tree growth; no full evaluation function required |
| **Backward Induction** (sibling sheet) | Exact SPNE on finite perfect-information trees | Enumerates every node; exact payoffs |
| **Alpha–Beta / Minimax** (sibling sheets) | Exact (or depth-limited) adversarial value | Needs a leaf evaluator; prunes by window |

README links only — **no** package `with` of siblings. Backward induction
gives the exact subgame-perfect value when the tree is tiny enough to expand
fully; MCTS approximates the same idea by concentrating playouts on promising
branches when the tree is large.

Sibling repositories (links only):

- [Ada-Backward-Induction](https://github.com/RobertBoettcherSF/Ada-Backward-Induction)
- [Ada-Alpha-Beta-Pruning](https://github.com/RobertBoettcherSF/Ada-Alpha-Beta-Pruning)
- [Ada-Minimax](https://github.com/RobertBoettcherSF/Ada-Minimax)

## Classroom domains

### Tic-Tac-Toe

Empty cells are legal moves; $X$ starts. A completed line for the side to
move scores $+1$, for the opponent $-1$, and a full board with no line is a
draw ($0$). With a fixed seed and enough iterations, `Search_TTT` prefers an
immediate winning move when one exists and never returns an illegal cell.

### Nim / subtraction

From heap size $H$, a player removes $1..m$ objects; facing $H=0$ loses.
Under optimal play, positions with

$$
H \bmod (m+1)=0
$$

are losing. From a winning heap, MCTS learns (via rollouts) to leave a
losing residue for the opponent — e.g. $H=5$, $m=3$ → take $1$ (leave $4$).

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pmonte_carlo_tree_search.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`monte_carlo_tree_search.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `UCT_Score` / `Select_UCT_Child` | UCT formula and argmax helper |
| `Make_RNG` / `Random_Unit` / `Random_Index` | Seeded educational LCG |
| `Board`, `Legal_Moves_TTT`, `Apply_Move_TTT` | Tic-Tac-Toe state |
| `Nim_State`, `Legal_Moves_Nim`, `Apply_Move_Nim` | Subtraction heap |
| `Search_TTT` / `Search_Nim` | UCT-MCTS → best move + visit stats |
| `Pure_Monte_Carlo_TTT` / `_Nim` | Flat equal-budget rollouts per root move |
| `Rollout_TTT` / `Rollout_Nim` | Light random playouts |
| `Search_Result` | Best index/move, per-child visits & means |
| `Invalid_Argument` / `No_Legal_Move` | Bad params / terminal root |

## Licence

Educational reference code for the RobertBoettcherSF Ada 2023 series.
