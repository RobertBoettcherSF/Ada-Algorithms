# Contour Lines (Ada 2023)

Educational Ada 2023 implementation of **contour lines** (**isolines** /
**isopleths**): curves where a scalar field $f(x,y)$ has a constant value
(a level set). In cartography, contours join points of equal elevation; the
**contour interval** is the elevation difference between successive lines.
The gradient of $f$ is always **perpendicular** to the contour; when lines
lie close together the magnitude of the gradient is large (steep slopes).

Based on the principles described in
[Wikipedia: Contour line](https://en.wikipedia.org/wiki/Contour_line).

This package focuses on **contour-map concepts** and **multi-level
extraction**. Isoline segments inside each 2×2 cell use a compact
marching-squares-style case table owned here. For the full educational
Marching Squares API (16-case lookup, isobands, triangle isolines), see the
companion repository **Ada-Marching-Squares**.

## Project Overview

A contour map is built from an arithmetic sequence of levels
`Min_Level + k·Interval`. Each level is extracted as a polyline of edge-
interpolated segments. Educational helpers cover bilinear sampling, numerical
gradients and orthogonality checks, slope classification from $|∇f|$,
transect profiles (plan view vs profile view), and iso-* labeling names
(isobar, isotherm, isohyet, isobath, …).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Contour interval | `Contour_Level_Count` / `Level_From_Index` / `Contour_Interval_Of` | Arithmetic level sequences |
| Sampling | `Sample_Height_Field` / `Bilinear_Sample` | Grid and bilinear field samples |
| Gradient | `Gradient_2D` / `Gradient_Perpendicular_Check` | $∇f$ and ⊥-to-contour check |
| Cell / level isolines | `Trace_Isoline_Cell` / `Extract_Isolines_At_Level` | Compact 2×2 extraction |
| Contour map | `Build_Contour_Map` | Multi-level isolines at a contour interval |
| Spacing | `Classify_Spacing` / `Spacing_From_Gradient` | Flat…Cliff from \|∇f\| |
| Labels | `Closest_Contour_Label` / `Format_Level_Label` / `Isoline_Kind_Name` | Educational naming |
| Transect | `Profile_Along_Line` | Values along a straight profile |
| Fixtures | `Fill_Hill_Field` / `Fill_Valley_Field` / `Fill_Ridge_Field` | Deterministic terrains |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Level_Value`,
`Contour_Interval_Value`, `Polyline`, `Contour_Map`, `Transect_Profile`,
`Slope_Class`, `Isoline_Kind`). Public subprograms carry `Pre` / `Post` /
`Global` contract aspects where meaningful (`SPARK_Mode => Off`).

Grids are bounded by `Max_Grid_Dim` (64), polylines by `Max_Segments` (1024),
and contour maps by `Max_Levels` (16).

## Usage

```bash
cd /workspace/ada-contour-lines
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 14 sections and 50+ `Check` assertions
covering:

- Vector helpers and perpendicular
- Contour interval / level indexing
- Grid and bilinear sampling
- Gradients and orthogonality to contour tangents
- Single-cell and full-grid isoline extraction
- Multi-level contour maps
- Spacing classification (gentle … cliff)
- Label helpers (contour / isobar / isotherm / …)
- Transect profiles across a hill
- Hill, valley, and ridge fixtures
- Named exceptions (`Degenerate_Geometry`, `Invalid_Argument`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `contour_lines.gpr`:

```ada
project Contour_Lines is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Contour_Lines;
```

Sources live in the repository root (no `src/` folder):

- `contour_lines.ads` / `contour_lines.adb` — package
- `tests.adb` — test main
- `contour_lines.gpr`, `Makefile`, `README.md`

## Relation to Marching Squares

| Concern | Contour_Lines | Marching_Squares |
| --- | --- | --- |
| Multi-level contour maps / intervals | Yes | Single isolevel focus |
| Cartographic labeling / spacing class | Yes | No |
| Transect profiles | Yes | No |
| Full 16-case public API / isobands / triangles | Compact cell tracer only | Yes |

## Applications

Topographic contour maps, meteorological isobars and isotherms, bathymetric
isobaths, precipitation isohyets, and any sampled scalar field where level sets
convey structure.

## References

1. Wikipedia: [Contour line](https://en.wikipedia.org/wiki/Contour_line)
2. Wikipedia: [Marching squares](https://en.wikipedia.org/wiki/Marching_squares)
3. Wikipedia: [Level set](https://en.wikipedia.org/wiki/Level_set)
