# Isosurfaces (Ada 2023)

Educational Ada 2022/2023 package for isosurfaces: the three-dimensional analogue of an isoline—representing a surface of constant value within a volume (the level set of $f: \mathbb{R}^3 \to \mathbb{R}$). Commonly applied in computational fluid dynamics (CFD), medical CT density visualization, molecular chemistry, and geophysics.
Based on the principles described in
[Wikipedia: Isosurface](https://en.wikipedia.org/wiki/Isosurface).

This package is an **educational isosurface layer**: sampling, level-set
evaluation, normals, and lightweight extraction helpers. It is **not** a
second full Marching Cubes implementation (no 256-case cube table). For the
full educational Marching Cubes / Marching Tetrahedra APIs, see the companion
repositories **Ada-Marching-Cubes** and **Ada-Marching-Tetrahedrons** (not
required as dependencies).

## Project Overview

Public helpers cover trilinear sampling of a scalar volume, inside/outside
classification relative to an isolevel, finite-difference gradients and
normals, a compact cube→6-tet cell triangulation, Surface Nets lite and Dual
Contouring lite extractors, mesh merge helpers, deterministic field fixtures
(sphere SDF, plane, gyroid), and a level-set band (shell) collector.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Sampling | `Evaluate_Field` / `Sample_Trilinear` | Grid and trilinear volume samples |
| Classification | `Is_Inside` / `Classify_Vertex` | Relative to isolevel |
| Gradient / normal | `Estimate_Gradient` / `Estimate_Normal` | Central differences on the field |
| Surface Nets lite | `Extract_Via_Surface_Nets_Lite` | Dual vertex per active cell + quads |
| Dual Contouring lite | `Extract_Via_Dual_Contouring_Lite` | Averaged Hermite + normal projection |
| Marching tetrahedra cell | `Marching_Tetrahedra_Cell` | Cube→6-tet single-cell wrapper |
| Mesh helpers | `Count_Triangles` / `Face_Normal` / `Append_*` / `Merge_Meshes` | Mesh utilities |
| Fixtures | `Fill_Sphere_SDF` / `Fill_Plane_Field` / `Fill_Gyroid_Field` | Deterministic volumes |
| Level-set band | `Collect_Level_Set_Band` | Voxels near the isolevel within ε |

Strong typing uses domain types (`Real` digits 6, `Vec3`, `Iso_Level`,
`Scalar_Grid3`, `Triangle`, `Mesh`, `Level_Set_Band`, `Vertex_Class`).
Public subprograms carry `Pre` / `Post` / `Global` contract aspects where
meaningful (`SPARK_Mode => Off`).

Grids are bounded by `Max_Grid_Dim` (32), meshes by `Max_Triangles` (8192),
and bands by `Max_Band_Points` (4096).

## Usage

```bash
cd /workspace/ada-isosurfaces
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 14 sections and 50+ `Check` assertions
covering:

- Vector helpers and cube-corner offsets
- Field evaluation and trilinear sampling
- Inside / outside / on-surface classification
- Gradients and normals on planar fields
- Marching-tetrahedra single-cell extraction
- Surface Nets lite and Dual Contouring lite on spheres / planes
- Mesh append, merge, and face normals
- Sphere, plane, and gyroid fixtures
- Level-set band collection
- Named exceptions (`Invalid_Argument`, `Degenerate_Geometry`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `isosurfaces.gpr`:

```ada
project Isosurfaces is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Isosurfaces;
```

Sources live in the repository root (no `src/` folder):

- `isosurfaces.ads` / `isosurfaces.adb` — package
- `tests.adb` — test main
- `isosurfaces.gpr`, `Makefile`, `README.md`

## Relation to Marching Cubes / Tetrahedrons

| Concern | Isosurfaces | Marching_Cubes / Tetrahedrons |
| --- | --- | --- |
| Volume sampling / classification / band | Yes | Focused on extraction |
| Surface Nets / Dual Contouring lite | Yes | No |
| Full 256-case MC table | No (conceptual reference only) | Marching_Cubes yes |
| Full cube→tet grid marcher | Single-cell wrapper only | Marching_Tetrahedrons yes |

## Applications

CFD pressure/vorticity surfaces, medical CT isodensity surfaces, molecular
metaballs / gyroids, and any sampled scalar volume where a constant-value
surface conveys structure.

## References

1. Wikipedia: [Isosurface](https://en.wikipedia.org/wiki/Isosurface)
2. Lorensen & Cline (1987): Marching Cubes
3. Ju et al. (2002): Dual Contouring of Hermite Data
4. Wikipedia: [Marching tetrahedra](https://en.wikipedia.org/wiki/Marching_tetrahedra)
5. Wikipedia: [Level set](https://en.wikipedia.org/wiki/Level_set)
