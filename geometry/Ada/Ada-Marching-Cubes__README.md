# Marching Cubes (Ada 2023)

Educational Ada 2023 implementation of **marching cubes**: an isosurface
extraction algorithm that classifies each grid cube into one of **256**
configurations from its eight corner samples, looks up a triangulation of the
intersected edges, and places triangle vertices by linear interpolation along
those edges (Lorensen & Cline, SIGGRAPH 1987).

Face and interior ambiguities of the trilinear interpolant are documented; this
package includes an **Asymptotic Decider** helper (Nielson & Hamann, 1991) for
face-saddle resolution. Full Chernyaev Marching Cubes 33 / interior
disambiguation is out of scope for this educational package.

Based on the principles described in
[Wikipedia: Marching cubes](https://en.wikipedia.org/wiki/Marching_cubes).

## Project Overview

Cube corners use the standard unit-cell numbering
`0=(0,0,0) … 6=(1,1,1)`. The twelve cube edges follow the classic Paul Bourke /
Lorensen numbering. Bit *i* of the case index is set when corner *i* is
**strictly below** the isolevel (classic table convention). The triangulation
table is the well-known 256-entry educational table.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Case index | `Cube_Case_Index` | 0..255 from eight corner signs |
| Edge interpolate | `Interpolate_Edge_Vertex` | Position (+ optional gradient blend) |
| Lookup / cell | `Lookup_Triangles` / `March_Cube` | Emit 0..5 triangles (256-case table) |
| Single cell | `March_Single_Cube` | March one grid cell into a mesh |
| Face resolve | `Asymptotic_Decider` / `Disambiguate_Face` | Nielson–Hamann face saddle helper |
| Full grid | `March_Grid` | March an NxNxN scalar field to a mesh |
| Normals | `Face_Normal` / `Estimate_Vertex_Normal` | Triangle and central-difference normals |
| Stats | `Count_Triangles` / `Compute_Mesh_Stats` | Mesh size and AABB |
| Fixtures | `Fill_Sphere_SDF` / `Fill_Plane_Field` / `Fill_Metaball_Field` | Deterministic test fields |

Strong typing uses domain types (`Real` digits 6, `Vec3`, `Triangle`, `Mesh`,
`Scalar_Grid3`, `Case_Index`). Public subprograms carry `Pre` / `Post` /
`Global` contract aspects where meaningful (`SPARK_Mode => Off`).

Grids are bounded by `Max_Grid_Dim` (32) and meshes by `Max_Triangles`
(16384) so educational demos stay safe.

## Usage

```bash
cd /workspace/ada-marching-cubes
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 13+ sections and 50+ `Check` assertions
covering:

- Vector helpers and cube-corner offsets
- Case indices (empty / full / single-corner / mixed)
- Linear edge interpolation
- Lookup table and single-cube triangulation
- Asymptotic decider / face disambiguation
- Single-cell and full-grid marching (plane, sphere SDF, metaballs)
- Adjacent-cell shared-edge consistency
- Face / estimated normals and mesh statistics
- Named exceptions (`Degenerate_Geometry`, `Invalid_Argument`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `marching_cubes.gpr`:

```ada
project Marching_Cubes is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Marching_Cubes;
```

Sources live in the repository root (no `src/` folder):

- `marching_cubes.ads` / `marching_cubes.adb` — package
- `tests.adb` — test main
- `marching_cubes.gpr`, `Makefile`, `README.md`

## Relation to marching squares and marching tetrahedra

**Marching squares** is the 2-D analogue (16 cell cases, isolines/isobands).
**Marching tetrahedra** splits each cube into six tetrahedra (16 cases each) and
was historically used as a patent-free, crack-oriented alternative; it avoids
classic MC face ambiguity by construction. This package implements the original
**marching cubes** 256-case approach with a documented face asymptotic-decider
helper for educational study of those ambiguities.

## Applications

Typical uses include medical CT/MRI isosurface visualization and metaball /
metasurface modelling in computer graphics.

## References

1. Lorensen, W. E. & Cline, H. E. (1987). *Marching cubes: A high resolution 3D surface construction algorithm.* ACM SIGGRAPH Computer Graphics.
2. Nielson, G. M. & Hamann, B. (1991). *The asymptotic decider: Resolving the ambiguity in marching cubes.* Visualization '91.
3. Chernyaev, E. (1995). *Marching Cubes 33: construction of topologically correct isosurfaces.*
4. Wikipedia: [Marching cubes](https://en.wikipedia.org/wiki/Marching_cubes)
5. Wikipedia: [Marching squares](https://en.wikipedia.org/wiki/Marching_squares)
6. Wikipedia: [Marching tetrahedra](https://en.wikipedia.org/wiki/Marching_tetrahedra)
