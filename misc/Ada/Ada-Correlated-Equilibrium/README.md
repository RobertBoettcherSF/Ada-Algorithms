# Correlated Equilibrium in Ada 2023

## Project Overview

A **correlated equilibrium** (CE) is a solution concept in non-cooperative
game theory introduced by **Robert Aumann (1974)**. A mediator (or public
signal) draws an action profile from a joint distribution $\mu$ and
privately recommends to each player $i$ only their own component $a_i$.
The distribution $\mu$ is a correlated equilibrium when no player wants to
deviate from a recommended action, assuming the others obey their
recommendations.

For a finite strategic game $(N,\{A_i\},\{u_i\})$, the (direct) CE
incentive constraints are: for every player $i$, every recommended action
$a\in A_i$, and every alternate $a'\in A_i$,

$$
\sum_{a_{-i}}\mu(a,a_{-i})\,u_i(a,a_{-i})
\;\ge\;
\sum_{a_{-i}}\mu(a,a_{-i})\,u_i(a',a_{-i}).
$$

Equivalently, every strategy modification $\phi_i:A_i\to A_i$ yields weakly
lower expected payoff under $\mu$. The set of correlated equilibria is a
**convex polytope** defined by these linear inequalities together with
$\mu\ge 0$ and $\sum\mu=1$, so membership is a linear feasibility check;
finding *some* CE is cheaper than computing Nash equilibrium in general
games (Papadimitriou–Roughgarden).

**Every Nash equilibrium**, viewed as a **product distribution**
$\mu(a)=p_1(a_1)\cdots p_n(a_n)$, is a correlated equilibrium. The
converse is false: correlation can strictly expand the feasible payoff
set (classic Chicken / “traffic light” examples).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for **two-player bimatrix** games with action sets at most
$\mathrm{Max\_Actions}=5$. It checks CE membership of a candidate joint
$\mu$, builds product (Nash) distributions from mixed strategies, reports
expected payoffs and incentive-violation gaps, and ships classic
constructors (Prisoner's Dilemma, Chicken, Matching Pennies, Battle of
Sexes, Pure Coordination) plus hand-built Chicken CEs. Finding an
arbitrary CE **without a general LP** uses a known NE product, uniform
mass on pure NE profiles, a hand-built classic joint, or an optional
tiny $2\times 2$ probability-grid search.

Primary source:
[Wikipedia — Correlated equilibrium](https://en.wikipedia.org/wiki/Correlated_equilibrium).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Nash and Bayesian Nash (README only)

| Concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Correlated-Equilibrium`) | Joint recommendation $\mu$ with unilateral obedience incentives | Polytope / LP; strictly generalizes Nash products |
| **Nash equilibrium** (sibling sheet) | Independent mixed strategies, mutual best replies | Product $\mu$; every NE is a CE |
| **Bayesian Nash** (sibling sheet) | Incomplete-information NE of a Bayesian game | Types / beliefs; not the same object as Aumann CE |

README links only — **no** package `with` of siblings. Aumann CE is a
complete-information solution concept with an explicit correlating device.
Bayesian Nash concerns type-contingent strategies under a common prior on
types; one may *interpret* some CE constructions via beliefs, but this
package does not model type spaces.

## Classroom Chicken (Wikipedia)

Actions: Dare $=1$, Chicken-out $=2$. Payoffs:

$$
\begin{array}{c|cc}
 & D & C \\ \hline
D & 0,0 & 7,2 \\
C & 2,7 & 6,6
\end{array}
$$

Pure NE: $(D,C)$ and $(C,D)$. Mixed NE: each plays $C$ with probability
$2/3$. The **traffic-light CE** puts mass $1/3$ on $(C,C)$, $(D,C)$, and
$(C,D)$ (zero on $(D,D)$). Expected payoff $5$ for each player, above the
mixed-Nash value. A **better CE** uses $\mu(C,C)=1/2$ and
$\mu(D,C)=\mu(C,D)=1/4$, raising expected payoffs to $5.25$.

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pcorrelated_equilibrium.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`correlated_equilibrium.gpr` builds the standalone `tests` main into
`bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Max_Actions` | Cap ($5$) on each player's action count |
| `Game` | Bimatrix $(A,B)$ with discriminants `Rows`, `Cols` |
| `Distribution` | Joint $\mu$ over action pairs |
| `Mixed_Strategy` | Mixed strategy vector (1-based) |
| `Near`, `Default_Tol` | Numeric comparison |
| `Is_Probability_Distribution`, `Normalize`, `Total_Mass` | Joint validators |
| `Pure_Distribution`, `Uniform_Distribution`, `Product_Distribution` | Constructors |
| `Is_Product_Distribution`, `Row_Marginal`, `Col_Marginal` | Factorization helpers |
| `Expected_Payoff_Row` / `_Col` | $\mathbb{E}_\mu[u_i]$ |
| `Row_Incentive_Gap`, `Col_Incentive_Gap` | CE linear inequalities |
| `Max_Incentive_Violation`, `Is_Correlated_Equilibrium` | Membership |
| `Is_Best_Response_Row` / `_Col`, `Is_Nash_Product` | Nash product checks |
| `Uniform_Over_Pure_Profiles`, `Find_CE_Grid_2x2` | CE without general LP |
| Classic `Game` / `Distribution` constructors | PD, Chicken, MP, BoS, Coordination, traffic-light / better CE |
| `Invalid_Argument` | Bad sizes, non-probability data, negative tolerances |

Action indices are $1..\mathrm{Rows}$ (row player) and $1..\mathrm{Cols}$
(column player). Joints passed to `Is_Correlated_Equilibrium` must be
probability distributions within tolerance.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not a general $N$-player CE solver; for large games use an
external LP / regret-dynamics library outside this package.
