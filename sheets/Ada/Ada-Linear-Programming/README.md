# Linear Programming — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Linear programming](https://en.wikipedia.org/wiki/Linear_programming)
(*linear optimization / LP*): maximizing or minimizing a linear objective over
a convex polytope defined by finitely many linear inequalities.

A linear program in **canonical** (inequality) form is

$$
\begin{aligned}
\underset{x}{\mathrm{maximize}}\quad & c^{\mathrm{T}}x \\
\mathrm{subject\ to}\quad & Ax\le b, \\
& x\ge 0,
\end{aligned}
$$

while **standard** form uses equalities $Ax=b$ with $x\ge 0$. The **slack /
augmented** form converts each $\le$ row into an equality by adding a
non-negative slack variable. This package works in inequality form and builds
a dense Bland tableau with slacks (and artificials when needed).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling solvers are
**independent** — this repo does **not** depend on them. It embeds a runnable
**Bland two-phase simplex** (`Maximize` / `Minimize`), **weak duality** and
**complementary slackness** smoke helpers, form / method taxonomy, and an
optional **2-variable graphical** vertex enumerator. Full Simplex / Karmarkar /
ILP / Dantzig–Wolfe / delayed column generation live in the siblings linked
below.

## Form taxonomy

| Kind | Meaning | Helper |
| --- | --- | --- |
| **Canonical** | $Ax\le b$, $x\ge 0$ | Default input to `Build_Tableau` |
| **Standard_Equality** | $Ax=b$, $x\ge 0$ | Convert via slacks / surplus |
| **Slack** | $[A\ I][x;s]=b$, $x,s\ge 0$ | `Append_Slacks` |

Method metadata (`Method_Kind`): `Simplex`, `Interior_Point`, `Ellipsoid`,
`Dual_Simplex` — via `Classify_Method` / `Method_Name`. Only **Simplex** is
fully implemented here (flags for the rest).

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Helpers** | `Near`, `Vec_Near`, `Dot`, `Objective_Value` | Dense educational |
| **Taxonomy** | `Form_Kind`, `Method_Kind`, `Classify_Method` | Metadata |
| **Form / feasibility** | `Append_Slacks`, `Primal_Slack`, `Feasible_Inequality`, `Dual_Feasible` | $\le$ → equality |
| **Simplex** | `Maximize`, `Minimize`, `Build_Tableau`, Bland enter/leave/`Pivot` | $Ax\le b$, $x\ge 0$ |
| **Duality** | `Weak_Duality_Holds`, `Complementary_Slackness_Holds`, `Duality_Gap` | Symmetric max-form |
| **Graphical 2-D** | `Feasible_Vertices_2D`, `Best_Vertex`, `Evaluate_At` | Polygon vertices |

