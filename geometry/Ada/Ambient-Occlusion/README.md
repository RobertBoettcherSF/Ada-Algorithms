# Ambient Occlusion (Ada 2023)

Educational, deterministic Ada 2023 implementation of **ambient occlusion** (AO)
and related accessibility / screen-space / horizon / ray-traced variants.
AO estimates how exposed each surface point is to ambient lighting — interiors of
tubes and inner corners darken, open surfaces stay bright — a crude global-
illumination approximation that looks like an overcast day.

Based on the principles described in
[Wikipedia: Ambient occlusion](https://en.wikipedia.org/wiki/Ambient_occlusion)
(Miller accessibility shading; Crytek real-time SSAO; Nvidia RTAO 2018; HBAO / GTAO).

## Project Overview

Ambient occlusion at a point $\bar{p}$ with normal $\hat{n}$ integrates
visibility over the hemisphere with respect to projected solid angle. This
package approximates that integral with typed Ada constructions:

- Cosine-weighted hemisphere / Monte Carlo sampling against scene proxies
- Open-sky visibility fraction
- Accessibility (dirt / reachability) shading
- Screen-space AO on a depth neighborhood (SSAO-style, pure math)
- Horizon-based AO (HBAO-style) from height walks
- Ground-truth-inspired integral over horizon angles (GTAO-like)
- Ray-traced AO with binary hemisphere hits (RTAO-style)
- Tube-interior and corner-darkening intuition helpers

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Hemisphere AO | `Hemisphere_AO` | Cosine-weighted discrete hemisphere samples vs scene |
| Monte Carlo AO | `MonteCarlo_Hemisphere_AO` | Same deterministic sampler (Wikipedia MC framing) |
| Sky visibility | `Sky_Visibility_AO` | Open-sky fraction of the hemisphere |
| Accessibility | `Accessibility_Shading` | Reach / dirt-style factor + clear radius |
| Screen-space | `Screen_Space_AO_Sample` | SSAO from depth + offset neighborhood |
| Horizon-based | `Horizon_Based_AO` | HBAO-style max horizon angle integration |
| Ground-truth | `Ground_Truth_AO_Integral` | GTAO-inspired analytical horizon integral |
| Ray-traced | `Ray_Traced_AO` | Binary ray hits within max distance |
| Tube demo | `Tube_Occlusion_Demo` | Deeper into a tube ⇒ darker |
| Corner demo | `Corner_Darkening` | Tighter / closer corners darken more |
| Helpers | `Normalize`, `Dot`, `Fixed_Hemisphere_Samples`, `Ray_Hit_Distance`, … | Shared vector / scene utilities |

Strong typing uses domain subtypes (`AO_Factor`, `Unit_Interval`, `Non_Negative`,
`Angle_Rad`, …) over a shared `type Real is digits 6`. Public subprograms carry
`Pre` / `Post` / `Global` contract aspects where meaningful.

Scene fixtures use spheres, planes, and AABBs — no file I/O; hemisphere directions
are a fixed Fibonacci spiral (deterministic, no PRNG).

## Usage

```bash
cd /workspace/ada-ambient-occlusion
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 16 sections and 50+ `Check` assertions
covering:

- Functional correctness of each public variant
- Open vs occluded scene comparisons
- Monotonic tube / corner darkening intuition
- Error handling (`Degenerate_Geometry` on zero normalize)
- Invariants (unit normals, factors in `[0,1]`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `ambient_occlusion.gpr`:

```ada
project Ambient_Occlusion is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Ambient_Occlusion;
```

Sources live in the repository root (no `src/` folder):

- `ambient_occlusion.ads` / `ambient_occlusion.adb` — package
- `tests.adb` — test main
- `ambient_occlusion.gpr`, `Makefile`, `README.md`

## References

1. Miller, G. (1994). *Efficient algorithms for local and global accessibility shading*. SIGGRAPH.
2. Wikipedia: [Ambient occlusion](https://en.wikipedia.org/wiki/Ambient_occlusion)
3. Crytek — real-time SSAO (CryEngine 2)
4. Bavoil et al. — Horizon-Based Ambient Occlusion (HBAO)
5. Jimenez et al. — Ground Truth Ambient Occlusion (GTAO)
6. Nvidia (2018) — Ray Traced Ambient Occlusion (RTAO)
