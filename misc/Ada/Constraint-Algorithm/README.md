# Constraint Algorithm (SHAKE / RATTLE) — Ada 2023

Educational, self-contained Ada 2023 package for **molecular-dynamics
constraint algorithms**: iterative **SHAKE** (positions) and **RATTLE**
(velocities) solvers for holonomic **distance constraints**

$$
g(\mathbf{q})=\lvert\mathbf{r}_i-\mathbf{r}_j\rvert^2-d^2=0.
$$

This is the **MD constraint-algorithm family** used in computational
chemistry (rigid bonds, water models, frozen H-bonds) — **not** generic
CSP / constraint-satisfaction programming.

Based on
[Wikipedia: Constraint algorithm](https://en.wikipedia.org/wiki/Constraint_algorithm)
(page title: *Constraint (computational chemistry)*).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Why constrain bonds?

Newton’s second law for $N$ particles,

$$
\mathbf{M}\cdot\frac{d^2\mathbf{q}}{dt^2}=\mathbf{f}=-\frac{\partial V}{\partial\mathbf{q}},
$$

plus $M$ algebraic constraints $g_j(\mathbf{q})=0$ yields a
**differential-algebraic** system. Explicit stiff springs that “almost”
fix bonds force tiny timesteps. **Implicit** Lagrange-multiplier
methods (SHAKE, RATTLE, SETTLE, LINCS, …) restore $g=0$ after each
unconstrained step, allowing larger $\Delta t$ — especially valuable when
freezing fast covalent **H-bond** vibrations that are unimportant for the
phenomenon of interest.

## Lagrange multipliers

Given distance constraints

$$
\sigma_k(t)=\lvert\mathbf{x}_{k\alpha}(t)-\mathbf{x}_{k\beta}(t)\rvert^2-d_k^2=0,
$$

constraint forces enter the equations of motion via multipliers $\lambda_k$:

$$
m_i\ddot{\mathbf{x}}_i=-\frac{\partial}{\partial\mathbf{x}_i}
\Biggl[V(\mathbf{x})-\sum_{k=1}^{n}\lambda_k\sigma_k\Biggr].
$$

After an unconstrained integrator step producing provisional positions
$\hat{\mathbf{x}}_i$, the constrained update has the form

$$
\mathbf{x}_i(t+\Delta t)=\hat{\mathbf{x}}_i(t+\Delta t)
+\sum_{k}\lambda_k\frac{\partial\sigma_k}{\partial\mathbf{x}_i}
\frac{(\Delta t)^2}{m_i},
$$

and the $\lambda_k$ are chosen so $\sigma_k(t+\Delta t)=0$.

## SHAKE vs RATTLE

| Algorithm | Constrains | Typical use |
| --- | --- | --- |
| **SHAKE** (Ryckaert–Ciccotti–Berendsen, 1977) | Positions: $g=0$ | After Verlet / leapfrog position update |
| **RATTLE** (Andersen, 1983) | Positions **and** velocities: $g=\dot g=0$ | Velocity-Verlet; $\dot g=2(\mathbf{r}_i-\mathbf{r}_j)\cdot(\mathbf{v}_i-\mathbf{v}_j)=0$ |

**SHAKE** solves the nonlinear system by a **Gauss–Seidel** sweep: for each
constraint, compute a scalar multiplier and immediately correct the two
particle positions, iterating until $\max_k\lvert g_k\rvert\le\mathrm{tol}$.
With reference bond vector $\mathbf{r}_0$ (classic) and absorbing
$(\Delta t)^2$ into $\lambda$,

$$
\lambda=\frac{g}{2\,\mathbf{r}\cdot\mathbf{r}_0\,(m_i^{-1}+m_j^{-1})},\quad
\mathbf{r}_i\leftarrow\mathbf{r}_i-\frac{\lambda}{m_i}\mathbf{r}_0,\quad
\mathbf{r}_j\leftarrow\mathbf{r}_j+\frac{\lambda}{m_j}\mathbf{r}_0.
$$

**RATTLE** additionally projects velocities so the bond stretch rate
vanishes:

$$
\mu=\frac{\mathbf{r}\cdot\mathbf{v}_{\mathrm{rel}}}
{\lvert\mathbf{r}\rvert^2\,(m_i^{-1}+m_j^{-1})},\quad
\mathbf{v}_i\leftarrow\mathbf{v}_i-\frac{\mu}{m_i}\mathbf{r},\quad
\mathbf{v}_j\leftarrow\mathbf{v}_j+\frac{\mu}{m_j}\mathbf{r}.
$$

Isolated SHAKE/RATTLE corrections on a free molecule approximately
preserve **linear momentum** $\sum_i m_i\mathbf{v}_i$ and the
**center of mass**.

Related solvers mentioned on Wikipedia (not implemented here): **SETTLE**
(analytic rigid water), **LINCS**, **M-SHAKE**, **P-SHAKE**, **SHAPE**.

## Package overview

| Concern | API | Notes |
| --- | --- | --- |
| Types | `Vec3`, `Particle`, `Distance_Constraint` | 3-D; modest `Max_Particles` / `Max_Constraints` |
| Evaluate | `Constraint_Value`, `Constraint_Dot`, `Constraint_Violation_Max`, `Velocity_Violation_Max` | $g$ and stretch rate |
| SHAKE | `Shake_Positions` → `Shake_Result` | Iterative Lagrange position fix |
| RATTLE | `Rattle_Velocities` → `Rattle_Result` | Velocity projection |
| Demo step | `Velocity_Verlet_Constrained_Step` | Free-flight ($a=0$) + SHAKE + RATTLE |
| Builders | `Make_Diatomic`, `Make_Water_Like`, `Make_Two_Bond_Chain` | Rigid bond / TIP3P-style / chain |
| Helpers | `Near`, `Dot`, `Norm`, `Linear_Momentum`, `Perturb_Positions` | Tests & demos |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`,
`Constraint_Not_Converged`, `Empty_System`.

## Usage sketch

```ada
with Constraint_Algorithm; use Constraint_Algorithm;

procedure Demo is
   P  : Particle_Array (1 .. Max_Particles);
   C  : Constraint_Array (1 .. Max_Constraints);
   NP : Particle_Count;
   NC : Constraint_Count;
   R  : Shake_Result;
   Cfg : constant Solver_Config := Default_Config;
begin
   Make_Diatomic (1.0, 1.0, 1.0, P, NP, C, NC);
   P (2).Pos.X := 1.2;                    -- unconstrained stretch
   Shake_Positions (P, C, NP, NC, Cfg, R); -- restore |r|=1
end Demo;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022` with project `constraint_algorithm.gpr`
(`Main = tests.adb`). Expect exit status 0 and `Fail_Count = 0`.

## Layout

Exactly seven root entries (no `main.adb`):

1. `constraint_algorithm.ads`
2. `constraint_algorithm.adb`
3. `constraint_algorithm.gpr`
4. `Makefile`
5. `tests.adb`
6. `README.md`
7. `.gitignore` (`obj/`, `bin/`)

## References

- Wikipedia: [Constraint algorithm](https://en.wikipedia.org/wiki/Constraint_algorithm)
  (*Constraint (computational chemistry)*)
- Ryckaert, J.-P.; Ciccotti, G.; Berendsen, H. J. C. (1977). *Numerical
  Integration of the Cartesian Equations of Motion of a System with
  Constraints*. J. Comput. Phys. 23, 327–341. (**SHAKE**)
- Andersen, H. C. (1983). *RATTLE: A “Velocity” Version of the SHAKE
  Algorithm*. J. Comput. Phys. 52, 24–34.
- Miyamoto, S.; Kollman, P. A. (1992). *SETTLE*. J. Comput. Chem. 13, 952–962.
- Hess, B. et al. (1997). *LINCS*. J. Comput. Chem. 18, 1463–1472.

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
