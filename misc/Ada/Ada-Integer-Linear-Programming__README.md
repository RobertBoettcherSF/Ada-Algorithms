# Integer Linear Programming — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Integer linear programming](https://en.wikipedia.org/wiki/Integer_linear_programming)
(*integer programming / ILP*): maximizing a linear objective over a
polyhedron with some or all variables required to be integers.

A (pure) integer linear program in **canonical** form is

$$
\begin{aligned}
\underset{x\in\mathbb{Z}^{n}}{\mathrm{maximize}}\quad & c^{\mathrm{T}}x \\
\mathrm{subject\ to}\quad & Ax\le b, \\
& x\ge 0,
\end{aligned}
$$

while **standard** form uses equalities $Ax=b$ with $x\ge 0$ (still
$x\in\mathbb{Z}^{n}$). This package works in **inequality form**
$Ax\le b$, $x\ge 0$, matching the embedded Bland tableau.

**NP-hardness.** Deciding feasibility of a 0–1 ILP is one of Karp’s
21 NP-complete problems; general ILP is NP-hard. Practical solvers rely
on LP relaxations, cutting planes, and branch-and-bound / branch-and-cut.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling solvers are
**independent** — this repo does **not** depend on them. It implements
runnable **LP relaxation** (tiny Bland simplex), **integrality-gap**
helpers, exact **0–1 knapsack DP**, and a **tiny pure branch-and-bound**
(no cuts) for binary IPs with $n\le 12$. Full Simplex / Cutting-Plane /
Branch-and-Cut / Karmarkar live in the siblings linked below.

## Problem taxonomy

| Kind | Meaning | `Classify` |
| --- | --- | --- |
| **Pure IP** | All decision vars integer | All `Required` True |
| **Binary IP (0–1)** | Vars in $\{0,1\}$ | All integer + `Binary => True` |
| **MILP** | Some continuous, some integer | Mixed `Required` flags |

Method metadata (`Method_Kind`): `Branch_And_Bound`, `Cutting_Planes`,
`Branch_And_Cut`, `Dynamic_Programming` — via `Classify_Method` /
`Method_Name` (catalog only for cut-based / full MIP frameworks).

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Helpers** | `Near`, `Frac`, `Is_Integer`, `Is_Binary`, … | Dense educational |
| **Taxonomy** | `Classify`, `Problem_Kind`, `Method_Kind`, `Classify_Method` | Metadata |
| **LP relaxation** | `Maximize_LP`, `Build_Tableau`, Bland enter/leave/`Pivot` | $Ax\le b$, $x\ge 0$ |
| **Integrality gap** | `Integrality_Gap`, `Relative_Integrality_Gap`, `Gap_From_Relaxation` | LP vs known IP |
| **Feasibility / round** | `Feasible_Inequality`, `Round_Binary`, `Round_And_Check` | Simple heuristic |
| **0–1 knapsack** | `Solve_Knapsack_01` | Exact $O(nW)$ DP |
| **Binary B&B** | `Solve_Binary_BB`, `Branch_Variable_Binary` | Pure B&B, **no cuts**, $n\le 12$ |