Caps: `Max_Constraints = 16`, `Max_Vars = 32` (incl. slacks/artificials),
`Max_Vertices = 24`. Exceptions: `Invalid_Argument`. Public subprograms carry
`Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

## Formula summary

### Weak duality (symmetric max-form)

Primal $\max c^{\mathrm{T}}x$ s.t. $Ax\le b$, $x\ge 0$; dual
$\min b^{\mathrm{T}}y$ s.t. $A^{\mathrm{T}}y\ge c$, $y\ge 0$. For any feasible
pair $(x,y)$:

$$
c^{\mathrm{T}}x \le b^{\mathrm{T}}y.
$$

The **duality gap** is $b^{\mathrm{T}}y - c^{\mathrm{T}}x$ (zero at a jointly
optimal pair).

### Complementary slackness

With primal slacks $w=b-Ax$ and dual slacks $z=A^{\mathrm{T}}y-c$, a feasible
pair is optimal iff

$$
x_j z_j = 0\quad(j=1,\ldots,n),\qquad
w_i y_i = 0\quad(i=1,\ldots,m).
$$

### Bland two-phase simplex

Phase I drives artificial variables to zero (feasibility); Phase II maximizes
the original objective. Entering column: smallest index with reduced cost
$< -\mathrm{Tol}$. Leaving row: min-ratio with Bland tie-break on basic index.

### Graphical method (2 variables)

Vertices of $\{x\in\mathbb{R}^{2}:Ax\le b,\,x\ge 0\}$ arise as intersections of
binding constraint lines (including the axes). The optimum of a linear
objective over a nonempty bounded polytope is attained at a vertex.

## Sibling solvers (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-Simplex-Algorithm](https://github.com/RobertBoettcherSF/Ada-Simplex-Algorithm) | Dense Bland two-phase tableau LP |
| [Ada-Karmarkars-Algorithm](https://github.com/RobertBoettcherSF/Ada-Karmarkars-Algorithm) | Interior-point LP (Karmarkar) |
| [Ada-Integer-Linear-Programming](https://github.com/RobertBoettcherSF/Ada-Integer-Linear-Programming) | ILP / MILP survey (B&B, knapsack DP) |
| [Ada-Dantzig-Wolfe-Decomposition](https://github.com/RobertBoettcherSF/Ada-Dantzig-Wolfe-Decomposition) | Block-angular LP / column generation |
| [Ada-Delayed-Column-Generation](https://github.com/RobertBoettcherSF/Ada-Delayed-Column-Generation) | Delayed column generation / cutting stock |

## Public API (summary)

**Types:** `Real`, `Matrix`, `Vector`, `Config`, `Result`, `Tableau`, `Status`,
`Form_Kind`, `Method_Kind`, `Method_Info`, `Point2`, `Vertex_List`.

**Helpers:** `Near`, `Vec_Near`, `Dot`, `Objective_Value`, `Mat_Vec`,
`Mat_T_Vec`, `Is_Nonnegative`.

**Taxonomy:** `Classify_Method`, `Method_Name`, `Form_Name`, `Method_Count`,
`Form_Count`.

**Form / feasibility:** `Append_Slacks`, `Slack_Column_Count`, `Primal_Slack`,
`Dual_Slack`, `Feasible_Inequality`, `Dual_Feasible`.

**LP:** `Build_Tableau`, `Solve_Tableau`, `Maximize`, `Minimize`, `Pivot`,
`Select_Entering`, `Select_Leaving`, `Extract_Primal`, `Is_Optimal_LP`.

**Duality:** `Weak_Duality_Holds`, `Complementary_Slackness_Holds`,
`Duality_Gap`.

**Graphical:** `Feasible_Vertices_2D`, `Best_Vertex`, `Evaluate_At`.

## Usage sketch

```ada
with Linear_Programming; use Linear_Programming;

procedure Demo is
   A : constant Matrix (1 .. 3, 1 .. 2) :=
     [[1.0, 0.0], [0.0, 2.0], [3.0, 2.0]];
   B : constant Vector (1 .. 3) := [4.0, 12.0, 18.0];
   C : constant Vector (1 .. 2) := [3.0, 5.0];
   R : Result;
   Y : constant Vector (1 .. 3) := [0.0, 1.5, 1.0];  -- example dual
   V : Vertex_List;
begin
   R := Maximize (A, B, C);           -- opt (2,6), z = 36
   V := Feasible_Vertices_2D (A, B);  -- polygon vertices
   --  Weak_Duality_Holds (A, B, C, R.X (1 .. 2), suitable_Y)
end Demo;
```

## Building

```bash
cd /workspace/ada-linear-programming
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Plinear_programming.gpr`. Expect
**zero** errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests` (15 sections, 100+ assertions). Exit status 0 and
`Fail_Count = 0` (`pragma Assert`). Caps are educational; production LP
solvers belong in the Simplex / Karmarkar siblings.

## Layout

```
ada-linear-programming/
├── linear_programming.ads   # public API
├── linear_programming.adb   # implementation
├── linear_programming.gpr
├── tests.adb                # main test program
├── Makefile
├── README.md
└── .gitignore
```

Root-only layout (no `src/`, no separate `main.adb`). Exactly **seven** root
files.

## Caveats

- Dense tableau only; $m,n$ tiny (`Max_Constraints=16`, `Max_Vars=32`).
- `Interior_Point` / `Ellipsoid` / `Dual_Simplex` are **taxonomy flags** — not
  implemented (see Ada-Karmarkars-Algorithm for an interior-point sibling).
- Complementary slackness helper is a **smoke check** (products near zero); it
  does not by itself prove optimality without feasibility.
- Graphical helper is 2-D only and may miss / duplicate vertices under
  degeneracy; it caps at `Max_Vertices`.
- Floating-point tolerances (`Tol`, `Epsilon_Tol`) matter near degeneracy.

## References

1. [Wikipedia: Linear programming](https://en.wikipedia.org/wiki/Linear_programming)
   — standard/canonical/slack form, duality, complementary slackness,
   simplex / ellipsoid / interior-point algorithms.
2. Dantzig, G. B. — simplex method (1947); Bland’s anti-cycling rule.
3. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
