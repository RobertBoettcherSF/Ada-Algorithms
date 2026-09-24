# Difference-Map Algorithm — Ada 2023

Educational, self-contained Ada 2023 implementation of **Veit Elser's
difference-map algorithm**: an iterative dynamical system built from two
projectors $P_A$ and $P_B$ onto constraint sets $A$ and $B$. Solutions of the
set-intersection problem $x \in A \cap B$ are encoded as **fixed points** of
the map. The package is a meta-algorithm for general **constraint satisfaction
problems (CSPs)** in the incomplete sense — it can efficiently verify a
candidate once found, but cannot prove that no solution exists.

Based on [Wikipedia: Difference-map algorithm](https://en.wikipedia.org/wiki/Difference-map_algorithm).
Related: [Douglas–Rachford algorithm](https://en.wikipedia.org/wiki/Douglas%E2%80%93Rachford_algorithm),
[Projection (linear algebra) / metric projection](https://en.wikipedia.org/wiki/Projection_(linear_algebra)),
[Constraint satisfaction problem](https://en.wikipedia.org/wiki/Constraint_satisfaction_problem).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Min-Conflicts](https://github.com/RobertBoettcherSF/Ada-Min-Conflicts)** —
  min-conflicts hill climbing for CSPs (discrete local search)
- **[Ada-Local-Search](https://github.com/RobertBoettcherSF/Ada-Local-Search)** —
  broader local-search taxonomy (hill climbing, restarts, 2-opt)
- **[Ada-DPLL](https://github.com/RobertBoettcherSF/Ada-DPLL)** —
  classical DPLL for CNF-SAT (complete branching search)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: dimension $\mathrm{Dim} \le 16$, iteration budget
$\le 10\,000$ (`Max_Iter`). Toy `Float` (`digits 15`) vectors only — not a
production phase-retrieval or packing solver.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Problem** | Find $x \in A \cap B$ via projectors | Incomplete CSP meta-algorithm |
| **Update** | Elser difference map $D$ with parameter $\beta$ | Fixed points encode solutions |
| **Monitor** | Residual $\Delta = \|P_A(f_B(x)) - P_B(f_A(x))\|_2$ | Stop when $\Delta \le \mathrm{Tol}$ |
| **Projectors** | Box, ball/sphere, orthant, hyperplane | Required educational toys |
| **Contrast** | Alternating projections; Douglas–Rachford; averaged | Convex teaching maps |
| **API** | `Difference_Map_Step`, `Iterate_Difference_Map`, … | See table below |

## History and scope

Elser's difference map generalizes **Fienup's hybrid input–output (HIO)**
method for phase retrieval and the **Douglas–Rachford** iteration for convex
feasibility. Beyond imaging, it has been applied to SAT, protein structure,
Ramsey numbers, Diophantine equations, Sudoku, and packing problems. Because
those include NP-complete tasks, the map is an **incomplete** search method:
success yields a verifiable feasible point; failure after a budget does not
prove emptiness of $A \cap B$.

## The Elser difference map

Formulate the task as set intersection in Euclidean space: find
$x \in A \cap B$, given metric projections $P_A$ and $P_B$. One iteration is

$$
\begin{aligned}
x &\mapsto D(x) = x + \beta \bigl[ P_A(f_B(x)) - P_B(f_A(x)) \bigr], \\
f_A(x) &= P_A(x) - \frac{1}{\beta}\bigl(P_A(x) - x\bigr), \\
f_B(x) &= P_B(x) + \frac{1}{\beta}\bigl(P_B(x) - x\bigr).
\end{aligned}
$$

The real parameter $\beta$ must be nonzero (either sign). A common first guess
is $\beta = 1$ (or $\beta = -1$), which reduces the per-iteration work to

$$
D(x) = x + P_A\bigl(2 P_B(x) - x\bigr) - P_B(x).
$$

A point $x$ is a **fixed point** of $D$ precisely when
$P_A(f_B(x)) = P_B(f_A(x))$. The common value lies in $A \cap B$; the iterate
$x$ itself need not lie in either set. Progress is monitored by the residual

$$
\Delta = \bigl\| P_A(f_B(x)) - P_B(f_A(x)) \bigr\|_2,
$$

which vanishes at a recovered feasible point.

## Related maps (teaching)

For convex contrast and pedagogy this package also exposes:

- **Alternating projections:** $x \leftarrow P_A(P_B(x))$
- **Douglas–Rachford:** $x \leftarrow \tfrac{1}{2}\bigl(x + R_A(R_B(x))\bigr)$
  with reflections $R_C = 2 P_C - I$
- **Averaged projections:** $x \leftarrow \tfrac{1}{2}\bigl(P_A(x) + P_B(x)\bigr)$

On nonconvex sets, alternating projections can stall; the difference map (and
DR) are the interesting incomplete search engines.

## Toy projectors

| Projector | Geometry | Formula sketch |
| --- | --- | --- |
| `Project_Box` | Axis-aligned box | Componentwise clamp into $[\ell_i, h_i]$ |
| `Project_Ball` | Closed ball | Keep $x$ if $\|x-c\| \le R$, else boundary |
| `Project_Sphere` | Sphere surface | $c + R (x-c)/\|x-c\|$ (origin $\to$ $e_1$) |
| `Project_Orthant` | $x_i \ge 0$ | $\max(0, x_i)$ |
| `Project_Hyperplane` | $a\cdot x = b$ | $x - \frac{a\cdot x - b}{\|a\|^2} a$ |

Demos in tests: line $\cap$ circle in $\mathbb{R}^2$, box $\cap$ ball,
orthant $\cap$ plane, plane $\cap$ sphere in $\mathbb{R}^3$.

## API (`Difference_Map`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Dim`, `Max_Iter` | $\mathrm{Dim}\le 16$, budget $\le 10\,000$ |
| Types | `Vector`, `Parameters`, `Result`, `Constraint` | State + $\beta$/Tol/budget |
| Helpers | `Near`, `Norm2`, `Dot`, `Add`, `Sub`, `Scale`, `Distance` | Vector algebra |
| Projectors | `Project_Box`, `Project_Ball`, `Project_Sphere`, `Project_Orthant`, `Project_Hyperplane`, `Project` | Toys + dispatch |
| Elser | `F_A`, `F_B`, `Difference_Map_Step`, `Iterate_Difference_Map` | Core map |
| Monitor | `Residual`, `Is_Near_Feasible`, `Feasible_Candidate` | $\Delta$ and recovery |
| Related | `Alternating_Projections`, `Douglas_Rachford_Step`, `Iterate_Douglas_Rachford`, `Averaged_Projections_Step`, `Reflect` | Teaching maps |
| Builders | `Make_Box`, `Make_Ball`, `Make_Sphere`, `Make_Orthant`, `Make_Hyperplane` | Constraint records |

Named exception: `Invalid_Argument` (e.g. $\beta = 0$, zero hyperplane normal,
inverted box bounds).

`Parameters` fields: `Beta` (default $1$), `Max_Iter` (default $1000$),
`Tol` (default $10^{-8}$). `Result` carries the final iterate `X`, a
`Feasible` candidate $P_A(f_B(x))$, residual, iteration count, and
convergence flags.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pdifference_map.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

There is **no** `main.adb`; `tests.adb` is the sole main. Object and binary
artifacts live under `obj/` and `bin/` (gitignored).

## Caveats

- Educational `Float` arithmetic (`digits 15`); no SPARK proofs; no FFT phase
  retrieval.
- Incomplete method: nonconvergence does **not** prove $A \cap B = \emptyset$.
- $\beta$ is problem-dependent; defaults are teaching choices, not tuned for
  hard combinatorial instances.
- Caps $\mathrm{Dim}\le 16$ and $\mathrm{Max\_Iter}\le 10\,000$ are intentional.
