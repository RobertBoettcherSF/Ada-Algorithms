# AC-3 — Ada 2023

Educational, self-contained Ada 2023 package implementing **Mackworth's AC-3**
(arc consistency algorithm #3, 1977) for **binary constraint satisfaction
problems (CSPs)** with finite domains. Demos include a tiny **Australia-style
map colouring**, **N-queens** pairwise binary pruning, and an **alldiff**
network built from pairwise $\neq$.

Based on [Wikipedia: AC-3 algorithm](https://en.wikipedia.org/wiki/AC-3_algorithm).
Related: [Constraint satisfaction problem](https://en.wikipedia.org/wiki/Constraint_satisfaction_problem),
[Local consistency](https://en.wikipedia.org/wiki/Local_consistency) (arc consistency),
[N-queens](https://en.wikipedia.org/wiki/Eight_queens_puzzle).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Min-Conflicts](https://github.com/RobertBoettcherSF/Ada-Min-Conflicts)** —
  min-conflicts local search / repair for CSPs (N-queens, map sketch)
- Constraint satisfaction survey forthcoming
  (`Ada-Constraints-Satisfaction` or similar later)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: $\textit{Vars}\le 16$, $\textit{Domain}\le 16$,
$\textit{Constraints}\le 64$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **State** | Domains as membership vectors over $1..D_{\max}$ | Incomplete assignment / filtering view |
| **Constraints** | Binary only: $\neq$, $<$, or Allowed-pairs table | Undirected edges stored once |
| **Revise** | Drop $v\in D(X_i)$ with no support in $D(X_j)$ | Returns whether domain changed |
| **AC-3** | Worklist of directed arcs; re-queue neighbours | Fail on empty domain (wipeout) |
| **API** | `Revise`, `AC3` / `Make_Arc_Consistent` | Demos: map, N-queens, alldiff |
| **Result** | `Success` or `Domain_Wipeout` | Plus revision / arc counters |

## Arc consistency

A binary CSP is **arc-consistent** when, for every directed arc $(X_i,X_j)$
implied by a constraint, every value $v\in D(X_i)$ has at least one
**support** $w\in D(X_j)$ such that $(v,w)$ satisfies the constraint(s)
linking $X_i$ and $X_j$. AC-3 enforces this by repeatedly revising arcs
until the worklist is empty or a domain is wiped out.

## AC-3 loop

Pseudocode (Mackworth / Wikipedia / Russell & Norvig style):

1. Optionally apply unary constraints (here: set domains via `Set_Domain`).
2. Initialise a worklist with both directed arcs for every binary constraint.
3. While the worklist is nonempty:
   - dequeue arc $(X_i,X_j)$;
   - if $\mathrm{Revise}(X_i,X_j)$ removed values:
     - if $D(X_i)=\emptyset$, return failure (domain wipeout);
     - else enqueue $(X_k,X_i)$ for every neighbour $X_k\neq X_j$.
4. Otherwise return success (domains are arc-consistent).

$$
\mathrm{Revise}(X_i,X_j):\quad
D(X_i)\leftarrow
\bigl\{v\in D(X_i)\;\big|\;
\exists\,w\in D(X_j):\ R_{ij}(v,w)\bigr\}
$$

Worst-case time complexity is often stated as

$$
O(e\,d^{3})
$$

with space $O(e)$, where $e$ is the number of arcs and $d$ the size of the
largest domain (each arc revised $O(d)$ times; each revise costs $O(d^{2})$
naïvely).

## Map colouring demo

`Build_Australia_Map` builds a 7-region / 3-colour instance (WA, NT, SA, Q,
NSW, V, T) with the usual borders as pairwise $\neq$. Pure AC-3 does not
solve the map by itself — it filters domains. Fixing adjacent regions to
the same colour yields `Domain_Wipeout`; fixing WA and NT to distinct
colours forces SA's remaining colour.

`Build_Unsat_Triangle` is $K_3$ with 2 colours: after fixing one vertex,
AC-3 detects wipeout.

## N-queens & alldiff

`Build_N_Queens_Binary(N)` places one variable per row with domain
$\{1..N\}$ (columns). Each unordered row pair gets an `Allowed_Pairs`
table forbidding same column and same diagonal:

$$
R_{ij}(c_i,c_j)
\iff
c_i\neq c_j \land |c_i-c_j|\neq |i-j|
$$

`Build_Alldiff_Demo` / `Add_All_Different` encode $\mathrm{alldifferent}$
as a clique of pairwise $\neq$ constraints (educational; not a GAC-alldiff
propagator).

## API (`AC_3`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| **Caps** | `Max_Vars`, `Max_Domain`, `Max_Constraints` | Educational bounds ($16/16/64$) |
| **Domain** | `Domain`, `Domain_Size`, `Is_Empty`, `Full_Domain`, … | Membership over $1..D_{\max}$ |
| **CSP** | `CSP`, `Init`, `Set_Domain` | Variables + constraint list |
| **Constraints** | `Add_Not_Equal`, `Add_Less_Than`, `Add_Allowed_Pairs`, `Add_All_Different` | Binary store |
| **Core** | `Satisfies`, `Has_Support`, `Revise` | Support check / domain prune |
| **AC-3** | `Fill_Initial_Queue`, `AC3`, `Make_Arc_Consistent` | Worklist arc consistency |
| **Result** | `AC3_Status`, `AC3_Result` | `Success` / `Domain_Wipeout` |
| **Demos** | `Build_Australia_Map`, `Build_Unsat_Triangle`, `Build_N_Queens_Binary`, `Build_Alldiff_Demo` | Tiny CSPs |

## Limits & caveats

- Educational caps: $\textit{Vars}\le 16$, domain values $\le 16$,
  constraints $\le 64$ (arc worklist $\le 128$).
- Binary constraints only — no n-ary GAC, no watched literals, no backtracking
  search. AC-3 is a **filter**, not a complete solver.
- Pairwise alldiff is weaker than a dedicated $\mathrm{alldifferent}$
  propagator; N-queens still needs search for $N\ge 4$ after AC-3.
- Undirected constraints are stored once; revise examines both orientations.
- Multiple constraints on the same pair are all enforced (conjunction).
- `Domain_Wipeout` proves unsatisfiability only when empty domains appear;
  failure to wipe out does **not** prove satisfiability.

## Build & test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pac_3.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. Zero warnings expected under
`-gnatwa -gnat2022`.
