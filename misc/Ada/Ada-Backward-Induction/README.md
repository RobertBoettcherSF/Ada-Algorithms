# Backward Induction in Ada 2023

## Project Overview

**Backward induction** solves a finite decision problem or extensive-form game
by reasoning from the **terminal** nodes back to the **root**: at each
decision point the moving agent chooses an action that maximises their
continuation value, taking later agents' optimal choices as given.

In game theory the same procedure yields a **subgame-perfect Nash
equilibrium (SPNE)** of a finite extensive-form game of **perfect
information**. For a two-player tree, if $V(n)\in\mathbb{R}^2$ denotes the
SPNE payoff vector of the subgame rooted at node $n$, then at a terminal
leaf $\ell$ one has $V(\ell)=u(\ell)$, and at a decision node $n$ owned by
player $i$ with children $n_1,\ldots,n_k$,

$$
V(n)=V(n_{j^\star}),
\qquad
j^\star\in\arg\max_{j\in\{1,\ldots,k\}} V(n_j)_i
$$

(with the lowest index $j$ on ties). The SPNE path is the unique walk that
follows each $j^\star$ from the root until a terminal is reached.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for **two-player** pure strategies on finite perfect-information
trees. It exposes `Value`, `Optimal_Action`, and `Solve` (equilibrium
payoffs plus the action path), plus classic constructors: **Ultimatum**,
**Entry deterrence / Stackelberg toy**, **Finite Centipede**,
**Subtraction / Nim heap**, **take-or-leave chains**, and small hand-built
binary trees.

Primary source:
[Wikipedia — Backward induction](https://en.wikipedia.org/wiki/Backward_induction).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with BNE and MCTS (README only)

| Concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Backward-Induction`) | Exact SPNE on finite PI trees | Pure strategies; no chance required |
| **Bayesian Nash Equilibrium** (sibling sheet) | Type-contingent NE under a common prior | Incomplete information; normal form |
| **MCTS / Minimax** (sibling sheets) | Search / approx. on large or zero-sum trees | Sampling or $\alpha$–$\beta$; not SPE membership |

README links only — **no** package `with` of siblings. Backward induction
assumes **perfect information** and a **finite** tree; Bayesian Nash
equilibrium encodes private types in the normal form; Monte Carlo tree
search approximates values by sampling when the tree is too large to expand
exhaustively.

## Classroom examples

### Ultimatum

Player 2 accepts or rejects a fixed offer from pot $P$. Money-maximising
backward induction accepts any offer $\ge 0$. With discrete offers
$k=0,\ldots,P$, the proposer offers $0$ and the responder accepts.

### Entry deterrence

Entrant chooses Out $\to(0,2)$ or In; incumbent then Fight $(-1,-1)$ or
Accommodate $(1,1)$. SPNE: In, Accommodate $\to(1,1)$. Fighting is an
incredible threat ruled out by subgame perfection.

### Stackelberg toy

Quantity leadership: leader High/Low, follower responds. Backward induction
gives the unique SPNE path and payoffs $(5,2)$ in the shipped payoff table.

### Finite Centipede

At each ply the mover may Take the current pot or Pass. Rational induction
unravels to **Take at the first node**, even though mutual Pass would grow
the pot — a classic tension with laboratory play.

### Subtraction / Nim heap

Players remove $1..m$ objects from a heap; the player facing $0$ loses.
Positions with heap size congruent to $0$ modulo $(m+1)$ are losing under
optimal play.

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pbackward_induction.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`backward_induction.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Game_Node`, `Node_Access`, `Node_Kind` | Terminal or Decision tree nodes |
| `Payoff_Vector`, `Player_Id` | Two-player Long_Float payoffs |
| `Make_Terminal`, `Make_Decision` | Heap constructors |
| `Is_Well_Formed`, `Node_Count`, `Depth` | Tree queries |
| `Value`, `Optimal_Action` | SPNE continuation / best child |
| `Solve`, `Equilibrium_Profile` | Path + payoff vector |
| `Equilibrium_Payoffs`, `Equilibrium_Path_Length`, `Action_On_Path` | Helpers |
| Classic constructors | Ultimatum, Entry, Stackelberg, Centipede, Subtraction, … |
| `Invalid_Argument` | Null / empty / malformed trees, bad sizes, negative tol |

Decision nodes maximise the moving player's own coordinate of $V$; ties break
toward the lowest child index. Chance moves and imperfect-information sets
are out of scope for this sheet.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not a general $N$-player imperfect-information solver or Perfect
Bayesian Equilibrium engine; for large trees prefer specialised game-theory
or search libraries outside this package.
