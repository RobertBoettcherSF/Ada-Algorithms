# Beam Tracing (Ada 2023)

Educational, compilable Ada 2023 implementation of **beam tracing** (Heckbert &
Hanrahan): unbounded pyramidal beams with polygonal cross-sections that replace
zero-thickness rays for visibility, reflection, refraction, acoustics, and
backwards caustic gathering.

Based on the principles described in
[Wikipedia: Beam tracing](https://en.wikipedia.org/wiki/Beam_tracing).

## Project Overview

Conventional ray tracing models rays as geometric lines with no thickness. Beam
tracing casts a **pyramidal beam** through the viewing frustum (or per pixel),
intersects scene polygons nearest-to-furthest, removes visible polygons from the
beam aperture, and spawns reflected / refracted child beams. Related techniques
include cone tracing (circular vs polygonal pyramid) and Watt-style backwards
beams from lights for caustics.

This package provides typed Ada constructions and queries for:

- Viewing and per-pixel pyramidal beams
- Planar polygon clip / subtract (aperture update)
- Specular reflection (planar image method) and Snell refraction
- Polygon and AABB scene queries
- Occluder sub-beam split
- Acoustic path length, delay, and geometric spreading
- Backwards beams from a light toward a receiver rectangle

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Viewing beam | `Construct_Viewing_Beam` | Pyramid through full image frustum |
| Pixel beam | `Construct_Pixel_Beam` | Four corner rays through one pixel |
| Clip / subtract | `Beam_Clip_Against_Polygon`, `Subtract_Polygon_From_Beam` | Sutherland–Hodgman aperture update |
| Reflect | `Reflect_Beam` | Planar mirror image-method child beam |
| Refract | `Refract_Beam` | Snell transmission; TIR → exception |
| Scene query | `Beam_Intersect_Polygon`, `Beam_Intersect_AABB` | Hit / coverage; conservative AABB |
| Occluder split | `Split_Beam_By_Occluder` | Visible vs occluded sub-beams |
| Acoustics | `Acoustic_Path_Attenuation`, `Propagation_Delay` | Path length, delay, 1/r spreading |
| Backwards / caustic | `Backwards_Beam_From_Light` | Light → receiver rectangle pyramid |
| Helpers | `Normalize`, `Dot`, `Cross`, `Make_Rectangle`, `Beam_Axis`, … | Shared vector / polygon utilities |

Strong typing uses domain subtypes (`Non_Negative`, `Index_Of_Refraction`,
`Sound_Speed`, …) over a shared `type Real is digits 6`. Public subprograms
carry `Pre` / `Post` / `Global` contract aspects where meaningful.

## Usage

```bash
cd /workspace/ada-beam-tracing
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 16 sections and 50+ `Check` assertions
covering:

- Functional correctness of each public variant
- Edge cases (miss polygons, empty clip results, near/far acoustics)
- Error handling (`Degenerate_Geometry`, `Invalid_Input`)
- Invariants (unit axes, image-apex reflection, Snell transmission)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `beam_tracing.gpr`:

```ada
project Beam_Tracing is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Beam_Tracing;
```

Sources live in the repository root (no `src/` folder):

- `beam_tracing.ads` / `beam_tracing.adb` — package
- `tests.adb` — test main
- `beam_tracing.gpr`, `Makefile`, `README.md`

## References

1. Heckbert, P. S. & Hanrahan, P. (1984). *Beam tracing polygonal objects*. Computer Graphics 18(3).
2. Watt, M. (1990). *Light-water interaction using backwards beam tracing*. SIGGRAPH.
3. Funkhouser et al. (1998). *A beam tracing approach to acoustic modelling*. SIGGRAPH.
4. Wikipedia: [Beam tracing](https://en.wikipedia.org/wiki/Beam_tracing)
