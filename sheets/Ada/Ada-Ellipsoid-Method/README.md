# Ellipsoid Method — Ada 2023

Educational, self-contained Ada 2023 package implementing the **ellipsoid
method** (Khachiyan / Shor–Nemirovski–Yudin) for **small dense convex
feasibility** problems. The algorithm maintains a shrinking ellipsoid that
contains a target convex set, repeatedly cutting with a **separation oracle**
(central or deep cuts) until a feasible point is found or the volume becomes
too small (empty-set proxy).

**Honest scope:** this is an **educational Float sketch** with dimension cap
$n\le 8$. It illustrates volume-contraction geometry and Khachiyan-style
**polynomial-time intuition** for LP feasibility with rational data — it does
**not** implement bit-complexity arithmetic, exact rational oracles, or a
production LP solver. Prefer simplex / interior-point siblings for practical
tiny LPs.

Based on [Wikipedia: Ellipsoid method](https://en.wikipedia.org/wiki/Ellipsoid_method).

Siblings (full GitHub URLs):

| Package | Role |
| --- | --- |
| [Ada-Simplex-Algorithm](https://github.com/RobertBoettcherSF/Ada-Simplex-Algorithm) | Dense Bland two-phase tableau LP |
| [Ada-Karmarkars-Algorithm](https://github.com/RobertBoettcherSF/Ada-Karmarkars-Algorithm) | Affine-scaling / Karmarkar spirit |
| [Ada-Interior-Point-Method](https://github.com/RobertBoettcherSF/Ada-Interior-Point-Method) | Barrier / affine-scaling IPM survey |
| [Ada-Linear-Programming](https://github.com/RobertBoettcherSF/Ada-Linear-Programming) | LP survey umbrella |
| [Ada-Cutting-Plane-Method](https://github.com/RobertBoettcherSF/Ada-Cutting-Plane-Method) | Gomory / Kelley cuts |

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Shrink an enclosing ellipsoid via cuts | Circumscribed / Yudin–Nemirovski |
| **Set** | $E=\{x:(x-c)^{\top}P^{-1}(x-c)\le 1\}$ | Store dense $P\succ 0$ |
| **Oracle** | Halfspaces $a_i\cdot x\le b_i$ | Or deep/central cut API |
| **Update** | Central ($\alpha=0$) or deep ($0\le\alpha<1$) | Volume factor depends on $n$ |
| **Stop** | Feasible center / tiny volume / max iters | Educational statuses |
| **Limits** | $n\le 8$ | Float; not production |

## Brief history

As an iterative convex-minimization method, a preliminary version is due to
**Naum Z. Shor**; in 1972 **Arkadi Nemirovski** and **David B. Yudin** studied
an approximation algorithm for real convex minimization. **Leonid Khachiyan**
applied the ellipsoid method to **linear programming with rational data** and
proved the first **polynomial-time** LP algorithm (a theoretical breakthrough
versus worst-case exponential simplex examples). In practice the method is
slow and numerically delicate; it inspired later **interior-point** work
(notably Karmarkar). Complexity bounds depend on dimension and data size, not
on the number of inequality rows — hence lasting importance in combinatorial
optimization theory.

## Ellipsoid and central cut

At iteration $k$ the working set is the ellipsoid

$$
\mathcal{E}^{(k)}=\bigl\{x\in\mathbb{R}^{n}:
(x-x^{(k)})^{\top}P_{(k)}^{-1}(x-x^{(k)})\le 1\bigr\},
\qquad P_{(k)}\succ 0.
$$

A separation oracle returns $g$ such that every feasible (or optimal) point
$x^{*}$ satisfies $g^{\top}(x^{*}-x^{(k)})\le 0$. The next ellipsoid is the
**minimum-volume** ellipsoid containing the half-ellipsoid
$\mathcal{E}^{(k)}\cap\{z:g^{\top}(z-x^{(k)})\le 0\}$. With the normalized
direction

$$
\tilde g=\frac{g}{\sqrt{g^{\top}P_{(k)}g}},
$$

the **central-cut** update is

$$
\begin{aligned}
x^{(k+1)}&=x^{(k)}-\frac{1}{n+1}\,P_{(k)}\tilde g,\\
P_{(k+1)}&=\frac{n^{2}}{n^{2}-1}
\Bigl(P_{(k)}-\frac{2}{n+1}\,P_{(k)}\tilde g\,\tilde g^{\top}P_{(k)}\Bigr).
\end{aligned}
$$

Volume contracts by a factor depending only on $n$ (roughly
$e^{-1/(2n)}$ per step), which yields the classic $O(n^{2}\log(1/\varepsilon))$
iteration intuition.

## Deep cuts

If the cut is deeper than through the center, write the kept halfspace as
$g^{\top}(z-c)\le -\alpha\sqrt{g^{\top}Pg}$ with depth $\alpha\in[0,1)$. Then

$$
\begin{aligned}
\tau&=\frac{1+n\alpha}{n+1},&
\sigma&=\frac{2(1+n\alpha)}{(n+1)(1+\alpha)},&
\delta&=\frac{n^{2}(1-\alpha^{2})}{n^{2}-1},\\
c^{+}&=c-\tau\,P\tilde g,&
P^{+}&=\delta\bigl(P-\sigma\,P\tilde g\,\tilde g^{\top}P\bigr).
\end{aligned}
$$

($\alpha=0$ recovers the central formulas; $n=1$ uses the half-interval
special case $c\leftarrow c-\frac{1+\alpha}{2}P\tilde g$,
$P\leftarrow\bigl(\frac{1-\alpha}{2}\bigr)^{2}P$.)

For a violated halfspace $a\cdot x\le b$ at the center, this package sets
$\alpha=(a\cdot c-b)/\sqrt{a^{\top}Pa}$ (clamped to $[0,1)$) when deep cuts
are enabled.

## Feasibility loop

Given halfspaces $\{a_i\cdot x\le b_i\}$ and an initial ball (or ellipsoid)
known to contain any feasible point of interest:

1. If the center satisfies all inequalities within `Tol` → **Feasible**.
2. Otherwise build a central/deep cut from the first violated halfspace and
   update $(c,P)$.
3. If $\tfrac12\log\det(P)$ falls below `Min_Log_Vol` (or $\det P\le 0$) →
   **Volume_Too_Small** (educational empty-set proxy).
4. If `Max_Iters` is exhausted → **Iteration_Limit**.

Optional `Maximize_Linear_Feasibility` binary-searches an objective threshold
$\gamma$ by testing feasibility of $Ax\le b$ together with $c\cdot x\ge\gamma$
(LP-feasibility sketch; not a full simplex/IPM solver).

## API (`Ellipsoid_Method`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Vector`, `Matrix`, `Ellipsoid`, `Halfspace`, `Cut`, `Config`, `Result`, `Status` | Domain |
| Helpers | `Near`, `Vec_Near`, `Dot`, `Norm2`, `Normalize`, `Scale`, `Add`, `Sub` | Numerics |
| LA | `Mat_Vec`, `Mat_Mul`, `Transpose`, `Identity`, `Symmetric_Part`, `Determinant`, `Determinant_2x2`/`3x3` | Dense $n\le 8$ |
| Ellipsoid | `Init_Ball`, `Volume_Proxy`, `Log_Volume_Proxy`, `Contains_Point`, `Quadratic_Form` | Geometry |
| Cuts | `Make_Cut`, `Cut_From_Halfspace`, `Apply_Central_Cut`, `Apply_Deep_Cut`, `Apply_Cut` | Updates |
| Feasibility | `First_Violated`, `Is_Feasible`, `Feasibility_Ellipsoid`, `Feasibility_Box`, `Maximize_Linear_Feasibility` | Oracles / loops |

Statuses: `Feasible`, `Infeasible` (reserved), `Iteration_Limit`,
`Volume_Too_Small`, `Ill_Started`.

## Build & test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pellipsoid_method.gpr
make test   # runs bin/tests; expect Fail_Count = 0
make clean
```

## Caveats

- **Float only** — no exact arithmetic; deep sequences can lose positive-definiteness.
- **Small $n$** — designed for demos (boxes, triangles, tiny polytopes), not large LPs.
- **Empty detection** is via volume collapse, not a formal Farkas certificate.
- Initial ellipsoid must **contain** the feasible region of interest; a too-small
  start can miss feasible points or stall.

## License

Educational code for the RobertBoettcherSF Ada algorithm series.
