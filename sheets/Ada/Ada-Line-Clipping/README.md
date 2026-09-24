# Line Clipping — Survey (Ada 2023)

Educational Ada 2023 **umbrella / survey** package for
[Wikipedia: Line clipping](https://en.wikipedia.org/wiki/Line_clipping).
In computer graphics, **line clipping** removes portions of line segments
outside a viewport (here: an **axis-aligned rectangular** clip window).

This repository embeds compact, self-contained implementations of several
classic algorithms so they can be compared side-by-side. Deeper treatments
of individual methods live in sibling Ada algorithm repos (see below).

Based on the principles described on Wikipedia and in Newman & Sproull,
Foley / van Dam, and Hearn & Baker.

## Project Overview

| Algorithm | Style | Notes |
| --- | --- | --- |
| **Cohen–Sutherland** | 4-bit outcodes + iterative edge clips | Fast trivial accept/reject |
| **Liang–Barsky** | Parametric $t$ vs four edges | Often fewer intersections |
| **Midpoint Subdivision** | Binary search along the segment | Classic textbook companion to CS |
| **Skala (lite)** | Corner encoding vs supporting line | Educational approx.; rectangle only |
| Cyrus–Beck | Parametric vs convex polygon | See sibling repo |
| Nicholl–Lee–Nicholl | Canonical regions | See sibling repo |
| Fast clipping | Line encoding + case handlers | See sibling repo |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Sibling repositories (deeper treatments)

| Topic | Repository |
| --- | --- |
| Cohen–Sutherland | [Ada-Cohen-Sutherland](https://github.com/RobertBoettcherSF/Ada-Cohen-Sutherland) |
| Liang–Barsky | [Ada-Liang-Barsky](https://github.com/RobertBoettcherSF/Ada-Liang-Barsky) |
| Cyrus–Beck | [Ada-Cyrus-Beck](https://github.com/RobertBoettcherSF/Ada-Cyrus-Beck) |
| Nicholl–Lee–Nicholl | [Ada-Nicholl-Lee-Nicholl](https://github.com/RobertBoettcherSF/Ada-Nicholl-Lee-Nicholl) |
| Fast clipping | [Ada-Fast-Clipping](https://github.com/RobertBoettcherSF/Ada-Fast-Clipping) |

This survey package does **not** depend on those packages; algorithms are
embedded compactly for comparison.

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Window | `Make_Window`, `Is_Valid_Window`, `Point_Inside_Window` | Axis-aligned clip rectangle |
| Dispatch | `Algorithm_Kind`, `Clip_With` | Choose CS / LB / Midpoint / Skala-lite |
| Classic | `Cohen_Sutherland_Clip` | Embedded outcode loop |
| Parametric | `Liang_Barsky_Clip` | Embedded $t_{\mathrm{enter}}/t_{\mathrm{leave}}$ |
| Subdivision | `Midpoint_Subdivision_Clip` | Recursive midpoint until $\varepsilon$ |
| Encoding | `Skala_Clip_Lite` | Skala-inspired corner/edge encoding (AA only) |
| Compare | `Compare_Algorithms` | Agreement report (`Same_Clipped_Seg`) |
| Helpers | `Make_Segment`, `Length`, `Same_Clipped_Segment` | Fixtures & comparison |
| Outcodes | `Compute_OutCode`, `Trivial_Accept`, `Trivial_Reject` | Shared CS-style helpers |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Segment`,
`Clip_Window`, `Clip_Result`, `Algorithm_Kind`, `Agreement_Report`, …).
Public subprograms carry `Pre` / `Post` / `Global` contract aspects where
meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`.

### Skala_Clip_Lite limits

The lite variant documents Skala’s idea of classifying window corners against
the supporting line $ax+by+c=0$ and counting crossed edges, then clips the
segment against the rectangle with a parametric interval. It is **not** the
full homogeneous / duality algorithm for arbitrary convex polygons.

## Usage

```bash
cd /workspace/ada-line-clipping
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections covering:

- Vector helpers, windows, segments, point-in-window
- Outcodes and trivial accept/reject
- Cohen–Sutherland / Liang–Barsky / Midpoint / Skala-lite fixtures
- `Clip_With` dispatch across `Algorithm_Kind`
- `Compare_Algorithms` agreement reports
- Lattice agreement: **CS == LB == Midpoint** on many segments
- Lattice agreement: **CS == Skala_Lite**
- Degenerate points, diagonals, exhaustive reject

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `line_clipping.gpr`:

```ada
project Line_Clipping is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Line_Clipping;
```

Sources live in the repository root (no `src/` folder):

- `line_clipping.ads` / `line_clipping.adb` — package
- `tests.adb` — test main
- `line_clipping.gpr`, `Makefile`, `README.md`

## References

1. Wikipedia: [Line clipping](https://en.wikipedia.org/wiki/Line_clipping)
2. Cohen, D. & Sutherland, I. — Cohen–Sutherland algorithm (1967 flight-sim work)
3. Liang, Y.-D. & Barsky, B. A. (1984). ACM TOG — Liang–Barsky
4. Cyrus, M. & Beck, J. (1978). Computers & Graphics — Cyrus–Beck
5. Skala, V. (2005). *A new approach to line and line segment clipping in homogeneous coordinates*. The Visual Computer
6. Newman, W. & Sproull, R. *Principles of Interactive Computer Graphics* (midpoint subdivision)
