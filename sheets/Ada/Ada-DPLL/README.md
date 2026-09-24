# DPLL — Ada 2023

Educational, self-contained Ada 2023 implementation of the classical
**Davis–Putnam–Logemann–Loveland (DPLL)** algorithm for **CNF-SAT**:
unit propagation to fixpoint, optional **pure-literal elimination**,
and branching backtracking that returns a satisfying **model** or
unsatisfiable.

Based on [Wikipedia: DPLL algorithm](https://en.wikipedia.org/wiki/DPLL_algorithm).
Related: [Davis–Putnam algorithm](https://en.wikipedia.org/wiki/Davis%E2%80%93Putnam_algorithm)
(resolution / DP, 1960).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Davis-Putnam](https://github.com/RobertBoettcherSF/Ada-Davis-Putnam)** —
  earlier Davis–Putnam (resolution) procedure (*forthcoming* later in the sheet)
- **[Ada-Chaff](https://github.com/RobertBoettcherSF/Ada-Chaff)** —
  Chaff-style watched literals / VSIDS modernisation (*forthcoming*)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: $|Vars|\le 32$, clauses $\le 128$, clause length
$\le 8$. Industrial SAT instances are intentionally out of scope — use
modern CDCL solvers (or the forthcoming Chaff sibling for watched-literal
ideas).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | CNF as clause list; literals $\pm v$ | Caps above |
| **Unit rule** | Eager propagate to fixpoint | Cascades of units |
| **Pure rule** | Polarity scan on open clauses | Preferred educational |
| **Search** | Branch on smallest open var | Copy assignment + backtrack |
| **Result** | `Satisfiable` + `Model`, or `Unsatisfiable` | Total model on success |
| **Parser** | `From_DIMACS_Lite` | Tiny `p cnf` strings |

## History: DP $\rightarrow$ DPLL

Davis and Putnam (1960) gave a **resolution**-based decision procedure for
propositional CNF (often called **DP**). In 1961 Davis, Logemann and
Loveland replaced the resolution step with **splitting** (branch on a
literal) plus simplification — the **DPLL** / DLL family used by almost
all modern SAT solvers as the backbone of **CDCL**.

DPLL decides satisfiability of a formula $\Phi$ in **conjunctive normal
form** (CNF): a conjunction of **clauses**, each a disjunction of
**literals** $v$ or $\neg v$.

## The algorithm

At each node:

1. **Unit propagation.** If a clause has exactly one unassigned literal
   and all others are false, that literal is forced. Repeat to fixpoint.
2. **Pure-literal elimination.** If variable $v$ occurs with only one
   polarity among still-unsatisfied clauses, assign it to satisfy those
   clauses.
3. **Success / failure.** Empty clause (or conflict under the partial
   assignment) $\Rightarrow$ unsat branch. All clauses satisfied
   $\Rightarrow$ sat (return model).
4. **Split.** Choose an unassigned variable $v$; try $v=\top$ then
   $v=\bot$ with backtracking.

Pseudocode sketch (Wikipedia-style):

$$
\begin{align*}
&\mathbf{function}\ \mathrm{DPLL}(\Phi):\\
&\quad \Phi \leftarrow \mathrm{unit\text{-}propagate}(\Phi)\\
&\quad \Phi \leftarrow \mathrm{pure\text{-}literal\text{-}assign}(\Phi)\\
&\quad \mathbf{if}\ \Phi=\emptyset\ \mathbf{then\ return}\ \mathsf{true}\\
&\quad \mathbf{if}\ \square\in\Phi\ \mathbf{then\ return}\ \mathsf{false}\\
&\quad \ell \leftarrow \mathrm{choose\text{-}literal}(\Phi)\\
&\quad \mathbf{return}\ \mathrm{DPLL}(\Phi\land\{\ell\})\ \vee\ \mathrm{DPLL}(\Phi\land\{\neg\ell\})
\end{align*}
$$

Unit propagation on literal $\ell$ removes every clause containing $\ell$
and deletes $\neg\ell$ from the rest — equivalently, in this package, we
keep the clause list fixed and maintain an **assignment** array
(`Unassigned` / `Is_False` / `Is_True`).

## Classic examples

**Satisfiable two-clause.** $(a\lor b)\land(\neg a\lor b)$ forces $b$
(and leaves $a$ free). Encoded as `Build_Two_Clause_Sat`.

**Contradictory units.** $(a)\land(\neg a)$ — unit propagation alone
proves unsatisfiable.

**Empty clause / empty formula.** A clause with no literals is
immediately unsat; a formula with no clauses is vacuously sat.

**Small 3-SAT toys.** `Build_Small_3SAT_Sat` / `Build_Small_3SAT_Unsat`
(pairwise “all equal and unequal” style contradiction on three variables).

## API (`DPLL`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Vars`, `Max_Clauses`, `Max_Clause_Len` | Educational bounds |
| Types | `Formula`, `Clause`, `Literal`, `Assignment`, `Model` | CNF + partial assign |
| Literals | `Var_Of`, `Negate`, `Make_Literal`, `Lit_Is_True` / `False` | $\pm v$ helpers |
| Build | `Clear`, `Set_Num_Vars`, `Add_Clause`, `From_DIMACS_Lite` | Construct CNF |
| Query | `Unit_Literal`, `Clause_Is_Conflict`, `Model_Satisfies` | Educational probes |
| Steps | `Unit_Propagate`, `Pure_Literals`, `Eliminate_Pures`, `Choose_Variable` | DPLL rules |
| Solve | `Solve`, `Is_Satisfiable` | Full search |
| Examples | `Build_Two_Clause_Sat`, `Build_Contradictory_Units`, … | Textbooks |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Parse_Error`.

Literals are signed integers in $-32..32\setminus\{0\}$: $+v$ means $v$,
$-v$ means $\neg v$. `Solve` returns `Solve_Result` with `Status` and, on
success, `Result_Model` (type `Model`) over `1 .. Num_Vars` (don't-care
variables set to `Is_False`).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: DPLL algorithm](https://en.wikipedia.org/wiki/DPLL_algorithm)
- [Wikipedia: Davis–Putnam algorithm](https://en.wikipedia.org/wiki/Davis%E2%80%93Putnam_algorithm)
- [Wikipedia: Boolean satisfiability problem](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem)
- M. Davis, H. Putnam (1960); M. Davis, G. Logemann, D. Loveland (1961)
- Sibling (forthcoming): [Ada-Davis-Putnam](https://github.com/RobertBoettcherSF/Ada-Davis-Putnam)
- Sibling (forthcoming): [Ada-Chaff](https://github.com/RobertBoettcherSF/Ada-Chaff)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.

## SPARK / GNATprove (Level 2)

`SPARK_Mode => On` on the package. Exception-raising builders/parsers
(`Set_Num_Vars`, `Add_Clause`, `From_DIMACS_Lite`, `Build_*`) and the
recursive search core (`Solve`, `DPLL_Search`, `Pure_Literals`,
`Eliminate_Pures`, `Choose_Variable`, `Is_Satisfiable`) are
`SPARK_Mode => Off` (exceptions / termination). Flow-safe literal and
clause queries plus `Unit_Propagate` remain in SPARK.

```bash
make prove   # gnatprove --level=2
```

**Bar:** Level 2, all SPARK-analyzed checks proved (56/56 at last run).
`make test` stays green (`-gnatwa`).

