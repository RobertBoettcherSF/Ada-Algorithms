# Cone Tracing (Ada 2023)

Educational, compilable Ada 2023 implementation of **cone tracing** and related
**beam tracing** algorithms. Thick rays (circular cones / pyramidal beams)
approximate pixel footprints and solid angles to reduce aliasing compared with
zero-thickness rays.

Based on the principles described in
[Wikipedia: Cone tracing](https://en.wikipedia.org/wiki/Cone_tracing)
(Amanatides 1984 and later differential / voxel cone-tracing work).

## Project Overview

Conventional ray tracing models rays as geometric lines with no thickness. From
a light-transport perspective that is inaccurate: a sensor pixel has non-zero
area, so energy arrives from a **solid angle** (the pixel footprint). Cone
tracing replaces each ray with a cone (or pyramidal beam) whose aperture matches
that footprint.

This package provides typed Ada constructions and queries for:

- Circular cones from an eye / pixel
- Pyramidal beams through pixel corners
- Analytical cone–sphere and cone–plane tests, plus a conservative AABB overlap
- Soft-shadow / penumbra approximation via light cones
- Glossy reflection cones expanded by roughness
- Footprint-driven LOD / mip selection
- Depth-of-field cones whose cross-section shrinks to the focus plane then expands

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Circular cone | `Construct_Circular_Cone` | Apex, unit axis, half-angle from pixel extent |
| Pixel beam | `Construct_Pixel_Beam`, `Beam_Half_Angles` | Four corner rays; enclosing half-angle |
| Cone–sphere | `Intersect_Cone_Sphere` | Analytical angular test + coverage proxy |
| Cone–plane / AABB | `Intersect_Cone_Plane`, `Cone_Overlaps_AABB` | Footprint disk; conservative scene query |
| Soft shadow | `Soft_Shadow_Cone` | Umbra / penumbra from light & occluder angles |
| Glossy reflection | `Glossy_Reflection_Cone` | Reflection axis + roughness aperture |
| Footprint LOD | `Footprint_LOD` | Radius at hit → filter width / mip level |
| Depth of field | `Depth_Of_Field_Cone` | Lens radius shrinks then expands about focus |
| Helpers | `Normalize`, `Dot`, `Cross`, `Clamp`, … | Shared vector / angle utilities |

Strong typing uses domain subtypes (`Half_Angle`, `Non_Negative`, `Roughness`,
`LOD_Level`, …) over a shared `type Real is digits 6`. Public subprograms carry
`Pre` / `Post` / `Global` contract aspects where meaningful.

## Usage

```bash
cd /workspace/ada-cone-tracing
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 16 sections and 50+ `Check` assertions
covering:

- Functional correctness of each public variant
- Edge cases (parallel / behind-apex planes, zero half-angle)
- Error handling (`Degenerate_Geometry`, `Invalid_Input`)
- Invariants (unit axes, monotonic radius, focus-plane zero CoC)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `cone_tracing.gpr`:

```ada
project Cone_Tracing is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Cone_Tracing;
```

Sources live in the repository root (no `src/` folder):

- `cone_tracing.ads` / `cone_tracing.adb` — package
- `tests.adb` — test main
- `cone_tracing.gpr`, `Makefile`, `README.md`

## References

1. Amanatides, J. (1984). *Ray tracing with cones*. ACM SIGGRAPH.
2. Wikipedia: [Cone tracing](https://en.wikipedia.org/wiki/Cone_tracing)
3. Igehy, H. *Tracing Ray Differentials*
4. Crassin et al. (2011). *Interactive Indirect Illumination Using Voxel Cone Tracing*
