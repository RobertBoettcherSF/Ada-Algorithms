# D* Lite in Ada 2023

## Project Overview

**D\*** (pronounced "D star") is a family of **incremental heuristic search**
algorithms for robot path planning in unknown or changing terrain. The family
includes original D\* (Stentz), Focused D\*, and **D\* Lite** (Koenig &
Likhachev). Modern systems almost always use **D\* Lite** — simpler than
original D\*, with equal or better performance.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of **D\* Lite**. The Ada package is named `D_Star` to match the family; the
algorithm coded here is specifically D\* Lite (backward search from the goal,
$g$ / $\mathit{rhs}$ values, lexicographic keys $(k_1,k_2)$).

Primary sources:

- [Wikipedia — D\*](https://en.wikipedia.org/wiki/D*)
- Koenig & Likhachev, AAAI 2002 / ICRA 2002 (D\* Lite)

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with search siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-D-Star`) | D\* Lite incremental grid replan |
| **[Ada-Jump-Point-Search](https://github.com/RobertBoettcherSF/Ada-Jump-Point-Search)** | JPS on a static 8-connected grid |
| **[Ada-Dijkstras-Algorithm](https://github.com/RobertBoettcherSF/Ada-Dijkstras-Algorithm)** | Classic shortest paths on graphs |

README links only — **no** package `with` of siblings.

## Algorithm

D\* Lite solves sequences of similar path problems when **edge costs change**
(new obstacles, cleared cells, terrain costs). It reuses prior $g$ / $\mathit{rhs}$
experience instead of restarting A\* from scratch.

This package uses a **4-connected** grid and the **Manhattan** heuristic. The
cost of a cardinal step into free cell $v$ is the cell cost of $v$ (default
$1$). Blocked cells are untraversable. Search runs **backward from the goal**
(classic D\* Lite): $g(s)$ estimates cost from $s$ to the goal.

### Keys and local consistency

Each cell $s$ stores $g(s)$ and a one-step lookahead

$$
\mathit{rhs}(s) =
\begin{cases}
0 & \text{if } s = \mathit{Goal} \\
\min_{s'\in\mathrm{Succ}(s)}\big(c(s,s') + g(s')\big) & \text{otherwise.}
\end{cases}
$$

$s$ is **locally consistent** when $g(s)=\mathit{rhs}(s)$. The priority-queue
key is the lexicographic pair

$$
k(s) = \big(\min(g(s),\mathit{rhs}(s)) + h(\mathit{Start},s) + k_m,\;
\min(g(s),\mathit{rhs}(s))\big).
$$

With a **fixed start** between cost updates (this educational API), $k_m=0$.
`ComputeShortestPath` expands inconsistent cells until $\mathit{Start}$ is
consistent and no open key beats $k(\mathit{Start})$.

### Manhattan heuristic

$$
h(a,b) = \big(|a_x-b_x| + |a_y-b_y|\big)\cdot c
\quad\text{with } c=1.
$$

### Replan sketch

1. `Initialize` copies the grid, sets $\mathit{rhs}(\mathit{Goal})=0$, and runs
   D\* Lite to plan Start → Goal.
2. On map change: `Update_Cell_Cost` / `Set_Blocked` adjust costs and call
   `UpdateVertex` on affected cells (no search yet).
3. `Replan` runs `ComputeShortestPath` again — typically far fewer expansions
   than a full A\* restart when the change is local.
4. Path extraction greedily follows
   $\arg\min_{s'}(c(s,s')+g(s'))$ from Start to Goal.

`A_Star_Replan` is a full-restart A\* oracle on the same movement model; after
any successful D\* Lite plan (initial or repaired), path **costs** must match.

## API summary

| Entity | Role |
| --- | --- |
| `Max_Width` / `Max_Height` | Educational caps (64) |
| `Point` | Cell `(X,Y)` — **0-based** |
| `Grid` / `Clear` / `Set_Blocked` / `Set_Cell_Cost` | Static cost map |
| `Planner` / `Initialize` | D\* Lite state; initial plan from Goal |
| `Path_Exists` / `Get_Path` / `Path_Cost` | Query current plan |
| `Update_Cell_Cost` / `Set_Blocked` / `Replan` | Incremental repair |
| `Expansion_Count` | Nodes popped in last search |
| `A_Star_Replan` | Full A\* oracle (same 4-conn / Manhattan) |
| `Manhattan_Heuristic` | Admissible heuristic |
| `Invalid_Argument` | OOB, oversize grid, bad cost, uninit planner |

`Start = Goal` (free) yields a length-1 path. Blocked endpoints yield no path.
Out-of-bounds endpoints raise `Invalid_Argument`.

## Build and test

```bash
make
make test
```

Or directly:

```bash
gnatmake -gnatwa -gnat2022 -Pd_star.gpr
```

Expect **zero warnings** under `-gnatwa` and all tests **PASS**.

## Files

| File | Purpose |
| --- | --- |
| `d_star.ads` | Package spec / API |
| `d_star.adb` | D\* Lite + A\* implementation |
| `tests.adb` | Standalone test harness |
| `d_star.gpr` | GNAT project |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/`, build artefacts |

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
