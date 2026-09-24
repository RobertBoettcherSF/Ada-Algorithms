# Binary Space Partitioning (Ada 2023)

Educational Ada 2023 package for
[Wikipedia: Binary space partitioning](https://en.wikipedia.org/wiki/Binary_space_partitioning).
**Binary space partitioning (BSP)** recursively subdivides Euclidean space into
two convex sets using **hyperplanes**, producing a **BSP tree**. In computer
graphics this yields view-dependent polygon order for the **painter's
algorithm**, supports front-to-back visibility, polygon splitting at
partition planes (Fuchs et al.), and lite spatial / collision queries.

This repository focuses on a clear **2-D educational** implementation
(hyperplanes as lines) with fixed-capacity node and polygon pools—no unbounded
heap trees. BSP generalizes axis-aligned structures such as *k*-d trees,
quadtrees, and octrees (related sibling topics, not dependencies).

Based on Wikipedia and the classic literature: Fuchs / Kedem / Naylor
(SIGGRAPH 1980), Naylor, Thibault & Naylor (CSG / polyhedral set ops).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Hyperplane (2-D)** | `Plane2` = unit normal + offset | `Dot(N,P)+Offset = 0` |
| **Classification** | `Classify_Point` / `Relate_Polygon` | Front / Back / On / Straddle |
| **Polygon cut** | `Split_Polygon` / `Split_Segment` | Fuchs-style straddler split |
| **Auto BSP build** | `Build_BSP` | First / Least_Split heuristic |
| **Painter order** | `Traverse_Back_To_Front` | Far → near for painting |
| **Early-Z order** | `Traverse_Front_To_Back` | Near → far |
| **Collision lite** | `Ray_Cast_2D` / `Segment_Hits_Tree` | First edge hit |
| **Solid query** | `Point_In_Solid` | Educational solid-leaf flags |
| ***k*-d special case** | `Build_KD_Style` | Axis-aligned splitters only |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Geometry | `Vec2`, `Point2`, `Segment`, `Polygon`, `Plane2` | Domain types |
| Planes | `Make_Plane_From_Points`, `Make_Plane_From_Polygon`, `Make_Axis_Aligned_Plane` | Splitters |
| Classify | `Classify_Point`, `Relate_Polygon`, `Signed_Distance` | Side tests |
| Split | `Split_Segment`, `Split_Polygon` | Hyperplane cuts |
| Build | `Build_BSP` | Auto BSP (Fuchs preprocessing) |
| *k*-d style | `Build_KD_Style` | Axis-aligned educational BSP |
| Traversal | `Traverse`, `Traverse_Back_To_Front`, `Traverse_Front_To_Back` | Painter / early-Z |
| Queries | `Point_In_Solid`, `Classify_Point_In_Tree`, `Ray_Cast_2D` | Spatial / collision |
| Helpers | `Is_Empty_Tree`, `Node_Count`, `Polygon_Count`, `Make_Rect_Polygon` | Fixtures / stats |

Strong typing uses domain types (`Real` digits 6, bounded polygons, fixed
node/polygon pools). Public subprograms carry `Pre` / `Post` / `Global`
contract aspects where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`, `Capacity_Exceeded`.

### Educational limits

This is **not** a Quake-level engine: no PVS, no 3-D brush CSG merge, and no
dynamic object insertion. Solid-leaf flags are a teaching aid for
`Point_In_Solid`. Prefer clarity and contracts over raw throughput.

## Usage

```bash
cd /workspace/ada-binary-space-partitioning
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections covering:

- Vector helpers, segments, polygons, plane construction
- Point / polygon classification and relations
- Segment and polygon splitting at hyperplanes
- `Build_BSP` on empty, single, overlapping, and room-like scenes
- Back-to-front (painter's) and front-to-back traversal vs known viewpoints
- Point-in-solid / leaf classification
- Ray cast / segment collision lite
- `Build_KD_Style` axis-aligned special case
- Degenerates (empty input, coplanar, filtered short polygons)
- First_Polygon vs Least_Split heuristics

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.x**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `binary_space_partitioning.gpr`:

```ada
project Binary_Space_Partitioning is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Binary_Space_Partitioning;
```

## References

- [Wikipedia: Binary space partitioning](https://en.wikipedia.org/wiki/Binary_space_partitioning)
- Fuchs, H.; Kedem, Z. M.; Naylor, B. F. (1980). *On Visible Surface Generation by A Priori Tree Structures*. SIGGRAPH '80.
- Naylor, B. (1981 / 1993). BSP development and *Constructing Good Partitioning Trees*.
- Thibault, W. C.; Naylor, B. F. (1987). *Set operations on polyhedra using binary space partitioning trees*. SIGGRAPH '87 (CSG).
- Chen, S.; Gordon, D. (1991). *Front-to-Back Display of BSP Trees*. IEEE CGA.
- de Berg et al., *Computational Geometry* (§12 Binary Space Partitions).
- Related structures (siblings, not dependencies): *k*-d trees, quadtrees, octrees.

## License

Educational reference implementation for the Ada algorithm collection.
