# Cohen–Sutherland Line Clipping (Ada 2023)

Educational Ada 2023 implementation of the **Cohen–Sutherland** line clipping
algorithm. The plane is divided into **9 regions** with **4-bit outcodes**
(TOP, BOTTOM, RIGHT, LEFT). A segment is:

- **trivially accepted** when the bitwise OR of endpoint outcodes is `0000`
  (both endpoints inside the viewport);
- **trivially rejected** when the bitwise AND is nonzero (both endpoints share
  at least one outside half-plane);
- otherwise the outside endpoint is clipped against a crossed edge, its
  outcode is recomputed, and the loop continues.

The algorithm applies only to a **rectangular** clip window. The educational
**3-D lite** variant extends the same idea with **6-bit** outcodes against an
axis-aligned box.

Developed in 1967 during flight-simulator work by **Danny Cohen** and
**Ivan Sutherland**. Based on
[Wikipedia: Cohen–Sutherland algorithm](https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm)
and Newman & Sproull, *Principles of Interactive Computer Graphics*.

## Project Overview

| Algorithm | Style | Notes |
| --- | --- | --- |
| **Cohen–Sutherland** | Outcodes + iterative edge clips | May clip a segment multiple times |
| Liang–Barsky | Parametric `t` against four edges | Fast; extends to 3-D |
| Cyrus–Beck | Parametric vs convex polygon | General convex windows |
| Nicholl–Lee–Nicholl | Canonical regions + few intersections | 2-D rectangle only |
| Fast clipping | Line encoding + case handlers | Same 9-region grid; fewer loops |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Window | `Make_Window`, `Is_Valid_Window` | Axis-aligned clip rectangle |
| Box | `Make_Box`, `Is_Valid_Box` | Axis-aligned 3-D clip box |
| Outcodes | `Compute_OutCode` | 4-bit (2-D) / 6-bit (3-D) region codes |
| Trivial | `Trivial_Accept`, `Trivial_Reject` | OR=0 accept / AND≠0 reject helpers |
| Edges | `Clip_Against_Edge` | Intersect segment with one window edge |
| Main clip | `Cohen_Sutherland_Clip` | Classic iterative 2-D outcode clip |
| 3-D lite | `Cohen_Sutherland_Clip_3D_Lite` | Educational 6-bit AABB clip |
| Reference | `Liang_Barsky_Clip_Lite` | Minimal parametric clip for agreement |
| Helpers | `Make_Segment`, `Length`, `Point_Inside_Window` / `Point_Inside_Box`, `Same_Clipped_Segment` | Fixtures & comparison |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Vec3`, `Segment`,
`Segment3`, `Clip_Window`, `Clip_Box`, `Out_Code`, `Out_Code_3D`,
`Clip_Result`, `Clip_Result_3D`, …).
Public subprograms carry `Pre` / `Post` / `Global` contract aspects where
meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`.

## Usage

```bash
cd /workspace/ada-cohen-sutherland
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections covering:

- Vector helpers (2-D / 3-D), windows, boxes, segments, point-in-window
- Nine-region `Compute_OutCode` bit patterns
- `Trivial_Accept` / `Trivial_Reject` (2-D and 3-D)
- `Clip_Against_Edge` (including parallel raise)
- `Cohen_Sutherland_Clip` trivial, edge crossings, partial, degenerate
- `Liang_Barsky_Clip_Lite` reference + CS↔LB agreement lattice
- `Cohen_Sutherland_Clip_3D_Lite` inside / outside / Z-axis / partial
- Full 9-region grid coverage and boundary endpoints

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `cohen_sutherland.gpr`:

```ada
project Cohen_Sutherland is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Cohen_Sutherland;
```

Sources live in the repository root (no `src/` folder):

- `cohen_sutherland.ads` / `cohen_sutherland.adb` — package
- `tests.adb` — test main
- `cohen_sutherland.gpr`, `Makefile`, `README.md`

## References

1. Newman, W. M. & Sproull, R. F. (1973). *Principles of Interactive Computer Graphics*. McGraw–Hill.
2. Foley, J. D. et al. *Computer Graphics: Principles and Practice*. Addison-Wesley.
3. Wikipedia: [Cohen–Sutherland algorithm](https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm)
4. Related: Liang–Barsky, Cyrus–Beck, Nicholl–Lee–Nicholl, Fast clipping.
