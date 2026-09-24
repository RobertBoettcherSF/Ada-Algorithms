# Min-Conflicts — Ada 2023

Educational, self-contained Ada 2023 package implementing the **min-conflicts**
hill-climbing heuristic (Minton, Johnston, Philips, Laird) for **constraint
satisfaction problems (CSPs)**. The flagship demo is **N-queens** local
search with seeded randomness and optional random restarts; a tiny
**map-coloring** binary CSP sketch is included for contrast.

Based on [Wikipedia: Min-conflicts algorithm](https://en.wikipedia.org/wiki/Min-conflicts_algorithm).
Related: [Constraint satisfaction problem](https://en.wikipedia.org/wiki/Constraint_satisfaction_problem),
[Local search (optimization)](https://en.wikipedia.org/wiki/Local_search_(optimization)),
[N-queens](https://en.wikipedia.org/wiki/Eight_queens_puzzle).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Dancing-Links](https://github.com/RobertBoettcherSF/Ada-Dancing-Links)** —
  sparse DLX exact-cover search (systematic / complete)
- **[Ada-Algorithm-X](https://github.com/RobertBoettcherSF/Ada-Algorithm-X)** —
  dense-matrix Algorithm X for the same exact-cover framing
- **[Ada-Local-Search](https://github.com/RobertBoettcherSF/Ada-Local-Search)** —
  broader local-search taxonomy (hill climbing, restarts, 2-opt)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: N-queens $N\le 32$ (tests focus $N\le 16$); map sketch
$\le 8$ regions, $\le 4$ colors, $\le 32$ edges.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **State** | Complete assignment (every variable valued) | Local-search / repair view of a CSP |
| **N-queens** | `Board(Row)=Column` | One queen per row by construction |
| **Conflict** | Attacking pairs / per-variable attacks | Column + both diagonals |
| **Move** | Reassign one conflicted variable | Min-conflict value, random ties |
| **Restart** | Alternate greedy / random starts | Escapes plateaus / local minima |
| **API** | `Conflict_Count`, `Step`, `Solve_N_Queens` | Seeded LCG for tests |

## CSP local search

A CSP asks for an assignment of domain values to variables such that all
constraints hold. Systematic solvers (backtracking, AC-3, Algorithm X /
DLX) explore a search tree. **Local search** instead starts from a
*complete* assignment — possibly violating many constraints — and
iteratively *repairs* it.

Min-conflicts is the classic repair heuristic: always fix a currently
conflicted variable by giving it the value that violates the fewest
constraints, given the rest of the assignment.

## Min-conflicts loop

Pseudocode (Wikipedia / Russell & Norvig):

1. Start from a complete assignment $A$.
2. For up to $\textit{max\_steps}$ iterations:
   - if $A$ is a solution, return $A$;
   - pick a conflicted variable $v$ uniformly at random;
   - set $A[v]$ to a value that minimises
     $\mathrm{CONFLICTS}(v,\cdot,A)$, breaking ties randomly.
3. Otherwise fail (optionally restart from a new random $A$).

$$
v \leftarrow \mathrm{uniform}\bigl(\{x : \mathrm{CONFLICTS}(x,A[x],A)>0\}\bigr)
$$

$$
A[v] \leftarrow \arg\min_{d\in D(v)}\ \mathrm{CONFLICTS}(v,d,A)
\quad\text{(ties random)}
$$

## N-queens fame

N-queens is the flagship example because solutions are densely scattered
in the state space: with a decent start, the expected number of repairs
grows surprisingly slowly with $N$. Historically, Minton et al. used
min-conflicts to schedule Hubble observations, cutting a multi-week
manual process to minutes.

Representation here: one queen per row, `Board(R)` = column. A conflict
is a pair of queens sharing a column or a diagonal:

$$
\mathrm{attack}(r_1,c_1;r_2,c_2)
\iff c_1=c_2 \lor |r_1-r_2|=|c_1-c_2|
$$

`Variable_Conflicts(B,R)` counts attackers of the queen in row $R$;
`Conflict_Count(B)` is the number of attacking pairs
$\bigl(=\tfrac12\sum_R \mathrm{Variable\_Conflicts}(B,R)\bigr)$.

## Map-coloring sketch

`Build_Four_Region_Map` builds a 4-region / 3-color instance (4-cycle plus
one chord). The same min-conflicts loop reassigns a conflicted region to
a colour that minimises monochromatic edges. Map colouring can trap local
search in stable wrong colourings more often than N-queens — useful as a
contrast demo, not as a production colourer.

## API (`Min_Conflicts`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| **Board** | `Board`, `Queens_N`, `Max_N` | Row→column assignment |
| **Params** | `Parameters`, `Default_Parameters` | `Max_Steps`, `Seed`, `Restarts` |
| **RNG** | `RNG_State`, `Seed_RNG`, `Next_Natural` | Reproducible ties / restarts |
| **Init** | `Random_Board`, `Greedy_Board` | Complete starting assignments |
| **Conflicts** | `Variable_Conflicts`, `Conflict_Count`, `Is_Solved` | N-queens scoring |
| **Operators** | `Min_Conflict_Value`, `Pick_Conflicted_Variable`, `Step` | One repair; ties prefer a move |
| **Solve** | `Minimize_Conflicts`, `Solve_N_Queens` | Hill-climb / restart loop |
| **Result** | `Solve_Result` | Solved flag, steps, restarts, residual |
| **Map** | `Map_CSP`, `Solve_Map_Coloring`, … | Tiny binary CSP sketch |

## Limits & caveats

- Educational caps: $N\le 32$; tests emphasise $N\le 16$.
- Incomplete method: may fail even when solutions exist if
  `Max_Steps` / `Restarts` are too small, or on plateaus.
- Tie-breaking and variable choice are randomised (seeded LCG) —
  different seeds explore different paths. Among min-conflict
  values, a non-current value is preferred when available (sideways
  escape).
- `Solve_N_Queens` alternates `Greedy_Board` / `Random_Board` across
  restarts; small $N$ (especially $N=4$) still needs ample restarts.
- No generic CSP language / constraint store — N-queens and the map
  sketch are hard-coded educational demos.
- Ada-Constraints-Satisfaction / Ada-AC-3 siblings are not linked here
  until published under the same org.

## Build & test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pmin_conflicts.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. Zero warnings expected under
`-gnatwa -gnat2022`.
