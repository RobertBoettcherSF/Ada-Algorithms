# Vatti Polygon Clipping (Ada 2023)

Educational Ada 2023 implementation of the **Vatti** polygon clipping
algorithm — boolean clipping of subject polygon(s) by clip polygon(s) using a
**sweep-line / scanbeam** event structure (conceptually related to
Bentley–Ottmann) and linked-list contour tracing for the solution polygons.

Based on the principles described in
[Wikipedia: Vatti clipping algorithm](https://en.wikipedia.org/wiki/Vatti_clipping_algorithm)
and Bala R. Vatti, *A generic solution to polygon clipping*, Communications of
the ACM, Vol. 35, Issue 7 (July 1992), pp. 56–63.

A widely used open-source realization of Vatti’s ideas is
[Clipper2](https://github.com/AngusJohnson/Clipper2). This repository is an
**educational** Ada package, not a Clipper2 port.

## Relation to other clippers

| Algorithm | Strength | Restriction (classic) |
| --- | --- | --- |
| **Sutherland–Hodgman** | Fast convex clip window | Clip polygon must be convex |
| **Weiler–Atherton** | Arbitrary clip shape, holes | Typically simple polygons |
| **Vatti** | Many subjects × many clips; self-intersecting & holes | More complex sweep state |

Vatti processes edges from bottom to top via **scanlines** / **scanbeams**,
inserting intersection vertices into solution polygons. Unlike
Sutherland–Hodgman and Weiler–Atherton, the full algorithm admits complex
(self-intersecting) polygons and holes.

## Limitations (this educational build)

- **Correct boolean ops for simple (non-self-intersecting) polygons.**
- Self-intersecting subjects/clips and true hole rings are **not** fully
  implemented; nested difference without holes returns the outer subject
  unchanged (documented behaviour in tests / `No_Hit_Result`).
- Prefer correctness on classic simple cases over a broken “full” Vatti.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Ops | `Boolean_Operation` | `Intersection`, `Union`, `Difference`, `Exclusive_Or` |

> Note: Ada reserves the word `xor`, so the enumeration literal is
> `Exclusive_Or`; the convenience wrapper is still named `Vatti_Xor`.
| Sweep | `Collect_Scanline_Ys`, `Build_Local_Minima` | Event Y coordinates |
| Scanbeam | `Sweep_Process_Scanbeam` | Intersections in one Y-band |
| Clip | `Vatti_Clip` | Subject × clip × op → `Polygon_Set` |
| Wrappers | `Vatti_Intersection` / `Vatti_Union` / `Vatti_Difference` / `Vatti_Xor` | Polygon & set overloads |
| Geometry | `Segment_Intersection`, `Point_In_Polygon`, … | Helpers |
| Fixtures | `Make_Rectangle`, `Make_Triangle`, Orient helpers | Tests & demos |
| Multi | `Polygon_Set`, `Singleton`, `Make_Set` | Bounded multi-polygon I/O |

Strong typing: `Real` digits 6, `Vec2`, `Polygon`, `Polygon_Set`, `Scanline_List`,
`Scanbeam`, … Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Bounds: `Max_Vertices = 64`, `Max_Polygons = 8`, `Max_Intersections = 64`,
`Max_Scanlines = 128`.

## Usage

```bash
cd /workspace/ada-vatti
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` covers 16 sections with 3+ checks each, exercising every public
API entry (vectors, orientation, PIP, segments, scanlines, scanbeams, all four
boolean ops, multi-polygon sets, exceptions).

Classic cases: rect∩rect, union of overlapping rects, difference, xor,
triangle∩rect, disjoint → empty intersection, subject inside clip.

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `vatti.gpr`:

```ada
project Vatti is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Vatti;
```

Sources live in the repository root (no `src/` folder):

- `vatti.ads` / `vatti.adb` — package
- `tests.adb` — test main
- `vatti.gpr`, `Makefile`, `README.md`

## References

1. Vatti, B. R. (1992). *A generic solution to polygon clipping*. CACM 35(7):56–63.
2. Wikipedia: [Vatti clipping algorithm](https://en.wikipedia.org/wiki/Vatti_clipping_algorithm)
3. [Clipper2](https://github.com/AngusJohnson/Clipper2) — production Vatti-style library.
4. Related: Weiler–Atherton, Sutherland–Hodgman, Greiner–Hormann, Martínez–Rueda.
