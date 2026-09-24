# Nesting algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **nesting** sketches:
make efficient use of **material or space** by placing pieces without
overlap. Covers **linear (1D) stock cutting** and a classical **2D
axis-aligned shelf / first-fit decreasing** rectangle packing heuristic
on a plate. See
[Wikipedia: Nesting algorithm](https://en.wikipedia.org/wiki/Nesting_algorithm).

This package is a **classroom packing** sketch on small instances
(`Max_Pieces = 32`). Lengths use ordinary `Real` (`digits 15`)
arithmetic. It is **not** industrial nesting CAD (no freeform irregular
nesting, no guillotine tree search, no intersection-heavy combinatorial
explosion of cut positions).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry / packing siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Nesting-Algorithm`) | 1D stock cutting + 2D shelf rectangle nesting |
| **[Ada-Point-In-Polygon](https://github.com/RobertBoettcherSF/Ada-Point-In-Polygon)** | Ray casting / winding containment |
| **[Ada-Shoelace-Algorithm](https://github.com/RobertBoettcherSF/Ada-Shoelace-Algorithm)** | Polygon area / centroid |
| **Ada-Bin-Packing** (ahead) | Classical bin / bin-capacity packing variants |

README links only — **no** package `with` of siblings.

## Algorithm sketch

### Linear (1D) stock cutting

Wikipedia: for an existing set there is only one position where a new
cut can be placed — at the end of the last cut. Validation is the
identity

$$
\text{Scrap} = \text{Stock} - \text{Yield} - \text{Kerf}_{\text{total}}.
$$

Here $\text{Yield}$ is the sum of placed piece lengths and
$\text{Kerf}_{\text{total}} = (n-1)\cdot\text{Kerf}$ for $n \ge 1$
placed pieces (kerf between successive cuts; zero when $n \le 1$).
`Nest_1D` places pieces end-to-end in input order and reports used
length, scrap, and whether every piece fits.

### Plate (2D) shelf / first-fit decreasing

Wikipedia notes plate nesting is significantly more complex (many
candidate cut positions, rotations, intersection checks). This package
teaches a classical **shelf / level** heuristic:

1. Sort pieces by decreasing height (with optional $90^\circ$ rotation,
   by decreasing $\max(W,H)$).
2. Open horizontal shelves from the bottom of the plate.
3. **First-fit**: place each piece in the first shelf with enough
   remaining width; else open a new shelf if height remains.
4. Optional $90^\circ$ rotation when choosing an orientation that fits.

Utilization:

$$
U = \frac{\sum \text{placed areas}}{\text{Plate\_Width}\times\text{Plate\_Height}}.
$$

### Educational robustness

Floating comparisons use an $\varepsilon$ tolerance. Instances with
$n \le 32$ are adequate for classroom demos. Production nesting CAD
uses much richer search (irregular polygons, compaction, exact
intersection kernels).

## API sketch

| Operation | Role |
| --- | --- |
| `Nest_1D` | Place lengths on stock; return used / yield / kerf / scrap / fit |
| `Scrap_1D` | Educational $\text{Stock}-\text{Yield}-\text{Kerf}_{\text{total}}$ |
| `Nest_2D_Shelf` | Shelf FFD packing; return placements $(x,y)$, utilization |
| `Rectangles_Overlap` | Axis-aligned open-interior intersection test |
| `Fits_In_Plate` | Box contained in plate $[0,W]\times[0,H]$ |
| `Near` / `Area_Of` | Educational numeric helpers |

Domain types: `Real`, `Length_Array`, `Rectangle`, `Rect_Array`,
`Placement`, `Nest_1D_Result`, `Nest_2D_Result`.
Exception: `Invalid_Argument` for nonpositive stock/plate, negative
kerf, empty piece list, oversized list, or nonpositive piece sizes.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
