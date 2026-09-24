# Core (Game Theory) in Ada 2023

## Project Overview

The **core** is a solution concept from **cooperative game theory**: the set
of feasible payoff allocations (imputations) that no coalition of players
can improve upon by breaking away from the grand coalition. One can think
of the core as describing situations where cooperation among all agents can
be sustained. The modern definition is due to Donald B. Gillies and Lloyd
Shapley; the idea already appears in Edgeworth's 1881 *contract curve*.

For a transferable-utility game $(N,v)$ with player set
$N=\{1,\ldots,n\}$ and characteristic function $v:2^{N}\to\mathbb{R}$, an
**imputation** $x\in\mathbb{R}^{N}$ satisfies

$$
\sum_{i\in N}x_{i}=v(N)
\quad\text{(efficiency)}
$$

and

$$
x_{i}\ge v(\{i\})
\quad\text{for all }i\in N
\quad\text{(individual rationality)}.
$$

Allocation $x$ lies in the **core** if and only if it is an imputation and
every coalition is coalitionally rational:

$$
\sum_{i\in S}x_{i}\ge v(S)
\quad\text{for all }S\subseteq N.
$$

Equivalently, the **excess** of coalition $S$ at $x$,

$$
e(S,x)=v(S)-\sum_{i\in S}x_{i},
$$

satisfies $e(S,x)\le 0$ for every $S$. A coalition with positive excess
**blocks** (improves upon) $x$.

The core is always a well-defined closed convex polyhedron (a system of
weak linear inequalities), but it **may be empty**. The
**Bondareva–Shapley theorem** states that the core is nonempty if and only
if the game is *balanced* (README-level only — this package does not
implement a general balancedness LP).

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: players $1..N$ with cap $N\le\mathrm{Max\_N}=12$ (dense
characteristic table on bitmasks $0..2^{N}-1$), imputation / core
membership tests, excess and blocking helpers, textbook game constructors
(gloves, miners, majority, unanimity, additive), and a few **LP-free**
core-point constructors for those special games. For arbitrary $v$, the
primary API is **membership testing** — computing a general core point
needs a linear-programming solver outside this classroom sheet.

Primary source:
[Wikipedia — Core (game theory)](https://en.wikipedia.org/wiki/Core_(game_theory)).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with cooperative-game siblings

| Package / concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Core`) | Stable payoff **set** | Imputations no coalition can block; may be empty |
| Shapley Value (sibling) | Axiomatic fair allocation $\varphi(v)$ | Unique point; always exists; in the core when $v$ is convex |
| Nucleolus (sibling) | Lexicographic excess minimizer | Always in the core when the core is nonempty |
| Banzhaf (sibling) | Swing / power index | Unweighted marginal swings; not a core concept |

README links only — **no** package `with` of siblings. The Shapley value
asks for a fair single point; the **core** asks for coalitional stability
and can be a whole set (or empty). The **nucleolus** picks a distinguished
core point by minimizing worst excesses. The **Banzhaf** index measures
voting power and is not an imputation concept.

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

The core is the **unique** imputation $(0,0,1)$ (the scarce left glove
takes the whole surplus). Note that the Shapley value
$\varphi=(1/6,1/6,2/3)$ is **not** in the core — this game is not convex.

### Miners

$$
v(S)=\bigl\lfloor |S|/2\bigr\rfloor.
$$

Even $n$: unique core $(1/2,\ldots,1/2)$. Odd $n$: **empty** core.

### Two-player pair gloves (Wikipedia)

$v(\{1\})=v(\{2\})=5$, $v(\{1,2\})=15$. Core $=$ all $(x,y)$ with
$x+y=15$, $x\ge 5$, $y\ge 5$.

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pcore_game_theory.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`core_game_theory.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Max_N` | Cap ($12$) |
| `Player_Id`, `Worth`, `Characteristic`, `Allocation` | Domain types |
| `Player_Bit`, `Bit_Count`, `Has_Player`, `Power2` | Bitmask helpers |
| `Sum_Allocation`, `Coalition_Payoff` | Payoff sums |
| `Is_Efficient`, `Is_Individually_Rational`, `Is_Imputation` | Feasibility |
| `Coalition_Excess`, `Blocks`, `Is_In_Core` | Stability / membership |
| `Max_Excess`, `Worst_Coalition`, `Count_Blocking` | Excess diagnostics |
| `Make_Additive`, `Make_Gloves`, `Make_Pair_Gloves`, `Make_Miners`, `Make_Majority`, `Make_Unanimity`, `Make_Zero` | Textbook games |
| `Additive_Core_Point`, `Gloves_Core_Point`, `Pair_Gloves_Core_Point`, `Miners_Core_Point`, `Unanimity_Equal_Point` | LP-free core points |
| `Equal_Surplus_Allocation` | Classroom probe (not always in core) |
| `Instance`, `Clear`, `Load`, `Set_Worth`, `Get_Worth`, `Grand_Worth` | Imperative builder |
| `Near`, `Invalid_Argument` | Numeric / error helpers |

Players are $1..N$. Characteristic tables must be **0-based** with length
exactly $2^{N}$. General core *finding* (beyond the special constructors)
requires an external LP solver; this sheet focuses on membership and
excesses.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not a production core solver; for large $n$ or general nonempty-core
search use an LP library outside this package.
