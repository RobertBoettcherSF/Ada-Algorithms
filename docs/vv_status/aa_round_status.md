# AA round status — fixed_origin room decision (2026-10-09)

## Mechanical KEEP test
KEEP fixed origin ONLY if the algorithm does arithmetic on the index values themselves
(heap 2*I / I/2, Fenwick I and -I, FFT bit-reversal, 1-based DP, interpolation probe,
package-merge 2*P, polynomial degree index Poly(I)*I). Indexes that only walk or line
arrays up → First-relative rewrite. No judgment beyond that test.

Room recheck flipped Heapsort / Introsort / Smoothsort / Interpolation-Search / KMP
to rewrite (offset / First-relative forms exist); only Package-Merge and PGZ remain KEEP.

## Ledger (`tools/vv/fixed_origin_decisions.tsv`)
- **2 KEEP** (subtypes preferred; one-line arithmetic reason in CSV `note`)
- **88 REWRITE**

### KEEP (2)
| Folder | Reason |
|--------|--------|
| misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm | package-merge pairs 2*P-1 / 2*P |
| compression/Ada/Peterson-Gorenstein-Zierler-Algorithm | coeff index = degree (Derivative Poly(I)*I); subtype Degree_Poly First=0; syndromes First-rel |

### Rewritten First-relative (38) — green make test + CSV `rewritten_first_relative`
**Earlier (15):** BCJR, N-Body, Spline (Thomas), Levinson, Memetic (TSP), Thomas,
Floyds-Cycle, Brents, Barnes-Hut, Gale-Shapley, Min-Conflicts, Hungarian,
Top-Trading-Cycle, Fast-Multipole, Ant-Colony.

**Room-recheck sorts / search / string (23):** Heapsort (Silver offset heap),
Introsort (Silver in-place offset heap), Smoothsort (Fits geometry),
Interpolation-Search, Knuth-Morris-Pratt, Insertion-Sort, Bubble-Sort,
Selection-Sort, Gnome-Sort, Cycle-Sort, Cocktail-Shaker-Sort, Comb-Sort,
Shell-Sort, Pancake-Sorting, Slowsort, Stooge-Sort, Odd-Even-Sort, Merge-Sort,
Quicksort, Spaghetti-Sort, Bead-Sort, Radix-Sort, Tree-Sort.

### Still stamped `rewrite_first_relative` / `first_pinned` (50)
Remaining SPARK4 classroom sorts (Bogosort, Bitonic, Bucket, Burstsort, Counting,
Flashsort, Library, Patience, Pigeonhole, Postman, Quantum, Samplesort,
Sort-Merge-Join, Strand, Timsort, Topological, …), searching SPARK4, hashing /
compression / misc SPARK2–4, FLAME, Branch-and-Bound, Combinatorial-Optimization,
and other Ada walk-index folders. Pins still First=1; code rewrite not done yet.
A2 owns the Float→int list (Clustering, ACO×2, Cross-Entropy, DE, K-Means++,
Harmony, Local-Search, RRHC, SA, Memetic float, ES, EC, GEP, GA, MLT) plus
BrownBoost — leave those alone.

## Other tracks (same tip)
- Johnsons-Algorithm: Initialize_Scalars finding was a real uninit at
  `johnsons_algorithm.adb:527` (Fill_From_Potentials left Dist/Prev beyond N
  undefined). Fixed; flaky init=yes on GNAT 14; section 24 was red on old code.
- Recursive-Descent-Parser: AA_SEED 1,2,22 overflowed Integer on deep literal
  trees; Eval_Wide + Constraint_Error contract; 30 seeds 0 failed on GNAT 14/12.
- SPARK Mersenne-Twister (finding, not flaky): the `-gnata -gnatVa` build hit a
  GNAT bug box on `Next`'s Post (`X'Old` inside an if-expression branch). Minimal
  standalone reproducer `tests/gnat_bug_gnatVa_old` (r.ads 11 + r.adb 6 lines,
  no Initialize_Scalars needed) re-run 2026-10-09: bug box on GNAT 14.2.0
  (decl.cc:464) and 12.2.0 (decl.cc:472); clean without `-gnatVa`. Post now uses
  `or else` (f22269ac); init pass yes on GNAT 14 and on a GNAT 12 re-run (the
  earlier GNAT 12 init=no row predated the fix).
- Mersenne-Twister known answers (seed 5489, C++ [rand.predef]): Ada twin
  asserts mt19937 10000th = 4123659995 and mt19937_64 10000th =
  9981545732273789042 (TEST 14); SPARK port asserts 4123659995 (MT19937-64 not
  in the SPARK package by design). Pass on GNAT 14.2.0 and 12.2.0.
- GNAT 12 three-pass (`/tmp/flk/g12_tr.csv`, 271 folders) merged into
  `tools/vv/flaky.csv` (2111 data rows). Counting-Sort finished on GNAT 12
  (10/10, init yes) after long runs; GNAT 14 had previously timed out at 300 s.
- Tip: see `git log -1`
