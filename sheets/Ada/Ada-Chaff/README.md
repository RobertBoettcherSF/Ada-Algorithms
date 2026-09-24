# Chaff — Ada 2023

Educational, self-contained Ada 2023 package for **Chaff-style SAT engineering**:
**two-watched-literals** Boolean Constraint Propagation (BCP) and a **VSIDS**
(Variable State Independent Decaying Sum) activity sketch on a small
DPLL-family search with chronological backtracking.

Based on Moskewicz, Madigan, Zhao, Zhang, Malik —
*Chaff: Engineering an Efficient SAT Solver*, 39th Design Automation
Conference (**DAC 2001**), and
[Wikipedia: Chaff algorithm](https://en.wikipedia.org/wiki/Chaff_algorithm).
Historical implementations include **mChaff** / **zChaff** (Princeton).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-DPLL](https://github.com/RobertBoettcherSF/Ada-DPLL)** —
  classical DPLL (eager unit / pure / split)
- **[Ada-Davis-Putnam](https://github.com/RobertBoettcherSF/Ada-Davis-Putnam)** —
  earlier Davis–Putnam resolution procedure
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: $|Vars|\le 32$, clauses $\le 128$, clause length
$\le 8$. Industrial SAT instances and full **CDCL** clause learning /
non-chronological backjumping are out of scope here (documented as
*forthcoming*); this package still implements watched BCP, VSIDS branching,
and chronological backtrack.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | CNF; literals $\pm v$ | Same caps as Ada-DPLL |
| **BCP** | Two watched literals / clause | `Init_Watches`, `Propagate` |
| **Branching** | VSIDS activity + decay | Tie-break lowest index |
| **Search** | DPLL split + chronological BT | Learning stub via bumps |
| **Result** | `Satisfiable` + `Model`, or `Unsatisfiable` | `Solve` / `Is_Satisfiable` |
| **Parser** | `From_DIMACS_Lite` | Tiny `p cnf` strings |

## History: DPLL $\rightarrow$ Chaff $\rightarrow$ CDCL

Classical **DPLL** (1961) already combines unit propagation, optional
pure-literal rules, and branching. **Chaff** (DAC 2001) kept that
backbone but engineered the hot path:

1. **Two-watched-literals** so BCP does not scan every clause on every
   assignment — each clause watches two literals; only clauses watching a
   newly falsified literal are touched.
2. **VSIDS**: per-variable activity counters bumped when variables appear
   in conflict / clause events, decayed periodically; decisions pick the
   highest activity.

Modern **CDCL** solvers add clause learning (often first-UIP) and
non-chronological backtracking on top of the same watched / VSIDS ideas.
This educational package focuses on the Chaff engineering core; a tiny
first-UIP / learned-clause path is left as a clean future extension.

## Watched literals (BCP)

For a clause $C=\ell_1\lor\cdots\lor\ell_k$ with $k\ge 2$, maintain two
watch indices $w_1,w_2$. When a watched literal becomes **false**, try to
find another non-false literal to watch. If none exists:

- the other watched literal is a **unit** (enqueue it), or
- both are false $\Rightarrow$ **conflict**.

Unary clauses are seeded onto the trail at solve start. Empty clauses
are immediate unsat.

$$
\begin{align*}
&\mathbf{on}\ \mathrm{falsify}(\ell):\quad
  \mathbf{for\ each}\ C\ \mathrm{watching}\ \ell:\\
&\quad \mathbf{if}\ \exists\ \ell'\in C.\ \ell'\ \mathrm{not\ false}\
  \mathbf{then}\ \mathrm{rewatch}(C,\ell')\\
&\quad \mathbf{else\ if}\ \mathrm{other\_watch}(C)\ \mathrm{unassigned}\\
&\quad\quad \mathbf{then}\ \mathrm{enqueue}(\mathrm{other\_watch}(C))\\
&\quad \mathbf{else}\ \mathrm{conflict}
\end{align*}
$$

## VSIDS sketch

Let $a(v)$ be the activity of variable $v$. On a conflict (or conflict-clause
context) bump variables that appear there:

$$
a(v)\leftarrow a(v)+\Delta,\qquad
a(v)\leftarrow \rho\cdot a(v)\ \text{(periodic decay)}
$$

with educational defaults $\Delta=1$ (`Bump_Amount`) and $\rho=0.95$
(`Decay_Factor`). `Choose_VSIDS` returns

$$
\arg\max_{v\ \mathrm{unassigned}} a(v)
$$

breaking ties by the smallest index $v$.

## The educational search loop

At each node:

1. **`Propagate`** — drain the trail with watched BCP.
2. On conflict — bump activities on a conflicting clause (learning stub),
   fail the branch.
3. If all clauses are satisfied — success (return model).
4. **`Choose_VSIDS`** — pick a free variable; try $\top$ then $\bot$ with
   chronological backtrack.

Pseudocode:

$$
\begin{align*}
&\mathbf{function}\ \mathrm{Search}(\\Phi,A,S):\\
&\quad \mathrm{Propagate}(\\Phi,A,S)\\
&\quad \mathbf{if}\ \mathrm{conflict}\ \mathbf{then}\
  \mathrm{bump};\ \mathbf{return}\ \mathsf{false}\\
&\quad \mathbf{if}\ \mathrm{satisfied}(\\Phi,A)\ \mathbf{then}\
  \mathbf{return}\ \mathsf{true}\\
&\quad v\leftarrow \mathrm{Choose\_VSIDS}(\\Phi,A,S)\\
&\quad \mathbf{return}\
  \mathrm{Search}(v{=}\top)\ \vee\ \mathrm{Search}(v{=}\bot)
\end{align*}
$$

## Classic examples

**Chain units.** $(a)\land(\neg a\lor b)\land(\neg b\lor c)$ — watched BCP
forces $a,b,c$ (`Build_Chain_Units`).

**Two-clause sat.** $(a\lor b)\land(\neg a\lor b)$ forces $b$
(`Build_Two_Clause_Sat`).

**Contradictory units / empty clause.** Immediate unsat.

**Small 3-SAT toys.** `Build_Small_3SAT_Sat` / `Build_Small_3SAT_Unsat`.

## API (`Chaff`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Vars`, `Max_Clauses`, `Max_Clause_Len` | Educational bounds |
| Types | `Formula`, `Clause`, `Literal`, `Assignment`, `Model`, `Solver_State` | CNF + watches + VSIDS |
| Literals | `Var_Of`, `Negate`, `Make_Literal`, `Slot_Of`, `Lit_Is_True` / `False` | $\pm v$ helpers |
| Build | `Clear`, `Set_Num_Vars`, `Add_Clause`, `From_DIMACS_Lite` | Construct CNF |
| Watches | `Init_Watches`, `Propagate`, `Enqueue`, `Watches_Invariant` | Two-watched BCP |
| VSIDS | `Bump_Activity`, `Decay_Activities`, `Choose_VSIDS`, `Get_Activity` | Branching heuristic |
| Solve | `Solve`, `Is_Satisfiable` | Full educational search |
| Examples | `Build_Two_Clause_Sat`, `Build_Chain_Units`, … | Textbooks |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Parse_Error`,
`Not_Initialized`.

Literals are signed integers in $-32..32\setminus\{0\}$: $+v$ means $v$,
$-v$ means $\neg v$. `Solve` returns `Solve_Result` with `Status` and, on
success, `Result_Model` (type `Model`) over $1..\mathit{Num\_Vars}$
(don't-care variables set to `Is_False`).

## Caveats

- **No full CDCL:** clause learning and non-chronological backjump are
  *forthcoming*; conflicts only bump activities and chronologically
  backtrack.
- **Educational caps** keep watch buckets and trails tiny; not a
  replacement for zChaff / MiniSat / Glucose / Kissat.
- **VSIDS** is a Float sketch (not the exact bit-packed Chaff counters).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- M. Moskewicz, C. Madigan, Y. Zhao, L. Zhang, S. Malik. *Chaff: Engineering
  an Efficient SAT Solver*, DAC 2001.
- [Wikipedia: Chaff algorithm](https://en.wikipedia.org/wiki/Chaff_algorithm)
- [Wikipedia: DPLL algorithm](https://en.wikipedia.org/wiki/DPLL_algorithm)
- Vizel, Weissenbacher, Malik (2015), *Boolean Satisfiability Solvers and
  Their Applications in Model Checking*, Proc. IEEE.
- Sibling: [Ada-DPLL](https://github.com/RobertBoettcherSF/Ada-DPLL)
- Sibling: [Ada-Davis-Putnam](https://github.com/RobertBoettcherSF/Ada-Davis-Putnam)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
