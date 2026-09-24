# Branch and Cut — Ada 2023

Educational, self-contained Ada 2023 package implementing **branch and cut**
for small dense mixed-integer linear programs (MILPs):

1. **Embedded Bland two-phase tableau simplex** for each node LP relaxation
   (sibling ideas only — **no** `with`-clause dependency).
2. Optional **Gomory fractional cuts** at the root / local nodes
   (`Max_Cuts_Per_Node`; set to $0$ to disable).
3. **Branch-and-bound**: pick a fractional integer-required variable, branch
   $x_j \le \lfloor x_j\rfloor$ and $x_j \ge \lceil x_j\rceil$; FIFO or
   best-bound node queue; prune by infeasibility or LP upper bound versus
   the incumbent.

Caps: original $n,m\le 10$. Educational `Max_Nodes` budget.

Based on [Wikipedia: Branch and cut](https://en.wikipedia.org/wiki/Branch_and_cut).

Sibling packages (README links only):
**[Ada-Cutting-Plane-Method](../ada-cutting-plane-method/)**,
**[Ada-Simplex-Algorithm](../ada-simplex-algorithm/)**.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **MILP** | $\max c^\top x$ s.t. $Ax\le b$, $x\ge 0$, some $x_j\in\mathbb{Z}$ | Dense educational |
| **Node LP** | Embedded Bland two-phase tableau | Same spirit as Ada-Simplex |
| **Cuts** | Gomory fractional (optional, local) | Few per node |
| **Branch** | Most-fractional integer var | Bound rows via `Apply_Bound` |
| **Queue** | FIFO or best-bound | `Use_Best_Bound` |
| **Status** | `Optimal` / `Infeasible` / `Node_Limit` | Plus $x$, nodes, cuts |
| **Limits** | $n,m\le 10$ | Tableau room for bounds/cuts |

## Brief history

**Branch and cut** combines **branch and bound** (Land–Doig / Dakin) with
**cutting planes** (Gomory and later MIP cuts). Modern MIP solvers (CPLEX,
Gurobi, SCIP, CBC, …) are dominated by this framework: solve the LP
relaxation, add cuts that remove fractional solutions without cutting off
integer points, and branch when the relaxation remains fractional.

If cuts are used only at the root before branching, the hybrid is sometimes
called **cut and branch**. This package may add a few local Gomory cuts at
each node (`Max_Cuts_Per_Node`).

## Algorithm sketch

Given

$$
\max_x\; c^\top x
\quad\text{subject to}\quad
Ax\le b,\quad x\ge 0,\quad
x_j\in\mathbb{Z}\ \text{for selected }j,
$$

maintain a queue $L$ of bound-restricted subproblems and a global incumbent
$(x^*,v^*)$ (best integer-feasible objective for maximization, initially
$v^*=-\infty$).

While $L$ is nonempty and the node budget remains:

1. Dequeue a node (FIFO or largest estimated LP bound).
2. Build the LP relaxation with the original rows plus bound inequalities
   from `Apply_Bound`, and solve with the embedded simplex.
3. If infeasible, or if the LP value $v\le v^*$, **prune**.
4. Optionally separate a few **Gomory fractional cuts** from fractional
   basic rows, dual-restore, and reoptimize.
5. If all integer-required components of $x$ are integral, update the
   incumbent and prune.
6. Otherwise pick a branch variable $x_j$ (most fractional), and enqueue
   children with $x_j\le\lfloor x_j\rfloor$ and $x_j\ge\lceil x_j\rceil$.

Return $x^*$ or report infeasible / node-limit.

### Classic example

$$
\max\; x+y
\quad\text{s.t.}\quad
2x+2y\le 3,\quad x,y\ge 0\text{ integer}.
$$

LP relaxation optimum $1.5$; integer optimum $1$ at $(1,0)$ or $(0,1)$.

## API summary

| Symbol | Role |
| --- | --- |
| `Config` | `Max_Nodes`, `Max_Pivots`, `Max_Cuts_Per_Node`, `Tol`, `Integer_Tol`, `Use_Best_Bound` |
| `Result` | `Stat`, `Objective`, `X`, `N_Vars`, `Nodes`, `Cuts`, `Success` |
| `Solve` | Branch-and-cut MILP driver |
| `Maximize_LP` | Embedded Bland LP only |
| `Branch_Variable` | Most-fractional integer-required index |
| `Apply_Bound` | Append bound rows $x_j\le H_j$, $-x_j\le -L_j$ |
| `Near` / `Is_Integer` / `Frac` | Numeric helpers |
| `Gomory_Cut_From_Row` / `Add_Gomory_Cut` | Optional local cuts |
| `Required_Are_Integer` | Check integer-required components |

Tableau helpers (`Build_Tableau`, `Pivot`, `Select_Entering`, …) mirror the
sibling simplex layout for tests and education.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT (`gnatmake`) with `-gnatwa -gnat2022`. The test binary is the
only main (`tests.adb`); there is no `main.adb`. Expect `Fail_Count=0` and
`Pass_Count` well above $100$.

## Caveats

- Dense tableau, tiny problems only ($n,m\le 10$); not a production MIP solver.
- Gomory cuts are a numerical sketch (few per node, **pure IP only** — skipped
  when any decision variable is continuous); no MIR/GMI/lift-and-project cut
  library, no presolve, no heuristics beyond incumbent updates.
- Unbounded LP rays at a node are treated as prune/infeasible for this
  bounded educational MILP setting (`No_Upper` sentinel for open upper bounds).
- Local cuts are **not** inherited by children (each node rebuilds from
  original rows + its own variable bounds).

## License

Educational reference code for the Ada algorithm series.
