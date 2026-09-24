# Swarm Intelligence — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Swarm intelligence](https://en.wikipedia.org/wiki/Swarm_intelligence):
collective behaviour of decentralised, self-organised systems of simple
agents. This survey ships a compact **Reynolds-style boids** flocking
sketch (separation / alignment / cohesion), a **PSO-lite** one-step
velocity helper, and an **ACO-style** pheromone evaporation helper. A
**method taxonomy** flags Particle_Swarm / Ant_Colony / Bees /
Harmony_Search / Flocking_Boids — full solvers live in sibling repos
(README links only; **not** build dependencies).

Swarm intelligence systems typically consist of a population of simple
agents (**boids**) that interact locally with one another and with their
environment. Agents follow very simple rules; there is no centralised
control, yet local interactions yield emergent global behaviour. Classic
natural inspirations include ant colonies, bee colonies, bird flocking,
and fish schooling. Application to robots is **swarm robotics**; the
broader algorithmic family includes PSO, ACO, and related metaheuristics.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling solvers (links
only — **not** build dependencies):

- [Ada-Particle-Swarm](https://github.com/RobertBoettcherSF/Ada-Particle-Swarm)
- [Ada-Ant-Colony-Optimization](https://github.com/RobertBoettcherSF/Ada-Ant-Colony-Optimization)
- [Ada-Bees-Algorithm](https://github.com/RobertBoettcherSF/Ada-Bees-Algorithm)
- [Ada-Harmony-Search](https://github.com/RobertBoettcherSF/Ada-Harmony-Search)

Style siblings: `ada-local-search`, `ada-nonlinear-optimization`.

Educational limits: flock size $n\le 32$, agents in $\mathbb{R}^2$ only.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Taxonomy** | `Method_Kind` | PSO / ACO / Bees / HS = flags; Boids sketch implemented |
| **Boids** | Separation / alignment / cohesion | Reynolds 1987 continuous agents |
| **PSO-lite** | One-step $v$ update | Not a full PSO package |
| **ACO helper** | $\tau\leftarrow(1-\rho)\tau$ | Evaporation (+ deposit) |
| **Vectors** | `Vec2`, `Near`, `Norm2`, … | 2D educational helpers |
| **Flock step** | Euler + force clamps | `Step_Flock` / `Simulate_Flock` |

## Formula summary

### Reynolds boids (1987)

Each agent $i$ with position $x_i$ and velocity $v_i$ steers using three
local rules over neighbours within perception radius $r$:

$$
\begin{aligned}
s_i &= \mathrm{normalize}\!\left(
  \frac{1}{|N_i|}\sum_{j\in N_i}\frac{x_i-x_j}{\|x_i-x_j\|^2}
\right)
&& \text{(separation)} \\
a_i &= \mathrm{normalize}\!\left(
  \frac{1}{|N_i|}\sum_{j\in N_i} v_j
\right)
&& \text{(alignment)} \\
c_i &= \mathrm{normalize}\!\left(
  \Bigl(\tfrac{1}{|N_i|}\sum_{j\in N_i} x_j\Bigr) - x_i
\right)
&& \text{(cohesion)}
\end{aligned}
$$

where $N_i=\{j\neq i:\|x_i-x_j\|<r\}$. Combined acceleration is a weighted,
force-clamped sum $w_s s_i + w_a a_i + w_c c_i$, then

$$
v_i \leftarrow \mathrm{limit}(v_i + \Delta t\, u_i,\, v_{\max}),
\qquad
x_i \leftarrow x_i + \Delta t\, v_i.
$$

### PSO-lite (one step)

For particle position $x$, velocity $v$, personal best $p$, and global
best $g$:

$$
v \leftarrow \omega\, v + c_1 r_1 (p-x) + c_2 r_2 (g-x),
\qquad
x \leftarrow x + v,
$$

with $r_1,r_2\in[0,1]$. Full population PSO is the sibling
[Ada-Particle-Swarm](https://github.com/RobertBoettcherSF/Ada-Particle-Swarm)
package.

### Pheromone evaporation (ACO spirit)

$$
\tau \leftarrow (1-\rho)\,\tau,
\qquad
\tau \leftarrow \tau + \Delta\tau,
$$

with evaporation rate $\rho\in[0,1]$. Full Ant System / ACS tours live in
[Ada-Ant-Colony-Optimization](https://github.com/RobertBoettcherSF/Ada-Ant-Colony-Optimization).

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Limits | `Max_Boids` | Flock capacity $n\le 32$ |
| Types | `Vec2`, `Boid`, `Flock`, `Config`, `Result` | 2D agents |
| Helpers | `Near`, `Vec_Near`, `Make_Config`, `Zero_Vec` | Utilities |
| Vectors | `Add` / `Sub` / `Scale` / `Dot` / `Norm2` / `Distance` / `Normalize` / `Limit` | $\mathbb{R}^2$ |
| PSO-lite | `PSO_Velocity_Step`, `PSO_Position_Step` | One-step $v,x$ |
| ACO helper | `Evaporate_Pheromone`, `Deposit_Pheromone` | $\tau$ update |
| Steering | `Separation` / `Alignment` / `Cohesion` (+ `_At`) | Reynolds rules |
| Combine | `Combined_Steer` | Weighted force-limited sum |
| Integrate | `Step_Boid`, `Step_Flock`, `Simulate_Flock` | Euler flock |
| Stats | `Mean_Speed`, `Mean_Nearest_Spacing` | Diagnostics |
| Init | `Make_Grid_Flock` | Regular lattice flock |
| Taxonomy | `Method_Kind`, `Classify_Method`, `Method_Name`, `Method_Count` | Metadata flags |

Strong typing uses `Real` (digits 15) and capacity subtypes. Public
subprograms carry `Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exception: `Invalid_Argument`.

## Usage

```ada
with Swarm_Intelligence; use Swarm_Intelligence;

declare
   Cfg : constant Config := Make_Config (Perception => 5.0, Dt => 0.1);
   F   : Flock := Make_Grid_Flock (2, 3, Spacing => 1.0, Speed => 0.5);
   R   : Result;
   V   : Vec2;
   Tau : Non_Negative := 1.0;
begin
   Step_Flock (F, Cfg);
   R := Simulate_Flock (F, Cfg, Steps => 20);
   V := PSO_Velocity_Step
     ((1.0, 0.0), (0.0, 0.0), (2.0, 0.0), (4.0, 0.0),
      Omega => 0.729, C1 => 1.49445, C2 => 1.49445,
      R1 => 0.5, R2 => 0.5);
   Tau := Evaporate_Pheromone (Tau, Rho => 0.5);
end;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pswarm_intelligence.gpr`. Main program is
`tests.adb` (no `main.adb`). Expect **zero** warnings and `Fail_Count = 0`
with `Pass_Count ≥ 100`.

## Layout

| File | Role |
| --- | --- |
| `swarm_intelligence.ads` | Package spec |
| `swarm_intelligence.adb` | Package body |
| `swarm_intelligence.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## References

- Wikipedia: [Swarm intelligence](https://en.wikipedia.org/wiki/Swarm_intelligence).
- Wikipedia: [Boids](https://en.wikipedia.org/wiki/Boids).
- Reynolds, C.W. (1987). Flocks, herds and schools: A distributed behavioral model. *SIGGRAPH*.
- Kennedy, J. and Eberhart, R. (1995). Particle swarm optimization.
- Dorigo, M. (1992). Optimization, Learning and Natural Algorithms (ACO).
- Vicsek, T. et al. (1995). Novel type of phase transition in a system of self-driven particles.

## Related packages

- **[Ada-Particle-Swarm](https://github.com/RobertBoettcherSF/Ada-Particle-Swarm)** —
  full box-constrained PSO solver (link only).
- **[Ada-Ant-Colony-Optimization](https://github.com/RobertBoettcherSF/Ada-Ant-Colony-Optimization)** —
  Ant System / pheromone TSP (link only).
- **[Ada-Bees-Algorithm](https://github.com/RobertBoettcherSF/Ada-Bees-Algorithm)** —
  bees algorithm continuous search (link only).
- **[Ada-Harmony-Search](https://github.com/RobertBoettcherSF/Ada-Harmony-Search)** —
  harmony search metaheuristic (link only).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
