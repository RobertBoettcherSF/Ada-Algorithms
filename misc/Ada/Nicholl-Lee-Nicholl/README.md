# Nicholl–Lee–Nicholl Line Clipping (Ada 2023)

Educational Ada 2023 implementation of the **Nicholl–Lee–Nicholl (NLN)** 2-D
line clipping algorithm. A line segment is clipped against an **axis-aligned
rectangular** window by classifying the first endpoint into a small set of
**canonical regions** (Inside / Left / Left_Top), applying reflections and an
optional 90° remap when needed, then determining at most one or two clip edges
from corner-ray regions (L, LT, LB, TR, …). This reduces repeated intersection
work compared with **Cohen–Sutherland**.

Based on the principles described in
[Wikipedia: Nicholl–Lee–Nicholl algorithm](https://en.wikipedia.org/wiki/Nicholl%E2%80%93Lee%E2%80%93Nicholl_algorithm)
and Nicholl, Lee & Nicholl, *An efficient new algorithm for 2-D line clipping*,
SIGGRAPH 1987.

## Spelling note (Nicoll vs Nicholl)

Some course slides and spreadsheets write **“Nicoll–Lee–Nicoll”** or
**“Nicol–Lee–Nicol”**. The published authors are **Tina M. Nicholl**,
**D. T. Lee**, and **Robin A. Nicholl** — the correct algorithm name is
**Nicholl–Lee–Nicholl**. This repository uses the correct spelling throughout
(`Nicholl_Lee_Nicholl`, paths, and prose).

## Project Overview

NLN is limited to **2-D rectangles** (unlike Liang–Barsky / Cyrus–Beck, which
extend more naturally to 3-D or convex polygons). Related algorithms:

| Algorithm | Style | Notes |
| --- | --- | --- |
| Cohen–Sutherland | Outcodes + iterative edge clips | May clip a segment multiple times |
| Liang–Barsky | Parametric `t` against four edges | Fast; extends to 3-D |
| Cyrus–Beck | Parametric vs convex polygon | General convex windows |
| Fast clipping | Encoding variants | Same problem family |
| **Nicholl–Lee–Nicholl** | Canonical regions + few intersections | 2-D rectangle only |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Window | `Make_Window`, `Is_Valid_Window` | Axis-aligned clip rectangle |
| Regions | `Classify_Point`, `Region_Is_*` | NLN-style nine regions |
| Canonicalize | `Canonicalize_Segment`, `Apply_Inverse_*` | Reflect / 90° remap so P0 is Inside/Left/Left_Top |
| Direct cases | `Clip_Without_Canonicalize` | Educational case table when P0 already canonical |
| Main clip | `Nicholl_Lee_Nicholl_Clip` | Canonicalize → clip → inverse transform |
| Reference | `Cohen_Sutherland_Clip` | In-package CS clip for agreement tests |
| Edges | `Intersection_With_Edge` | Hit left/right/bottom/top infinite edge lines |
| Helpers | `Make_Segment`, `Length`, `Point_Inside_Window`, `Same_Clipped_Segment` | Fixtures & comparison |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Segment`,
`Clip_Window`, `Clip_Result`, `Region_Kind`, `Canonical_Transform`, …).
Public subprograms carry `Pre` / `Post` / `Global` contract aspects where
meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`, `Not_Canonical`.

## Usage

```bash
cd /workspace/ada-nicholl-lee-nicholl
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections and 70+ `Check` assertions
covering:

- Vector helpers, windows, segments, point-in-window
- Nine-region `Classify_Point` and corner/edge predicates
- `Intersection_With_Edge` (including parallel raise)
- `Canonicalize_Segment` for Left / Right / Top / corners + inverse
- `Clip_Without_Canonicalize` Inside / Left / Left_Top (+ `Not_Canonical`)
- `Nicholl_Lee_Nicholl_Clip` fixtures (inside, enter, reject, cross, degenerate)
- `Cohen_Sutherland_Clip` reference behaviour
- NLN ↔ CS agreement on fixtures and a 16-segment lattice
- Diagonal / vertical / horizontal clips

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `nicholl_lee_nicholl.gpr`:

```ada
project Nicholl_Lee_Nicholl is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Nicholl_Lee_Nicholl;
```

Sources live in the repository root (no `src/` folder):

- `nicholl_lee_nicholl.ads` / `nicholl_lee_nicholl.adb` — package
- `tests.adb` — test main
- `nicholl_lee_nicholl.gpr`, `Makefile`, `README.md`

## References

1. Nicholl, T. M., Lee, D. T. & Nicholl, R. A. (1987). *An efficient new algorithm for 2-D line clipping: Its development and analysis*. SIGGRAPH ’87, pp. 253–262. doi:10.1145/37401.37432
2. Hearn, D. & Baker, M. P. *Computer Graphics*. Prentice Hall (NLN textbook treatment).
3. Wikipedia: [Nicholl–Lee–Nicholl algorithm](https://en.wikipedia.org/wiki/Nicholl%E2%80%93Lee%E2%80%93Nicholl_algorithm)
4. Related: Liang–Barsky, Cyrus–Beck, Fast clipping, Cohen–Sutherland.
