# Convex hull algorithms — Ada 2023 (survey)

Educational, self-contained Ada 2023 **survey** package for **2-D convex hull**
algorithms on a finite unordered point set. Computing the convex hull means
constructing a non-ambiguous representation of the smallest convex set that
contains every input point — in the plane, a convex polygon whose vertices are
a subset of the input. See
[Wikipedia: Convex hull algorithms](https://en.wikipedia.org/wiki/Convex_hull_algorithms).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Orientation and distance predicates use ordinary `Real`
(`digits 15`) arithmetic with a fixed absolute tolerance
$\varepsilon = 10^{-9}$ (`Epsilon`). It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

**Implementation:** four classical planar methods live in **one** package —
Gift wrapping (Jarvis march), Graham scan, Andrew monotone chain, and
Quickhull — plus a thin `Hull_Method` dispatcher. The package does **not**
`with` sibling algorithm packages.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Why $\Omega(n \log n)$?

Sorting reduces to planar convex hull: map numbers $x_i$ to points
$(x_i, x_i^2)$ on a parabola; hull traversal recovers sorted order. In the
algebraic decision-tree model this yields the familiar lower bound
$\Omega(n \log n)$ in the worst case when complexity is measured only in $n$.
**Output-sensitive** algorithms may beat $\Theta(n \log n)$ when
$h = o(n)$, with the planar optimum $\Omega(n \log h)$.

## Complexity table

| Method | Time | Notes |
| --- | --- | --- |
| **Gift wrapping** (Jarvis march) | $O(nh)$ | Worst $O(n^2)$; simple wrap |
| **Graham scan** | $O(n \log n)$ | Polar sort + stack; $O(n)$ if pre-sorted by angle |
| **Andrew monotone chain** | $O(n \log n)$ | Lex sort + lower/upper; $O(n)$ if pre-sorted |
| **Quickhull** | expected $O(n \log n)$ | Worst $O(n^2)$; farthest-point D&C |
| Divide-and-conquer (Preparata–Hong) | $O(n \log n)$ | Survey mention only |
| Kirkpatrick–Seidel | $O(n \log h)$ | Marriage-before-conquest (sibling) |
| **Chan's algorithm** | $O(n \log h)$ | Mini-hulls + Jarvis wrap (sibling) |

Here $n$ is the number of input points and $h$ is the number of hull
vertices. Chan and Kirkpatrick–Seidel are covered by sibling packages in this
series; this survey embeds the four classical classroom methods above.

## Algorithms in this package

### Gift wrapping / Jarvis march — $O(nh)$

Start at the leftmost point (then lowest on ties). Repeatedly choose the next
hull vertex as the point that makes the most counterclockwise turn relative to
the current candidate edge; on a shared ray keep the farthest extreme. Stop
when the walk wraps back to the start.

### Graham scan — $O(n \log n)$

Pivot $=$ lowest $y$ (then leftmost). Sort the remaining points by polar angle
around the pivot (same-ray ties by distance; keep the farthest on each ray).
Scan with a stack, popping while $\operatorname{Orient2D}$ is not a strict
left turn.

### Andrew monotone chain — $O(n \log n)$ (classroom oracle)

Sort lexicographically by $(x, y)$. Build the **lower** hull left→right and
the **upper** hull right→left, requiring a strict left turn at every vertex.
Concatenate (dropping the duplicated endpoints). Tests treat Andrew as the
oracle for vertex set / count / area agreement.

### Quickhull — expected $O(n \log n)$

Find leftmost / rightmost extremes $A, B$. Partition points by the directed
line $AB$. Recursively find the farthest point $C$ on each side; discard
points inside triangle $ACB$; continue on the two new edges. Analogous to
quicksort.

### Orientation predicate

Twice the signed area of triangle $ABC$ (left-of-line test):

$$
\operatorname{Orient2D}(A,B,C)
  = (B_x-A_x)(C_y-A_y) - (B_y-A_y)(C_x-A_x).
$$

$\operatorname{Orient2D} > 0$ means $C$ is left of directed $AB$ (CCW);
$< 0$ means right (CW); $\approx 0$ means collinear (within $\varepsilon$).

## Hull convention

All methods return an **open** ring of extreme vertices in **counterclockwise
(CCW)** order. Near-duplicates and strictly interior / edge-collinear midpoints
are dropped. Degenerate cases:

- $1$ unique point → $1$ vertex
- $2$ unique points or all-collinear → the two extreme endpoints

Starting vertex differs slightly by method (Andrew / Quickhull / Gift:
lexicographically lowest or leftmost; Graham: lowest-then-leftmost). Compare
hulls by **vertex set**, count, CCW, and shoelace area — not by a fixed cyclic
shift of the open ring.

Empty inputs and oversized sets ($n < 1$ or $n > Max\_Points$) raise
`Invalid_Argument`.

## Akl–Toussaint heuristic (survey note)

A common $O(n)$ pre-filter finds extreme $x$/$y$ points (optionally also
max/min of $x\pm y$), forms a convex quadrilateral or octagon, and discards
points strictly inside. Not implemented here; mentioned because Wikipedia
lists it as a practical accelerator for many hull algorithms.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Convex-Hull-Algorithms`) | Survey: Gift / Graham / Andrew / Quickhull |
| **[Ada-Gift-Wrapping](https://github.com/RobertBoettcherSF/Ada-Gift-Wrapping)** | Jarvis march alone |
| **[Ada-Graham-Scan](https://github.com/RobertBoettcherSF/Ada-Graham-Scan)** | Graham scan alone |
| **[Ada-Quickhull](https://github.com/RobertBoettcherSF/Ada-Quickhull)** | Quickhull alone |
| **[Ada-Chans-Algorithm](https://github.com/RobertBoettcherSF/Ada-Chans-Algorithm)** | Output-sensitive $O(n\log h)$ |
| **[Ada-Kirkpatrick-Seidel](https://github.com/RobertBoettcherSF/Ada-Kirkpatrick-Seidel)** | Marriage-before-conquest idea |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Antipodal pairs on a **convex** polygon |
| **[Ada-Minimum-Bounding-Box](https://github.com/RobertBoettcherSF/Ada-Minimum-Bounding-Box)** | AABB + min-area OBB |

README links only — **no** package `with` of siblings.

**Next sheet item:** [Cone algorithm](https://en.wikipedia.org/wiki/Cone_algorithm) → planned package `Ada-Cone-Algorithm`.

## API sketch

| Entity | Role |
| --- | --- |
| `Gift_Wrapping` / `Jarvis_March` | Jarvis march hull |
| `Graham_Scan` | Polar-sort + stack hull |
| `Andrew_Monotone_Chain` | Lex lower+upper hull (oracle) |
| `Quickhull` | Farthest-point divide-and-conquer |
| `Convex_Hull (Points, Method)` | Dispatcher (`Hull_Method` enum; default Andrew) |
| `Hull_Vertex_Count` | Length of selected hull |
| `Orient2D`, `Cross`, `Dot`, `Dist2`, `Dist` | Geometry helpers |
| `Signed_Area`, `Is_CCW` | Shoelace / orientation checks |
| `Near` / `Near_Point` | Absolute $\varepsilon$-tolerance compares |
| `Polar_Less`, `Distance_To_Line` | Sort / Quickhull helpers |
| `Invalid_Argument` | Empty or $n > Max\_Points$ |

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pconvex_hull_algorithms.gpr
make test   # runs bin/tests → "Results: N PASS, 0 FAIL"
make clean
```

## References

- [Wikipedia: Convex hull algorithms](https://en.wikipedia.org/wiki/Convex_hull_algorithms)
- Jarvis, R. A. (1973). On the identification of the convex hull of a finite set of points.
- Graham, R. L. (1972). An efficient algorithm for determining the convex hull of a finite planar set.
- Andrew, A. M. (1979). Another efficient algorithm for convex hulls in two dimensions.
- Barber, C. B.; Dobkin, D. P.; Huhdanpaa, H. (1996). The Quickhull algorithm for convex hulls.
- Chan, T. M. (1996). Optimal output-sensitive convex hull algorithms in two and three dimensions.
