# Jump Point Search in Ada 2023

## Project Overview

**Jump Point Search (JPS)** is an optimisation of the **A\*** search algorithm
for **uniform-cost grids**. It reduces symmetries in the search by *graph
pruning*: under mild assumptions about a node's neighbours, whole stretches of
the grid can be skipped. The search therefore expands long **jumps** along
straight (horizontal, vertical, and diagonal) lines instead of every adjacent
grid step that ordinary A\* would consider.

JPS **preserves A\***'s optimality while often cutting running time by an order
of magnitude on open terrain.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational implementation
of classic JPS (Harabor & Grastien) on an **8-connected** occupancy grid with
the **octile** heuristic, plus a plain `A_Star_Grid` oracle for cost checks.

Primary sources:

- [Wikipedia — Jump point search](https://en.wikipedia.org/wiki/Jump_point_search)
- Harabor & Grastien, SoCS 2011 / 2012 / 2014

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with search siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Jump-Point-Search`) | JPS on an 8-connected uniform grid |
| **[Ada-Jump-Search](https://github.com/RobertBoettcherSF/Ada-Jump-Search)** | Block / jump search on a sorted *array* (unrelated) |
| **[Ada-Binary-Search](https://github.com/RobertBoettcherSF/Ada-Binary-Search)** | Classic binary chop on a sorted array |

README links only — **no** package `with` of siblings.

## Algorithm

On a uniform 8-connected grid, many shortest paths are symmetric. JPS prunes
neighbours that cannot improve an optimal path, then **jumps** in each
remaining direction until it hits a **jump point** (a node with a *forced*
neighbour, or the goal).

### Octile heuristic

With cardinal step cost $c=1$ and diagonal step cost $d=\sqrt{2}$, the
admissible octile distance between cells differing by $(\Delta x,\Delta y)$
(absolute) is

$$
h = \max(\Delta x,\Delta y)\,c + \min(\Delta x,\Delta y)\,(d-c).
$$

Equivalently $h = (\max-\min)\,c + \min\cdot d$.

### Corner-cutting policy

This package **disallows corner-cutting**: a diagonal step from $(x,y)$ to
$(x\pm 1,\,y\pm 1)$ is legal only when the destination is free **and** both
orthogonally adjacent cells $(x\pm 1,\,y)$ and $(x,\,y\pm 1)$ are free. That
matches Harabor & Grastien's 2012 pruning rules for agents with positive
footprint (typical in games and robotics). The original 2011 rules allowed
cutting corners; we do **not**.

### Search sketch

1. Insert $\mathit{Start}$ into the open set with $g=0$, $f=h(\mathit{Start},\mathit{Goal})$.
2. While the open set is non-empty:
   - Pop the node $n$ with smallest $f$ (tie-break larger $g$).
   - If $n=\mathit{Goal}$, reconstruct the path and halt.
   - Identify pruned neighbour directions of $n$ (natural + forced).
   - For each direction $\vec{d}$, $\mathit{Jump}$ until a jump point $j$
     (or failure). If $j$ improves $g(j)$, push $j$ with parent $n$.
3. If the open set empties, there is no path.

`Find_Path` returns the **cell-by-cell** path (intermediate cells between jump
points are filled in). `A_Star_Grid` explores every legal adjacent step with
the same costs and heuristic; on success its path **cost** must match JPS.

## API summary

| Entity | Role |
| --- | --- |
| `Max_Width` / `Max_Height` | Educational caps (128) |
| `Point` | Cell `(X,Y)` — **0-based** |
| `Grid` / `Clear` / `Set_Blocked` / `Is_Blocked` | Occupancy map |
| `Find_Path` | JPS; `True` + path, or `False` if none |
| `A_Star_Grid` | A\* oracle (same movement model) |
| `Octile_Heuristic` / `Path_Cost` / `Can_Step` | Helpers |
| `Invalid_Argument` | OOB coordinates, oversize grid, short path buffer |

`Start = Goal` (free) yields length-1 path. Blocked endpoints yield `False`.
Out-of-bounds endpoints raise `Invalid_Argument`.

## Build and test

```bash
make
make test
```

Or directly:

```bash
gnatmake -gnatwa -gnat2022 -Pjump_point_search.gpr
```

Expect **zero warnings** under `-gnatwa` and all tests **PASS**.

## Files

| File | Purpose |
| --- | --- |
| `jump_point_search.ads` | Package spec / API |
| `jump_point_search.adb` | JPS + A\* implementation |
| `tests.adb` | Standalone test harness |
| `jump_point_search.gpr` | GNAT project |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/`, build artefacts |

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
