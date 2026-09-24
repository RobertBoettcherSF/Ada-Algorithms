# B* — Ada 2023

Educational, self-contained Ada 2023 package implementing **B\*** (Berliner,
1979): a **best-first proof search** over **interval-labelled** nodes of a
finite two-player zero-sum game tree. On every finite tree with exact leaf
scores the search returns the **same root minimax value** as pure minimax.

Based on [Wikipedia: B*](https://en.wikipedia.org/wiki/B*).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-SSS-Star](https://github.com/RobertBoettcherSF/Ada-SSS-Star)** —
  Stockman best-first solution-tree search
- **[Ada-Minimax](https://github.com/RobertBoettcherSF/Ada-Minimax)** —
  alternate-moves minimax / maximin
- **[Ada-Alpha-Beta-Pruning](https://github.com/RobertBoettcherSF/Ada-Alpha-Beta-Pruning)** —
  depth-first windowed adversarial search

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Best-first interval proof search | Same root value as minimax |
| **Core** | `Evaluate` — Berliner B\* bounds | prove-best / disprove-rest |
| **Oracle** | `Minimax` | Recursive Max/Min baseline |
| **Tree** | Indexed `Game_Tree` | Children arrays + leaf values |
| **Build** | `Clear` / `Add_Leaf` / `Add_Internal` / `Set_Root` | Educational API |
| **Errors** | `Invalid_Argument` | Empty, malformed, capacity |

## Interval evaluations

Every node stores an interval $[L,\,U]$ supposed to contain its true
game-theoretic value. Unevaluated leaves start as $[-\infty,\,+\infty]$;
expanding a leaf with static score $v$ sets $[v,\,v]$.

Backup for two-player zero-sum trees:

$$
\begin{aligned}
\text{MAX:}&\quad L=\max_i L(c_i),\quad U=\max_i U(c_i),\\\\
\text{MIN:}&\quad L=\min_i L(c_i),\quad U=\min_i U(c_i).
\end{aligned}
$$

(Different children may supply $L$ vs $U$.)

The pure minimax oracle on the same tree is

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

## Separation and expansion

**Separation** (best-move proof) at a MAX root occurs when some child $B$
satisfies $L(B)\ge U(C)$ for every other root child $C$ — a proof that $B$ is
at least as good as any alternative. This educational package continues until
the **root interval itself collapses** ($L=U$), which on finite trees with
correct leaf scores yields the exact minimax value.

B\* is best-first. At the root it applies one of two strategies:

| Strategy | Selection | Hope |
| --- | --- | --- |
| **prove-best** | most optimistic child (MAX: highest $U$; MIN: lowest $L$) | raise its pessimistic bound enough to separate |
| **disprove-rest** | runner-up optimistic child | worsen its optimistic bound below the leader’s $L$ |

Disprove-rest is pointless until the prove-best child’s pessimistic bound is
already the best among siblings (Wikipedia). Below the root, descend by
repeatedly choosing the most optimistic open child for the side to move until
a pending leaf is reached; assign $[v,\,v]$ and back up.

Historical engines add heuristic leaf intervals, transposition graphs, and
artificial cutoffs (time/memory). This package keeps exact leaf values so
`Evaluate` always matches `Minimax`.

## Complexity (teaching bounds)

| Resource | Bound |
| --- | --- |
| Nodes per tree | $\textit{Max\_Nodes}=2000$ |
| Children per node | $\textit{Max\_Children}=16$ |
| Bound store | $O(\textit{Max\_Nodes})$ |
| `Minimax` | time linear in tree size |
| `Evaluate` | expands pending leaves until root $[L,U]$ is a singleton |

## API

| Subprogram / type | Role |
| --- | --- |
| `Game_Tree` | Explicit indexed MAX/MIN/Leaf tree |
| `Node_Kind` | `Max_Node`, `Min_Node`, `Leaf` |
| `Clear` | Reset tree |
| `Add_Leaf (Value)` | Terminal with static score |
| `Add_Internal (Kind, Children)` | MAX/MIN with child indices |
| `Set_Root` | Designate search root |
| `Evaluate (G)` | B\* → minimax value |
| `Minimax (G)` | Pure minimax oracle |
| `Node_Count` / `Root_Of` / `Kind_Of` / … | Queries |
| `Invalid_Argument` | Malformed / empty / overflow |
| `Max_Nodes` / `Max_Children` | Educational caps |
| `Pos_Inf` / `Neg_Inf` | Interval sentinels |

## Build / test

```bash
make
make test
# equivalent: gnatmake -gnatwa -gnat2022 -Pb_star.gpr && bin/tests
```

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
