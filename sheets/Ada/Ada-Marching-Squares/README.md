# Marching Squares (Ada 2023)

Educational Ada 2023 implementation of **marching squares**: a contouring
algorithm that generates **isolines** (lines of a single isovalue) and
**isobands** (filled regions between thresholds) on a 2-D scalar field, plus a
triangle-mesh isoline variant.

Each 2×2 cell is classified into one of **16** configurations via a 4-bit case
index from its corner samples; a lookup table lists the edges that carry the
contour; linear interpolation places vertices exactly on those edges. Ambiguous
**saddle** cases (5 and 10) are resolved with the average centre value.

Based on the principles described in
[Wikipedia: Marching squares](https://en.wikipedia.org/wiki/Marching_squares).

## Project Overview

Corners are ordered clockwise from the top-left (MSB → LSB), matching the
Wikipedia walk. Cell edges are numbered `0=top`, `1=right`, `2=bottom`,
`3=left`. The contouring grid is one cell smaller than the sample lattice in
each direction.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Case index | `Cell_Case_Index` | 0..15 from four corner signs |
| Edge interpolate | `Interpolate_Edge` | Contour point on a cell edge |
| Lookup / cell isoline | `Lookup_Segments` / `March_Cell_Isoline` | Emit 0..2 segments (16-case table) |
| Saddle resolve | `Disambiguate_Saddle` / `Saddle_Center_Above` | Cases 5 & 10 via centre average |
| Full-grid isolines | `March_Grid_Isolines` | March NxM field to a polyline |
| Cell / grid isobands | `March_Cell_Isoband` / `March_Grid_Isobands` | Filled bands between Lo/Hi |
| Triangle isoline | `March_Triangle_Isoline` | Contour a single triangle (8 cases) |
| Stats | `Count_Segments` / `Compute_Polyline_Stats` | Segment count, AABB, length |
| Fixtures | `Fill_Height_Field` / `Fill_Radial_Field` | Deterministic test fields |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Segment`,
`Polyline`, `Band_Polygon`, `Scalar_Field`, `Case_Index`). Public subprograms
carry `Pre` / `Post` / `Global` contract aspects where meaningful
(`SPARK_Mode => Off`).

Grids are bounded by `Max_Grid_Dim` (64), polylines by `Max_Segments` (16384),
and band lists by `Max_Bands` (8192) so educational demos stay safe.

## Usage

```bash
cd /workspace/ada-marching-squares
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 14 sections and 50+ `Check` assertions
covering:

- Vector helpers and cell-corner offsets
- All 16 cell case indices
- Linear edge interpolation
- Lookup table and single-cell isolines
- Saddle disambiguation (cases 5 and 10)
- Full-grid isolines (planar height and radial fixtures)
- Cell and grid isobands
- Triangle isolines (8 cases)
- Named exceptions (`Degenerate_Geometry`, `Invalid_Argument`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `marching_squares.gpr`:

```ada
project Marching_Squares is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Marching_Squares;
```

Sources live in the repository root (no `src/` folder):

- `marching_squares.ads` / `marching_squares.adb` — package
- `tests.adb` — test main
- `marching_squares.gpr`, `Makefile`, `README.md`

## Applications

Typical uses of marching squares include topographic contour lines on elevation
grids and isobars on weather maps. The triangle variant applies the same idea to
Delaunay (or other) meshes of scattered samples.

## References

1. Maple, C. (2003). *Geometric design and space planning using the marching squares and marching cube algorithms.* GMAG 2003.
2. Mantz, H.; Jacobs, K.; Mecke, K. (2008). *Utilizing Minkowski functionals for image analysis: a marching square algorithm.* J. Stat. Mech.
3. Wikipedia: [Marching squares](https://en.wikipedia.org/wiki/Marching_squares)
4. Wikipedia: [Marching cubes](https://en.wikipedia.org/wiki/Marching_cubes)
