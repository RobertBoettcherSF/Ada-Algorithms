# Global Illumination (Ada 2023)

Educational, deterministic Ada 2023 implementation of **global illumination**
(GI) layer concepts: direct vs indirect lighting, one-bounce color bleeding,
radiosity form factors and gather, path-throughput accumulation, a caustic
density proxy, a discrete rendering-equation sample, and ambient-vs-GI contrast.

Based on the principles described in
[Wikipedia: Global illumination](https://en.wikipedia.org/wiki/Global_illumination)
(Whitted; radiosity; path tracing; photon mapping; diffuse inter-reflection;
caustics; the rendering equation $L_o = L_e + \int f_r L_i \cos\theta\,d\omega$).

This package provides **composable educational variants**. Full offline
algorithms live in dedicated sibling Ada repos (radiosity, path tracing,
photon mapping, ambient occlusion, beam tracing, …) — do not treat this as a
reimplementation of those solvers.

## Project Overview

Global illumination accounts for light that reaches a surface after bouncing
from other surfaces (indirect illumination), not only rays that travel
straight from a light source (direct illumination). Effects include color
bleeding, diffuse inter-reflection, and caustics. This package approximates
selected GI building blocks with typed Ada constructions:

- Lambertian direct illumination with optional hard shadows
- Single-bounce / one-bounce GI between planar patches
- Radiosity form factors (Nusselt / differential-area) and Jacobi gather
- Fixed-path BRDF·cos/pdf throughput (path-tracing style accumulator)
- Color bleeding from tinted emitters
- Photon-map style caustic density proxy
- Discrete hemisphere sum for the rendering equation
- Crude constant ambient vs computed indirect comparison

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Direct illumination | `Direct_Illumination` | Lambertian response to point / directional lights + optional occluder shadow |
| Indirect bounce | `Indirect_Bounce` | Single diffuse bounce between two patches |
| One-bounce GI | `One_Bounce_GI` | Sum of indirect bounces from a patch set |
| Form factor | `Radiosity_Form_Factor` | Differential-area / Nusselt form factor $F_{ij}$ |
| Radiosity gather | `Radiosity_Gather` | One Jacobi gather: $B_i = E_i + \rho_i \sum F_{ij} B_j$ |
| Path throughput | `Path_Throughput_Bounce` | Multiply $f_r \cos\theta / \mathrm{pdf}$ along a fixed path |
| Color bleeding | `Color_Bleeding` | Tinted irradiance transfer emitter → receiver |
| Caustic proxy | `Caustic_Proxy` | Kernel density estimate from redirected “photons” |
| RE sample | `Rendering_Equation_Sample` | Discrete sum approximating the hemisphere integral |
| Ambient vs GI | `Ambient_Term_Vs_GI` | Contrast constant ambient with computed indirect |
| Helpers | `Normalize`, `Color_Add`, `Segment_Occluded`, … | Shared vector / color / scene utilities |

Strong typing uses domain subtypes (`Radiance`, `Reflectance`, `Unit_Interval`,
`Non_Negative`, …) over a shared `type Real is digits 6`. Public subprograms
carry `Pre` / `Post` / `Global` contract aspects where meaningful.

Geometry fixtures use planar `Patch` records and sphere `Occluder`s — no file
I/O; samples and paths are fixed (deterministic, no PRNG).

## Usage

```bash
cd /workspace/ada-global-illumination
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections and 50+ `Check` assertions
covering:

- Functional correctness of each public variant
- Front vs back lighting, hard shadows, facing form factors
- Color bleeding (red / green tint transfer)
- Path throughput survival vs termination
- Ambient flattening vs GI contrast
- Error handling (`Degenerate_Geometry` on zero normalize)
- Invariants (form factors in `[0,1]`, non-negative radiance)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `global_illumination.gpr`:

```ada
project Global_Illumination is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Global_Illumination;
```

Sources live in the repository root (no `src/` folder):

- `global_illumination.ads` / `global_illumination.adb` — package
- `tests.adb` — test main
- `global_illumination.gpr`, `Makefile`, `README.md`

## Relation to sibling Ada algorithm repos

| Topic | Dedicated repo (full algorithm) | This package |
| --- | --- | --- |
| Radiosity | Ada radiosity solver | Form factor + one gather step |
| Path tracing | Ada path-tracing repo | Fixed-path throughput accumulator |
| Photon mapping | Ada photon-mapping repo | Caustic density proxy |
| Ambient occlusion | `ada-ambient-occlusion` | Ambient-vs-GI contrast only |
| Beam / cone tracing | `ada-beam-tracing`, `ada-cone-tracing` | Not reimplemented |

## References

1. Kajiya, J. T. (1986). *The rendering equation*. SIGGRAPH.
2. Whitted, T. (1980). *An improved illumination model for shaded display*. CACM.
3. Goral et al. (1984). *Modeling the interaction of light between diffuse surfaces* (radiosity).
4. Jensen, H. W. — Photon mapping.
5. Wikipedia: [Global illumination](https://en.wikipedia.org/wiki/Global_illumination)
