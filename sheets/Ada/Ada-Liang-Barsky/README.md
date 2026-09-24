# Liang–Barsky Line Clipping (Ada 2023)

Educational Ada 2023 implementation of the **Liang–Barsky** 2-D line clipping
algorithm. A line segment is clipped against an **axis-aligned rectangular**
window using the parametric form

$$
x = x_0 + t\,\Delta x,\quad y = y_0 + t\,\Delta y
$$

and the four inequalities $t\,p_i \le q_i$ for the left, right, bottom, and
top edges. Entering boundaries ($p_i < 0$) and leaving boundaries
($p_i > 0$) yield $t_{\mathrm{enter}} = \max(0,\ldots)$ and
$t_{\mathrm{leave}} = \min(1,\ldots)$. Edges with $p_i = 0$ are parallel;
if the corresponding $q_i < 0$, the segment is rejected. The algorithm is
significantly more efficient than **Cohen–Sutherland** by doing as much testing
as possible before computing intersections.

Based on the principles described in
[Wikipedia: Liang–Barsky algorithm](https://en.wikipedia.org/wiki/Liang%E2%80%93Barsky_algorithm)
and Liang & Barsky, *An Analysis and Algorithm for Polygon Clipping*,
ACM Transactions on Graphics, 1984.

## Project Overview

| Algorithm | Style | Notes |
| --- | --- | --- |
| Cohen–Sutherland | Outcodes + iterative edge clips | May clip a segment multiple times |
| **Liang–Barsky** | Parametric `t` against four edges | Fast; extends to 3-D |
| Cyrus–Beck | Parametric vs convex polygon | General convex windows |
| Nicholl–Lee–Nicholl | Canonical regions + few intersections | 2-D rectangle only |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Window | `Make_Window`, `Is_Valid_Window` | Axis-aligned clip rectangle |
| PQ | `Compute_PQ` | $p_{1..4}$, $q_{1..4}$ for left/right/bottom/top |
| Parameters | `Clip_Parameters` | $t_{\mathrm{enter}}$, $t_{\mathrm{leave}}$ or reject |
| Point | `Point_At_Parameter` | $(x_0,y_0) + t(\Delta x,\Delta y)$ |
| Main clip | `Liang_Barsky_Clip` | Accept/Reject + clipped segment |
| Params clip | `Liang_Barsky_Clip_Params` | Clip + retained `t0`/`t1` |
| Reference | `Cohen_Sutherland_Clip` | In-package CS clip for agreement tests |
| Helpers | `Make_Segment`, `Length`, `Point_Inside_Window`, `Same_Clipped_Segment` | Fixtures & comparison |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Segment`,
`Clip_Window`, `Clip_Result`, `Parameter` in `0 .. 1`, `PQ_Values`, …).
Public subprograms carry `Pre` / `Post` / `Global` contract aspects where
meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`.

## Usage

```bash
cd /workspace/ada-liang-barsky
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections covering:

- Vector helpers, windows, segments, point-in-window
- `Compute_PQ` left/right/bottom/top values
- `Clip_Parameters` fully inside / outside / enter-leave
- `Point_At_Parameter` at $t \in \{0, 0.5, 1\}$
- `Liang_Barsky_Clip` fixtures (inside, outside, edge crossings)
- `Liang_Barsky_Clip_Params` retained $t_0,t_1$
- Parallel outside, horizontal / vertical / diagonal
- Degenerate point segments
- `Cohen_Sutherland_Clip` reference + LB↔CS agreement lattice

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `liang_barsky.gpr`:

```ada
project Liang_Barsky is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Liang_Barsky;
```

Sources live in the repository root (no `src/` folder):

- `liang_barsky.ads` / `liang_barsky.adb` — package
- `tests.adb` — test main
- `liang_barsky.gpr`, `Makefile`, `README.md`

## References

1. Liang, Y.-D. & Barsky, B. A. (1984). *An Analysis and Algorithm for Polygon Clipping*. ACM Transactions on Graphics, 3(1), 1–22.
2. Hearn, D. & Baker, M. P. *Computer Graphics*. Prentice Hall (Liang–Barsky textbook treatment).
3. Wikipedia: [Liang–Barsky algorithm](https://en.wikipedia.org/wiki/Liang%E2%80%93Barsky_algorithm)
4. Related: Nicholl–Lee–Nicholl, Cyrus–Beck, Cohen–Sutherland.
