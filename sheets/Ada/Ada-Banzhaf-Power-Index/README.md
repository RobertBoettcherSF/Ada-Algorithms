# Banzhaf Power Index in Ada 2023

## Project Overview

The **Banzhaf power index** (also called the **Penrose–Banzhaf** index and,
with Coleman's related ratios, the **Banzhaf–Coleman** index) measures voting
power in a **weighted voting game** or, more generally, a **simple game**.
Lionel Penrose introduced it in 1946; John F. Banzhaf III reinvented it in
1965 (famously analysing the Nassau County board); James S. Coleman
reinvented it again in 1971.

A player $i$ is a **swing** (or **critical voter**) in a coalition $S$ that
does not contain $i$ when $S$ is losing but $S\cup\{i\}$ is winning. Writing
$\eta_i$ for the number of such coalitions,

$$
\beta'_{i}=\frac{\eta_{i}}{2^{n-1}},
\qquad
\beta_{i}=\frac{\eta_{i}}{\sum_{j}\eta_{j}}.
$$

Here $\beta'_{i}$ is the **absolute** (Penrose–Banzhaf) index — the fraction
of the $2^{n-1}$ coalitions excluding $i$ in which $i$ is critical — and
$\beta_{i}$ is the **normalized** Banzhaf index (the share of all swing
votes). Coleman's **power to prevent action** is $\eta_{i}$ divided by the
number of winning coalitions; his **power to initiate action** is $\eta_{i}$
divided by the number of losing coalitions.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: players $1..N$ with cap $N\le\mathrm{Max\_N}=16$ (so a dense
$0/1$ characteristic table on bitmasks $0..2^{N}-1$ and a $2^{n-1}$ swing
enumeration fit in classroom settings). It accepts a weighted voting game
$[q;w_{1},\ldots,w_{n}]$ or a general simple game via a $0/1$ bitmask table,
exposes `Swing_Counts`, `Absolute_Banzhaf` / `Penrose_Banzhaf`,
`Normalized_Banzhaf`, `Is_Winning` / `Is_Critical`, Coleman helpers, dummy /
dictator / veto / symmetry tests, constructors (majority, equal weights,
UN Security Council toy, corporate shareholders), and raises
`Invalid_Argument` for bad $N$, quota, weights, or a non-simple table.

Primary source:
[Wikipedia — Banzhaf power index](https://en.wikipedia.org/wiki/Banzhaf_power_index).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with cooperative-game siblings

| Package / concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Banzhaf-Power-Index`) | Swing / voting-power index | Unweighted count of critical coalitions; $\beta$ and $\beta'$ |
| Shapley value (sibling) | Axiomatic fair allocation $\varphi(v)$ | Weighted marginals; generally differs from $\beta$ |
| Shapley–Shubik power index | Shapley value of a simple game | Same swings, but coalitions weighted by $s!(n-s-1)!/n!$ for coalition size $s$ (equivalently: pivotal positions in $n!$ orderings) |
| Core (sibling) | Stable payoff **set** | Imputations no coalition can improve upon; may be empty |
| Nucleolus (sibling) | Lexicographic excess minimizer | Always in the Core when the Core is nonempty |

README links only — **no** package `with` of siblings. Banzhaf treats every
coalition excluding $i$ as equally likely (a random yes/no vote). 
**Shapley–Shubik** is the Shapley value specialized to simple voting games
and therefore weights coalitions by size. The two indices coincide on some
games (for example Straffin's $[6;4,3,2,1]$) and differ on others (for
example $[3;2,1,1]$, where Banzhaf gives
$(3/5,1/5,1/5)$ and Shapley–Shubik gives $(4/6,1/6,1/6)$). The **Core** and
**nucleolus** are allocation concepts for transferable-utility games, not
voting-power indices.

## Characteristic function and bitmasks

A coalition $S\subseteq N$ is encoded as a bitmask: bit $(i-1)$ is set iff
player $i\in S$. A weighted game declares $S$ winning when
$\sum_{i\in S}w_{i}\ge q$. A general simple game is a $0/1$ table
`Characteristic` indexed by $0..2^{n}-1$, with $v(\emptyset)=0$ and
monotonicity required. Classroom size $n\le 16$ keeps $2^{n}\le 65\,536$
(the $2^{n-1}$ swing loop remains practical near $n=20$).

### Straffin / four-shareholder example

The textbook game $[6;4,3,2,1]$ (equivalent to corporate shares
$[51;40,30,20,10]$) has twelve swing votes:

$$
\eta=(5,3,3,1),\qquad
\beta=\Bigl(\tfrac{5}{12},\,\tfrac{3}{12},\,\tfrac{3}{12},\,\tfrac{1}{12}\Bigr).
$$

### Nassau County (Banzhaf 1965)

$[16;9,9,7,3,1,1]$ yields $\eta=(16,16,16,0,0,0)$: the three large towns
hold all $48$ swings; the three small ones are **dummies** despite a
combined $16\%$ of the votes.

### UN Security Council toy

Five permanent members (weight $7$) and ten rotating members (weight $1$),
quota $39$, encode “nine yes votes including every veto.” Then
$\eta_{\mathrm{P}5}=848$, $\eta_{\mathrm{rot}}=84$, and
$\sum\eta=5080$.

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pbanzhaf_power_index.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`banzhaf_power_index.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Max_N` | Cap ($16$) |
| `Player_Id`, `Worth`, `Weight_Vector`, `Characteristic` | Domain types |
| `Count_Vector`, `Index_Vector` | $\eta$ and $\beta$ / $\beta'$ |
| `Player_Bit`, `Bit_Count`, `Has_Player`, `Power2` | Bitmask helpers |
| `Factorial`, `Binomial`, `Coalition_Weight` | Combinatorial / weight sums |
| `Weighted`, `From_Characteristic` | Game constructors |
| `Majority`, `Equal_Weights`, `UN_Security_Council`, `Corporate_Shareholders` | Named toys |
| `Is_Winning`, `Is_Critical` | Coalition predicates (instance, weighted, or table) |
| `Swing_Counts` | $\eta$ (instance, weighted, table, or callback) |
| `Absolute_Banzhaf` / `Penrose_Banzhaf` | $\beta'_{i}=\eta_{i}/2^{n-1}$ |
| `Normalized_Banzhaf` | $\beta_{i}=\eta_{i}/\sum\eta_{j}$ |
| `Coleman_Prevent`, `Coleman_Initiate` | Coleman power-to-prevent / initiate |
| `Is_Dummy`, `Is_Dictator`, `Is_Vetoer`, `Are_Symmetric` | Role tests |
| `Winning_Count`, `Losing_Count`, `Total_Swings`, `Near`, `Is_Normalized` | Numeric helpers |
| `Invalid_Argument` | Bad $N$, quota, weights, table, mask, or zero denominator |

Players are $1..N$. Weight vectors must be **1-based**. Characteristic
tables must be **0-based** with length exactly $2^{N}$ and entries in
$\{0,1\}$. Callback forms take anonymous `access function` parameters so
nested test functions may be passed via `'Access`.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not optimized for large $n$; for $n>16$ use generating functions,
dynamic programming, or Monte Carlo estimators outside this package.
