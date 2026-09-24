# Flood Fill (Ada 2023)

Educational Ada 2023 implementation of **flood fill** (seed fill) and related
variants: recursive four- / eight-way fills, iterative stack (DFS-like) and
queue (BFS-like) fills, span/scanline filling, boundary fill, pattern filling,
and connected-region measurement.

Flood fill determines and alters the area connected to a start node in a
2-D grid that shares a matching attribute (the classic paint-bucket tool).
A **boundary fill** variant fills until a border colour is reached. Flood
filling is **not** suitable for drawing filled polygons (acute corners can be
missed); use even-odd / nonzero winding rules for that.

Based on the principles described in
[Wikipedia: Flood fill](https://en.wikipedia.org/wiki/Flood_fill)
(Smith tint fill; Levoy area flooding; Heckbert seed fill / Graphics Gems;
Fishkin & Barsky filling propagation).

## Project Overview

The traditional algorithm takes a start node, a target colour, and a
replacement colour. Connectivity may be **four-way** (edge neighbours) or
**eight-way** (corners too). Recursion can be moved into an explicit stack or
queue; span filling processes horizontal runs for fewer visits and better
cache behaviour. Pattern fills need a visited mask (or a temporary unique
colour) so `Inside` stays sound after writing pattern pixels.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Variant | Subprogram | Role |
| --- | --- | --- |
| Recursive 4-way | `Flood_Fill_Recursive_4` | Classic stack-based recursive seed fill |
| Recursive 8-way | `Flood_Fill_Recursive_8` | Same with corner connectivity |
| Explicit stack | `Flood_Fill_Stack` | Iterative DFS-like fill (4- or 8-way) |
| Explicit queue | `Flood_Fill_Queue` | Iterative BFS-like fill (4- or 8-way) |
| Span / scanline | `Flood_Fill_Span` | Horizontal-span optimisation (4-way) |
| Boundary 4-way | `Boundary_Fill_4` | Fill until border colour |
| Boundary 8-way | `Boundary_Fill_8` | Boundary fill with corners |
| Pattern fill | `Pattern_Flood_Fill` | Repeating tile via visited mask |
| Measure | `Count_Connected` / `Measure_Region` | Size of region without mutating |
| Helpers | `In_Bounds`, `Get_Color`, `Set_Color`, `Count_Color`, `Same_Grid`, … | Grid utilities |

Strong typing uses domain types (`Pixel_Coord`, `Color_Id`, `Connectivity`,
`Grid`, `Pattern_Grid`, `Fill_Result`). Public subprograms carry `Pre` /
`Global` contract aspects where meaningful (`SPARK_Mode => Off`).

Grids are bounded by `Max_Dim` (64) so educational demos stay safe; recursive
variants are exercised on small fixtures.

## Usage

```bash
cd /workspace/ada-flood-fill
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite with 15 sections and 50+ `Check` assertions
covering:

- Functional correctness of every public fill variant
- Four-way vs eight-way connectivity (diagonal chains)
- Span fill agreement with stack/queue/recursive results
- Boundary fill stopping at the border colour
- Pattern tiling and non-mutating region measurement
- No-ops (target = replacement, seed mismatch)
- Named exceptions (`Out_Of_Bounds`, `Invalid_Argument`)

The process exits successfully only when `Fail_Count = 0` (`pragma Assert`).

## Building

Requirements:

- GNAT (tested with **gnatmake 14.2.0**)
- Ada 2023 mode: `-gnat2022`
- Warnings as first-class: `-gnatwa` (build must be **zero errors, zero warnings**)

Project file `flood_fill.gpr`:

```ada
project Flood_Fill is
   for Source_Dirs use (".");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("tests.adb");
end Flood_Fill;
```

Sources live in the repository root (no `src/` folder):

- `flood_fill.ads` / `flood_fill.adb` — package
- `tests.adb` — test main
- `flood_fill.gpr`, `Makefile`, `README.md`

## References

1. Smith, A. R. (1979). *Tint Fill*. SIGGRAPH '79.
2. Levoy, M. (1982). *Area Flooding Algorithms*. SIGGRAPH course notes.
3. Heckbert, P. S. (1990). *A Seed Fill Algorithm*. Graphics Gems.
4. Fishkin, K. P. & Barsky, B. A. (1985). *An Analysis and Algorithm for Filling Propagation*.
5. Wikipedia: [Flood fill](https://en.wikipedia.org/wiki/Flood_fill)
