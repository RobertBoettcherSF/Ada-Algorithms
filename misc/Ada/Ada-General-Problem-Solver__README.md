# General Problem Solver (GPS) — Ada 2023

Educational, self-contained Ada 2023 package implementing a **classic
means–ends analysis** planner in the spirit of Newell, Shaw, and Simon’s
**General Problem Solver** (1957/1959). States are compact bitsets of
boolean conditions; operators are STRIPS-like (preconditions, add-list,
delete-list) with an optional preferred difference; an ordered difference
table guides which gap to reduce next. This is a teaching subset — not a
full historical GPS / IPL replica — but faithful to the means–ends idea.

Based on [Wikipedia: General Problem Solver](https://en.wikipedia.org/wiki/General_Problem_Solver).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Alpha-Beta-Pruning](https://github.com/RobertBoettcherSF/Ada-Alpha-Beta-Pruning)** —
  adversarial tree search with windows
- **[Ada-Tabu-Search](https://github.com/RobertBoettcherSF/Ada-Tabu-Search)** —
  metaheuristic local search with short-term memory

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Means–ends analysis | Reduce most important difference |
| **State** | Bitset (`State` mod $2^{32}$) | Up to 32 conditions |
| **Operators** | Preconditions / add / delete | STRIPS-like |
| **Priority** | `Difference_Order` table | Most important first |
| **Core** | Recursive `Solve` | Depth-bounded GPS |
| **Check** | `Execute_Plan` / `Plan_Reaches_Goal` | Simulate found plans |
| **Fixtures** | School + blocks lite | Textbook demos |

## Brief history

Herbert A. Simon, J. C. Shaw, and Allen Newell (RAND) introduced GPS as a
universal problem-solving engine that **separated** problem knowledge
(operators as data) from a generic search strategy. Unlike the earlier
Logic Theorist, GPS used **means–ends analysis**: compare the current
state to the goal, identify differences, and select operators that reduce
the most important difference — recursively achieving operator
preconditions as subgoals. GPS inspired later architectures such as Soar.
On large domains the combinatorial explosion limited practicality; this
package stays on tiny discrete toys for clarity.

## Means–ends analysis

Given current state $S$ and goal conditions $G$, the **difference mask**
is the set of goal bits still missing:

$$
\Delta(S,G) = G \land \neg S.
$$

Goal satisfaction is subset semantics:

$$
\mathrm{satisfied}(S,G) \iff (S \land G) = G.
$$

An operator $o$ has precondition mask $P_o$, add-list $A_o$, and
delete-list $D_o$. It is applicable when $P_o \subseteq S$, and its
effect is:

$$
\mathrm{apply}(S,o) = (S \land \neg D_o) \lor A_o.
$$

GPS loops while $\Delta(S,G) \ne \emptyset$: pick the highest-priority
difference $d$ from an ordered table, try operators that **reduce** $d$
(preferred `Reduces` field or $d \in A_o$), recursively achieve $P_o$,
then apply $o$ and append it to the plan. A depth bound detects
failure / loops; backtracking undoes failed branches.

## Classic school domain

The package embeds the textbook **“drive son to school”** toy (Norvig /
Newell–Simon style):

| Id | Condition |
| --- | --- |
| 1 | son-at-home |
| 2 | son-at-school |
| 3 | car-works |
| 4 | car-needs-battery |
| 5 | have-money |
| 6 | have-phone-book |
| 7 | know-phone-number |
| 8 | in-communication-with-shop |
| 9 | shop-knows-problem |
| 10 | shop-has-money |

**Start:** son-at-home, car-needs-battery, have-money, have-phone-book.
**Goal:** son-at-school.

Operators chain look-up-number → telephone-shop → tell-shop-problem,
give-shop-money, shop-installs-battery, then drive-son-to-school.
`School_Operators` / `School_Start` / `School_Goal` build the fixture;
`Solve` returns a plan that `Plan_Reaches_Goal` confirms.

A smaller **blocks-world lite** (on-table → held → on-target) is also
included for short demos.

## API (`General_Problem_Solver`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `State`, `Operator`, `Operator_List`, `Plan_Array`, `Difference_Order` | Domain |
| Bits | `Bit`, `Has`, `Set_Bit`, `Clear_Bit`, `Make_State`, `Count_Bits` | State algebra |
| Goals | `Goal_Satisfied`, `Difference_Mask`, `Is_Subset` | Means–ends primitives |
| Ops | `Applicable`, `Apply`, `Reduces_Difference`, `Operator_Valid` | STRIPS apply |
| Order | `Ranked_Differences`, `Empty_Order` | Priority table |
| Search | `Solve` | Recursive GPS planner |
| Check | `Execute_Plan`, `Plan_Reaches_Goal` | Simulate plans |
| School | `School_*`, condition / op constants | Drive-to-school fixture |
| Blocks | `Blocks_*`, `Pickup_Op` / `Stack_Op` / … | Tiny blocks fixture |

`Solve (Start, Goal, Ops, Plan, Length, Max_Depth, Order)` returns
`Boolean`, writes operator indices into `Plan (1 .. Length)`, and raises
`Invalid_Argument` on illegal `Reduces` values or an undersized
`Plan_Array`.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pgeneral_problem_solver.gpr
make test   # run bin/tests — expect ALL TESTS PASSED, Pass_Count ≥ 100
make clean
```

Root layout (exactly seven tracked source/project files; **no** `main.adb`):

`.gitignore`, `Makefile`, `README.md`, `general_problem_solver.ads`,
`general_problem_solver.adb`, `general_problem_solver.gpr`, `tests.adb`.

## Caveats

- Educational finite domains only — not a real-world planner.
- No protection against operator sets that thrash without a depth bound;
  always set a sensible `Max_Depth`.
- Difference ordering strongly affects which plan is found first; many
  plans may exist.
- Goal semantics are **subset** (extra true conditions are allowed).
- Not a byte-for-byte reconstruction of GPS-2-2 / IPL; means–ends only.

## References

- [Wikipedia: General Problem Solver](https://en.wikipedia.org/wiki/General_Problem_Solver)
- Newell, A.; Shaw, J. C.; Simon, H. A. (1959). *Report on a general
  problem-solving program.*
- Newell, A.; Simon, H. A. (1972). *Human Problem Solving.*
- Ernst, G. W.; Newell, A. (1969). *GPS: A Case Study in Generality and
  Problem Solving.*
- Sibling packages: Ada-Alpha-Beta-Pruning, Ada-Tabu-Search
