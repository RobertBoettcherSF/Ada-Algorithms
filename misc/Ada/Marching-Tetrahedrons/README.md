# Marching Tetrahedrons (Ada 2023)

Educational Ada 2023 implementation of **marching tetrahedra** (also spelled
**marching tetrahedrons**): an isosurface extraction algorithm that splits each
grid cube into six tetrahedra, classifies each tetrahedron into one of 16
configurations, and emits zero, one, or two triangles by linearly interpolating
edge crossings of an isolevel.

Marching tetrahedra was introduced in 1991 (Doi & Koide) as a crack-free,
historically patent-free alternative to **marching cubes**. It clarifies cube
configuration ambiguity by operating on tetrahedra; adjacent cubes share face
edges and face diagonals so interpolated vertices match across cell faces.

Based on the principles described in
[Wikipedia: Marching tetrahedra](https://en.wikipedia.org/wiki/Marching_tetrahedra)
(redirects from *Marching tetrahedrons*).

## Project Overview

Each cube is cut diagonally through all three pairs of opposing faces so the
six irregular tetrahedra share one main diagonal (here corners `0`–`6`). The
cell then has nineteen edges (12 cube + 6 face diagonals + 1 space diagonal).
For each tetrahedron, corner signs relative to the isolevel form a 4-bit case
index; a lookup emits triangle strips of interpolated edge vertices.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Cube split | `Split_Cube_Into_Tetrahedra` | Fixed 6-tet vertex-index mapping |
| Case index | `Tetra_Case_Index` | 0..15 from four corner signs |
| Edge interpolate | `Interpolate_Edge_Vertex` | Position (+ optional gradient blend) |
| Tet triangulate | `Triangulate_Tetrahedron` | Emit 0..2 iso triangles |
| Single cell | `March_Single_Cube` | Split + triangulate one grid cell |
| Full grid | `March_Grid` | March an NxNxN scalar field to a mesh |
| Normals | `Face_Normal` / `Estimate_Normal` | Triangle and tet-gradient normals |
| Stats | `Count_Triangles` / `Compute_Mesh_Stats` | Mesh size and AABB |
| Fixtures | `Fill_Sphere_SDF` / `Fill_Plane_Field` | Deterministic test fields |

Strong typing uses domain types (`Real` digits 6, `Vec3`, `Tetrahedron`,
`Triangle`, `Mesh`, `Scalar_Field`, `Case_Index`). Public subprograms carry
`Pre` / `Post` / `Global` contract aspects where meaningful
(`SPARK_Mode => Off`).

Grids are bounded by `Max_Grid_Dim` (32) and meshes by `Max_Triangles`
(16384) so educational demos stay safe.

## Usage

```bash
cd /workspace/ada-marching-tetrahedrons
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections and 50+ `Check` assertions
covering:

- Vector helpers and cube-corner offsets
- Six-tetrahedron split sharing diagonal 0–6
- All 16 tetra case indices and triangle counts (0 / 1 / 2)
- Linear edge interpolation (position and gradient)
- Single-cell and full-grid marching (plane and sphere SDF fixtures)
- Face / estimated normals and mesh statistics
- Named exceptions (`Degenerate_Geometry`, `Invalid_Argument`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `marching_tetrahedrons.gpr`:

```ada
project Marching_Tetrahedrons is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Marching_Tetrahedrons;
```

Sources live in the repository root (no `src/` folder):

- `marching_tetrahedrons.ads` / `marching_tetrahedrons.adb` — package
- `tests.adb` — test main
- `marching_tetrahedrons.gpr`, `Makefile`, `README.md`

## Relation to marching cubes

Marching cubes classifies 256 configurations of eight cube corners and may need
extra ambiguity handling on face/body saddles. Marching tetrahedra replaces that
with six tetrahedra × 16 cases, is unambiguous, and reuses face-diagonal
intersections across cells (crack-free). Trade-offs: up to nineteen edge
samples per cube versus twelve, and the chosen tet orientation can introduce
mild “bumps” along face diagonals.

## References

1. Doi, A. & Koide, A. (1991). *An Efficient Method of Triangulating Equi-Valued Surfaces by Using Tetrahedral Cells.* IEICE Transactions.
2. Hansen, C. D. & Johnson, C. R. (2004). *Visualization Handbook.* Academic Press.
3. Wikipedia: [Marching tetrahedra](https://en.wikipedia.org/wiki/Marching_tetrahedra)
4. Wikipedia: [Marching cubes](https://en.wikipedia.org/wiki/Marching_cubes)
