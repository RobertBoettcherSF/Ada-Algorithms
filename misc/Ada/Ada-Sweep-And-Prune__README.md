# Sweep and Prune — Ada 2023 (sort and sweep)

Educational, self-contained Ada 2023 package for
[Wikipedia: Sweep and prune](https://en.wikipedia.org/wiki/Sweep_and_prune)
(**sort and sweep**): a **broad-phase** collision-detection filter that
limits how many solid pairs need an expensive narrow-phase intersection
test.

Each solid is enclosed in an **axis-aligned bounding box** (AABB). Box
endpoints are projected onto one or more axes, sorted, and swept while an
**active set** tracks intervals under the sweep line. When two boxes
overlap on **every** axis, the pair is reported as a candidate for
narrow-phase testing.

**Temporal coherence:** between simulation steps solids rarely jump far, so
endpoint lists stay almost sorted. Algorithms that are fast on nearly
sorted input (notably **insertion sort**, exposed here as `Update_Sorted`)
keep the lists cheap to refresh. Also known as *sort and sweep* (Baraff
1992); later work such as I-COLLIDE (Cohen et al., 1995) popularized the
name *sweep and prune*.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

This is an **educational reconstruction** of the standard SAP pipeline
(Wikipedia stub + Ericson / Baraff / I-COLLIDE). Overlap uses **closed**
intervals so touching edges count as candidates (`Max >= Min`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Bounds** | 2-D AABB (`Min_X`…`Max_Y`); optional 3-D | Fixed educational capacity |
| **Overlap** | Closed projections on all axes | Touching edges → candidate |
| **Reference** | `Find_Overlapping_Pairs_Brute` | $O(n^2)$ all-pairs AABB test |
| **SAP** | Sweep X endpoints → filter Y (and Z) | Active-set 1-D sweep |
| **Coherence** | `Update_Sorted` insertion sort | Almost-sorted endpoints |
| **Pairs** | Canonical `A < B`, unordered once | `Normalize_Pairs` / `Same_Pair_Set` |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Objects`, `Max_Pairs`, `Object_Id` | Fixed educational limits |
| Boxes | `AABB_2D`, `AABB_3D`, `Make_AABB`, `Is_Valid_AABB` | Geometry |
| World | `World`, `Add_Box`, `Set_Box`, `Clear` | Object storage |
| Overlap | `AABBs_Overlap`, `Projections_Overlap` | Closed interval tests |
| Endpoints | `Endpoint`, `Build_Endpoints`, `Sort_Endpoints` | Axis projections |
| Coherence | `Update_Sorted`, `Endpoints_Sorted` | Insertion re-sort |
| Broad phase | `Find_Overlapping_Pairs_SAP`, `Find_1D_Overlap_Pairs` | Candidate pairs |
| Reference | `Find_Overlapping_Pairs_Brute` | Correctness oracle |
| Pairs | `Pair`, `Pair_List`, `Make_Pair`, `Append_Pair` | Result set |

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Post` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Formula summary

### Closed 1-D projection overlap

Two intervals $[a_{\min}, a_{\max}]$ and $[b_{\min}, b_{\max}]$ overlap when

$$
a_{\max} \ge b_{\min} \quad\text{and}\quad b_{\max} \ge a_{\min}.
$$

Touching at an endpoint (e.g. $a_{\max} = b_{\min}$) **is** an overlap
under this closed convention.

### 2-D AABB overlap

Boxes $A$ and $B$ overlap iff their $X$ projections overlap **and** their
$Y$ projections overlap:

$$
\mathrm{overlap}(A,B)
  \iff
  \mathrm{proj}_X(A)\cap\mathrm{proj}_X(B)\ne\emptyset
  \;\land\;
  \mathrm{proj}_Y(A)\cap\mathrm{proj}_Y(B)\ne\emptyset
$$

(with nonempty closed-interval intersection as above). In 3-D the same
rule adds the $Z$ axis.

### Sweep step (one axis)

Sort endpoints $(value, kind, id)$ with starts ($kind=+1$) before ends
($kind=-1$) on ties. Sweep left to right; maintain an active set $S$. On
a start for object $i$, emit candidate pairs $(i,j)$ for all $j\in S$,
then insert $i$ into $S$. On an end, remove $i$ from $S$.

2-D SAP here: collect 1-D overlapping pairs on $X$, then retain only those
that also overlap on $Y$ (equivalently: intersect the $X$- and $Y$-pair
sets). Complexity is $O(n\log n + k)$ dominated by sorting plus reporting,
versus $O(n^2)$ brute force.

## Usage

```ada
with Sweep_And_Prune; use Sweep_And_Prune;

declare
   W : World := Empty_World;
   P : Pair_List;
begin
   Add_Box (W, Make_AABB (0.0, 1.0, 0.0, 1.0));
   Add_Box (W, Make_AABB (0.5, 1.5, 0.5, 1.5));
   P := Find_Overlapping_Pairs_SAP (W);
   -- P.Count = 1, pair (1, 2)
end;
```

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Psweep_and_prune.gpr`. Main program is
`tests.adb` (no `main.adb`).

## References

1. Ericson, Christer (2005). *Real-Time Collision Detection*. Morgan Kaufmann.
2. Baraff, D. (1992). *Dynamic Simulation of Non-Penetrating Rigid Bodies*
   (Ph.D. thesis), Cornell University.
3. Cohen, Jonathan D.; Lin, Ming C.; Manocha; Ponamgi, Madhav K. (1995).
   *I-COLLIDE: An Interactive and Exact Collision Detection System for
   Large Scale Environments*. Symposium on Interactive 3D Graphics.
4. Wikipedia: [Sweep and prune](https://en.wikipedia.org/wiki/Sweep_and_prune).

## License

Educational reference implementation; no warranty.
