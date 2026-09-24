# Value Iteration in Ada 2023

## Project Overview

A **Markov decision process (MDP)** is a 4-tuple $(S,A,P,R)$ for sequential
choice under uncertainty: from state $s\in S$ the agent picks an action
$a\in A$, the next state is drawn as $s'\sim P(\cdot\mid s,a)$, and an
immediate reward $R(s,a,s')$ (or the expected form $R(s,a)$) is received.
A (deterministic) policy $\pi:S\to A$ induces a Markov chain; the usual
objective is the expected discounted return

$$
\mathbb{E}_\pi\Bigl[\sum_{t=0}^{\infty}\gamma^{t}R(s_t,a_t,s_{t+1})\Bigr],
\qquad 0\le\gamma<1.
$$

**Value iteration** (Bellman 1957; also called backward induction on a
finite discounted MDP) computes the optimal state-value function $V^*$ by
repeated application of the **Bellman optimality operator** $T^*$:

$$
V_{k+1}(s)=\max_a\sum_{s'}P(s'\mid s,a)\bigl(R(s,a,s')+\gamma V_k(s')\bigr).
$$

Equivalently, $V_{k+1}(s)=\max_a Q_k(s,a)$ with

$$
Q(s,a)=\sum_{s'}P(s'\mid s,a)\bigl(R(s,a,s')+\gamma V(s')\bigr).
$$

The operator $T^*$ is a contraction of modulus $\gamma$ on
$(\mathbb{R}^{|S|},\|\cdot\|_\infty)$, so Banach's fixed-point theorem
gives $V_k\to V^*$ from any start. A **greedy** policy

$$
\pi^*(s)\in\arg\max_a Q^*(s,a)
$$

(lowest action index on ties in this package) is optimal. Iteration stops
when the max residual satisfies $\max_s|V_{k+1}(s)-V_k(s)|<\varepsilon$,
or after a fixed number of synchronous sweeps.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for **finite** discounted MDPs with explicit $P$ and $R$
arrays. It exposes `Iterate` / `Solve` (value function $V$, greedy $\pi$,
sweep count), `Q_Value`, `Greedy_Policy`, and `Bellman_Residual`, plus
classroom constructors: **Tiny_Chain**, **Gridworld_3x3**, **Gambler_Toy**,
and **Absorbing_Goal**.

Primary source:
[Wikipedia — Markov decision process (Value iteration)](https://en.wikipedia.org/wiki/Markov_decision_process#Value_iteration).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Policy Iteration (README only)

| Concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Value-Iteration`) | Repeated $T^*$ backups; extract $\pi$ at the end | Many cheap sweeps; residual stopping |
| **Policy Iteration** (sibling sheet) | Alternate policy *evaluation* ($T^\pi$) with *improvement* | Fewer outer rounds; each needs a linear solve / many eval sweeps |

README links only — **no** package `with` of the sibling. Both algorithms
converge to $V^*$ and an optimal greedy $\pi^*$. Value iteration folds the
$\max_a$ into every backup. Policy iteration holds $\pi$ fixed, solves
$V=T^\pi V$ (exactly or approximately), then sets
$\pi(s)\leftarrow\arg\max_a Q_V(s,a)$ until $\pi$ is unchanged. When the
action space is huge relative to $S$, policy iteration can need fewer
outer iterations; on typical classroom grids value iteration is simpler
and usually faster. This sheet ships a small `Evaluate_Policy` helper so
tests can check $V^\pi$ without depending on the Policy Iteration package.

## Classroom examples

### Tiny chain

States $1,\ldots,L$ on a line; actions Left / Right; $L$ is absorbing.
Reward $+1$ on the transition that first enters $L$. Exact optimum:
$V(L)=0$ and $V(k)=\gamma^{L-1-k}$ for $k<L$ (so $V(L-1)=1$). The greedy
policy is Right on every transient state.

### Absorbing goal

Two states. Stay loops on the start with reward $0$; Go moves to an
absorbing goal with reward $+1$. Then $V^*(2)=0$, $V^*(1)=1$,
$\pi^*(1)=\mathrm{Go}$. With a *living* reward of $+1$ on the goal,
$V^*(2)=1/(1-\gamma)$.

### $3\times 3$ gridworld

Row-major cells $1..9$, actions North / East / South / West, off-grid
moves bounce. Cell $9$ is an absorbing goal ($+1$ on entry); optional
cell $7$ is an absorbing pit ($-1$). Optional slip sends the agent to a
perpendicular neighbour. With no pit, no slip, and zero step cost,
values decay as $\gamma^{d-1}$ in Manhattan distance $d$ from the goal.

### Gambler's problem (toy)

Capital $0,\ldots,N$; a stake $a\in\{1,\ldots,\min(s,N-s)\}$ is won with
probability $p$ (heads) and lost otherwise. Reward $+1$ on first reaching
$N$; $0$ and $N$ absorb. For $p=1/2$ and $\gamma\to 1$,
$V(\mathrm{capital})\to\mathrm{capital}/N$ and every legal stake is
optimal (this package breaks ties toward the smallest stake).

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pvalue_iteration.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`value_iteration.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `MDP` | Finite $(S,A,P,R,\gamma)$; states / actions are $1..N$ |
| `Solution` | $V$, greedy $\pi$, sweep count, leftover residual |
| `Near`, `Near_Values`, `Default_Tol` | Numeric comparison |
| `Is_Valid_MDP`, `Is_Stochastic` | Dimension / $\gamma$ / row-stochastic checks |
| `Empty_MDP`, `Set_*`, `Make_MDP`, `Make_MDP_SA` | Explicit $P$, $R(s,a,s')$ or $R(s,a)$ builders |
| `Q_Value`, `Q_Values`, `Bellman_Backup` | $Q(s,a)$ and $(T^*V)(s)$ |
| `Bellman_Operator`, `Iterate` | Synchronous sweeps of $T^*$ |
| `Greedy_Action`, `Greedy_Policy` | $\arg\max_a Q$; lowest index on ties |
| `Bellman_Residual` | $\|V-T^*V\|_\infty$ |
| `Solve`, `Solve_From` | Value iteration from $0$ or a warm start |
| `Evaluate_Policy` | Iterative $V^\pi$ (not the PI sibling) |
| Classic constructors | Tiny_Chain, Gridworld_3x3, Gambler_Toy, Absorbing_Goal |
| `Invalid_Argument` | Bad dims, non-stochastic rows, $\gamma\notin[0,1)$, $\varepsilon<0$ |

Synchronous updates use the *old* $V$ for every state in a sweep, then
replace the vector. Discount $\gamma=1$ is rejected (the Banach argument
needs a contraction). Chance, continuous $S$, and function approximation
are out of scope.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not a production MDP solver or reinforcement-learning library; for
large or continuous problems prefer specialised DP / RL tooling outside
this package.
