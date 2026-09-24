# Top Trading Cycle in Ada 2023

## Project Overview

The **Top Trading Cycle (TTC)** algorithm reallocates indivisible items
(classically: houses) among agents who each own one item and have
**strict** ordinal preferences over the set of items. David Gale
proposed the procedure; Lloyd Shapley and Herbert Scarf published it
in 1974 (*On cores and indivisibility*). With strict preferences TTC
returns the **unique core allocation** of the housing market and is
**strategy-proof** (Roth, 1982). In the strict-preference domain it is
the unique mechanism that is individually rational, Pareto efficient,
and strategy-proof.

Agents $N=\{1,\ldots,n\}$ and houses $\{1,\ldots,n\}$ share the same
index set. The **endowment** is a permutation $e:N\to\{\text{houses}\}$
(identity $e(i)=i$ by default). Preferences are complete rankings:
agent $i$'s list is a permutation of the houses. Each round every
remaining agent points to the **owner** of their favourite remaining
house; the pointing map is a functional graph, so at least one directed
cycle exists; every such cycle is cleared (each agent on a cycle
receives the house held by the agent they point to) and those agents
leave. Repeat until none remain. The procedure terminates in at most
$n$ rounds.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: 1-based `Agent_Id` / `House_Id`, preference lists as
$n\times n$ rank-ordered permutations (or incremental `Set_Preference`),
identity or general endowment, `Solve` / `Allocate` returning
agent$\to$house and house$\to$agent arrays, pointing-graph and cycle
helpers, `Is_Individually_Rational` and a small-$n$ `Is_In_Core`
spot-check, fixed arrays (no dynamic heap), and `Invalid_Argument` for
bad sizes, non-permutations, and malformed endowments. Cap
$n\le\mathrm{Max\_N}=32$ (classroom scale).

Primary source:
[Wikipedia — Top trading cycle](https://en.wikipedia.org/wiki/Top_trading_cycle).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Gale–Shapley and VCG

| Package / method | Problem | Notes |
| --- | --- | --- |
| **This package** (`Ada-Top-Trading-Cycle`) | One-sided **housing market** with endowments | Unique strict core; strategy-proof |
| Gale–Shapley (sibling sheet) | Two-sided **stable matching** | Deferred acceptance; no house endowments |
| VCG (sibling sheet) | Quasilinear **money** mechanisms | Efficient + strategy-proof with transfers |

README links only — **no** package `with` of siblings. Gale–Shapley
matches two sides with ordinal preferences and requires **stability**
(no blocking pair); TTC reassigns owned objects using **top cycles**
and requires **core** stability among coalitions that trade their
endowments. VCG uses transferable utility and payments; classical TTC
uses **no money**.

## Housing market and the core

An **allocation** is a bijection $\mu$ from agents to houses. Coalition
$S\subseteq N$ **blocks** $\mu$ (weak core) when the members of $S$ can
reassign among themselves the houses $\{e(i):i\in S\}$ so that every
$i\in S$ strictly prefers the new house to $\mu(i)$. Allocation $\mu$
is in the **core** when no nonempty coalition blocks. With strict
preferences the core is a singleton, and TTC finds it.

### Wikipedia example ($n=6$, identity endowment)

| Agent | Preference (best $\to$ worst, top 4 shown) |
| --- | --- |
| $1$ | $3,2,4,1,\ldots$ |
| $2$ | $3,5,6,\ldots$ |
| $3$ | $3,1,\ldots$ |
| $4$ | $2,5,6,4,\ldots$ |
| $5$ | $1,3,2,\ldots$ |
| $6$ | $2,4,5,6,\ldots$ |

Rounds: $\{3\}$ keeps house $3$; then $\{1,2,5\}$ trade to houses
$2,5,1$; then $\{4,6\}$ swap to $6,4$. Final allocation:

$$
\mu = (1\!\mapsto\!2,\;2\!\mapsto\!5,\;3\!\mapsto\!3,\;4\!\mapsto\!6,\;5\!\mapsto\!1,\;6\!\mapsto\!4).
$$

## Algorithm

### Top trading cycles

Residual market $R\leftarrow\{1,\ldots,n\}$; each agent holds $e(i)$.
While $R\neq\emptyset$:

1. Every $i\in R$ points to the agent in $R$ who currently holds $i$'s
   favourite house still in the residual market.
2. The pointing map has out-degree one on $R$, so $\ge 1$ directed cycle
   exists (including length-$1$ “already happy” fixed points).
3. Clear **all** cycles found in that map: agent $i$ on a cycle receives
   the house held by the agent $i$ points to; those agents leave $R$.

### Pseudocode

```text
holding[i] := endowment[i] for all i
R := {1 .. n}
while R ≠ ∅:
    for each i in R:
        H := favourite house of i among {holding[j] : j in R}
        point[i] := owner of H in R
    for each directed cycle C in point|R:
        for each i in C:
            μ[i] := holding[point[i]]
        R := R \ C
```

### Complexity

Each round removes at least one agent; scanning preference lists to
build the pointing map costs $O(n^{2})$ work per round in the worst
case, for a simple bound of

$$
O(n^{3})
$$

classroom time (tighter implementations exist). Cap $n\le 32$ keeps
instances tiny for demos and tests.

## API summary

| Entity | Role |
| --- | --- |
| `Max_N` / `Max_Core_Check_N` | Capacity $32$; core oracle up to $10$ |
| `Agent_Id`, `House_Id` | Indices $1..N$ |
| `Pref_Matrix`, `Id_Array` | Preferences / endowment / pointing |
| `Instance` | Problem: prefs + endowment |
| `Clear` / `Load*` / `Set_*` | Build instances |
| `Preference`, `Endowment`, `Rank_Of`, `Prefers` | Queries |
| `Compute_Pointing`, `Find_Cycle`, `Has_Cycle`, `Count_Cycles` | Residual graph helpers |
| `Solve` / `Allocate` | Run TTC → `Allocation` |
| `Is_Bijection`, `Is_Individually_Rational`, `Is_In_Core` | Checks |
| `Invalid_Argument` | Bad sizes, non-permutations, oversized core check |

## Build and test

```bash
make
make test
```

Uses `gnatmake -gnatwa -gnat2022` via `top_trading_cycle.gpr`. Expect
a green suite with on the order of $150$–$400$ `PASS` lines and
**zero** `FAIL`, and **zero** `-gnatwa` warnings.

## License

Educational material for the RobertBoettcherSF Ada 2023 algorithm
series. Use and adapt freely for teaching and self-study.
