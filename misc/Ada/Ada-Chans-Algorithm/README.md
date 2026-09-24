# Chan's algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Chan's algorithm**:
an **output-sensitive** 2D convex hull in $O(n\log h)$ that combines
mini-hulls (Graham / Andrew) with a Jarvis-style wrap and tangent
queries. See
[Wikipedia: Chan's algorithm](https://en.wikipedia.org/wiki/Chan's_algorithm).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Predicates and distances use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Chans-Algorithm`) | Chan mini-hulls + Jarvis wrap ($O(n\log h)$) |
| **[Ada-Graham-Scan](https://github.com/RobertBoettcherSF/Ada-Graham-Scan)** | Polar-sort + stack Graham scan |
| **[Ada-Gift-Wrapping](https://github.com/RobertBoettcherSF/Ada-Gift-Wrapping)** | Jarvis march gift wrapping ($O(nh)$) |
| **[Ada-Quickhull](https://github.com/RobertBoettcherSF/Ada-Quickhull)** | Quicksort-style farthest-point divide-and-conquer |
| **[Ada-Kirkpatrick-Seidel](https://github.com/RobertBoettcherSF/Ada-Kirkpatrick-Seidel)** | Marriage-before-conquest hull ($O(n\log h)$ idea) |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Antipodal pairs / diameter / width on a **convex** polygon |
| **[Ada-Minimum-Bounding-Box](https://github.com/RobertBoettcherSF/Ada-Minimum-Bounding-Box)** | AABB + min-area OBB (embeds Andrew's chain) |
| **Ada-Convex-Hull** (ahead) | Survey of planar convex-hull algorithms |

README links only — **no** package `with` of siblings.
The convex-hull **survey** package is next in the series.

## Algorithm sketch

Chan (1996) builds the hull in **counterclockwise** order without knowing
$h$ in advance:

1. **Guess** a hull-size parameter $H = \min(2^{2^{t}}, n)$ for
   $t = 1, 2, \ldots$ (the **squaring** scheme).
2. **Partition** the $n$ points into $K = \lceil n/H \rceil$ groups of
   size at most $H$. Compute the **mini-hull** of each group with an
   $O(m\log m)$ method (Andrew monotone chain embedded here; Graham
   scan is also exposed as a teaching oracle).
3. Run a **Jarvis-style wrap**: from the current hull vertex, query a
   **tangent** (binary-search style) on every mini-hull, then pick the
   best candidate among the $K$ answers. Abort the pass if more than
   $H$ vertices are emitted ($H < h$).
4. On wrap-back to the start, **return** the hull; otherwise increase
   $t$ (hence $H$) and retry.

The start vertex is the **lowest** $y$-coordinate (then leftmost $x$),
guaranteed on the global hull.

### Orientation

Twice the signed area of triangle $ABC$ (left-of-line test):

$$
\operatorname{Orient2D}(A,B,C)
  = (B_x-A_x)(C_y-A_y) - (B_y-A_y)(C_x-A_x).
$$

$\operatorname{Orient2D} > 0$ means $C$ is left of directed $AB$ (CCW);
$< 0$ means right (CW); $\approx 0$ means collinear.

### Complexity

With the squaring scheme, $O(\log\log h)$ passes suffice. Each pass
costs $O(n\log H)$; when the first successful $H$ satisfies
$H \le h^{2}$, the total is $O(n\log h)$. A naïve Jarvis march alone
is $O(nh)$; Graham / Andrew alone are $O(n\log n)$. Chan is preferable
when $h \ll n$ but $h$ is not tiny enough for plain gift wrapping.

### Classroom simplifications

Documented deliberately for auditability on `Max_Points = 64`:

- **Mini-hulls** use an embedded Andrew monotone chain (same code path
  as the teaching oracle). Graham scan is also embedded and exposed for
  cross-checks — **no** sibling `with`.
- **Tangent queries** use a binary-search-style walk on each mini-hull
  with a **linear fallback** for tiny hulls ($m \le 8$) and a short
  polish pass. Ideal Chan is $O(\log m)$ per query; the classroom
  variant stays correct and easy to read.
- **No hull reuse / merging** across increasing $H$ passes (Chan’s
  paper suggests reuse for practice; we recompute mini-hulls each
  pass).
- **Floating predicates** with a fixed $\varepsilon$-threshold — fine
  for well-separated classroom examples, not an exact kernel.
- If every squaring pass fails (should not happen for $H \ge n$), a
  full Andrew fallback returns a correct hull.

Empty inputs and oversized sets ($n < 1$ or $n > Max\_Points$) raise
`Invalid_Argument`. Near-duplicates and collinear-on-edge points are
dropped; a single point or collinear segment returns $1$ or $2$
vertices.

## API sketch

| Operation | Role |
| --- | --- |
| `Convex_Hull` / `Hull_Vertex_Count` | Chan's algorithm → CCW open ring |
| `Graham_Scan_Hull` | Teaching oracle ($O(n\log n)$ polar+stack) |
| `Andrew_Monotone_Chain` | Teaching oracle ($O(n\log n)$ monotone chain) |
| `Orient2D` / `Polar_Less` | Predicate + polar compare |
| `Dist2` / `Dist` / `Cross` / `Dot` | Geometric helpers |
| `Signed_Area` / `Is_CCW` | Hull orientation checks |
| `Near` / `Near_Point` | Educational floating comparisons |

Domain types: `Point`, `Point_Array` / `Point_Set`, `Real`. Exception:
`Invalid_Argument` when $n < 1$ or $n > Max\_Points$.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