Caps: `Max_Problem_Vars = 12`, `Max_Problem_Rows = 16`, knapsack
$W\le 200$, $n\le 32$ items. Exceptions: `Invalid_Argument`. Public
subprograms carry `Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

## Formula summary

### LP relaxation

Drop integrality: solve $\max c^{\mathrm{T}}x$ s.t. $Ax\le b$, $x\ge 0$.
If $A$ is totally unimodular and $b$ is integer, the LP optimum is
already integer (Wikipedia: total unimodularity) — otherwise the
relaxation may be fractional.

### Integrality gap (maximization)

$$
\mathrm{gap}=z_{\mathrm{LP}}-z_{\mathrm{IP}},\qquad
\mathrm{rel\ gap}=\frac{z_{\mathrm{LP}}-z_{\mathrm{IP}}}{\max(1,|z_{\mathrm{IP}}|)}.
$$

When both optima are exact, $z_{\mathrm{LP}}\ge z_{\mathrm{IP}}$ and the
gap is nonnegative.

### 0–1 knapsack (DP special case)

$$
\max\sum_{i=1}^{n}v_i x_i
\quad\text{s.t.}\quad
\sum_{i=1}^{n}w_i x_i\le W,\quad
x_i\in\{0,1\}.
$$

Classic DP recurrence $f(i,w)=\max\bigl(f(i-1,w),\,v_i+f(i-1,w-w_i)\bigr)$.

### Tiny pure branch-and-bound (binary)

At each node solve the LP relaxation with fixed $x_j\in\{0,1\}$ bounds;
if fractional, branch on a most-fractional variable ($x_j=0$ / $x_j=1$);
prune by infeasibility or LP bound versus the incumbent. **No cutting
planes** here — see siblings for Gomory cuts and full branch-and-cut.

## Sibling solvers (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-Simplex-Algorithm](https://github.com/RobertBoettcherSF/Ada-Simplex-Algorithm) | Dense Bland two-phase tableau LP |
| [Ada-Cutting-Plane-Method](https://github.com/RobertBoettcherSF/Ada-Cutting-Plane-Method) | Gomory fractional cuts + Kelley sketch |
| [Ada-Branch-and-Cut](https://github.com/RobertBoettcherSF/Ada-Branch-and-Cut) | MILP B&B with optional Gomory cuts |
| [Ada-Karmarkars-Algorithm](https://github.com/RobertBoettcherSF/Ada-Karmarkars-Algorithm) | Interior-point LP (Karmarkar) |

## Public API (summary)

**Types:** `Real`, `Matrix`, `Vector`, `Integer_Flags`, `Binary_Vector`,
`Config`, `Result`, `Tableau`, `Status`, `Problem_Kind`, `Method_Kind`,
`Method_Info`, `Knapsack_Item`, `Knapsack_Items`, `Knapsack_Result`.

**Helpers:** `Near`, `Vec_Near`, `Frac`, `Is_Integer`, `Is_Integer_Vector`,
`Is_Binary`, `Is_Binary_Vector`, `Required_Are_Integer`.

**Taxonomy:** `Classify`, `Classify_Method`, `Method_Name`, `Problem_Name`,
`Method_Count`.

**LP:** `Build_Tableau`, `Solve_Tableau`, `Maximize_LP`, `Pivot`,
`Select_Entering`, `Select_Leaving`, `Extract_Primal`, `Is_Optimal_LP`.

**Gap / heuristic:** `Integrality_Gap`, `Relative_Integrality_Gap`,
`Gap_From_Relaxation`, `Feasible_Inequality`, `Round_Binary`,
`Binary_To_Real`, `Objective_Value`, `Round_And_Check`.

**Solvers:** `Solve_Knapsack_01`, `Solve_Binary_BB`,
`Branch_Variable_Binary`.

## Usage sketch

```ada
with Integer_Linear_Programming; use Integer_Linear_Programming;

procedure Demo is
   A : constant Matrix (1 .. 1, 1 .. 2) := [[2.0, 2.0]];
   B : constant Vector (1 .. 1) := [3.0];
   C : constant Vector (1 .. 2) := [1.0, 1.0];
   LP, IP : Result;
   Items : constant Knapsack_Items (1 .. 3) :=
     [(2, 3.0), (3, 4.0), (4, 5.0)];
   K : Knapsack_Result;
begin
   LP := Maximize_LP (A, B, C);           -- relaxation ≈ 1.5
   IP := Solve_Binary_BB (A, B, C);       -- binary opt = 1
   --  Integrality_Gap (LP.Objective, IP.Objective) = 0.5

   K := Solve_Knapsack_01 (Items, 5);     -- value 7 (items 1+2)
end Demo;
```

## Building

```bash
cd /workspace/ada-integer-linear-programming
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pinteger_linear_programming.gpr`. Expect
**zero** errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests` (14 sections, 100+ assertions). Exit status 0 and
`Fail_Count = 0` (`pragma Assert`). Binary B&B is educational ($n\le 12$);
production MIP solvers belong in the Branch-and-Cut sibling.

## Layout

```
ada-integer-linear-programming/
├── integer_linear_programming.ads   # public API
├── integer_linear_programming.adb   # implementation
├── integer_linear_programming.gpr
├── tests.adb                        # main test program
├── Makefile
├── README.md
└── .gitignore
```

Root-only layout (no `src/`, no separate `main.adb`). Exactly **seven** root
files.

## Canonical vs standard form (notes)

Wikipedia distinguishes **canonical** ($Ax\le b$, $x\ge 0$, $x\in\mathbb{Z}^{n}$)
from **standard** ($Ax=b$, $x\ge 0$). Equality systems convert to
inequalities (or vice versa with slacks). This survey’s tableau builder
accepts **inequality** form and introduces slacks / artificials internally
(two-phase Bland), same spirit as Ada-Simplex-Algorithm.

## References

1. [Wikipedia: Integer linear programming](https://en.wikipedia.org/wiki/Integer_linear_programming)
   — definition, canonical/standard form, NP-hardness, variants (MILP,
   0–1), algorithms (TU, cuts, B&B, B&C), applications.
2. [Wikipedia: Branch and bound](https://en.wikipedia.org/wiki/Branch_and_bound).
3. [Wikipedia: Cutting-plane method](https://en.wikipedia.org/wiki/Cutting-plane_method).
4. [Wikipedia: Branch and cut](https://en.wikipedia.org/wiki/Branch_and_cut).
5. [Wikipedia: Knapsack problem](https://en.wikipedia.org/wiki/Knapsack_problem)
   — 0–1 DP special case.
6. Schrijver, *Theory of Linear and Integer Programming*, Wiley.
