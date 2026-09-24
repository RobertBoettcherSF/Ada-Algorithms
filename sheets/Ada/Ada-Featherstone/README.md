# Featherstone's Algorithm — Ada 2023 (Planar Educational)

Educational, self-contained Ada 2023 package for **Featherstone-family**
rigid-body dynamics on a **planar (2-D) serial open chain** with revolute
joints: the **Recursive Newton–Euler Algorithm (RNEA)** for inverse
dynamics and the **Articulated-Body Algorithm (ABA)** for $O(N)$ forward
dynamics, plus a **Composite-Rigid-Body / unit-acceleration** mass matrix
and a dense CRBA solve for cross-checks.

Based on Roy Featherstone, *Robot Dynamics Algorithms* (1987); clear ABA
write-ups in Brian Mirtich's Ph.D. thesis; comparison with maximal-coordinate
Lagrange-multiplier methods in Baraff's "Linear-time dynamics using Lagrange
multipliers"; and the stub article
[Wikipedia: Featherstone's algorithm](https://en.wikipedia.org/wiki/Featherstone%27s_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Why Featherstone?

Articulated figures (robots, ragdolls, skeletons) are trees of rigid links
and joints. Dynamics asks two dual questions:

| Problem | Inputs | Outputs | Classic method |
| --- | --- | --- | --- |
| **Inverse dynamics** | $q,\dot q,\ddot q$ | joint torques $\tau$ | RNEA — $O(N)$ |
| **Forward dynamics** | $q,\dot q,\tau$ | $\ddot q$ | ABA — $O(N)$ |

Naïve formation of the joint-space mass matrix $H(q)$ and dense factorisation
is $O(N^3)$. Featherstone's **ABA** propagates **articulated inertias** so
forward dynamics stays **linear** in the number of bodies — crucial for long
kinematic chains and real-time physics.

## Reduced coordinates vs Lagrange multipliers

Featherstone (and this package) uses **reduced coordinates**: the
configuration is the vector of joint angles $q\in\mathbb{R}^N$. Constraints
are built into the parameterisation; there are no explicit joint-constraint
forces in the solve.

**Maximal-coordinate** methods (e.g. Baraff) instead track each body's
unrestricted pose and enforce joints with **Lagrange multipliers**. Both
can be $O(N)$ for trees; they differ in constraint drift, contact handling,
and implementation style. Wikipedia notes Mirtich's thesis as a clear ABA
reference and Baraff's paper for the multiplier comparison.

## Planar educational scope

Full spatial ABA uses $6\times 6$ inertias. This repository demonstrates the
**same recursion** in the plane with **3-D spatial vectors**
$(\omega,v_x,v_y)$ and $3\times 3$ inertias — enough to teach articulated
inertias, RNEA $\leftrightarrow$ ABA duality, and gravity / Coriolis terms
without drowning in 6-D bookkeeping. Bodies form a **serial open chain**
(no branches, no loops). Capacity $N\le 16$.

Each link stores mass $m$, COM offset in the body frame, scalar inertia
$I_{\mathrm{COM}}$ about the COM, and the distal joint offset.

## Equations of motion

In joint space,

$$
H(q)\,\ddot q + C(q,\dot q) = \tau,
$$

where $H(q)$ is the symmetric positive-definite mass matrix and
$C(q,\dot q)$ collects Coriolis, centrifugal, and gravity torques.
Equivalently,

$$
\tau = \mathrm{RNEA}(q,\dot q,\ddot q),
\qquad
C(q,\dot q)=\mathrm{RNEA}(q,\dot q,0),
\qquad
\ddot q = \mathrm{ABA}(q,\dot q,\tau).
$$

Consistency checks used in tests:

$$
\mathrm{RNEA}\bigl(q,\dot q,\mathrm{ABA}(q,\dot q,\tau)\bigr)\approx\tau,
\qquad
\mathrm{ABA}\bigl(q,\dot q,\mathrm{RNEA}(q,\dot q,\ddot q)\bigr)\approx\ddot q.
$$

### One-link pendulum

For a point mass $m$ at distance $\ell$ from a fixed pivot, with $q$ measured
from the $+x$ axis and gravity $\mathbf{g}=(0,-g)$,

$$
\tau_{\mathrm{hold}} = +m g \ell \cos q,
\qquad
H = m\ell^2.
$$

At $q=0$ (horizontal) inverse dynamics returns the holding torque $+m g \ell$.

### Spatial inertia (planar)

About the proximal joint, with COM $(c_x,c_y)$ in the link frame:

$$
\mathbf{I}=
\begin{pmatrix}
I_{\mathrm{COM}}+m(c_x^2+c_y^2) & -m c_y & m c_x \\
-m c_y & m & 0 \\
m c_x & 0 & m
\end{pmatrix}.
$$

Revolute joint subspace $S=(1,0,0)^\top$. ABA forms articulated inertias
$\mathbf{I}^A$, scalars $D=S^\top\mathbf{I}^A S$, and recurses outward for
$\ddot q$.

## Algorithms implemented

| Routine | Role | Complexity |
| --- | --- | --- |
| `Inverse_Dynamics_RNEA` | $\ddot q\mapsto\tau$ (world-frame Newton–Euler) | $O(N)$ |
| `Forward_Dynamics_ABA` | $\tau\mapsto\ddot q$ (planar articulated bodies) | $O(N)$ |
| `Mass_Matrix` | $H(q)$ via unit-acceleration RNEA columns | $O(N^2)$ |
| `Forward_Dynamics_CRBA` | $H^{-1}(\tau-C)$ dense Cholesky cross-check | $O(N^3)$ |
| `Forward_Kinematics` | joint / COM / tip poses from $q$ | $O(N)$ |
| `Bias_Forces` / `Gravity_Torques` | $C(q,\dot q)$ and gravity-only torques | $O(N)$ |

## API (package `Featherstone`)

- **Types:** `Real`, `Vec2`, `Link`, `Chain`, `Real_Array`, `Mat_NN`, `FK_Result`
- **Build:** `Create`, `Make_Uniform_Chain`, `Set_Link`, `Set_Gravity`, `Set_State`, `Set_Q` / `Set_Qd` / `Set_Qdd` / `Set_Tau`
- **Query:** `N_Links`, `Gravity`, `Get_Link`, `Get_Q`, …
- **Kinematics / dynamics:** `Forward_Kinematics`, `Inverse_Dynamics_RNEA`, `Forward_Dynamics_ABA`, `Forward_Dynamics_CRBA`, `Mass_Matrix`, `Bias_Forces`, `Gravity_Torques`
- **Helpers:** `Near`, `Near_Vec`, `Rot`, `Cross_Z`, `Mag`
- **Limits:** `Max_N = 16`

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022` with `featherstone.gpr` (`Main = tests.adb`).
Expect exit status 0, zero warnings, and **≥ 100** `PASS` lines with
`Fail_Count = 0`.

## References

- Roy Featherstone, *Robot Dynamics Algorithms*, Kluwer, 1987.
- Brian Mirtich, *Impulse-based Dynamic Simulation of Rigid Body Systems*
  (Ph.D. thesis) — detailed ABA description.
- David Baraff, “Linear-time dynamics using Lagrange multipliers,” for
  maximal-coordinate comparison.
- [Wikipedia: Featherstone's algorithm](https://en.wikipedia.org/wiki/Featherstone%27s_algorithm)
- [Roy Featherstone's home page](http://royfeatherstone.org)
- Bullet Physics Featherstone multibody; Moby / other open implementations
  linked from Wikipedia.

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
