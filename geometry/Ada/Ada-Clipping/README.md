# Clipping — Survey (Ada 2023)

Educational Ada 2023 **umbrella / survey** package for
[Wikipedia: Clipping (computer graphics)](https://en.wikipedia.org/wiki/Clipping_(computer_graphics)).
**Clipping** selectively enables or disables rendering inside a region of
interest: mathematically, draw only the intersection of the clip region and
the scene. In 2-D this is a window/viewport (often the composite of *user*
and *device* clip). In 3-D it includes the view frustum, **near clipping**,
and **far / Z clipping**. Terminology often distinguishes **clipping**
(trimming geometry) from **culling** (discarding primitives).

This repository embeds compact, self-contained implementations spanning
point, line, polygon, region-intersection, educational 2-D frustum, and
near/far Z clip. Deeper treatments of individual algorithms live in sibling
Ada algorithm repos (see below).

Based on the principles described on Wikipedia and in Newman & Sproull,
Foley / van Dam, and Hearn & Baker.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Clip region (2-D)** | Axis-aligned `Clip_Rect` | Window / viewport |
| **Point clip** | Inclusive `Point_In_Rect` / `Clip_Point` | Accept / reject |
| **Line clip** | Embedded **Liang–Barsky** | Parametric $t$ vs four edges |
| **Polygon clip** | Embedded **Sutherland–Hodgman** | Convex clip poly / rect |
| **Composite clip** | `Intersect_Clip_Regions` | User ∩ device AA rects |
| **2-D frustum** | Convex quad + half-plane clip | Educational view frustum |
| **Near / far Z** | `Near_Far_Clip_3D_Lite` | Axis-aligned depth planes |
| **Visibility** | `Classify_Visibility` | Fully / Partially / Invisible |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Sibling repositories (deeper treatments)

| Topic | Repository |
| --- | --- |
| Line clipping (survey) | [Ada-Line-Clipping](https://github.com/RobertBoettcherSF/Ada-Line-Clipping) |
| Cohen–Sutherland | [Ada-Cohen-Sutherland](https://github.com/RobertBoettcherSF/Ada-Cohen-Sutherland) |
| Liang–Barsky | [Ada-Liang-Barsky](https://github.com/RobertBoettcherSF/Ada-Liang-Barsky) |
| Cyrus–Beck | [Ada-Cyrus-Beck](https://github.com/RobertBoettcherSF/Ada-Cyrus-Beck) |
| Nicholl–Lee–Nicholl | [Ada-Nicholl-Lee-Nicholl](https://github.com/RobertBoettcherSF/Ada-Nicholl-Lee-Nicholl) |
| Fast clipping | [Ada-Fast-Clipping](https://github.com/RobertBoettcherSF/Ada-Fast-Clipping) |
| Sutherland–Hodgman | [Ada-Sutherland-Hodgman](https://github.com/RobertBoettcherSF/Ada-Sutherland-Hodgman) |
| Weiler–Atherton | [Ada-Weiler-Atherton](https://github.com/RobertBoettcherSF/Ada-Weiler-Atherton) |
| Vatti | [Ada-Vatti](https://github.com/RobertBoettcherSF/Ada-Vatti) |

This survey package does **not** depend on those packages; algorithms are
embedded compactly for the umbrella topic.

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Rect | `Make_Rect`, `Is_Valid_Rect`, `Point_In_Rect`, `Rect_To_Polygon` | 2-D AA clip region |
| Point | `Clip_Point` | Accept / reject vs rect |
| Line | `Clip_Line_Liang_Barsky` | Embedded parametric line clip |
| Polygon | `Clip_Polygon_Sutherland_Hodgman`, `Clip_Polygon_To_Rect` | Embedded SH |
| Composite | `Intersect_Clip_Regions` | User ∩ device |
| Frustum | `Make_Frustum_2D`, `Is_Valid_Frustum`, `Clip_Against_Frustum` | 2-D convex quad |
| Depth | `Near_Far_Clip_3D_Lite` | Near / far Z segment clip |
| Visibility | `Classify_Visibility` | Fully / Partially / Invisible |
| Helpers | `Make_Segment`, `Make_Segment3`, `Make_Polygon`, `Length` | Fixtures |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Vec3`, `Segment`,
`Segment3`, `Polygon`, `Clip_Rect`, `Clip_Result`, `Visibility`, …).
Public subprograms carry `Pre` / `Post` / `Global` contract aspects where
meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`, `Capacity_Exceeded`.

### Near_Far_Clip_3D_Lite limits

The lite variant clips a 3-D segment against two axis-aligned depth planes.
It is **not** a full perspective view-frustum / homogeneous clip-space
pipeline (see GPU / OpenGL clipping literature for that).

## Usage

```bash
cd /workspace/ada-clipping
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 14 sections covering:

- Vector helpers, rects, segments, polygons
- `Clip_Point` accept / reject
- Liang–Barsky line fixtures (inside / outside / crossing)
- Sutherland–Hodgman polygon fixtures
- User ∩ device region intersection
- Educational 2-D frustum point and line clip
- Near / far Z 3-D segment clip
- `Classify_Visibility` Fully / Partially / Invisible
- Composite clip pipeline and degenerates

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `clipping.gpr`:

```ada
project Clipping is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Clipping;
```

Sources live in the repository root (no `src/` folder):

- `clipping.ads` / `clipping.adb` — package
- `tests.adb` — test main
- `clipping.gpr`, `Makefile`, `README.md`

## References

1. Wikipedia: [Clipping (computer graphics)](https://en.wikipedia.org/wiki/Clipping_(computer_graphics))
2. Liang, Y.-D. & Barsky, B. A. (1984). ACM TOG — Liang–Barsky
3. Sutherland, I. E. & Hodgman, G. W. (1974). CACM — Sutherland–Hodgman
4. Cyrus, M. & Beck, J. (1978). Computers & Graphics — Cyrus–Beck
5. Newman, W. & Sproull, R. *Principles of Interactive Computer Graphics*
6. Foley, van Dam, Feiner, Hughes — *Computer Graphics: Principles and Practice*
