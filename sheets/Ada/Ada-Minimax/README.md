# Minimax Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**minimax** decision rule for **two-player zero-sum games with alternate
moves**: a recursive game-tree search in which the maximizing player
chooses the move with the best guaranteed value against a minimizing
opponent. Optional **alpha–beta pruning** returns the same root value as
full minimax on the included fixtures.

Based on [Wikipedia: Minimax](https://en.wikipedia.org/wiki/Minimax)
(combinatorial game theory — *Minimax algorithm with alternate moves*).
Simultaneous-move maximin/minimax from classical game theory is stated
for context; this package implements the **alternate-moves** tree search
(tic-tac-toe style), not mixed-strategy matrix games.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Viterbi](../ada-viterbi/)**,
**[Ada-BFGS](../ada-bfgs/)** — DP decode and quasi-Newton search.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Alternate-move game tree | Max / Min plies |
| **Core** | `Minimax` / `Max_Value` / `Min_Value` | Depth-limited |
| **Pruning** | `Alpha_Beta` | Same results as full MM on TTT |
| **Policy** | `Best_Move` | Argmax / argmin at root |
| **Tree fixture** | Explicit `Tree_Node` leaves | Wikipedia-style numeric scores |
| **Game API** | Access-to-subprogram callbacks | `Game_Callbacks` |
| **Concrete game** | Tic-Tac-Toe $3\times 3$ | Leaves $+1/0/-1$ |
| **Helpers** | Encode/decode, `Winner`, moves | Educational board ops |

## Brief history

Minimax (also *maximin*) arose in **zero-sum game theory** as a worst-case
decision rule. In combinatorial games with **alternate moves** (tic-tac-toe,
chess, draughts), the same name denotes the recursive tree algorithm that
backs leaf utilities up to the root: the player to move maximizes (or
minimizes) the value returned by the opponent’s perfect replies. **Alpha–beta
pruning** (late 1950s–1960s) cuts branches that cannot affect the root
value, often with dramatic speedups and **identical** results.

## Maximin / minimax (simultaneous-move context)

For player $i$ with action $a_i$ and opponents’ actions $a_{-i}$, the
**maximin** value (best guaranteed gain without knowing others’ moves) is

$$
\underline{v_i}=\max_{a_i}\min_{a_{-i}} v_i(a_i,a_{-i}).
$$

The **minimax** value (worst case when others know $i$’s action) is

$$
\overline{v_i}=\min_{a_{-i}}\max_{a_i} v_i(a_i,a_{-i}),
$$

and always $\underline{v_i}\le\overline{v_i}$. In zero-sum matrix games the
equilibrium payoff sits between these bounds (von Neumann).

## Alternate-moves tree search (this package)

With perfect information and alternate turns, associate a scalar score with
each position from the **maximizing** player’s view (here: $+1$ win, $0$
draw, $-1$ loss for X on tic-tac-toe). Depth-limited pseudocode:

$$
\mathrm{minimax}(n,d,\mathrm{max})=
\begin{cases}
h(n) & d=0\text{ or terminal},\\\\
\max_{c\in\mathrm{ch}(n)}\mathrm{minimax}(c,d-1,\mathrm{false}) & \mathrm{max},\\\\
\min_{c\in\mathrm{ch}(n)}\mathrm{minimax}(c,d-1,\mathrm{true}) & \mathrm{min}.
\end{cases}
$$

Equivalently, `Max_Value` / `Min_Value` recurse into each other. A root call
with the side to move yields the **perfect-play** value; `Best_Move` picks a
child attaining that value.

### Alpha–beta pruning

Maintain a window $(\alpha,\beta)$ of still-viable scores for the maximizer
and minimizer. When a maximizer node finds a value $\ge\beta$, or a
minimizer finds a value $\le\alpha$, the remaining siblings are pruned.
On the included explicit trees and all tested tic-tac-toe positions,
`Alpha_Beta` / `Alpha_Beta_Tree` / `Alpha_Beta_Callback` match full
`Minimax` root values exactly (within `Near` tolerance).

## Tic-Tac-Toe fixture

- Board: $3\times 3$ cells `Empty` / `X` / `O`; **X** maximizes, **O**
  minimizes; X moves first on the empty board.
- Terminals: three-in-a-row (`Winner`) or full board (`Is_Full`); leaf
  scores $+1$ / $0$ / $-1$ via `Evaluate`.
- Perfect play from the empty board is a **draw** (value $0$). Positions
  with an immediate forced win evaluate to $+1$ or $-1$ accordingly.
- `Encode` / `Decode` map boards to base-$3$ codes in $0..3^9-1$.

## Explicit numeric tree fixture

Unit tests build small heap trees with known leaf scores, e.g.

$$
\max\bigl(\min(3,5),\min(2,9)\bigr)=3,
$$

and a three-child tree with value $4$, exercising `Minimax_Tree`,
`Alpha_Beta_Tree`, and `Best_Child_Index`.

## API (`Minimax`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real` / `Score`, `Side`, `Tree_Node`, `Board`, `Move`, `Mark`, `Game_Callbacks` | Domain |
| Helpers | `Near`, `Max_Score`, `Min_Score` | Numerics |
| Tree | `Leaf`, `Branch`, `Minimax_Tree`, `Max_Value_Tree`, `Min_Value_Tree`, `Alpha_Beta_Tree`, `Best_Child_Index` | Numeric fixture |
| TTT board | `Empty_Board`, `Encode` / `Decode`, `Winner`, `Is_Terminal`, `Evaluate`, `Legal_Moves`, `Apply_Move`, `Side_To_Move` | $3\times 3$ game |
| TTT search | `Minimax`, `Max_Value`, `Min_Value`, `Alpha_Beta`, `Best_Move` | Perfect play |
| Callbacks | `Minimax_Callback`, `Alpha_Beta_Callback` | Access-to-subprogram API |

Named exceptions: `Invalid_Argument`, `No_Legal_Move`.

Limits: educational depth / $3\times 3$ board only — not a chess engine.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Minimax](https://en.wikipedia.org/wiki/Minimax)
  (alternate-moves algorithm, alpha–beta note, maximin/minimax formulas)
- [Wikipedia: Alpha–beta pruning](https://en.wikipedia.org/wiki/Alpha–beta_pruning)
- Sibling packages in this series: Viterbi, BFGS
