# Cyrus–Beck Line Clipping (Ada 2023)

Educational Ada 2023 implementation of the **Cyrus–Beck** line clipping
algorithm. A line segment is clipped against a **convex polygon** (2-D) or a
**convex polyhedron** given as outward planes (3-D lite) using the parametric
form

$$
\mathbf{p}(t) = (1-t)\,\mathbf{p}_0 + t\,\mathbf{p}_1,\quad 0 \le t \le 1
$$

For each clip edge/plane with outward normal $\mathbf{n}$ and a point
$\mathbf{p}_E$ on the plane, the intersection satisfies
$\mathbf{n}\cdot(\mathbf{p}(t)-\mathbf{p}_E)=0$. Entering vs leaving is
classified by the sign of $\mathbf{n}\cdot\mathbf{D}$ where
$\mathbf{D}=\mathbf{p}_1-\mathbf{p}_0$; then
$t_{\mathrm{enter}}=\max(\ldots)$ and $t_{\mathrm{leave}}=\min(\ldots)$,
accepting when $t_{\mathrm{enter}}\le t_{\mathrm{leave}}$.

**Liang–Barsky** is the rectangular specialisation of Cyrus–Beck.

Based on the principles described in
[Wikipedia: Cyrus–Beck algorithm](https://en.wikipedia.org/wiki/Cyrus%E2%80%93Beck_algorithm)
and Cyrus & Beck, *Generalized two- and three-dimensional clipping*,
Computers & Graphics, 1978.

## Project Overview

| Algorithm | Style | Notes |
| --- | --- | --- |
| Cohen–Sutherland | Outcodes + iterative edge clips | Rectangle only |
| Liang–Barsky | Parametric $t$ against four edges | Rectangle; CB special case |
| **Cyrus–Beck** | Parametric vs convex polygon / planes | General convex windows |
| Nicholl–Lee–Nicholl | Canonical regions | 2-D rectangle only |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Polygon | `Make_Convex_Polygon`, `Make_Convex_Rect`, `Edge_Normal` | CCW convex clip window; outward normals |
| Convexity | `Is_Convex_Polygon` | Precondition helper (CCW, strict turns) |
| Classification | `Plane_Dot_Classification` | Point vs edge half-plane (Inside/On/Outside) |
| Main clip | `Cyrus_Beck_Clip` | Accept/Reject + clipped segment vs polygon |
| Params clip | `Cyrus_Beck_Clip_Params` | Clip + retained $t_{\mathrm{enter}}$ / $t_{\mathrm{leave}}$ |
| Rectangle | `Cyrus_Beck_Clip_Rect` | Convenience via `Make_Convex_Rect` |
| Reference | `Liang_Barsky_Clip_Lite` | In-package LB for rectangle agreement |
| 3-D lite | `Cyrus_Beck_Clip_3D_Lite`, `Make_Axis_Aligned_Box_Planes` | Segment vs outward plane set |
| Helpers | `Make_Segment`, `Length`, `Point_Inside_Convex`, `Same_Clipped_Segment` | Fixtures & comparison |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Vec3`, `Segment`,
`Convex_Clip_Polygon` / `Polygon`, `Plane3`, `Clip_Result`, `Parameter` in
`0 .. 1`, …). Public subprograms carry `Pre` / `Post` / `Global` contract
aspects where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`.

## Usage

```bash
cd /workspace/ada-cyrus-beck
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 14 sections covering:

- Vector helpers (`Near`, `Dot`, `Cross_Z`, `Vec3`)
- Segments, length, point-in-convex
- `Make_Convex_Rect`, `Is_Convex_Polygon`, `Edge_Normal` (outward)
- `Plane_Dot_Classification` Inside / On / Outside
- `Point_At_Parameter`
- `Cyrus_Beck_Clip` inside / outside / edge crossings
- `Cyrus_Beck_Clip_Params` retained $t_0,t_1$
- Triangle clip window
- `Cyrus_Beck_Clip_Rect` ↔ `Liang_Barsky_Clip_Lite` agreement lattice
- `Liang_Barsky_Clip_Lite` reference cases
- `Cyrus_Beck_Clip_3D_Lite` against an axis-aligned box
- Degenerate / parallel / point segments

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `cyrus_beck.gpr`:

```ada
project Cyrus_Beck is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Cyrus_Beck;
```

Sources live in the repository root (no `src/` folder):

- `cyrus_beck.ads` / `cyrus_beck.adb` — package
- `tests.adb` — test main
- `cyrus_beck.gpr`, `Makefile`, `README.md`

## References

1. Cyrus, M. & Beck, J. (1978). *Generalized two- and three-dimensional clipping*. Computers & Graphics, 3(1), 23–28.
2. Foley, J. D. et al. *Computer Graphics: Principles and Practice*. Addison-Wesley (Cyrus–Beck treatment).
3. Wikipedia: [Cyrus–Beck algorithm](https://en.wikipedia.org/wiki/Cyrus%E2%80%93Beck_algorithm)
4. Related: Liang–Barsky, Cohen–Sutherland, Nicholl–Lee–Nicholl, Fast clipping.
