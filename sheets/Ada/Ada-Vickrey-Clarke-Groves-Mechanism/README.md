# Vickrey–Clarke–Groves Mechanism in Ada 2023

## Project Overview

The **Vickrey–Clarke–Groves (VCG)** mechanism is a generic **dominant-strategy
incentive compatible** social-choice rule for agents with **quasilinear**
utilities $u_i = v_i(o) - p_i$. Agents report valuation functions
$v_i : X \to \mathbb{R}$ over a finite outcome set $X$. The mechanism selects
an outcome that maximises **reported social welfare**

$$
o^{*} = \arg\max_{o \in X} \sum_{i} v_{i}(o)
$$

(lowest outcome index on ties) and charges each agent $i$ the **Clarke pivot**
payment — $i$'s **externality** on the others:

$$
p_{i} = h_{i}(v_{-i}) - \sum_{j \neq i} v_{j}(o^{*}),
\qquad
h_{i}(v_{-i}) = \sum_{j \neq i} v_{j}(o^{*}_{-i}),
$$

where $o^{*}_{-i}$ maximises $\sum_{j \neq i} v_{j}$ (the efficient outcome
when $i$ is absent). Equivalently, $u_i = \sum_j v_j(o^{*}) - h_i(v_{-i})$, so
$i$'s incentives line up with utilitarian welfare; the $h_i$ term does not
depend on $i$'s report and therefore does not affect strategy.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation for classroom-sized instances: at most
$\mathrm{Max\_Agents}=12$ agents and $\mathrm{Max\_Outcomes}=24$ outcomes.
It exposes the generic VCG pipeline (`Efficient_Outcome`, `Social_Welfare`,
`Clarke_Payment` / `VCG_Payments`, `Run`), optional **outcome costs**
$c(o)$ (so the maximand is $\sum_i v_i(o) - c(o)$), a **weighted** (Roberts
affine-maximiser) variant, and three specialisations:

- **Vickrey auction** — single-item second-price sealed bid (VCG on
  “give the item to $k$”);
- **public project / binary choice** — build iff $\sum_i \theta_i > C$,
  Clarke tax only on pivotal citizens;
- **tiny two-item combinatorial allocation** — items $A,B$ assigned to
  agents or left unsold.

Primary source:
[Wikipedia — Vickrey–Clarke–Groves mechanism](https://en.wikipedia.org/wiki/Vickrey%E2%80%93Clarke%E2%80%93Groves_mechanism).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Combinatorial Auction and Top Trading Cycle (README only)

| Concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Vickrey-Clarke-Groves-Mechanism`) | Utilitarian social choice + Clarke money | DSIC for quasilinear $v_i$; needs exact welfare max |
| **Combinatorial auction** (sibling sheet) | Domain: bundle allocation of many items | VCG is *one* payment rule on that domain (when winner determination is solved exactly). Practical CAs often use other prices (core-selecting, etc.) because VCG revenue can be low and the rule is vulnerable to collusion / shill bids |
| **Top Trading Cycle (TTC)** (sibling sheet) | Housing-market matching **without money** | Strategy-proof via the core of Shapley–Scarf; ordinal preferences over discrete objects, no transfers |

README links only — **no** package `with` of siblings. A combinatorial
auction is an *allocation problem*; VCG is a *payment identity* that can sit
on top of any finite $X$ (auctions included) once the welfare maximiser is
known. TTC does not use money: it cycles pointed-to houses until everyone
is assigned. The two-item constructor in this package is a toy VCG
combinatorial *allocation*, not a general CA solver and not TTC.

## Classroom examples

### Single-item Vickrey

Bids $(10, 7, 3)$. Outcomes: give the item to agent $1,2,3$. Welfare is
the winner's bid, so $o^{*}$ awards the item to agent $1$. Clarke:
without $1$ the item goes to agent $2$ at welfare $7$, and the others
get $0$ at $o^{*}$, hence $p_1 = 7$ and losers pay $0$. This is the
sealed **second-price** auction. A reserve $R$ is modelled as a seller
who values “unsold” at $R$; the winner then pays
$\max(\text{second bid}, R)$.

### Public project

Cost $C = 10$, reports $(6, 5, 4)$. Net welfare of Yes is $15 - 10 = 5 > 0$,
so the project is built. Citizen $1$ is pivotal (without $1$ the others
sum to $9 < 10$) and pays tax $C - 9 = 1$; citizens $2$ and $3$ pay $0$.
Collected tax $1 < C$: VCG is typically **not budget-balanced**.

### Two-item split

Agent $1$ values $A$ at $10$ and $B$ at $1$; agent $2$ the reverse.
Efficient assignment is the split (welfare $20$). Each pays the
externality $1$ (without $i$, the other would take both items at $11$).

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pvickrey_clarke_groves_mechanism.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`vickrey_clarke_groves_mechanism.gpr` builds the standalone `tests` main
into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Max_Agents`, `Max_Outcomes` | Caps ($12$, $24$) |
| `Valuation_Matrix` | Reports $v_i(o)$, 1-based |
| `Money`, `Money_Vector` | Valuations, bids, payments, costs, weights |
| `Mechanism_Result` | $o^{*}$, welfare, $p$, $u$ for agents $1..N$ |
| `Near`, `Default_Tol` | Numeric comparison |
| `Social_Welfare`, `Others_Welfare`, `Net_Welfare` | $\sum v_i$, $\sum_{j\neq i} v_j$, minus $c$ |
| `Efficient_Outcome`, `Efficient_Outcome_Without`, `Efficient_Welfare` | $o^{*}$, $o^{*}_{-i}$, $W^{*}$ |
| `Clarke_H`, `Clarke_Payment`, `VCG_Payments` | $h_i$, externality $p_i$, payment vector |
| `VCG_Utility`, `VCG_Utilities`, `Run` | $u_i = v_i(o^{*})-p_i$; full result |
| `Is_Pivotal`, `Changes_Outcome` | Nonzero $p_i$; $o^{*} \neq o^{*}_{-i}$ |
| `Total_Revenue`, `Payments_Nonnegative`, `Is_Individually_Rational` | Budget / IR helpers |
| `Weighted_*` | Affine maximiser $\sum w_i v_i$ with $w_i > 0$ |
| `With_Agent_Report` | Replace row $i$ (truthfulness experiments) |
| `Vickrey_Auction`, `Vickrey_Winner`, `Vickrey_Price` | Single-item second price, optional reserve |
| `Public_Project`, `Should_Build`, `Public_Project_Tax` | Yes/No project of cost $C$ |
| `Make_Binary_Choice` | Status quo vs alternative |
| `Two_Item_Allocation`, `Make_Two_Item_Valuations` | Tiny $A,B$ combinatorial VCG |
| `Instance` | Imperative table + per-outcome costs |
| `Invalid_Argument` | Empty sets, bad sizes, bad ids, $w_i \le 0$, $\mathrm{Tol} < 0$ |

Sign convention: $p_i$ is paid **by** the agent **to** the mechanism
(Wikipedia’s transfer-to-the-agent is $-p_i$). When all reports and costs
are weakly positive, Clarke payments are nonnegative and utilities are
individually rational.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not a production combinatorial-auction or public-goods engine; VCG
must compute an exact welfare maximiser (NP-hard on large combinatorial
domains), is not budget-balanced in general, and is vulnerable to collusion.
For large $X$ use specialised mechanism-design libraries outside this package.
