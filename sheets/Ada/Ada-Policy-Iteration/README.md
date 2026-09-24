# Policy Iteration in Ada 2023

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

**Policy iteration** (Howard 1960) finds an optimal policy by alternating
two steps until $\pi$ is unchanged:

1. **Policy evaluation.** Solve for the value $V^\pi$ of the current
   policy. Exactly, this is the linear system

$$
V^\pi(s)=\sum_{s'}P(s'\mid s,\pi(s))\bigl(R(s,\pi(s),s')+\gamma V^\pi(s')\bigr),
$$

   or in matrix form $(I-\gamma P^\pi)V^\pi=r^\pi$. This package solves that
   system by Gaussian elimination (Exact mode), or approximates it by
   synchronous backups of the Bellman policy operator $T^\pi$
   (Iterative mode).

2. **Policy improvement.** Replace $\pi$ by a greedy policy with respect
   to $Q^\pi$:

$$
\pi'(s)\in\arg\max_a Q^\pi(s,a),\qquad
Q^\pi(s,a)=\sum_{s'}P(s'\mid s,a)\bigl(R(s,a,s')+\gamma V^\pi(s')\bigr).
$$

Because a finite MDP has finitely many deterministic policies, and each
strict improvement raises $V$, exact evaluation terminates after a finite
number of outer rounds with $\pi^*=\pi'$ and $V^{\pi^*}=V^*$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for **finite** discounted MDPs with explicit $P$ and $R$
arrays. It exposes `Evaluate_Policy`, `Improve_Policy` / `Greedy_Policy`,
`Iterate` / `Solve` (policy $\pi^*$, value $V^{\pi^*}$, outer iteration
count), and `Q_Value`, plus classroom constructors: **Tiny_Chain**,
**Gridworld_3x3**, **Gambler_Toy**, and **Absorbing_Goal**.

Primary source:
[Wikipedia — Markov decision process (Policy iteration)](https://en.wikipedia.org/wiki/Markov_decision_process#Policy_iteration).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Value Iteration (README only)

| Concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Policy-Iteration`) | Alternate evaluation of $V^\pi$ with greedy improvement | Few outer rounds; each needs a linear solve or many $T^\pi$ sweeps |
| **Value Iteration** (sibling sheet) | Repeated $T^*$ backups; extract $\pi$ at the end | Many cheap sweeps; residual stopping |

README links only — **no** package `with` of the sibling. Both algorithms
converge to $V^*$ and an optimal greedy $\pi^*$. Value iteration folds the
$\max_a$ into every backup. Policy iteration holds $\pi$ fixed, solves
$V=T^\pi V$ (exactly or approximately), then sets
$\pi(s)\leftarrow\arg\max_a Q_V(s,a)$ until $\pi$ is unchanged. When the
action space is huge relative to $S$, policy iteration can need fewer
outer iterations; on typical classroom grids both match within tolerance.
Tests in this sheet reimplement a small independent value-iteration check
so optimality can be verified without depending on the Value Iteration
package.

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
make        # gnatmake -gnatwa -gnat2022 -Ppolicy_iteration.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`policy_iteration.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `MDP` | Finite $(S,A,P,R,\gamma)$; states / actions are $1..N$ |
| `Evaluation_Mode` | `Exact` (Gaussian elimination) or `Iterative` ($T^\pi$ sweeps) |
| `Solution` | $V^\pi$, $\pi$, outer iteration count, converged flag |
| `Near`, `Near_Values`, `Same_Policy` | Numeric / policy comparison |
| `Is_Valid_MDP`, `Is_Stochastic` | Dimension / $\gamma$ / row-stochastic checks |
| `Empty_MDP`, `Set_*`, `Make_MDP`, `Make_MDP_SA` | Explicit $P$, $R(s,a,s')$ or $R(s,a)$ builders |
| `Q_Value`, `Q_Values` | $Q(s,a)$ under a given $V$ |
| `Greedy_Action`, `Greedy_Policy`, `Improve_Policy` | $\arg\max_a Q$; lowest index on ties |
| `Policy_Backup`, `Policy_Operator`, `Policy_Residual` | $T^\pi$ and $\|V-T^\pi V\|_\infty$ |
| `Evaluate_Policy` | Exact linear solve or iterative $V^\pi$ |
| `Initial_Policy`, `Iterate`, `Solve`, `Solve_From` | Outer policy iteration |
| Classic constructors | Tiny_Chain, Gridworld_3x3, Gambler_Toy, Absorbing_Goal |
| `Invalid_Argument` | Bad dims, non-stochastic rows, $\gamma\notin[0,1)$, $\varepsilon<0$, singular Exact system |

Discount $\gamma=1$ is rejected (the linear system need not be a
contraction / invertible under every policy). Chance, continuous $S$, and
function approximation are out of scope.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not a production MDP solver or reinforcement-learning library; for
large or continuous problems prefer specialised DP / RL tooling outside
this package.
