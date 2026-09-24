# Davis–Putnam (DP) — Ada 2023

Educational, self-contained Ada 2023 implementation of the classical
**Davis–Putnam (DP, 1960)** **resolution**-based decision procedure for
**CNF-SAT**: the **unit / one-literal rule**, the **pure-literal rule**,
and **variable elimination by resolution**, with tiny educational caps so
resolution blow-up aborts cleanly (`Failed`) instead of exhausting memory.

Based on [Wikipedia: Davis–Putnam algorithm](https://en.wikipedia.org/wiki/Davis%E2%80%93Putnam_algorithm).
This package implements the **propositional** SAT step (often called the
Davis–Putnam *procedure*), not the full first-order Herbrand enumeration.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-DPLL](https://github.com/RobertBoettcherSF/Ada-DPLL)** —
  DPLL (1961): refined DP with **splitting / backtracking** instead of
  resolution (returns a model)
- **[Ada-Chaff](https://github.com/RobertBoettcherSF/Ada-Chaff)** —
  Chaff-style watched literals / VSIDS modernisation (*forthcoming*)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: $|Vars|\le 16$, clauses $\le 64$, clause length
$\le 8$, and at most $96$ resolvents in one elimination step. Industrial
SAT instances are intentionally out of scope — use modern CDCL solvers
(or the DPLL / forthcoming Chaff siblings for search-based ideas).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | CNF as clause list; literals $\pm v$ | Caps above |
| **Unit rule** | Rewrite: delete clauses with $\ell$, drop $\neg\ell$ | To fixpoint |
| **Pure rule** | Delete clauses containing a pure literal | Polarity scan |
| **Search** | Eliminate chosen $p$ by **resolution** | No backtracking |
| **Result** | `Satisfiable` / `Unsatisfiable` / `Failed` | No model (contrast DPLL) |
| **Parser** | `From_DIMACS_Lite` | Tiny `p cnf` strings |

## History: DP (1960) $\rightarrow$ DPLL (1961)

Davis and Putnam (1960) gave a **resolution**-based decision procedure for
propositional CNF. In 1961 Davis, Logemann and Loveland replaced the
resolution elimination step with **splitting** (branch on a literal) plus
simplification — **DPLL** — which needs only linear memory in the worst
case and is the backbone of modern **CDCL** solvers.

**Educational contrast:** this package **rewrites the clause set** and may
suffer **exponential blow-up** in the number of clauses; [Ada-DPLL](https://github.com/RobertBoettcherSF/Ada-DPLL)
keeps the clause list fixed, maintains an **assignment**, and **backtracks**.
There is **no** `with` of the DPLL package — siblings are README links only.

DP decides satisfiability of a formula $\Phi$ in **conjunctive normal
form** (CNF): a conjunction of **clauses**, each a disjunction of
**literals** $v$ or $\neg v$.

## The algorithm

At each step the working formula is **equisatisfiable** (not necessarily
equivalent) to the input:

1. **Unit / one-literal rule.** If $(\ell)\in\Phi$, delete every clause
   containing $\ell$ and delete $\neg\ell$ from the remaining clauses.
   Repeat to fixpoint.
2. **Pure-literal rule.** If variable $v$ occurs with only one polarity,
   delete every clause containing that pure literal.
3. **Success / failure.** No clauses left $\Rightarrow$ **SAT**. Empty
   clause $\square$ $\Rightarrow$ **UNSAT**.
4. **Eliminate variable $p$.** For every clause $C\ni p$ and $D\ni\neg p$,
   add the resolvent $(C\setminus\{p\})\cup(D\setminus\{\neg p\})$
   (skip **tautologies**). Then **remove** all clauses mentioning $p$.
   If the number of candidate resolvents exceeds `Max_Resolvents`, or the
   rebuilt formula would exceed `Max_Clauses`, return **`Failed`**.

Pseudocode sketch:

$$
\begin{align*}
&\mathbf{function}\ \mathrm{DP}(\Phi):\\
&\quad \mathbf{while}\ \mathsf{true}\ \mathbf{do}\\
&\quad\quad \Phi \leftarrow \mathrm{unit\text{-}rule}^*(\Phi)\\
&\quad\quad \Phi \leftarrow \mathrm{pure\text{-}literal\text{-}rule}^*(\Phi)\\
&\quad\quad \mathbf{if}\ \Phi=\emptyset\ \mathbf{then\ return}\ \mathsf{SAT}\\
&\quad\quad \mathbf{if}\ \square\in\Phi\ \mathbf{then\ return}\ \mathsf{UNSAT}\\
&\quad\quad p \leftarrow \mathrm{choose\text{-}variable}(\Phi)\\
&\quad\quad \Phi \leftarrow \mathrm{resolve\text{-}eliminate}(\Phi,p)\\
&\quad\quad \mathbf{if}\ \mathrm{blow\text{-}up}\ \mathbf{then\ return}\ \mathsf{Failed}
\end{align*}
$$

Resolution of $C\lor p$ with $D\lor\neg p$ yields $C\lor D$ (after
dropping $p$/$\neg p$). Worst-case size growth is on the order of
$|\{C:p\in C\}|\cdot|\{D:\neg p\in D\}|$ — hence the hard educational caps.

## Classic examples

**Satisfiable two-clause.** $(a\lor b)\land(\neg a\lor b)$ — unit/elim
forces $b$. Encoded as `Build_Two_Clause_Sat`.

**Contradictory units.** $(a)\land(\neg a)$ — unit rule alone yields
$\square$.

**Empty clause / empty formula.** $\square$ is immediately unsat; a
formula with no clauses is vacuously sat.

**Pure-only.** $(a\lor b)\land(a\lor\neg b)$ — $a$ is pure; pure rule
deletes both clauses $\Rightarrow$ sat.

**Blow-up guard.** `Build_Blowup_Risk` builds a $10\times 10$ pivot
pattern (plus anti-pure partner clauses so the pure rule cannot clear the
formula first) so `Eliminate_Variable` / `Solve` return `Failed` when
caps are exceeded.

## API (`Davis_Putnam`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Vars`, `Max_Clauses`, `Max_Clause_Len`, `Max_Resolvents` | Educational bounds |
| Types | `Formula`, `Clause`, `Literal`, `Status` | CNF + result |
| Literals | `Var_Of`, `Negate`, `Make_Literal`, `Clause_Contains` | $\pm v$ helpers |
| Build | `Clear`, `Set_Num_Vars`, `Add_Clause`, `From_DIMACS_Lite` | Construct CNF |
| Query | `Find_Unit_Literal`, `Find_Pure_Literal`, `Has_Empty_Clause` | Educational probes |
| Steps | `Unit_Propagate_Rule`, `Pure_Literal_Rule`, `Eliminate_Variable` | DP rules |
| Resolve | `Resolve_Clauses` | Single resolvent (+ tautology flag) |
| Solve | `Solve`, `Is_Satisfiable` | Full procedure |
| Examples | `Build_Two_Clause_Sat`, `Build_Contradictory_Units`, … | Textbooks |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Parse_Error`.

Literals are signed integers in $-16..16\setminus\{0\}$: $+v$ means $v$,
$-v$ means $\neg v$. `Solve` works on a **copy** (caller formula unchanged)
and returns `Status` only — **no model** (see Ada-DPLL for models).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: Davis–Putnam algorithm](https://en.wikipedia.org/wiki/Davis%E2%80%93Putnam_algorithm)
- [Wikipedia: DPLL algorithm](https://en.wikipedia.org/wiki/DPLL_algorithm)
- [Wikipedia: Boolean satisfiability problem](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem)
- M. Davis, H. Putnam (1960), *A Computing Procedure for Quantification Theory*, JACM
- M. Davis, G. Logemann, D. Loveland (1962), *A Machine Program for Theorem Proving*, CACM
- Sibling: [Ada-DPLL](https://github.com/RobertBoettcherSF/Ada-DPLL)
- Sibling (forthcoming): [Ada-Chaff](https://github.com/RobertBoettcherSF/Ada-Chaff)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
