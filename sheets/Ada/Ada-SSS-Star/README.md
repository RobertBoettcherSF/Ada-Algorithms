# SSS* — Ada 2023

Educational, self-contained Ada 2023 package implementing **SSS\*** (Stockman,
1979): a **best-first state-space search** over **solution trees** of a finite
two-player zero-sum game tree. On every finite tree the search returns the
**same root minimax value** as pure minimax (and alpha–beta).

Based on [Wikipedia: SSS*](https://en.wikipedia.org/wiki/SSS*).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Minimax](https://github.com/RobertBoettcherSF/Ada-Minimax)** —
  alternate-moves minimax / maximin
- **[Ada-Alpha-Beta-Pruning](https://github.com/RobertBoettcherSF/Ada-Alpha-Beta-Pruning)** —
  depth-first windowed adversarial search

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Best-first solution-tree search | Same root value as minimax |
| **Core** | `Evaluate` — Stockman SSS\* OPEN list | LIVE / SOLVED descriptors |
| **Oracle** | `Minimax` | Recursive Max/Min baseline |
| **Tree** | Indexed `Game_Tree` | Children arrays + leaf values |
| **Build** | `Clear` / `Add_Leaf` / `Add_Internal` / `Set_Root` | Educational API |
| **Errors** | `Invalid_Argument` | Empty, malformed, capacity |

## Solution trees

Informally, a **solution tree** is obtained from a game tree by keeping
**one** child at every **MAX** node and **all** children at every **MIN**
node. It encodes a complete strategy for MAX: one action for every possible
sequence of replies by the opponent. SSS\* searches the space of *partial*
solution trees in best-first order and finishes with a solution tree whose
root value equals the minimax value of the original game.

$$
\mathrm{minimax}(n)=
\begin{cases}
\mathrm{leaf}(n) & n\text{ terminal},\\\\
\max_{c\in\mathrm{ch}(n)}\mathrm{minimax}(c) & n\text{ MAX},\\\\
\min_{c\in\mathrm{ch}(n)}\mathrm{minimax}(c) & n\text{ MIN}.
\end{cases}
$$

Classic shallow example:

$$
\max\bigl(\min(3,5),\min(2,9)\bigr)=3.
$$

## Stockman OPEN list

Descriptors $(J,s,h)$ live in a priority queue **OPEN**, ordered by
**descending** merit $h$; ties prefer the **left-most** node in the tree.

| Status | Meaning |
| --- | --- |
| **LIVE** | $J$ not yet expanded; $h$ is an **upper bound** on its true value |
| **SOLVED** | $h$ is the **true** minimax value of $J$ |

Seed OPEN with $(\mathrm{root},\mathrm{LIVE},+\infty)$. Pop the head
$p=(J,s,h)$; if $J$ is the root and $s=\mathrm{SOLVED}$, return $h$.
Otherwise apply the $\Gamma$ operator (Wikipedia / Chess Programming Wiki):

| Case | Action |
| --- | --- |
| LIVE + leaf | push $(J,\mathrm{SOLVED},\min(h,\mathrm{value}(J)))$ |
| LIVE + MIN | push first child as LIVE with the same $h$ |
| LIVE + MAX | push **every** child as LIVE with the same $h$ |
| SOLVED under MAX parent | **purge** OPEN entries in siblings’ subtrees; solve the parent with $h$ |
| SOLVED under MIN parent | next sibling LIVE with $h$, or solve the parent if last child |

SSS\* never expands a node that alpha–beta would prune, and may prune
additional branches. The OPEN list can grow large and must stay sorted —
historically the main practical obstacle. Plaat, Schaeffer, Pijls, and
de Bruin showed that a sequence of **null-window** alpha–beta calls with a
transposition table (**MT-SSS\***) expands the same nodes in the same order,
placing SSS\* in the **MTD** family (with **MTD(f)** the best-known relative).

This package implements the **classic educational OPEN-list** formulation
(parent-based $\Gamma$ (4)/(5)/(6), including solved leaves under MAX) and
checks every fixture against `Minimax`.

## Complexity (teaching bounds)

| Resource | Bound |
| --- | --- |
| Nodes per tree | $\textit{Max\_Nodes}=2000$ |
| Children per node | $\textit{Max\_Children}=16$ |
| OPEN | $O(\textit{Max\_Nodes})$ educational cap |
| `Minimax` | time linear in tree size |
| `Evaluate` | expands a (often smaller) solution-tree frontier; OPEN ops dominate |

## API

| Subprogram / type | Role |
| --- | --- |
| `Game_Tree` | Explicit indexed MAX/MIN/Leaf tree |
| `Node_Kind` | `Max_Node`, `Min_Node`, `Leaf` |
| `Clear` | Reset tree |
| `Add_Leaf (Value)` | Terminal with static score |
| `Add_Internal (Kind, Children)` | MAX/MIN with child indices |
| `Set_Root` | Designate search root |
| `Evaluate (G)` | SSS\* → minimax value |
| `Minimax (G)` | Pure minimax oracle |
| `Node_Count` / `Root_Of` / `Kind_Of` / … | Queries |
| `Invalid_Argument` | Malformed / empty / overflow |
| `Max_Nodes` / `Max_Children` | Educational caps |
| `Pos_Inf` / `Neg_Inf` | OPEN merit sentinels |

## Build / test

```bash
make
make test
# equivalent: gnatmake -gnatwa -gnat2022 -Psss_star.gpr && bin/tests
```

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
