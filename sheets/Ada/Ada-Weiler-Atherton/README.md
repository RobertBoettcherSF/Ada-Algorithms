# Weiler–Atherton Polygon Clipping (Ada 2023)

Educational Ada 2023 implementation of the **Weiler–Atherton** polygon
clipping algorithm (and its merging / union variant). A subject polygon **B**
is clipped by an arbitrarily shaped clipping polygon **A** in 2-D by building
circular vertex lists, inserting edge intersections, linking the lists at
those intersections, and tracing clockwise from inbound (clip) or outbound
(merge) crossings.

Based on the principles described in
[Wikipedia: Weiler–Atherton clipping algorithm](https://en.wikipedia.org/wiki/Weiler%E2%80%93Atherton_clipping_algorithm)
and Weiler & Atherton, *Hidden Surface Removal using Polygon Area Sorting*,
Computer Graphics 11(2):214–222, 1977.

## Project Overview

Preconditions (enforced or normalized by helpers): candidate polygons should
be **clockwise**, **non-self-intersecting**, and simple. Holes (as
counter-clockwise children) are mentioned in the literature but omitted here
so the educational core stays clean. Convex pairs yield one result polygon;
**concave** clips may yield several.

When there are **no intersections**, classification decides the result:

| Case | Clip returns | Merge returns |
| --- | --- | --- |
| **B inside A** | B | A |
| **A inside B** | A | B |
| **Disjoint** | empty | A and B |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Orientation | `Signed_Area`, `Orient_Clockwise`, `Ensure_Orientation` | Shoelace area; force CW/CCW |
| Inside test | `Point_In_Polygon`, `Point_On_Boundary` | Ray-cast labeling / boundary |
| Intersections | `Segment_Intersection`, `Find_All_Intersections` | Proper edge–edge hits |
| Linked lists | `Build_Linked_Polygon_Lists` | Insert hits, link pairs, mark in/out |
| Collect | `Collect_Inbound_Intersections`, `Collect_Outbound_Intersections` | Start sets for walks |
| Clip | `Weiler_Atherton_Clip` | Intersection via inbound starts |
| Merge | `Weiler_Atherton_Merge` | Union via outbound starts |
| Classify | `Classify_No_Intersection` | `A_In_B` / `B_In_A` / `Disjoint` / `Overlapping` |
| Helpers | `Make_Rectangle`, `Make_Triangle`, `Vertex_Count_Of`, `Polygon_Copy`, … | Fixtures & utilities |

Strong typing uses domain types (`Real` digits 6, `Vec2`, `Polygon`,
`Intersection_Kind`, `Clip_Result`, `Linked_Polygon_Lists`, …). Public
subprograms carry `Pre` / `Post` / `Global` contract aspects where meaningful
(`SPARK_Mode => Off`).

Bounds: `Max_Vertices = 64`, `Max_Polygons = 8`, `Max_Intersections = 64`,
`Max_List_Nodes = 128`.

## Usage

```bash
cd /workspace/ada-weiler-atherton
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 16 sections and 80+ `Check` assertions
covering:

- Vector / orientation / point-in-polygon helpers
- Segment intersection and multi-edge intersection discovery
- Linked-list construction with inbound / outbound labeling
- Rect∩rect, triangle∩rect, CCW input normalization
- Subject-inside-clip, clip-inside-subject, and disjoint cases
- Merge (union) of overlapping and disjoint pairs
- Concave C-shaped clip producing **two** result pieces
- Named exceptions (`Invalid_Argument`, `Degenerate_Geometry`, `Capacity_Exceeded`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `weiler_atherton.gpr`:

```ada
project Weiler_Atherton is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Weiler_Atherton;
```

Sources live in the repository root (no `src/` folder):

- `weiler_atherton.ads` / `weiler_atherton.adb` — package
- `tests.adb` — test main
- `weiler_atherton.gpr`, `Makefile`, `README.md`

## References

1. Weiler, K. & Atherton, P. (1977). *Hidden Surface Removal using Polygon Area Sorting*. Computer Graphics, 11(2):214–222.
2. Foley, J. et al. *Computer Graphics: Principles and Practice*. Addison-Wesley. (Weiler–Atherton discussion, pp. 689–693 in early editions.)
3. Wikipedia: [Weiler–Atherton clipping algorithm](https://en.wikipedia.org/wiki/Weiler%E2%80%93Atherton_clipping_algorithm)
4. Related: Sutherland–Hodgman, Vatti, Greiner–Hormann clipping algorithms.
