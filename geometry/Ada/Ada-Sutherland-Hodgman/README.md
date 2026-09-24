# Sutherland–Hodgman Polygon Clipping (Ada 2023)

Educational Ada 2023 implementation of the **Sutherland–Hodgman** polygon
clipping algorithm. A subject polygon is clipped by a **convex** clip polygon
in 2-D by extending each clip edge in turn, keeping only vertices on the
visible half-plane, and inserting intersection vertices where subject edges
cross the infinite clip line. The result is always a **single** polygon
(concave subjects clipped outside the window may produce coincident /
overlapping edges — acceptable for rendering).

Based on the principles described in
[Wikipedia: Sutherland–Hodgman algorithm](https://en.wikipedia.org/wiki/Sutherland%E2%80%93Hodgman_algorithm)
and Sutherland & Hodgman, *Reentrant Polygon Clipping*, Communications of the
ACM 17(1):32–42, 1974.

## Project Overview

**Clip polygon must be convex** (`Is_Convex_Polygon`); the package raises
`Non_Convex_Clip` otherwise. Subject polygons may be concave. Clip orientation
is detected automatically: for a counter-clockwise clip, the **left** side of
each directed edge is inside; for clockwise, the **right** side.

Compared with **Weiler–Atherton**: WA can return multiple disjoint pieces when
a concave clip cuts the subject into several regions, but is more complex.
Sutherland–Hodgman is preferred for many rendering pipelines because it is
simpler and always emits one polygon. An educational **3-D** extension
(`Clip_Polygon_Against_Plane_3D_Lite`) shows how the same half-plane idea
clips a polygon against a viewing-frustum plane.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Half-plane | `Inside_HalfPlane`, `Clip_Against_Edge` | Core inside test + one edge pass |
| Intersection | `Compute_Intersection` | Subject edge ∩ infinite clip line |
| Full clip | `Sutherland_Hodgman_Clip` | Iterative clip vs convex polygon |
| Rect | `Clip_Against_Rect` | Axis-aligned window convenience |
| Frustum 2-D | `Clip_Against_Frustum_2D` | Alias of SH for a convex window |
| 3-D lite | `Clip_Polygon_Against_Plane_3D_Lite` | Keep positive half-space of one plane |
| Convex check | `Is_Convex_Polygon` | Precondition helper for clip |
| Helpers | `Make_Rectangle`, `Make_Triangle`, `Signed_Area`, `Orient_*`, … | Fixtures & orientation |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Vec3`, `Polygon`,
`Polygon3`, `Edge`, `Plane3`, …). Public subprograms carry `Pre` / `Post` /
`Global` contract aspects where meaningful (`SPARK_Mode => Off`).

Bounds: `Max_Vertices = 64`.

## Usage

```bash
cd /workspace/ada-sutherland-hodgman
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections and 70+ `Check` assertions
covering:

- Vector / orientation / rectangle & triangle helpers
- `Is_Convex_Polygon` for convex and concave shapes
- `Inside_HalfPlane` and `Compute_Intersection` (including parallel raise)
- Single-edge `Clip_Against_Edge` pass
- Rect∩rect, triangle∩rect, fully inside / outside subjects
- `Clip_Against_Rect` and `Clip_Against_Frustum_2D`
- Clockwise clip orientation handling
- 3-D single-plane clip and `Plane_Signed_Distance`
- Named exceptions (`Non_Convex_Clip`, `Degenerate_Geometry`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `sutherland_hodgman.gpr`:

```ada
project Sutherland_Hodgman is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Sutherland_Hodgman;
```

Sources live in the repository root (no `src/` folder):

- `sutherland_hodgman.ads` / `sutherland_hodgman.adb` — package
- `tests.adb` — test main
- `sutherland_hodgman.gpr`, `Makefile`, `README.md`

## References

1. Sutherland, I. & Hodgman, G. (1974). *Reentrant Polygon Clipping*. Communications of the ACM, 17(1):32–42.
2. Slater, M., Steed, A. & Chrysanthou, Y. *Computer Graphics and Virtual Environments*. Addison Wesley, 2002.
3. Wikipedia: [Sutherland–Hodgman algorithm](https://en.wikipedia.org/wiki/Sutherland%E2%80%93Hodgman_algorithm)
4. Related: Weiler–Atherton, Vatti, Greiner–Hormann clipping algorithms.
