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

### Rewritten First-relative (58) — green make test + CSV `rewritten_first_relative`
**Earlier (15):** BCJR, N-Body, Spline (Thomas), Levinson, Memetic (TSP), Thomas,
Floyds-Cycle, Brents, Barnes-Hut, Gale-Shapley, Min-Conflicts, Hungarian,
Top-Trading-Cycle, Fast-Multipole, Ant-Colony.

**Room-recheck sorts / search / string (23):** Heapsort (Silver offset heap),
Introsort (Silver in-place offset heap + Sort_Traced heap counter / Musser killer / Max_Depth 0), Smoothsort (Fits geometry), FLAME-Clustering (First-relative Result + Same_Bounds),
Interpolation-Search, Knuth-Morris-Pratt, Insertion-Sort, Bubble-Sort,
Selection-Sort, Gnome-Sort, Cycle-Sort, Cocktail-Shaker-Sort, Comb-Sort,
Shell-Sort, Pancake-Sorting, Slowsort, Stooge-Sort, Odd-Even-Sort, Merge-Sort,
Quicksort, Spaghetti-Sort, Bead-Sort, Radix-Sort, Tree-Sort.

**Ledger misc (2):** Branch-and-Bound (Same_Bounds overloads; Density_Order holds
absolute indices; packed Selected; section 13 origins 1/5/100),
Combinatorial-Optimization (pins dropped for Length; labels 1..N stored at any
Cost_Matrix / Tour / Permutation origin via At_Label; section 9 incl. storage
ending at Positive'Last; red on old code: CE at Total_Weight Sel (I)).

**Classroom SPARK4 search (5):** Linear-, Binary-, Jump-, Ternary-, Fibonacci-Search.
Element_Array indexed by Live_Index (1 .. Max_N), In_Bounds = A'Length <= Max_N,
Posts `Result in A'Range`. Jump / Fibonacci bodies walked logical positions as
storage indices, so they now read A (A'First + (P - 1)). Binary / Ternary invariants
now say Lo >= A'First. Shifted-origin sections (1, 5, 17, 33, flush to Max_N,
single cell at Max_N, 2 .. Max_N, empty at 10) were red on old code (Pre failure).
L4 proved: 32 / 106 / 95 / 100 / 69.

**SPARK2 checksum / hash (6):** Adler32, CRC32, Checksum-Ones-Complement,
Delta-Encoding, FNV-Hash, Pearson-Hashing. Pre is now a length bound only.
Delta-Encoding's Net_Delta read Input (1), and now reads Input (Input'First).
Tests use origins 5 / 200 / ending at Positive'Last and empty at 9 (red on old code:
failed precondition). CRC32 lost its unused `use type Unsigned_8` (-gnatwu).

**SPARK2 strings / text (6):** Damerau-Levenshtein, Longest-Common-Substring,
Trigram-Search, Run-Length-Encoding, LZ77, Zobrist-Hashing. DP rows read
A (A'First + (I - 1)); Trigram loops Text'First .. Text'Last - 2; Zobrist keys on
the position I - Text'First, so the hash does not depend on the origin.
RLE: once First was free, L4 found Input'First + 1 overflowing at Positive'Last.
A red test (CE overflow) was added, and the loop now runs First .. Last - 1.
L4 proved: 30 / 12 / 8 / 14 / 3 / 8.
**Held back:** strings/SPARK2 Longest-Common-Subsequence. The rewrite is tested
(GNAT 14/12 green, red on old code) but L4 never finishes (>600 s), the same as
HEAD (PROOFS: `tool crash`). Patch parked, not committed.

### Still stamped `rewrite_first_relative` / `first_pinned` (30)
Remaining SPARK4 classroom sorts (Bogosort, Bitonic, Bucket, Burstsort, Counting,
Flashsort, Library, Patience, Pigeonhole, Postman, Quantum, Samplesort,
Sort-Merge-Join, Strand, Timsort, Topological, …), searching SPARK4 (Uniform-Cost,
Best-First, Introselect, Quickselect), hashing /
compression / misc SPARK2–4,
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
- SPARK Mersenne-Twister: **known compiler bug, closed** — not flaky, not an
  open finding. GNAT 12.2.0/14.2.0 `-gnata -gnatVa` hit a bug box
  (`gnat_to_gnu_entity`) on `Next`'s Post when `X'Old` sat inside an
  if-expression branch. Minimal reproducer kept in-tree at
  `tests/gnat_bug_gnatVa_old` (re-run 2026-10-09: bug box on 14.2.0
  decl.cc:464 and 12.2.0 decl.cc:472; clean without `-gnatVa`). Shipping Post
  rewritten with `or else` (f22269ac, same meaning; written reason next to
  `Next`); init pass yes on GNAT 14 and 12. Recorded fixed in
  `tools/vv/findings.csv`. Does not block training_ready on current code.
- Mersenne-Twister known answers (seed 5489, C++ [rand.predef]): Ada twin
  asserts mt19937 10000th = 4123659995 and mt19937_64 10000th =
  9981545732273789042 (TEST 14); SPARK port asserts 4123659995 (MT19937-64 not
  in the SPARK package by design). Pass on GNAT 14.2.0 and 12.2.0.
- GNAT 12 three-pass (`/tmp/flk/g12_tr.csv`, 271 folders) merged into
  `tools/vv/flaky.csv` (2111 data rows). Counting-Sort finished on GNAT 12
  (10/10, init yes) after long runs; GNAT 14 had previously timed out at 300 s.
- Tip: `a24e4397 FLAME-Clustering: First-relative Dataset / Result bounds; section 20 shift tests`
