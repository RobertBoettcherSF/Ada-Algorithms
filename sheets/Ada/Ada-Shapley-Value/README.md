# Shapley Value in Ada 2023

## Project Overview

The **Shapley value** is a solution concept from **cooperative game theory**
for fairly allocating the total gains (or costs) of a coalition among its
members. Lloyd Shapley introduced it in 1951; it remains the unique allocation
that satisfies the four classic axioms of **efficiency**, **symmetry**,
**dummy (null) player**, and **additivity** (linearity).

For a transferable-utility game $(N,v)$ with player set
$N=\{1,\ldots,n\}$ and characteristic function $v:2^{N}\to\mathbb{R}$, the
Shapley value of player $i$ is the weighted average of $i$'s **marginal
contributions** over all coalitions that exclude $i$:

$$
\varphi_{i}(v)=\sum_{S\subseteq N\setminus\{i\}}
\frac{|S|!\,(n-|S|-1)!}{n!}\bigl(v(S\cup\{i\})-v(S)\bigr).
$$

Equivalently, $\varphi_{i}$ is the average marginal contribution of $i$ over
all $n!$ orderings $\pi$ of the players:

$$
\varphi_{i}(v)=\frac{1}{n!}\sum_{\pi}
\bigl(v(P_{i}^{\pi}\cup\{i\})-v(P_{i}^{\pi})\bigr),
$$

where $P_{i}^{\pi}$ is the set of players preceding $i$ in $\pi$.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: players $1..N$ with cap $N\le\mathrm{Max\_N}=12$ (so a dense
characteristic table on bitmasks $0..2^{N}-1$ fits in classroom memory),
`Compute` / `Values` returning the $\varphi$ vector, an optional
`Compute_By_Permutations` cross-check for $N\le\mathrm{Max\_Perm\_N}=10$,
helpers for marginals, factorial / binomial Shapley weights, efficiency /
dummy / symmetry checks, an imperative `Instance` builder, and
`Invalid_Argument` for bad $N$ or incomplete $v$.

Primary source:
[Wikipedia — Shapley value](https://en.wikipedia.org/wiki/Shapley_value).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with cooperative-game siblings

| Package / concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Shapley-Value`) | Axiomatic fair allocation $\varphi(v)$ | Unique value satisfying efficiency, symmetry, dummy, additivity |
| Core (upcoming sibling) | Stable payoff set | Imputations no coalition can improve upon; may be empty |
| Nucleolus (upcoming sibling) | Lexicographic excess minimizer | Always in the Core when the Core is nonempty |
| Banzhaf (upcoming sibling) | Swing / power index | Unweighted marginal swings; not the same axiomatic value |

README links only — **no** package `with` of siblings. The Shapley value
always exists and is unique under the four axioms above. The **Core** asks
for coalitional stability rather than a single point; it can be empty. The
**nucleolus** picks a distinguished Core point (when one exists) by
minimizing the worst coalition excesses. The **Banzhaf** index counts raw
swing probabilities and generally differs from $\varphi$ (except on special
games). Shapley–Shubik is the Shapley value specialized to simple voting
games.

## Characteristic function and bitmasks

A coalition $S\subseteq N$ is encoded as a bitmask: bit $(i-1)$ is set iff
player $i\in S$. The dense table `Characteristic` is indexed by
$0..2^{n}-1$, so $v(\emptyset)=V(0)$ and $v(N)=V(2^{n}-1)$. Classroom size
$n\le 12$ keeps $2^{n}\le 4096$.

### Classic glove game

$N=\{1,2,3\}$ with players $1,2$ holding right-hand gloves and player $3$ a
left-hand glove:

$$
v(S)=\begin{cases}
1 & \text{if }S\in\{\{1,3\},\{2,3\},\{1,2,3\}\},\\
0 & \text{otherwise.}
\end{cases}
$$

The Shapley value is

$$
\varphi(v)=\Bigl(\tfrac{1}{6},\,\tfrac{1}{6},\,\tfrac{2}{3}\Bigr).
$$

### Axioms (informal)

- **Efficiency:** $\sum_{i\in N}\varphi_{i}(v)=v(N)$.
- **Symmetry:** interchangeable players receive equal shares.
- **Dummy player:** if every marginal of $i$ is $0$, then $\varphi_{i}(v)=0$.
- **Additivity:** $\varphi(v+w)=\varphi(v)+\varphi(w)$.

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pshapley_value.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`shapley_value.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Max_N` / `Max_Perm_N` | Caps ($12$ / $10$) |
| `Player_Id`, `Worth`, `Characteristic`, `Value_Vector` | Domain types |
| `Player_Bit`, `Bit_Count`, `Has_Player`, `Power2` | Bitmask helpers |
| `Factorial`, `Binomial`, `Shapley_Weight` | Combinatorial weights |
| `Marginal` | $v(S\cup\{i\})-v(S)$ (array or callback) |
| `Compute` / `Values` | Coalition-sum $\varphi$ |
| `Compute_By_Permutations` | Ordering-average cross-check |
| `Is_Efficient`, `Is_Dummy`, `Are_Symmetric`, `Sum_Values`, `Near` | Axiom / numeric helpers |
| `Instance`, `Clear`, `Load`, `Set_Worth`, `Get_Worth`, `Grand_Worth` | Imperative builder |
| `Invalid_Argument` | Bad $N$, incomplete / mis-indexed $v$, null callback, OOB masks |

Players are $1..N$. Characteristic tables must be **0-based** with length
exactly $2^{N}$. Callback forms take anonymous `access function` parameters
so nested test functions may be passed via `'Access`.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not optimized for large $n$; for $n>12$ use sampling / Monte Carlo
Shapley estimators outside this package.
