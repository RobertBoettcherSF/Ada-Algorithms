# Bayesian Nash Equilibrium in Ada 2023

## Project Overview

A **Bayesian game** models strategic interaction under **incomplete
information**: each player $i$ has a private **type** $t_i$ drawn from a
**common prior** $p$ over type profiles. Harsanyi (1967–68) showed that such
games can be analysed as ordinary games on an expanded strategy space in which
a strategy for $i$ assigns an action (possibly mixed) to **each** of $i$'s
types. A **Bayesian Nash equilibrium (BNE)** is a Nash equilibrium of that
game: every type maximises interim expected payoff given Bayes beliefs about
others' types and others' type-contingent strategies.

Formally, for finite type and action sets, a strategy profile
$\sigma=(\sigma_1,\ldots,\sigma_N)$ is a BNE when for every player $i$ and
every type $t_i$ with positive marginal prior mass,

$$
\sigma_i(\cdot\mid t_i)
\;\in\;
\arg\max_{\alpha_i}
\;
\mathbb{E}\bigl[u_i(\alpha_i,\sigma_{-i})\mid t_i\bigr],
$$

where the expectation uses the conditional belief
$p(t_{-i}\mid t_i)=p(t_i,t_{-i})/p(t_i)$ and the opponents' strategies
$\sigma_{-i}$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for **two-player** Bayesian games with at most
$\mathrm{Max\_Types}=3$ types and $\mathrm{Max\_Actions}=3$ actions per
player. It checks membership of a candidate strategy profile, computes interim
expected payoffs and best-reply values, derives conditional beliefs from the
common prior, and ships classic constructors (Sheriff's dilemma, entry
deterrence, a Vickrey auction toy, battle with private information) plus
**degenerate** single-type games that reduce to ordinary Nash equilibrium of
the complete-information bimatrix game.

Primary source:
[Wikipedia — Bayesian game (Bayesian Nash Equilibrium)](https://en.wikipedia.org/wiki/Bayesian_game#Bayesian_Nash_Equilibrium).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Correlated Equilibrium and Backward Induction (README only)

| Concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Bayesian-Nash-Equilibrium`) | Type-contingent NE under a common prior | Incomplete information; interim BR per type |
| **Correlated Equilibrium** (sibling sheet) | Joint recommendation $\mu$ with obedience incentives | Complete-info polytope; not the same as BNE |
| **Backward Induction** (sibling sheet) | SPE / sequential rationality on trees | Extensive form; Perfect Bayesian Equilibrium refines BNE off path |

README links only — **no** package `with` of siblings. Aumann CE assumes
complete payoff information plus a correlating device. BNE encodes private
information via types. In dynamic games of incomplete information, Perfect
Bayesian equilibrium strengthens BNE by requiring Bayes-consistent beliefs and
sequential rationality at every information set.

## Classroom examples

### Sheriff's dilemma

Suspect (player 1) has types Criminal / Civilian; Sheriff (player 2) has one
type. Actions: Shoot / Not. With classroom payoffs matching the Wikipedia
threshold analysis, Criminal strictly prefers Shoot, Civilian strictly prefers
Not, and the Sheriff shoots in a pure BNE if and only if
$p(\mathrm{Criminal})>1/3$ (mixes at equality).

### Entry game

Entrant vs incumbent types Tough / Weak. Tough fights, Weak accommodates; the
entrant stays out when $p(\mathrm{Tough})\ge 1/2$ and enters when
$p(\mathrm{Tough})<1/2$.

### Auction toy (second-price)

Independent Low / High values $\{1,2\}$, bids $\{1,2\}$, Vickrey payment rule.
Truthful bidding (bid own value) is a pure BNE.

### Degenerate complete information

Single type each recovers ordinary Nash: Matching Pennies mixed $(1/2,1/2)$,
Prisoner's Dilemma (Defect, Defect), Chicken pure and mixed equilibria.

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pbayesian_nash_equilibrium.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`bayesian_nash_equilibrium.gpr` builds the standalone `tests` main into
`bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Max_Types`, `Max_Actions` | Caps ($3$) on type / action counts |
| `Bayesian_Game` | $(T_1,T_2,A_1,A_2)$ with tensors $U_1,U_2$ and prior $p$ |
| `Strategy_Profile` | Type-contingent mixes $S_1,S_2$ |
| `Near`, `Default_Tol` | Numeric comparison |
| `Is_Valid_Prior`, `Normalize_Prior`, `Prior_Mass` | Common-prior helpers |
| `Type_Marginal_1` / `_2`, `Belief_1_About_2` / `Belief_2_About_1` | Bayes beliefs |
| `Is_Mixed_Action`, `Pure_Mixed_Action`, `Uniform_Mixed_Action` | Action mixtures |
| `Pure_Strategy_Profile`, `Pure_Actions_Profile`, `Extract_Mixed_*` | Profile builders |
| `Expected_Payoff_Pure_*`, `Expected_Payoff_*`, `Best_Pure_Payoff_*` | Interim EU |
| `Is_Best_Response_For_Type_*`, `Is_Bayesian_Nash` | Membership |
| Classic `Bayesian_Game` / `Strategy_Profile` constructors | Sheriff, Entry, Auction, Battle, MP, PD, Chicken |
| `Invalid_Argument` | Bad sizes, probabilities, indices, negative tolerances |

Payoff tensors are indexed by $(t_1,a_1,t_2,a_2)$. Types with zero marginal
prior mass impose **vacuous** best-response constraints.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not a general $N$-player BNE solver or Perfect Bayesian Equilibrium
engine; for large type spaces use specialised game-theory libraries outside
this package.
