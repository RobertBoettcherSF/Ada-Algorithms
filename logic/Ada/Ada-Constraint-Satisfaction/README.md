# Constraint Satisfaction — Ada 2023

Educational **survey** package for **constraint satisfaction problems (CSPs)**
with finite domains: formal CSP types, partial-assignment consistency,
**backtracking** search (optional MRV), a **forward-checking** sketch, a tiny
embedded **arc-consistency** (`Revise` / one-pass `AC_Filter`), and a
**min-conflicts** one-variable repair step. Taxonomy flags mark **SAT
encoding** as forthcoming (sibling DPLL).

Based on [Wikipedia: Constraint satisfaction problem](https://en.wikipedia.org/wiki/Constraint_satisfaction_problem).
Related: [AC-3 algorithm](https://en.wikipedia.org/wiki/AC-3_algorithm),
[Min-conflicts algorithm](https://en.wikipedia.org/wiki/Min-conflicts_algorithm),
[DPLL algorithm](https://en.wikipedia.org/wiki/DPLL_algorithm),
[Local consistency](https://en.wikipedia.org/wiki/Local_consistency).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-AC-3](https://github.com/RobertBoettcherSF/Ada-AC-3)** —
  Mackworth AC-3 worklist arc consistency (full algorithm)
- **[Ada-Min-Conflicts](https://github.com/RobertBoettcherSF/Ada-Min-Conflicts)** —
  min-conflicts local search / repair (N-queens, map sketch)
- **[Ada-DPLL](https://github.com/RobertBoettcherSF/Ada-DPLL)** —
  Davis–Putnam–Logemann–Loveland SAT solver (CSP→SAT forthcoming here)
- **[Ada-Difference-Map](https://github.com/RobertBoettcherSF/Ada-Difference-Map)** —
  difference-map / projection heuristics (related combinatorial search)

Educational limits: $\textit{Vars}\le 12$, $\textit{Domain}\le 8$,
$\textit{Constraints}\le 32$; N-queens demo $N\le 5$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **CSP** | $\langle X, D, C\rangle$ | Binary $\neq$ / Allowed-pairs |
| **Domains** | Membership bit-vectors over $1..D_{\max}$ | Caps above |
| **Consistency** | `Is_Consistent` on partial assignments | Ignore unassigned ends |
| **Search** | `Backtrack_Solve` / `Count_Solutions` | Optional MRV |
| **Look-ahead** | `Forward_Check_Solve` | Domain restore on backtrack |
| **Inference** | Tiny `Revise` + one-pass `AC_Filter` | Full AC-3 → sibling |
| **Local search** | `Min_Conflicts_Step` | Full solver → sibling |
| **Taxonomy** | `Method_Kind` / `Classify` | Implemented vs Forthcoming |
| **Demos** | Map colouring, N-queens ($N\le 5$) | Australia-style 7/3 |

## Formal CSP

A finite-domain CSP is a triple

$$
\langle X, D, C\rangle
$$

where $X=\{X_1,\ldots,X_n\}$ are variables, $D=\{D_1,\ldots,D_n\}$ their
domains, and $C=\{C_1,\ldots,C_m\}$ constraints. Each $C_j=\langle t_j,R_j\rangle$
restricts a scope $t_j\subseteq\{1,\ldots,n\}$ to a relation $R_j$.

An evaluation is **consistent** if it violates no constraint, **complete** if
every variable is assigned, and a **solution** if it is both.

This package stores **binary** constraints only (`Not_Equal`,
`Allowed_Pairs`). Domains are Boolean membership arrays (educational
“bitsets”).

## Search vs inference vs local search

Wikipedia-style solution techniques (often combined):

1. **Search (backtracking).** Maintain a partial assignment; choose an
   unassigned variable; try each domain value; recurse when consistent;
   backtrack when stuck. Optional **MRV** (minimum remaining values) picks
   the variable with the fewest still-legal values.
2. **Inference / propagation.** Enforce local consistency (here: a minimal
   **arc** filter). Arc consistency: every $v\in D(X_i)$ has a support
   $w\in D(X_j)$ on each arc $(X_i,X_j)$. Full Mackworth **AC-3** lives in
   the Ada-AC-3 sibling; this survey embeds `Revise` + one-pass `AC_Filter`.
3. **Local search.** Start from a complete (often inconsistent) assignment;
   repair conflicting variables. **Min-conflicts** reassigns a variable to a
   value that minimises the number of broken constraints. This package
   exposes one `Min_Conflicts_Step`; the Ada-Min-Conflicts sibling has the
   full hill-climb / restart solver.
4. **SAT encoding (forthcoming).** Compile the CSP to CNF and call a SAT
   engine (sibling Ada-DPLL). Marked `Forthcoming` in the taxonomy.

Forward checking is look-ahead search: after $X\leftarrow v$, delete values
in future neighbours that are incompatible with $v$, and fail early on empty
domains.

## API summary

| Group | Entry points |
| --- | --- |
| Domains | `Empty_Domain`, `Full_Domain`, `Domain_Size`, `Contains`, `Remove_Value` |
| Builders | `Init`, `Set_Domain`, `Add_Not_Equal`, `Add_Allowed_Pairs`, `Add_All_Different` |
| Consistency | `Is_Consistent`, `Is_Complete`, `Is_Solution`, `Satisfies` |
| Ordering | `Select_Unassigned` (optional MRV) |
| Search | `Backtrack_Solve`, `Count_Solutions`, `Forward_Check_Solve` |
| Inference | `Has_Support`, `Revise`, `AC_Filter` |
| Local | `Conflict_Count`, `Min_Conflicts_Step` |
| Demos | `Build_Map_Coloring`, `Build_Australia_Map`, `Build_N_Queens` |
| Taxonomy | `Method_Kind`, `Classify`, `Method_Name`, `Implemented`, `Forthcoming` |

## Method taxonomy

| `Method_Kind` | Status | Family |
| --- | --- | --- |
| `Backtracking` | Implemented | Search |
| `Forward_Checking` | Implemented | Search |
| `Arc_Consistency` | Implemented (tiny filter) | Inference |
| `Min_Conflicts_Local` | Implemented (one step) | Local search |
| `SAT_Encoding` | Forthcoming | Encoding |

## Complexity notes

Naïve backtracking explores a tree of size up to $O(d^n)$ in the worst case
($n$ variables, domain size $d$). Forward checking and MRV prune many
branches in practice but do not change the worst-case bound. A single
`Revise` costs $O(d^{2})$ naïvely; full AC-3 is often cited as
$O(e\,d^{3})$ for $e$ arcs.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pconstraint_satisfaction.gpr
make test   # run bin/tests — expect ALL PASSED, Fail_Count=0, Pass_Count 80+
make clean
```

No `main.adb`: `tests.adb` is the sole main. Do not push from this workspace
unless explicitly requested.

## Limits and caveats

- Caps: $n\le 12$, $d\le 8$, $m\le 32$; N-queens builder requires $N\in 1..5$.
- Binary constraints only (no global alldiff propagator — pairwise $\neq$
  network via `Add_All_Different`).
- `AC_Filter` is a **one-pass** revise of both arc directions, not a worklist
  AC-3; use Ada-AC-3 for the full algorithm.
- `Min_Conflicts_Step` repairs one variable; use Ada-Min-Conflicts for
  restarts / N-queens local search.
- SAT / CNF compilation is intentionally **not** implemented here
  (`Forthcoming` + Ada-DPLL link).
- Educational code: clarity over industrial solvers (no watched literals,
  no nogood learning, no GAC for globals).

## References

- Wikipedia: Constraint satisfaction problem; AC-3; Min-conflicts; DPLL.
- Russell & Norvig, *Artificial Intelligence: A Modern Approach* (CSP
  chapters: backtracking, inference, local search).
- Mackworth, “Consistency in networks of relations” (1977) — AC-3.
- Minton et al., min-conflicts heuristic.
