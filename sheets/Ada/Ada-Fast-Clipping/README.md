# Fast Clipping — Line Encoding Line Clip (Ada 2023)

Educational Ada 2023 implementation of the **Sobkow–Pospisil–Yang Fast
clipping** algorithm (also called *line encoding*). Endpoints of a segment are
classified into the classic **9-region** Cohen–Sutherland grid; the pair of
outcodes forms a **line encoding**. A case / lookup on that encoding decides
trivial **Accept**, trivial **Reject**, or **Need_Clip** with suggested edges —
aiming for fewer intersection calculations than iterative **Cohen–Sutherland**,
which may revisit the same segment several times.

Based on the principles described in
[Wikipedia: Line clipping — Fast clipping](https://en.wikipedia.org/wiki/Line_clipping#Fast_clipping)
(redirect from *Fast clipping*) and Sobkow, Pospisil & Yang, *A Fast
Two-Dimensional Line Clipping Algorithm via Line Encoding*, Computers &
Graphics, 1987.

## Project Overview

| Algorithm | Style | Notes |
| --- | --- | --- |
| Cohen–Sutherland | Outcodes + iterative edge clips | May clip a segment multiple times |
| Liang–Barsky | Parametric `t` against four edges | Fast; extends to 3-D |
| Cyrus–Beck | Parametric vs convex polygon | General convex windows |
| Nicholl–Lee–Nicholl | Canonical regions + few intersections | 2-D rectangle only |
| Skala / O(lg N) | Duality / binary search on convex | Polygon windows |
| **Fast clipping** | Line encoding + case handlers | Same 9-region grid; fewer loops |

### Fast clipping vs CS / LB / NLN

- **vs Cohen–Sutherland:** Same 9-region outcodes, but the *pair* of codes is
  encoded once and dispatched to a specialized handler (Accept / Reject /
  Need_Clip with suggested edges) instead of looping while reclassifying.
- **vs Liang–Barsky:** LB is parametric (`t_enter` / `t_leave`) and tests all
  four edges; Fast clipping is an encoding approach that early-outs on region
  pairs and intersects only suggested edges.
- **vs Nicholl–Lee–Nicholl:** NLN remaps the first endpoint into a small set of
  canonical regions and uses corner rays; Fast clipping keeps CS-style outcodes
  and switches on the combined line code.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Window | `Make_Window`, `Is_Valid_Window` | Axis-aligned clip rectangle |
| Regions | `Region_Outcode`, `Classify_Point`, `Encode_Line` | 9-region CS outcodes + line encoding |
| Case table | `Fast_Clip_Case` | Accept / Reject / Need_Clip + suggested edges |
| Main clip | `Fast_Clip` | Case dispatch + `Clip_Against_Edge` Need_Clip handler |
| Edges | `Clip_Against_Edge` | Intersect segment with one window edge line |
| Reference | `Cohen_Sutherland_Clip` | In-package CS clip for agreement tests |
| Reference | `Liang_Barsky_Clip_Lite` | Minimal parametric clip for agreement tests |
| Helpers | `Make_Segment`, `Length`, `Point_Inside_Window`, `Same_Clipped_Segment` | Fixtures & comparison |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Segment`,
`Clip_Window`, `Out_Code`, `Clip_Result`, `Fast_Clip_Decision`, `Line_Code`, …).
Public subprograms carry `Pre` / `Post` / `Global` contract aspects where
meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`.

## Usage

```bash
cd /workspace/ada-fast-clipping
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections covering:

- Vector helpers, windows, segments, point-in-window
- Nine-region `Region_Outcode` / `Classify_Point` / `Encode_Line`
- `Fast_Clip_Case` Accept / Reject / Need_Clip suggestions
- `Clip_Against_Edge` (including parallel raise)
- `Fast_Clip` trivial, edge crossings, partial, degenerate
- `Cohen_Sutherland_Clip` and `Liang_Barsky_Clip_Lite` references
- Fast ↔ CS ↔ LB agreement on a 4×4 endpoint lattice
- Case-table coverage over a region grid
- Diagonal / vertical / horizontal clips

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `fast_clipping.gpr`:

```ada
project Fast_Clipping is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Fast_Clipping;
```

Sources live in the repository root (no `src/` folder):

- `fast_clipping.ads` / `fast_clipping.adb` — package
- `tests.adb` — test main
- `fast_clipping.gpr`, `Makefile`, `README.md`

## References

1. Sobkow, M. S., Pospisil, P. & Yang, Y.-H. (1987). *A Fast Two-Dimensional Line Clipping Algorithm via Line Encoding*. Computers & Graphics, 11(4), 459–467.
2. Hearn, D. & Baker, M. P. *Computer Graphics*. Prentice Hall (line clipping chapter).
3. Wikipedia: [Line clipping — Fast clipping](https://en.wikipedia.org/wiki/Line_clipping#Fast_clipping)
4. Related: Cohen–Sutherland, Liang–Barsky, Cyrus–Beck, Nicholl–Lee–Nicholl, Skala.
