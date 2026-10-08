# Automated Theorem Proving (propositional SAT)

**Scope (2026-10-08 review): propositional satisfiability only.** Despite the folder name, this is
not a first-order or higher-order theorem prover. It decides whether a propositional CNF formula is
satisfiable, in three ways:

1. `Is_Satisfiable_Exhaustive`: truth-table brute force over variables 1 .. Max_Var.
2. `Is_Satisfiable_DPLL`: DPLL (unit propagation, pure literals, splitting).
3. `Is_Satisfiable_DP_Resolution`: Davis-Putnam variable elimination by resolution.

Each answers yes or no. It produces no satisfying assignment and no proof object (no resolution
refutation), so an UNSAT answer cannot be checked independently. Helpers: `Simplify_Unit_Propagation`,
`Simplify_Pure_Literal`, `Resolve_Clauses`, `Is_Tautology`, `Remove_Duplicates`.

## Tests

`make test` builds with `-gnatwa -gnat2022 -gnata` and runs `tests.adb` and the own checks
(`own_checks.adb`; sources of the expected values in `tests/SOURCES.txt`). The three deciders are
compared with each other and with a bit-mask brute force on structured all-sign-pattern formulas and
random CNFs. Mutation scores: `tools/vv/flagship_mutation_phase2.csv` (held-out 32/32).
