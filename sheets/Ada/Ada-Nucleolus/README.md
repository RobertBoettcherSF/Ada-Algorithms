# Nucleolus in Ada 2023

## Project Overview

The **nucleolus** is a solution concept from **cooperative game theory** that
selects a unique payoff allocation by lexicographically optimizing coalition
**excesses**. David Schmeidler introduced it in 1969. Among all
**imputations** (efficient, individually rational allocations), the nucleolus
minimizes the worst coalition excess, then the second-worst, and so on.

This package uses the **Schmeidler sign convention**

$$
e(S,x)=v(S)-\sum_{i\in S}x_{i},
$$

and defines the nucleolus as the unique imputation that **lexicographically
minimizes** the **nonincreasingly** sorted excess vector
$\theta(x)=(e(S_{1},x),\ldots,e(S_{2^{n}},x))$ with
$\theta_{1}(x)\ge\theta_{2}(x)\ge\cdots$. Equivalently, Wikipedia writes
excess as payment minus value (the negation) and **maximizes** that vector in
the leximin order — same solution.

The nucleolus always exists when the imputation set is nonempty, is always
unique, lies in the **least core**, and lies in the **core** whenever the core
is nonempty.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational
implementation: players $1..N$ with cap $N\le\mathrm{Max\_N}=8$ (dense
characteristic table on bitmasks $0..2^{N}-1$), classroom
`Find_Nucleolus` / `Compute` via pure-Ada **grid search** for
$N\le\mathrm{Max\_Search\_N}=6$ (no external LP library), excess /
`Sorted_Excess_Vector` / `Lex_Compare` helpers, special-game constructors
(glove, majority, additive, unanimity, bankruptcy, airport), closed-form
nucleoli where known, an imperative `Instance` builder, and
`Invalid_Argument` for bad $N$ or incomplete $v$.

**Documented limitation:** a general large-$N$ nucleolus is computed by a
sequence of linear programs (lexicographic max-min). The classroom solver here
is for small $N$ only.

Primary source:
[Wikipedia — Nucleolus (game theory)](https://en.wikipedia.org/wiki/Nucleolus_(game_theory)).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with cooperative-game siblings

| Package / concept | Role | Notes |
| --- | --- | --- |
| **This package** (`Ada-Nucleolus`) | Lexicographic excess solution | Unique point in the least core; Schmeidler (1969) |
| Core (sibling) | Stable payoff **set** | May be empty; nucleolus ∈ core when nonempty |
| Shapley value (sibling) | Axiomatic fair allocation $\varphi(v)$ | Generally differs from the nucleolus |
| Banzhaf (sibling) | Swing / power index | Unweighted swings; not an imputation solution |

README links only — **no** package `with` of siblings.

## Characteristic function and bitmasks

A coalition $S\subseteq N$ is encoded as a bitmask: bit $(i-1)$ is set iff
player $i\in S$. The dense table `Characteristic` is indexed by
$0..2^{n}-1$, so $v(\emptyset)=V(0)$ and $v(N)=V(2^{n}-1)$. Classroom size
$n\le 8$ keeps $2^{n}\le 256$; grid search is limited to $n\le 6$.

### Classic glove game

$N=\{1,2,3\}$ with players $1,2$ holding right-hand gloves and player $3$ a
left-hand glove:

$$
v(S)=\begin{cases}
1 & \text{if }S\in\{\{1,3\},\{2,3\},\{1,2,3\}\},\\
0 & \text{otherwise.}
\end{cases}
$$

The unique core point (and nucleolus) is

$$
\nu(v)=(0,\,0,\,1).
$$

### Bankruptcy / contested garment

For an estate $E$ and claims $d$, the O'Neill game
$v(S)=\max\bigl(0,\,E-\sum_{i\notin S}d_{i}\bigr)$ has nucleolus equal to the
**Talmud** (contested-garment-consistent) rule of Aumann–Maschler. For two
creditors the contested garment awards each their uncontested part plus half
the remainder.

### Airport cost game

With nondecreasing runway costs $c_{1}\le\cdots\le c_{n}$, the TU worth is
$v(S)=-\max_{i\in S}c_{i}$. `Airport_Nucleolus` returns the negated
Littlechild–Owen sequential shares (the Shapley value of the airport cost
game). Littlechild (1974) studies the nucleolus of airport cost games; the
classroom grid solver returns a Schmeidler nucleolus approximation that
matches or lex-improves those shares on small instances.

## Build

```bash
make        # gnatmake -gnatwa -gnat2022 -Pnucleolus.gpr
make test   # run bin/tests
make clean
```

Requires GNAT with Ada 2022 support (`-gnat2022`). The project file
`nucleolus.gpr` builds the standalone `tests` main into `bin/`.

## API summary

| Entity | Role |
| --- | --- |
| `Max_N` / `Max_Search_N` | Caps ($8$ / $6$) |
| `Player_Id`, `Worth`, `Characteristic`, `Allocation`, `Excess_Vector` | Domain types |
| `Player_Bit`, `Bit_Count`, `Has_Player`, `Power2` | Bitmask helpers |
| `Excess`, `Max_Excess`, `Sorted_Excess_Vector` | Schmeidler excesses |
| `Lex_Compare` / `Lex_Order` | Lex order of nonincreasing excess vectors |
| `Find_Nucleolus` / `Compute` | Classroom grid-search nucleolus |
| `Is_Imputation`, `Is_Efficient`, `Is_Individually_Rational` | Imputation tests |
| `Make_Gloves`, `Make_Majority`, `Make_Additive`, `Make_Unanimity`, … | Toy games |
| `Make_Bankruptcy`, `Make_Airport` | Structured toys with known $\nu$ |
| `Gloves_Nucleolus`, `Talmud_Nucleolus`, `Airport_Nucleolus`, … | Closed forms |
| `Instance`, `Clear`, `Load`, `Set_Worth`, `Get_Worth` | Imperative builder |
| `Invalid_Argument` | Bad $N$, incomplete / mis-indexed $v$, empty imputations |

Players are $1..N$. Characteristic tables must be **0-based** with length
exactly $2^{N}$.

## License / series note

Educational reference code in the **RobertBoettcherSF** Ada 2023 algorithm
series. Not a production LP nucleolus solver; for $n>\mathrm{Max\_Search\_N}$
use sequential linear programs outside this package.
