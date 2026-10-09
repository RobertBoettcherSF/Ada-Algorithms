# Proof index

Generated 2026-10-08 21:57 CEST.

## Proof setup

```
gnatprove FSF 16.1.0
Why3 for gnatprove version 1.8.2+git
alt-ergo: Alt-Ergo version 2.6.1
cvc5: This is cvc5 version 1.3.2 [git 86cecd8 on branch HEAD]
z3: Z3 version 4.15.4 - 64 bit
(Alire crate gnatprove=16.1.0, alr 2.1.1; GNAT 14.2.0 system, GNAT 12.2.1 Alire gnat_native)
```

* Batch (all SPARK folders): `gnatprove -P <folder gpr> --mode=silver --level=2 -j1 --output=oneline -k` - level 2 = provers cvc5,z3,altergo, `--timeout=5` s per check (wall clock), `--steps=0`, `--memlimit=1000`, per_check, counterexamples off.
* Rerun with a deterministic step budget (rows with `proof_run` = `steps=N`; replaces the batch result): `gnatprove -P <folder gpr> --mode=silver --level=2 --timeout=0 --steps=1000000 --counterexamples=off -j2 --output=oneline -k` - no wall-clock timeout, so the result does not depend on machine load.
* Rows rerun with steps (185): `compression/SPARK2/Ada-SPARK-Compress-String`, `compression/SPARK2/Ada-SPARK-Interleaving-String`, `compression/SPARK2/Ada-SPARK-Run-Length-Encoding`, `geometry/Ada/Bresenhams-Line-Algorithm`, `geometry/Ada/Phong-Shading`, `geometry/SPARK2/Ada-SPARK-Convex-Hull-Graham`, `geometry/SPARK2/Ada-SPARK-Point-In-Polygon`, `graphs/SPARK2/Ada-SPARK-Find-If-Path-Exists-In-Graph`, `graphs/SPARK2/Ada-SPARK-Number-Of-Islands-DFS`, `graphs/SPARK2/Ada-SPARK-Prims-Algorithm`, `graphs/SPARK2/Bellman-Ford-Algorithm`, `hashing/SPARK2/Ada-SPARK-Design-HashMap`, `hashing/SPARK2/Ada-SPARK-Design-HashSet`, `hashing/SPARK2/Ada-SPARK-Pearson-Hashing`, `hashing/SPARK2/Ada-SPARK-Zobrist-Hashing`, `logic/Ada/DPLL`, `matrices/SPARK2/Ada-SPARK-Gaussian-Elimination`, `matrices/SPARK2/Ada-SPARK-Lucky-Numbers-In-A-Matrix`, `matrices/SPARK2/Ada-SPARK-Matrix-Cells-In-Distance-Order`, `matrices/SPARK2/Ada-SPARK-Num-Matrix-Block-Sum`, `misc/Ada/Delivery-Safety-Supervisor`, `misc/Ada/Orbital-Mechanics`, `misc/SPARK2/Ada-SPARK-3Sum-Closest`, `misc/SPARK2/Ada-SPARK-Add-Binary`, `misc/SPARK2/Ada-SPARK-Basic-Calculator-II`, `misc/SPARK2/Ada-SPARK-Beautiful-Arrangement`, `misc/SPARK2/Ada-SPARK-Binary-Watch`, `misc/SPARK2/Ada-SPARK-Broken-Calculator`, `misc/SPARK2/Ada-SPARK-Capacity-To-Ship-Packages`, `misc/SPARK2/Ada-SPARK-Car-Pooling`, `misc/SPARK2/Ada-SPARK-Cheapest-Flights-Within-K-Stops`, `misc/SPARK2/Ada-SPARK-Circular-Queue`, `misc/SPARK2/Ada-SPARK-Coin-Change-II`, `misc/SPARK2/Ada-SPARK-Combination-Sum-III`, `misc/SPARK2/Ada-SPARK-Combination-Sum-IV`, `misc/SPARK2/Ada-SPARK-Container-With-Most-Water`, `misc/SPARK2/Ada-SPARK-Convert-Binary-Number-In-A-Linked-List-To-Integer`, `misc/SPARK2/Ada-SPARK-Copy-List-With-Random-Pointer-Lite`, `misc/SPARK2/Ada-SPARK-Count-And-Say-Stub`, `misc/SPARK2/Ada-SPARK-Count-Odd-Numbers-In-An-Interval`, `misc/SPARK2/Ada-SPARK-Count-Of-Smaller-Numbers-After-Self-Lite`, `misc/SPARK2/Ada-SPARK-Covariance`, `misc/SPARK2/Ada-SPARK-Decode-Ways`, `misc/SPARK2/Ada-SPARK-Delete-Node-In-A-Linked-List`, `misc/SPARK2/Ada-SPARK-Delete-The-Middle-Node`, `misc/SPARK2/Ada-SPARK-Design-Bitset`, `misc/SPARK2/Ada-SPARK-Design-Number-Container-System`, `misc/SPARK2/Ada-SPARK-Design-Underground-System-Lite`, `misc/SPARK2/Ada-SPARK-Distinct-Subsequences`, `misc/SPARK2/Ada-SPARK-Elevator-Algorithm`, `misc/SPARK2/Ada-SPARK-Find-The-Smallest-Divisor`, `misc/SPARK2/Ada-SPARK-Greatest-Common-Divisor`, `misc/SPARK2/Ada-SPARK-Group-Anagrams`, `misc/SPARK2/Ada-SPARK-House-Robber`, `misc/SPARK2/Ada-SPARK-Image-Smoother`, `misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Linked-Lists`, `misc/SPARK2/Ada-SPARK-Jump-Game`, `misc/SPARK2/Ada-SPARK-LFU-Cache-Lite`, `misc/SPARK2/Ada-SPARK-LRU-Cache-Lite`, `misc/SPARK2/Ada-SPARK-Least-Common-Multiple`, `misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence`, `misc/SPARK2/Ada-SPARK-Longest-Ones`, `misc/SPARK2/Ada-SPARK-Longest-Palindromic-Subsequence`, `misc/SPARK2/Ada-SPARK-Longest-Word-In-Dictionary`, `misc/SPARK2/Ada-SPARK-Max-Product-Subarray`, `misc/SPARK2/Ada-SPARK-Maximum-Ice-Cream-Bars`, `misc/SPARK2/Ada-SPARK-Maximum-Product-Subarray`, `misc/SPARK2/Ada-SPARK-Maximum-Subarray`, `misc/SPARK2/Ada-SPARK-Maximum-Twin-Sum-Of-A-Linked-List`, `misc/SPARK2/Ada-SPARK-Mean-Variance`, `misc/SPARK2/Ada-SPARK-Merge-In-Between-Linked-Lists`, `misc/SPARK2/Ada-SPARK-Middle-Of-The-Linked-List`, `misc/SPARK2/Ada-SPARK-Min-Cost-Climbing-Stairs`, `misc/SPARK2/Ada-SPARK-Min-Stack`, `misc/SPARK2/Ada-SPARK-Minimum-ASCII-Delete-Sum`, `misc/SPARK2/Ada-SPARK-Minimum-Path-Sum`, `misc/SPARK2/Ada-SPARK-Next-Greater-Node-In-Linked-List`, `misc/SPARK2/Ada-SPARK-Nth-Digit-Stub`, `misc/SPARK2/Ada-SPARK-Nth-Ugly-Number`, `misc/SPARK2/Ada-SPARK-PN-Counter`, `misc/SPARK2/Ada-SPARK-Palindrome-Linked-List`, `misc/SPARK2/Ada-SPARK-Palindrome-Partitioning`, `misc/SPARK2/Ada-SPARK-Palindrome-Partitioning-II`, `misc/SPARK2/Ada-SPARK-Parity-Bits`, `misc/SPARK2/Ada-SPARK-Partition-Around-Pivot`, `misc/SPARK2/Ada-SPARK-Partition-List`, `misc/SPARK2/Ada-SPARK-Pascal-Triangle`, `misc/SPARK2/Ada-SPARK-Pow-X-N-Stub`, `misc/SPARK2/Ada-SPARK-Power-Of-Three`, `misc/SPARK2/Ada-SPARK-Queue-Using-Stacks`, `misc/SPARK2/Ada-SPARK-Ravenscar-Job-Pool`, `misc/SPARK2/Ada-SPARK-Rectangle-Area`, `misc/SPARK2/Ada-SPARK-Regular-Expression-Matching-Lite`, `misc/SPARK2/Ada-SPARK-Remove-Element`, `misc/SPARK2/Ada-SPARK-Remove-Linked-List-Elements`, `misc/SPARK2/Ada-SPARK-Remove-Nth-Node-From-End`, `misc/SPARK2/Ada-SPARK-Reorder-List`, `misc/SPARK2/Ada-SPARK-Reverse-Linked-List`, `misc/SPARK2/Ada-SPARK-Reverse-Linked-List-II`, `misc/SPARK2/Ada-SPARK-Robot-Return-To-Origin`, `misc/SPARK2/Ada-SPARK-Rotate-List`, `misc/SPARK2/Ada-SPARK-Shortest-Common-Supersequence-Lite`, `misc/SPARK2/Ada-SPARK-Special-Array-With-X-Elements`, `misc/SPARK2/Ada-SPARK-Sqrt-X`, `misc/SPARK2/Ada-SPARK-Swap-Nodes-In-Pairs`, `misc/SPARK2/Ada-SPARK-Swapping-Nodes-In-A-Linked-List`, `misc/SPARK2/Ada-SPARK-Tanimoto`, `misc/SPARK2/Ada-SPARK-To-Lower-Case`, `misc/SPARK2/Ada-SPARK-Top-K-Frequent-Words`, `misc/SPARK2/Ada-SPARK-Trapping-Rain-Water`, `misc/SPARK2/Ada-SPARK-Tribonacci`, `misc/SPARK2/Ada-SPARK-Unique-Paths-II`, `misc/SPARK2/Ada-SPARK-Validate-Stack-Sequences`, `misc/SPARK2/Ada-SPARK-Water-Bottles`, `misc/SPARK2/Ada-SPARK-Wildcard-Matching-Lite`, `misc/SPARK2/Pattern-132`, `misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm`, `ml/Ada/Backpropagation`, `ml/SPARK2/Linear-Regression`, `numerical/SPARK2/Ada-SPARK-Cooley-Tukey-FFT`, `numerical/SPARK2/Ada-SPARK-Count-Primes`, `numerical/SPARK2/Ada-SPARK-Extended-Euclidean`, `numerical/SPARK2/Ada-SPARK-Lagrange-Interpolation`, `numerical/SPARK2/Ada-SPARK-Minimum-Limit-Of-Balls-In-A-Bag`, `numerical/SPARK2/Ada-SPARK-Modular-Exponentiation`, `numerical/SPARK2/Ada-SPARK-Newton-Raphson`, `numerical/SPARK4/Ada-SPARK-Modular-Arithmetic`, `searching/SPARK2/Ada-SPARK-Design-Add-And-Search-Words`, `searching/SPARK2/Ada-SPARK-Exponential-Search`, `searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix`, `searching/SPARK2/Ada-SPARK-Validate-Binary-Search-Tree`, `searching/SPARK2/Ada-SPARK-Word-Search-II-Lite`, `searching/SPARK2/Bst-Insert-Search`, `sorting/SPARK2/Ada-SPARK-Find-Median-Sorted-Arrays-Lite`, `sorting/SPARK2/Ada-SPARK-Merge-Sorted-Array`, `sorting/SPARK2/Ada-SPARK-Merge-Two-Sorted-Lists`, `sorting/SPARK2/Ada-SPARK-Odd-Even-Linked-List`, `sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array-II`, `sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List`, `sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List-II`, `sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity-II`, `sorting/SPARK2/Ada-SPARK-Sort-Characters-By-Frequency`, `sorting/SPARK2/Ada-SPARK-Sort-Colors`, `sorting/SPARK2/Ada-SPARK-Sort-List-Lite`, `sorting/SPARK2/Ada-SPARK-Squares-Of-A-Sorted-Array`, `sorting/SPARK2/Ada-SPARK-Tim-Sort-Stub`, `strings/SPARK2/Ada-SPARK-Delete-Operation-For-Two-Strings`, `strings/SPARK2/Ada-SPARK-Edit-Distance`, `strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt`, `strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence`, `strings/SPARK2/Ada-SPARK-Multiply-Strings-Stub`, `strings/SPARK2/Ada-SPARK-Number-Of-Lines-To-Write-String`, `strings/SPARK2/Ada-SPARK-One-Edit-Distance`, `strings/SPARK2/Ada-SPARK-Rabin-Karp`, `strings/SPARK2/Ada-SPARK-Repeated-String-Match`, `strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String-III`, `strings/SPARK2/Ada-SPARK-Sum-Of-Digits-Of-String-After-Convert`, `strings/SPARK2/Ada-SPARK-Z-Algorithm`, `strings/SPARK3/Levenshtein-Distance`, `trees/SPARK2/Ada-SPARK-Balanced-Binary-Tree`, `trees/SPARK2/Ada-SPARK-Binary-Tree-Inorder`, `trees/SPARK2/Ada-SPARK-Binary-Tree-Level-Order`, `trees/SPARK2/Ada-SPARK-Binary-Tree-Max-Depth`, `trees/SPARK2/Ada-SPARK-Binary-Tree-Min-Depth`, `trees/SPARK2/Ada-SPARK-Binary-Tree-Postorder`, `trees/SPARK2/Ada-SPARK-Binary-Tree-Preorder`, `trees/SPARK2/Ada-SPARK-Convert-BST-To-Greater-Tree`, `trees/SPARK2/Ada-SPARK-Diameter-Of-Binary-Tree`, `trees/SPARK2/Ada-SPARK-Get-Equal-Substrings-Within-Budget`, `trees/SPARK2/Ada-SPARK-Implement-Trie`, `trees/SPARK2/Ada-SPARK-Insert-Into-BST`, `trees/SPARK2/Ada-SPARK-Invert-Binary-Tree`, `trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeat`, `trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-BST`, `trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-Of-BST`, `trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-Binary-Tree`, `trees/SPARK2/Ada-SPARK-Merge-Two-Binary-Trees`, `trees/SPARK2/Ada-SPARK-Minimum-Depth-Of-Binary-Tree`, `trees/SPARK2/Ada-SPARK-Number-Of-Substrings-Containing-All-Three-Characters`, `trees/SPARK2/Ada-SPARK-Range-Sum-BST`, `trees/SPARK2/Ada-SPARK-Range-Sum-Of-BST`, `trees/SPARK2/Ada-SPARK-Same-Tree`, `trees/SPARK2/Ada-SPARK-Subtree-Of-Another-Tree`, `trees/SPARK2/Ada-SPARK-Symmetric-Tree`, `trees/SPARK2/Ada-SPARK-Unique-Paths-With-Obstacles`

One row per algorithm folder (full data in [`PROOFS.csv`](PROOFS.csv)). Regenerate with
`python3 tools/proof_index.py --results <dir> --logs <prove-workdir>` (see `tools/audit/`).
Builds: `gnatmake -gnatwa -gnat2022` on `tests.adb` (GNAT 14 system, GNAT 12 Alire). `make test` = the folder's own Makefile (GNAT 14). Tests pass = `make test` passes, or the uniform build's test binary exits 0 with no FAIL lines.
Silver: `gnatprove --mode=silver --level=2` on the folder's own .gpr (generated where none exists).

Folders: 1840; duplicates (counted once): 2; Ada<->SPARK pairs: 110; stub sheets (name ends in -Stub or README says stub, column `stub`): 144.

**Training-ready: 4 folders** (duplicates counted once) - builds and tests pass on GNAT 12 and 14, the folder's own `make test` passes on GNAT 14 and on GNAT 12 (columns `make_test`, `make_test_gnat12`), no open finding in `tools/vv/findings.csv` (column `open_findings`), Silver-proven non-trivially, not a stub, and a known answer (column `known_answer`): a registered known-answer vector, own tests (self-written properties or brute-force reference, `tests/SOURCES.txt`), or an agreeing differential test against its twin - and in every case the do-nothing check must not flag the tests as weak. Stricter rule since 2026-10-08 (column `training_ready`; the old verdict is kept in `training_ready_old`, the reasons for a drop in `tr_drop`): (1) the folder's tests kill at least 90% of the planted mutants (column `mutation_score`; `tools/vv/mutate.py`, 20 seeded mutants per folder; surviving mutants count as non-equivalent until reviewed); (2) the known answer comes from a different method than the code under test - a registered vector or own tests (brute force or an independent property); agreement with the twin alone does not count (columns `ref_independent`, `twin_only`); (3) zero warnings with `-gnatwa` on GNAT 14 and on GNAT 12, fixed in code: a folder with `pragma Warnings (Off ...)` or `-gnatws`/`-gnatwA` is not training-ready (column `warnings_suppressed`, list in `tools/vv/warnings_suppressed.csv`); (4) every `pragma Assume` / `pragma Annotate (GNATprove, ...)` carries a written reason (column `proof_escapes`, list in `tools/vv/proof_escapes.csv`); an unexplained one voids the Silver claim. The column `known_answer_source` says where the expected values come from (own / standard / old_derived / old_unverified); hard-coded answers in old tests count only when they were derived independently (`tools/vv/old_derived.csv`), never when they may have been copied from program output (old_unverified). A sort whose proof rests on a final Bubble_Finish pass that masks the named algorithm (`tools/vv/sweep_masking.csv`, column `masked_by_finish`) is not training-ready either; a surviving mutant counts as equivalent only when `tools/vv/sweep_equivalent.csv` lists it with exhaustive evidence or a written reason. Flaky tests (docs/VV.md 3j, `tools/vv/flaky.py` -> `tools/vv/flaky.csv`, column `flaky`): a folder is training-ready only with flaky=no - the same result in 10 repeated runs on the default seed, no failing AA_SEED in 1..30 for tests that use randomness, and no new failure in a build with `pragma Initialize_Scalars` and `-gnatVa`; on a flaky folder no mutation score counts until it is fixed. Under the old rule: 271 folders.

**Do-nothing check:** 1708 folders checked, 34 flagged weak (tests still pass when the main subprogram does nothing), 24 unchecked (no trivial body compiles); 0 of the weak ones are Silver-proven non-trivial. Own tests: 288 folders (column `own_tests`).

**Silver headline (duplicates counted once):** 482 real SPARK folders proven non-trivially, 306 proven but trivial (<= 3 checks), 143 stubs proven (separate), 3 with unproved checks, 10 gnatprove tool crash/timeout, 11 not built for gnatprove, 0 not run; 143 proven real folders also prove functional contracts

`stub` column: every folder whose name ends in `-Stub` (toy fixed-size versions) is flagged, and so is every folder listed in `tools/readme_stubs.txt` (its README calls it a stub); the 3 near-duplicate stubs also carry `duplicate_of`. Stubs are counted separately and never in the "real" numbers. Folders listed in `tools/generalised_stubs.txt` keep their `-Stub` name but were rewritten for arbitrary-length input; they carry `generalised` = yes instead of `stub` and count as real. `trivial` = proven with at most 3 checks in total (gnatprove.out); `functional_checks` = number of functional-contract (post/contract-case) checks proved.

| Level | Folders | make test OK | Build 14 | Build 12 | Tests 14 | Tests 12 | 0 warn 14 | 0 warn 12 | Proven (real) | Proven (stub) | Trivial | Unproved | Tool crash | Not built | Not run |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Ada | 908 | 889 | 884 | 884 | 891 | 891 | 693 | 669 | 12 | 0 | 2 | 2 | 2 | 11 | 0 |
| SPARK2 | 859 | 859 | 859 | 859 | 859 | 859 | 594 | 589 | 708 | 143 | 373 | 0 | 8 | 0 | 0 |
| SPARK3 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 1 | 0 | 0 | 1 | 0 | 0 | 0 |
| SPARK4 | 69 | 67 | 67 | 67 | 67 | 67 | 67 | 31 | 67 | 0 | 0 | 0 | 0 | 0 | 0 |
| All | 1838 | 1817 | 1812 | 1812 | 1819 | 1819 | 1356 | 1291 | 788 | 143 | 375 | 3 | 10 | 11 | 0 |

## Flagship folders: what each one really does

Scope statements from the flagship review (`tools/vv/flagship_status.csv`, folder READMEs):

- Conflict-Driven-Clause-Learning: CDCL SAT solver (1-UIP-style learning, geometric restarts, oldest-non-reason clause deletion) with naive full-scan propagation. Decision rule: the lowest-numbered unassigned variable is set to False; with this rule every satisfiable answer is the lexicographically smallest model, whatever the restart and deletion options (argument in cdcl.ads). This is a property of this folder's decision rule only: standard CDCL with VSIDS or phase saving does not guarantee it.
- Automated-Theorem-Proving: propositional CNF satisfiability only (truth table, DPLL, Davis-Putnam resolution); yes/no answers, no model and no proof object.
- Verified-Unification-Engine: proved free of run-time errors (SPARK level 2) plus one functional property (Unify never changes an existing binding); unifier correctness is tested, not proved.
- First-Order-Logic: an evaluator over a fixed 3-element domain with capture-avoiding substitution; unary symbols get no second argument (Optional_Element); not a prover.
- Darwin-Godel-Machine: a demo that selects among caller-supplied numeric records; no self-modification, code evolution or proof.
- Hindley-Milner-Type-Inference-Algorithm / Hindley-Milner-Type-System: Algorithm W (and M) with let-polymorphism, checked against a separate let-expanding reference.
- Rete-Algorithm: alpha memories and beta join chains with retraction; the batched insert is a loop over single inserts.


## V&V (validation) results

Plan and harness: `docs/VV.md`, `make vv`. Differential pairs run: 74 (74 agree on every case); mutation: `mutation.csv` 66 killed / 19 survived (77%); `mutation_halves.csv` 11 killed / 0 survived (100%); `mutation_pilot.csv` 47 killed / 12 survived (79%); `mutation_sites_all.csv` 81 killed / 31 survived (72%); `mutation_tr.csv` 2682 killed / 771 survived (77%) (a folder in several files shows the last one: all-sites beats pilot beats sample); folders with registered known-answer vectors: 2. Own tests: 259 folders (`tools/vv/own_tests.csv`); do-nothing check: `vv/results/donothing.csv` (rows below: every folder with a V&V result or flagged weak). Columns `diff_test`, `mutation`, `kat`, `own_tests`, `do_nothing`, `known_answer` in PROOFS.csv.

| Folder | Differential test | Mutation (killed/total) | Tuned / held-out (non-equivalent killed/total) | Known-answer source | Own tests | Do-nothing | Known answer |
|---|---|---|---|---|---|---|---|
| compression/Ada/Audio-Compression |  |  |  |  |  | ok | own tests |
| compression/Ada/Run-Length-Encoding | agree (vs compression/SPARK2/Ada-SPARK-Run-Length-Encoding, 1000 cases) |  |  |  |  | ok | diff agree |
| compression/SPARK2/Ada-SPARK-Compress-String |  | 10/14 | - / 23/30 |  | own run-length size reference (character + decimal count per run); every string over {a;b} and {a;b;c} | ok | own tests |
| compression/SPARK2/Ada-SPARK-Interleaving-String |  | 14/15 |  |  | own recursive interleaving reference; all 29791 triples up to length 4 over {0;1} (exhaustive) | ok | own tests |
| compression/SPARK2/Ada-SPARK-Run-Length-Encoding | agree (vs compression/Ada/Run-Length-Encoding, 1000 cases) | 8/8 |  |  | own run-length encoder pair count; 20000 random strings over 1/2/26 letters (twin-only) | ok | own tests, diff agree |
| compression/SPARK2/Ada-SPARK-String-Compression |  | 7/9 |  |  | round trip (expand runs = input) + counts >= 1 + maximal runs; 5000 random | ok | own tests |
| compression/SPARK2/Burrows-Wheeler-Transform |  | 5/7 |  |  | rotation characters and lexicographic order of different rotations from the definition; 4000 random | ok | own tests |
| compression/SPARK3/Huffman-Coding |  | 6/8 |  |  | own symbol counts; distinct count; most frequent has maximal count; 4000 random | ok | own tests |
| concurrency/SPARK2/Course-Schedule |  |  |  |  |  | weak |  |
| cryptography/Ada/RSA |  |  | 21/22 / 47/50 |  |  | weak |  |
| geometry/Ada/Bresenhams-Line-Algorithm |  | 5/8 |  |  |  | ok |  |
| geometry/Ada/Liang-Barsky |  | 17/20 |  |  |  | ok | own tests |
| geometry/Ada/Line-Clipping |  | baseline killed |  |  | all 4 clippers vs own brute-force sampling (4001 samples); 3000 random window/segment pairs (sample_ada_30) | ok | own tests |
| geometry/Ada/Vatti |  |  |  |  |  | weak |  |
| geometry/SPARK2/Ada-SPARK-Convex-Hull-Graham |  | 16/16 |  |  | own monotone-chain hull (strict) as cyclic sequence; 20000 random distinct point sets prepared in Graham order (own exact angle sort) + collinear and extreme cases | ok | own tests |
| geometry/SPARK2/Ada-SPARK-Point-In-Polygon |  | 17/19 | - / 29/30 |  | own winding-number reference (exact integers); 4000 random simple triangles/quads x 60 off-boundary queries; degenerate 1-2 vertex polygons contain nothing | ok | own tests |
| graphs/Ada/Bellman-Ford-Algorithm | agree (vs graphs/SPARK2/Bellman-Ford-Algorithm, 1000 cases) | 13/19 |  |  | negative-cycle status + distances + Prev paths vs own simple-path/cycle enumeration; 4000 random digraphs (greedy family) | ok | own tests, diff agree |
| graphs/Ada/Dijkstras-Algorithm |  | 15/18 |  |  | distances + Prev paths vs own simple-path enumeration; 4000 random digraphs n<=6 (greedy family) | ok | own tests |
| graphs/Ada/Floyd-Warshall-Algorithm | agree (vs graphs/SPARK2/Ada-SPARK-Floyd-Warshall, 1000 cases) | 12/18 |  |  | negative-cycle status + all-pairs distances + Next paths vs own enumeration; 3000 random digraphs (greedy family) | ok | own tests, diff agree |
| graphs/Ada/Kruskals-Algorithm |  | 14/20 |  |  | MST weight vs own brute force over edge subsets + edge validity; 1500 connected multigraphs (sample_ada_30) | ok | own tests |
| graphs/SPARK2/Ada-SPARK-Clone-Graph |  |  |  |  |  | weak |  |
| graphs/SPARK2/Ada-SPARK-Clone-Graph-Stub |  |  |  |  |  | weak |  |
| graphs/SPARK2/Ada-SPARK-Find-If-Path-Exists-In-Graph |  | 7/8 | - / 30/30 |  | own Warshall transitive closure; 600 random directed/symmetric graphs; every start/goal pair (153600 queries) | ok | own tests |
| graphs/SPARK2/Ada-SPARK-Floyd-Warshall | agree (vs graphs/Ada/Floyd-Warshall-Algorithm, 1000 cases) |  |  |  |  | ok | diff agree |
| graphs/SPARK2/Ada-SPARK-Is-Graph-Bipartite |  | 5/5 |  |  |  | ok |  |
| graphs/SPARK2/Ada-SPARK-Number-Of-Islands-DFS |  | 16/17 |  |  | own recursive flood fill (4-connected); every 4x4 grid (65536) | ok | own tests |
| graphs/SPARK2/Ada-SPARK-Prims-Algorithm |  | 2/5 |  |  | own brute-force minimum spanning tree over every parent array; 5000 random connected 4-node graphs | ok | own tests |
| graphs/SPARK2/Bellman-Ford-Algorithm | agree (vs graphs/Ada/Bellman-Ford-Algorithm, 1000 cases) | 2/13 |  |  |  | ok | diff agree |
| hashing/Ada/Geohash |  |  |  |  |  | ok | own tests |
| hashing/Ada/Pearson-Hashing | agree (vs hashing/SPARK2/Ada-SPARK-Pearson-Hashing, 1000 cases) |  |  |  |  | ok | diff agree |
| hashing/SPARK2/Ada-SPARK-Design-HashMap |  | no sites |  |  | model-based: 2000 random Put sequences vs own array model; every key checked after every operation | ok | own tests |
| hashing/SPARK2/Ada-SPARK-Design-HashSet |  | no sites |  |  | model-based: 2000 random Add/Remove sequences vs own Boolean model; every element checked after every operation | ok | own tests |
| hashing/SPARK2/Ada-SPARK-Pearson-Hashing | agree (vs hashing/Ada/Pearson-Hashing, 1000 cases) |  |  |  |  | ok | diff agree |
| hashing/SPARK2/Ada-SPARK-Zobrist-Hashing |  | 3/11 | 4/4 / 14/30 |  | Zobrist properties via public Hash: XOR of per-(position;character) keys independent of other characters; one changed character changes the hash; distinct keys per position | ok | own tests |
| logic/Ada/Automated-Theorem-Proving |  |  | 35/35 / 32/32 |  |  | ok |  |
| logic/Ada/DPLL |  | 14/20 | - / 26/30 |  | own brute force over all 2^N assignments; model checked by own evaluator; Is_Satisfiable and From_DIMACS_Lite (own DIMACS writer) agree; 3000 random CNFs (1270 sat / 1730 unsat) | ok | own tests |
| logic/Ada/Verified-Unification-Engine |  |  | 54/55 / 35/35 |  |  | ok |  |
| matrices/Ada/Matrix-Multiplication |  |  | 353/363 / 121/123 |  |  | ok | own tests |
| matrices/Ada/Sparse-Matrix |  |  |  |  |  | weak |  |
| matrices/SPARK2/Ada-SPARK-Gaussian-Elimination |  | 6/6 |  |  | own property: R(2;1)=0 and same integer solution set on a 31x31 grid; every first-column pair x 60 random completions + zero-pivot cases | ok | own tests |
| matrices/SPARK2/Ada-SPARK-Lucky-Numbers-In-A-Matrix |  | 2/3 | - / 14/17 |  | lucky-number property (row min and column max) checked over all cells; 20000 random matrices (distinct values with planted lucky numbers; values 0..3 with ties) | ok | own tests |
| matrices/SPARK2/Ada-SPARK-Matrix-Cells-In-Distance-Order |  | 13/20 | - / 25/30 |  | own properties: every cell once; starts at origin; non-decreasing Manhattan distance; every origin; Manhattan for all 256 pairs | ok | own tests |
| matrices/SPARK2/Ada-SPARK-Num-Matrix-Block-Sum |  | 16/20 | - / 30/30 |  | own clipped-block reference over every cell and radius; 2000 random matrices (128000 sums) | ok | own tests |
| misc/Ada/Adler-32 | agree (vs misc/SPARK2/Ada-SPARK-Adler32, 1000 cases) |  |  |  |  | ok | diff agree |
| misc/Ada/Backtracking |  | 4/20 |  |  | N-Queens/subset-sum/colouring vs own exhaustive search (sample_ada_30) | ok | own tests |
| misc/Ada/Banzhaf-Power-Index |  |  |  |  |  | weak |  |
| misc/Ada/Bowyer-Watson |  | 12/20 |  |  | own hull/in-circle geometry: Delaunay property; count 2n-2-h; area = hull area; 1500 random sets (sample_ada_30) | ok | own tests |
| misc/Ada/Cheneys-Algorithm |  |  |  |  |  | weak |  |
| misc/Ada/Chinese-Whispers |  | 7/8 |  |  |  | unchecked (main stillborn) |  |
| misc/Ada/Computus |  | 18/19 |  |  | Gregorian Easter 1583..9999 vs own Clavius epact; Julian Easter 1..9999 from definition; Orthodox; weekday/day difference vs own JDN (sample_ada_30) | ok | own tests |
| misc/Ada/Conflict-Driven-Clause-Learning |  |  | 40/40 / 42/44 |  |  | ok |  |
| misc/Ada/Delta-Encoding | agree (vs misc/SPARK2/Ada-SPARK-Delta-Encoding, 1000 cases) |  |  |  |  | ok | diff agree |
| misc/Ada/Dice-Coefficient |  | 20/20 |  |  |  | ok | own tests |
| misc/Ada/Division-Algorithms |  | 14/19 |  |  | truncating-division identities on all 8-bit pairs; Schoolbook and float methods on random inputs (sample_ada_30) | ok | own tests |
| misc/Ada/Elser-Difference-Map-Algorithm |  |  |  |  |  | weak |  |
| misc/Ada/First-Order-Logic |  |  | - / 44/45 |  |  | ok |  |
| misc/Ada/Golomb-Coding |  | 7/8 |  |  |  | ok |  |
| misc/Ada/Gray-Code | agree (vs misc/SPARK2/Ada-SPARK-Gray-Code, 1000 cases) |  |  |  |  | ok | diff agree |
| misc/Ada/Hamming-Weight | agree (vs misc/SPARK2/Ada-SPARK-Hamming-Weight, 1000 cases) | 18/19 |  |  | all five variants vs own division-by-2 count; 50000 values with edges (sample_ada_30) | ok | own tests, diff agree |
| misc/Ada/Hidden-Subgroup-Problem |  |  | 51/52 / 164/166 |  |  | baseline fails | own tests |
| misc/Ada/Hindley-Milner-Type-Inference-Algorithm |  |  | - / 45/45 |  |  | ok |  |
| misc/Ada/Hindley-Milner-Type-System |  |  | 26/26 / 23/23 |  |  | ok |  |
| misc/Ada/Integer-Factorization |  | 16/20 |  |  |  | ok | own tests |
| misc/Ada/Johnsons-Algorithm |  |  |  |  |  | weak |  |
| misc/Ada/Kadanes-Algorithm | agree (vs misc/SPARK2/Ada-SPARK-Kadanes-Algorithm, 1000 cases) |  |  |  |  | ok | diff agree |
| misc/Ada/Knuth-Bendix-Completion |  | 5/8 |  |  |  | unchecked (main stillborn) |  |
| misc/Ada/Lempel-Ziv-Ross-Williams |  | 15/20 |  |  | own round-trip property; 2000 random inputs x 3 index ranges (1 .. N; from 'First; up to 'Last) | ok | own tests |
| misc/Ada/Longest-Increasing-Subsequence | agree (vs misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence, 1000 cases) |  |  |  |  | ok | diff agree |
| misc/Ada/Median-Filtering | agree (vs misc/SPARK2/Ada-SPARK-Median-Filtering, 1000 cases) | 12/20 |  |  | Process_1D vs own replicated-window median; 5000 signals; odd kernels (sample_ada_30) | ok | own tests, diff agree |
| misc/Ada/Mu-Law-Algorithm |  | 12/19 |  |  | all 256 codes decode without exception and non-decreasing | ok | own tests |
| misc/Ada/Mullers-Method |  |  |  |  |  | weak |  |
| misc/Ada/Nagles-Algorithm |  |  |  |  |  | weak |  |
| misc/Ada/Nonlinear-Optimization |  | 7/8 |  |  |  | ok |  |
| misc/Ada/Package-Merge-Algorithm | agree (vs misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm, 1000 cases) |  |  |  |  | unchecked (main stillborn) | diff agree |
| misc/Ada/Phonetic-Algorithms |  |  | 217/217 / 130/130 |  |  | ok | own tests |
| misc/Ada/Poly1305 |  | 18/20 |  |  |  | baseline fails | own tests |
| misc/Ada/Polynomial-Long-Division |  | 7/8 |  |  |  | ok |  |
| misc/Ada/Quine-McCluskey-Algorithm |  | 15/20 |  |  |  | ok | own tests |
| misc/Ada/Recovery-Exploiting-Semantics |  |  |  |  |  | weak |  |
| misc/Ada/Replicator-Equation |  | 6/8 |  |  |  | ok |  |
| misc/Ada/Rete-Algorithm |  |  | 56/56 / 38/40 |  |  | ok |  |
| misc/Ada/SEQUITUR-Algorithm |  |  |  |  |  | weak |  |
| misc/Ada/Selection-Algorithm | agree (vs misc/SPARK4/Ada-SPARK-Selection-Algorithm, 1000 cases) |  |  |  |  | ok | diff agree |
| misc/Ada/Truncated-Binary-Encoding |  | 20/20 |  |  | own code properties (lengths; prefix-free; complete) + decode round trips; N in 2 .. 200 (sample_ada_30) | ok | own tests |
| misc/Ada/Truncated-Binary-Exponential-Backoff |  |  |  |  |  | ok | own tests |
| misc/Ada/Unicode-Collation-Algorithm |  | 10/11 |  |  |  | weak |  |
| misc/Ada/Zero-Attribute-Rule |  | 20/20 |  |  | own mean/median/mode references (ties to smallest); 10000 random sets; empty -> Empty_Dataset_Error (sample_ada_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-3Sum-Closest |  | 9/13 | - / 26/30 |  | own enumeration of all triples (result is a triple sum at minimal distance); 4000 random arrays; lengths 0..2 rejected | ok | own tests |
| misc/SPARK2/Ada-SPARK-Add-Binary |  | 9/9 |  |  | own reference (A + B) mod 2^8; every pair of 8-bit values (65536) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Add-Without-Plus |  | 10/11 |  |  | own integer addition; every operand pair (40401) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Adler32 | agree (vs misc/Ada/Adler-32, 1000 cases) | 2/2 |  |  | standard value Adler-32("Wikipedia")=11E60398; empty=1; own definition sums on 5000 random inputs (twin-only) | ok | own tests, diff agree |
| misc/SPARK2/Ada-SPARK-Alien-Dictionary-Stub |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Arranging-Coins |  | 4/4 |  |  | definition property K(K+1)/2 <= N < (K+1)(K+2)/2; every N to 10^6; every triangular boundary; random to 10^9 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Assign-Cookies |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Basic-Calculator-II |  | 3/3 |  |  | exact integer result for every operand pair in -31..31 (3969 x 4 ops); out-of-range operands rejected (in tests.adb) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Beautiful-Arrangement |  | 9/9 |  |  | standard rule (permutation of 1..N + divisibility); every arrangement of 0..8 at 4 positions; 50000 random permutations N 5..8 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock |  | 1/3 |  |  | own all-pairs best gain; all 6561 arrays over 0..2 + 5000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-With-Cooldownoldown |  | 3/6 | - / 21/24 |  | own brute force over every buy/sell/rest sequence; 3000 random inputs | ok | own tests |
| misc/SPARK2/Ada-SPARK-Binary-Watch |  | 3/3 |  |  | definition 60*H+M and validity; every reading (720) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Broken-Calculator |  | 10/10 |  |  | own breadth-first search over 0..64 (double / decrement); every start and target in 1..32 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Bulb-Switcher |  | 5/5 |  |  | own simulation of the toggling rounds (N <= 3000) + perfect-square property; every N to 10^6; square boundaries; random to 10^9 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Candy |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Capacity-To-Ship-Packages |  | 5/6 | - / 19/19 |  | own enumeration of all 2^7 cut sets (min heaviest day); 3000 random weight lists x every day count | ok | own tests |
| misc/SPARK2/Ada-SPARK-Car-Pooling |  | 5/5 |  |  | own per-stop count (Pickup <= stop < Dropoff); 20000 random trip sets x limits 0..12; back-to-back case | ok | own tests |
| misc/SPARK2/Ada-SPARK-Cheapest-Flights-Within-K-Stops |  | 3/7 | - / 23/26 |  | own depth-first enumeration of routes with at most K+1 flights; 1500 random flight sets x every pair x K 0..3 (216000 queries) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Check-If-Number-Is-A-Sum-Of-Powers-Of-Three |  | 2/2 |  |  | own list of all 2^19 sums of distinct powers of three; every value to 2*10^6; 200000 random lookups to 10^9 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Circular-Queue |  | 12/14 | - / 29/30 |  | model-based: 500 random runs of 100 operations vs own FIFO model (wrap-around and full queue) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Coin-Change-II |  | 2/4 |  |  | own multiset enumeration; all distinct denomination prefixes and amounts 1..4 (exhaustive) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Combination-Sum-III |  | 16/17 |  |  | own enumeration of all 512 digit subsets; every K 0..9 and N 0..45 (Feasible and Count_Choices) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Combination-Sum-IV |  | 9/9 |  |  | own recursive enumeration of ordered sequences of parts {1;2;3}; every target 0..12 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Container-With-Most-Water |  | 3/7 |  |  | own all-pairs area; 6000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Convert-Binary-Number-In-A-Linked-List-To-Integer |  | 9/11 | - / 26/30 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Copy-List-With-Random-Pointer-Lite |  | 2/3 | - / 10/18 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Count-And-Say-Stub |  | 14/18 | - / 25/30 | OEIS A005150 (terms) and A005341 (lengths) |  | ok | kat |
| misc/SPARK2/Ada-SPARK-Count-Odd-Numbers-In-An-Interval |  | 8/8 |  |  | brute-force count for every interval in 0..400; additivity / half-length / short brute force on 50000 random large intervals | ok | own tests |
| misc/SPARK2/Ada-SPARK-Count-Of-Smaller-Numbers-After-Self-Lite |  | 4/5 | - / 17/18 |  | own definition count; 20000 random arrays with ties (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Counting-Bits |  | 3/3 |  |  | own bit count; 0..2**16 (exhaustive) + 20000 random + powers of two | ok | own tests |
| misc/SPARK2/Ada-SPARK-Covariance |  | 12/12 |  |  | own deviation-from-mean reference; 166375 vector pairs | ok | own tests |
| misc/SPARK2/Ada-SPARK-Decode-Ways |  | 5/5 |  |  | own recursive decoding; 4000 random + all-ones up to length 29 (30-32 can exceed Result) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Delete-Node-In-A-Linked-List |  | 7/10 | - / 24/30 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Delete-The-Middle-Node |  | 5/8 | - / 5/30 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Delta-Encoding | agree (vs misc/Ada/Delta-Encoding, 1000 cases) | 1/1 |  |  | sum of encoded deltas; 20000 random streams with extremes (twin-only) | ok | own tests, diff agree |
| misc/SPARK2/Ada-SPARK-Design-Bitset |  | 3/4 | - / 3/3 |  | own Boolean-array model; 500 random runs of 100 operations (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Design-Number-Container-System |  | 5/5 |  |  | own stack model; 1000 random runs x 60 operations plus full/empty rejection checks | ok | own tests |
| misc/SPARK2/Ada-SPARK-Design-Underground-System-Lite |  | 7/7 |  |  | own sum/count floor average; 20000 random trip lists (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Dutch-National-Flag |  | 1/3 |  |  | order and colour counts; all 243 arrays | ok | own tests |
| misc/SPARK2/Ada-SPARK-Elevator-Algorithm |  | 6/6 |  |  | exhaustive one-step and reach-target properties over all floor pairs (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Title |  | 8/8 |  |  |  | ok |  |
| misc/SPARK2/Ada-SPARK-Fibonacci-DP |  | 3/5 | - / 20/22 |  |  | ok | own tests |
| misc/SPARK2/Ada-SPARK-Find-Median-From-Data-Stream |  | 7/10 | - / 28/30 |  | own counting-order median (even count: Ada division); 20000 random inputs | ok | own tests |
| misc/SPARK2/Ada-SPARK-Find-The-City |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Find-The-Smallest-Divisor |  | 2/4 | - / 8/10 |  | minimality property (meets the limit; D - 1 does not); 73 limits + 3000 random; infeasible limits rejected (in tests.adb) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Flatten-Nested-List-Stub |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Gas-Station |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Gray-Code | agree (vs misc/Ada/Gray-Code, 1000 cases) | no sites |  |  | reflected-binary construction table 0..4095; one-bit successor; round trips on random 32-bit words (twin-only) | ok | own tests, diff agree |
| misc/SPARK2/Ada-SPARK-Greatest-Common-Divisor |  | 1/1 |  |  | own divisor search (definition); all pairs 1..150 + 20000 random pairs | ok | own tests |
| misc/SPARK2/Ada-SPARK-Group-Anagrams |  | 7/7 |  |  | own letter-count anagram reference (label = first word of the group); 20000 random word sets | ok | own tests |
| misc/SPARK2/Ada-SPARK-Guess-Number-Higher-Or-Lower |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Hamming-Weight | agree (vs misc/Ada/Hamming-Weight, 1000 cases) | 3/3 |  |  | count by repeated division; exhaustive 0..2**20 plus random (twin-only) | ok | own tests, diff agree |
| misc/SPARK2/Ada-SPARK-House-Robber |  | 4/4 |  |  | own enumeration of non-adjacent subsets; all 729 arrays over 0..2 + 5000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-House-Robber-II |  | 5/6 |  |  |  | ok | own tests |
| misc/SPARK2/Ada-SPARK-Image-Smoother |  | 20/20 |  |  | own 3x3-window floor-average reference; 20000 random images (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Linked-Lists |  | 7/11 | - / 19/30 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Jump-Game |  | 2/3 | - / 11/11 |  | own breadth-first reachability reference; hand cases; 20000 random arrays | ok | own tests |
| misc/SPARK2/Ada-SPARK-Jump-Game-II |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Kadanes-Algorithm | agree (vs misc/Ada/Kadanes-Algorithm, 1000 cases) |  |  |  |  | ok | diff agree |
| misc/SPARK2/Ada-SPARK-Knapsack-01 |  | 5/6 |  |  | own subset enumeration; 5000 random item sets x all limits 0..10 | ok | own tests |
| misc/SPARK2/Ada-SPARK-LFU-Cache-Lite |  | 18/20 |  |  | own frequency+recency model (ties: least recent); 1000 random runs x 60 operations; keys 0..24; capacity 16 | ok | own tests |
| misc/SPARK2/Ada-SPARK-LRU-Cache-Lite |  | 12/12 |  |  | own recency-list model; 1000 random runs x 60 operations; keys 0..24; capacity 16 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Largest-Rectangle-In-Histogram |  | 4/7 |  |  | own all-intervals width x minimum; 6000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Least-Common-Multiple |  | 2/2 |  |  | own multiple search (definition); all pairs 1..150 + 20000 random pairs | ok | own tests |
| misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence | agree (vs misc/Ada/Longest-Increasing-Subsequence, 1000 cases) | 4/8 |  |  |  | ok | diff agree |
| misc/SPARK2/Ada-SPARK-Longest-Ones |  | 9/11 | - / 30/30 |  | own all-windows reference; every 8-bit array and every flip budget (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Longest-Palindromic-Subsequence |  | 17/19 |  |  | own all-subsequences check; all strings over {a;b} up to length 9 + 1500 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Longest-Word-In-Dictionary |  | 6/8 | - / 27/29 |  | own prefix-closure reference on letter strings; 30000 random dictionaries (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Majority-Element |  | 20/20 |  |  | planted strict majority (4..7 of 7); 6000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Max-Product-Subarray |  | 3/8 | - / 19/30 |  | own all-subarrays reference in Long_Long_Integer; all 13**6 arrays over -6..6; out-of-range elements rejected (in tests.adb) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Maximal-Square |  | 20/20 |  |  | own all-squares check; all 65536 matrices (exhaustive) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Maximum-Ice-Cream-Bars |  | 0/1 |  |  | own one-bar-at-a-time reference; every price 1..1000 x budgets 0..3200 (in tests.adb) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Maximum-Points-You-Can-Obtain-From-Cards |  | 8/10 | - / 30/30 |  | own brute force over the left/right split; 20000 random inputs | ok | own tests |
| misc/SPARK2/Ada-SPARK-Maximum-Product-Subarray |  | 2/4 |  |  | own all-runs product (empty-run convention fixed by one input); all arrays over -3..3 up to length 4 + 5000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Maximum-Subarray |  | 2/6 |  |  | own all-runs maximum (empty-run convention fixed by one negative element); all arrays over -3..3 up to length 4 + 5000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Maximum-Twin-Sum-Of-A-Linked-List |  | 6/9 | - / 22/30 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Mean-Variance |  | 4/4 |  |  | mean in [floor; ceil] of S/5 + population variance in [floor; ceil] of (5Q - S**2)/25; constant samples; all 3125 inputs (exhaustive) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Median-Filtering | agree (vs misc/Ada/Median-Filtering, 1000 cases) | 7/14 |  |  |  | ok | own tests, diff agree |
| misc/SPARK2/Ada-SPARK-Merge-In-Between-Linked-Lists |  | 3/6 | - / 19/26 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Merge-Intervals |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Middle-Of-The-Linked-List |  | 4/5 | - / 17/22 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan); own middle-node property for every length 1 .. 16 plus empty-list rejection | ok | own tests |
| misc/SPARK2/Ada-SPARK-Min-Cost-Climbing-Stairs |  | 1/1 |  |  | own path enumeration (end convention fixed by one input); all 729 arrays over 0..2 + 5000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Min-Stack |  | 7/10 | - / 26/30 |  | own array model with minimum on 2000 random runs plus full/empty rejection checks (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Minimum-Path-Sum |  | 15/15 |  |  | own path recursion; 6000 random grids | ok | own tests |
| misc/SPARK2/Ada-SPARK-Missing-Number |  | 5/5 |  |  | planted missing value; all 720 orders of every 5-of-6 choice (exhaustive) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Move-Zeroes |  | 3/3 |  |  | own stable compaction; all 243 arrays over 0..2 + 4000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-My-Linked-List-Stub |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-N-th-Tribonacci |  | 4/6 |  |  |  | ok | own tests |
| misc/SPARK2/Ada-SPARK-Next-Greater-Node-In-Linked-List |  | 2/3 | - / 8/9 |  | own backward scan for the nearest greater; 20000 random lists (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Non-Overlapping-Intervals |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Nth-Digit-Stub |  | 14/14 |  |  | own directly built digit string (first ~20000 positions) + own digit-block arithmetic for n=10^9 and 2^31 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Nth-Ugly-Number |  | 8/9 | - / 26/30 |  | own full 2/3/5 factor removal; Is_Ugly 1 .. 1000 and Compute 1 .. 32 (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Number-Of-1-Bits |  | 3/3 |  |  | own bit count; 0..2**16 (exhaustive) + 20000 random + powers of two and 2**K-1 | ok | own tests |
| misc/SPARK2/Ada-SPARK-PN-Counter |  | 6/6 |  |  | own model: value = sum P - sum N; merge = componentwise max; commutative/idempotent; 20000 random replica pairs (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Palindrome-Linked-List |  | 7/8 | - / 25/30 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Palindrome-Partitioning |  | 15/17 | - / 27/30 |  | own exhaustive search over palindromic cuts; all words of length 4 over 3 letters and N = 0 .. 4 (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Parity-Bits |  | 0/1 |  |  | own bit count; 0 .. 70000 + single bits/complements + 20000 random words (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Partition-Around-Pivot |  | 8/8 |  |  | own stable two-group reference; 50000 random arrays and pivots (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Partition-List |  | 11/14 | - / 29/30 |  | stable partition vs own two-filter reference; all lists of length 0..7 over {0,1,2} x pivots -1..3 + 3000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Pascal-Triangle |  | 1/1 |  |  | own Pascal rows built by additions; rows 0..30 (31-32 do not fit Result) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Pascal-Triangle-II |  | 4/6 |  |  |  | ok | own tests |
| misc/SPARK2/Ada-SPARK-Pow-X-N-Stub |  | 4/5 | - / 25/30 | exact powers incl. (-2)**31 = Integer'First |  | ok | kat |
| misc/SPARK2/Ada-SPARK-Power-Of-Three |  | 3/3 |  |  | own 64-bit power table; 1 .. 100000 + every power and neighbours + 20000 random (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Product-Of-Array-Except-Self |  | 2/2 |  |  | own direct products; all 6561 arrays (exhaustive) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Queue-Using-Stacks |  | no sites |  |  | own FIFO model on 500 random runs plus full/empty rejection checks (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Range-Sum-Query-Immutable |  | 1/1 |  |  | own direct sums; 500 random arrays x all 528 ranges | ok | own tests |
| misc/SPARK2/Ada-SPARK-Ravenscar-Job-Pool |  | 2/20 |  |  | Bounded_Buffer vs own FIFO model; 500 random runs of 100 operations (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Rectangle-Area |  | 1/1 |  |  | exhaustive width * height over the domain (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Remove-Linked-List-Elements |  | 5/11 | 7/7 / 25/30 |  | Append/Remove_First random sequences vs own array model (240000 states) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Remove-Nth-Node-From-End |  | 9/14 | - / 24/30 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Reorder-List |  | 10/14 | - / 22/30 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Reverse-Bits |  | 2/2 |  |  | own bit mirror + involution; all 256 bytes (exhaustive) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Reverse-Linked-List |  | 5/7 | - / 22/29 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Reverse-Linked-List-II |  | 7/7 |  |  | reverse First..Last vs own reference; every length 1..16 x every range (distinct + random values) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Robot-Return-To-Origin |  | 12/16 | - / 24/30 |  | own move counts (U = D and L = R); 20000 random walks (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Roman-To-Int |  | 19/19 |  |  | own encoder round trip; every value 1..3999 with a numeral of at most 7 letters | ok | own tests |
| misc/SPARK2/Ada-SPARK-Rotate-List |  | 7/8 | - / 29/30 |  | rotate right by K vs own index-formula reference; every length 1..16 x every K 0..16 (distinct + random values) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Smallest-Integer-Divisible-By-K |  | 3/4 |  |  |  | ok | own tests |
| misc/SPARK2/Ada-SPARK-Special-Array-With-X-Elements |  | 9/9 |  |  | own count of elements equal to X (folder convention); 20000 random arrays (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Sqrt-X |  | no sites |  |  | floor-root definition; every N in 0 .. 100 | ok | own tests |
| misc/SPARK2/Ada-SPARK-Sum-Of-Subarray-Minimums |  | 1/4 |  |  | own running-minimum reference; 5000 random arrays | ok | own tests |
| misc/SPARK2/Ada-SPARK-Swap-Nodes-In-Pairs |  | 11/13 | - / 27/30 |  | pairwise swap vs own reference; every length 0..16 (distinct + 50 random each) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Swapping-Nodes-In-A-Linked-List |  | 2/3 | - / 12/17 |  | own full-list check: Count'Last appends then one more must be rejected (silent no-op scan) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Tanimoto |  | 19/19 |  |  | own definition plus symmetry/range/self properties; all 4096 vector pairs (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Third-Maximum-Number |  | 14/16 |  |  | own distinct-value scan (arrays with >= 3 distinct values); 6000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-To-Lower-Case |  | 2/2 |  |  | own ASCII letter mapping over all 256 characters; 20000 random texts (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Top-K-Frequent-Words |  | 3/4 | - / 12/12 |  | order-statistic property on own counts; 20000 random arrays (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Trapping-Rain-Water |  | 5/12 |  |  | own per-column water (min of left and right maxima); 6000 random | ok | own tests |
| misc/SPARK2/Ada-SPARK-Trapping-Rain-Water-II-Lite |  | 4/11 | - / 16/30 |  | own min(left max; right max) reference; 5000 random arrays with junk past Length | ok | own tests |
| misc/SPARK2/Ada-SPARK-Triangle-Min-Path |  | 6/6 |  |  | own brute force over all 8 paths; 20000 random triangles with junk outside the triangle | ok | own tests |
| misc/SPARK2/Ada-SPARK-Tribonacci |  | 4/6 | - / 26/30 |  | own defining recursion; every N 0 .. 10 (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Tribonacci-Number |  | 4/6 |  |  |  | ok | own tests |
| misc/SPARK2/Ada-SPARK-Unique-Paths-II |  | 13/15 |  |  | own path recursion avoiding blocked cells; 3000 random grids | ok | own tests |
| misc/SPARK2/Ada-SPARK-Valid-IP-Address-Stub |  |  |  |  |  | weak |  |
| misc/SPARK2/Ada-SPARK-Valid-Parentheses |  | 17/17 |  |  | own stack check; all 46656 strings over ()[]{} (exhaustive) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Validate-Stack-Sequences |  | 12/14 | - / 29/30 |  | own search over all push/pop interleavings; 20000 random cases with distinct values (sample_30) | ok | own tests |
| misc/SPARK2/Ada-SPARK-Water-Bottles |  | 6/6 |  |  | own drink-and-trade simulation; every Full 0 .. 100 and Exchange 2 .. 10 (sample_30) | ok | own tests |
| misc/SPARK2/Pattern-132 |  | 4/7 | - / 21/26 |  | own prefix-minimum reference; 20000 random arrays (sample_30) | ok | own tests |
| misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm | agree (vs misc/Ada/Package-Merge-Algorithm, 1000 cases) | 11/18 |  |  |  | ok | diff agree |
| misc/SPARK4/Ada-SPARK-Selection-Algorithm | agree (vs misc/Ada/Selection-Algorithm, 1000 cases) | 7/10 |  |  |  | ok | diff agree |
| ml/Ada/Backpropagation |  | baseline stillborn |  |  | own Long_Float forward pass and central finite differences of every weight/bias; 400 random networks (sample_30) | ok | own tests |
| ml/SPARK2/Linear-Regression |  | 13/13 |  |  | own normal-equation least squares truncated once; 40000 random sets (sample_30) | ok | own tests |
| numerical/Ada/Binary-GCD | agree (vs numerical/SPARK4/Binary-Gcd, 1000 cases) |  |  |  |  | ok | diff agree |
| numerical/Ada/Cantor-Zassenhaus |  | 3/8 |  |  |  | ok |  |
| numerical/Ada/Euclidean-Algorithm | agree (vs numerical/SPARK4/Ada-SPARK-Euclidean-Algorithm, 1000 cases) |  |  |  |  | ok | diff agree |
| numerical/Ada/Extended-Euclidean-Algorithm | agree (vs numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm, 1000 cases) |  |  |  |  | ok | diff agree |
| numerical/Ada/Fermat-Primality-Test |  |  |  |  |  | weak |  |
| numerical/Ada/Hybrid-Monte-Carlo |  |  |  |  |  | weak |  |
| numerical/Ada/Mersenne-Twister | agree (vs numerical/SPARK4/Ada-SPARK-Mersenne-Twister, 1000 cases) |  |  |  |  | ok | diff agree |
| numerical/Ada/Sieve-Of-Eratosthenes | agree (vs numerical/SPARK2/Ada-SPARK-Sieve-Of-Eratosthenes, 1000 cases) |  |  |  |  | ok | diff agree |
| numerical/SPARK2/Ada-SPARK-Cooley-Tukey-FFT |  | 18/19 |  |  | own Long_Float DFT reference (tolerance 1.5 from the error analysis); every +-212 impulse + 20000 random inputs; spectra that do not fit Sample rejected (in tests.adb) | ok | own tests |
| numerical/SPARK2/Ada-SPARK-Count-Primes |  | no sites |  |  | own trial-division count of primes < N; exhaustive 0..30 | ok | own tests |
| numerical/SPARK2/Ada-SPARK-Count-Primes-Stub |  | 10/10 |  |  | own trial division for Is_Prime and Below; exhaustive 0..100 | ok | own tests |
| numerical/SPARK2/Ada-SPARK-Extended-Euclidean | agree (vs numerical/Ada/Extended-Euclidean-Algorithm, 1000 cases) | 1/1 |  |  | brute-force largest common divisor; all pairs 1..200 plus random (twin-only) | ok | own tests, diff agree |
| numerical/SPARK2/Ada-SPARK-Lagrange-Interpolation |  | 10/10 |  |  | interpolation property at the three samples; all 9261 sample triples (sample_30) | ok | own tests |
| numerical/SPARK2/Ada-SPARK-Minimum-Limit-Of-Balls-In-A-Bag |  | 3/3 |  |  | own linear scan over L with ceiling(B/L)-1 splits; 2000 random | ok | own tests |
| numerical/SPARK2/Ada-SPARK-Modular-Exponentiation |  | 4/4 |  |  | own repeated multiplication mod M; exhaustive 173417 | ok | own tests |
| numerical/SPARK2/Ada-SPARK-Newton-Raphson |  | 10/17 | - / 11/30 |  | integer square root property R*R <= N < (R+1)**2 over all 10000 inputs | ok | own tests |
| numerical/SPARK2/Ada-SPARK-Sieve-Of-Eratosthenes | agree (vs numerical/Ada/Sieve-Of-Eratosthenes, 1000 cases) | 5/5 |  |  | trial division for 1..Capacity (twin-only) | ok | own tests, diff agree |
| numerical/SPARK2/Ada-SPARK-Simpson-Rule |  | 2/2 |  |  | own composite Simpson weighted sum on [0;Steps]; exhaustive | ok | own tests |
| numerical/SPARK2/Ada-SPARK-Valid-Perfect-Square |  | no sites |  |  |  | ok |  |
| numerical/SPARK4/Ada-SPARK-Euclidean-Algorithm | agree (vs numerical/Ada/Euclidean-Algorithm, 1000 cases) | 17/19 |  |  |  | ok | diff agree |
| numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm | agree (vs numerical/Ada/Extended-Euclidean-Algorithm, 1000 cases) | 18/20 |  |  | brute-force gcd; Bezout identity in Long_Long_Integer; modular inverse by search; all pairs 0..60 plus random (twin-only) | ok | own tests, diff agree |
| numerical/SPARK4/Ada-SPARK-Mersenne-Twister | agree (vs numerical/Ada/Mersenne-Twister, 1000 cases) | 13/15 |  |  |  | ok | diff agree |
| numerical/SPARK4/Binary-Gcd | agree (vs numerical/Ada/Binary-GCD, 1000 cases) | 12/19 | - / 28/30 |  | gcd vs own repeated subtraction on 0..60^2; divisibility/common-factor/coprime-cofactor properties on large values (twin-only) | ok | own tests, diff agree |
| parsing/Ada/Cyk-Algorithm |  |  | 31/31 / 101/103 |  |  | weak |  |
| parsing/Ada/Recursive-Descent-Parser |  | 18/20 |  |  | random expression trees vs own tree evaluation; Is_Valid; 20000 expressions (sample_ada_30) | ok | own tests |
| searching/Ada/Binary-Search | agree (vs searching/SPARK4/Ada-SPARK-Binary-Search, 1000 cases) | 14/20 |  |  | Find/Find_First/Find_Last vs own linear scan; 20000 sorted arrays with duplicates (sample_ada_30) | ok | own tests, diff agree |
| searching/Ada/Breadth-First-Search |  | 14/18 |  |  | Shortest_Paths vs own unit-weight relaxation + Prev validity; 3000 digraphs (sample_ada_30) | ok | own tests |
| searching/Ada/Fibonacci-Search | agree (vs searching/SPARK4/Ada-SPARK-Fibonacci-Search, 1000 cases) |  |  |  |  | ok | diff agree |
| searching/Ada/Interpolation-Search | agree (vs searching/SPARK4/Ada-SPARK-Interpolation-Search, 1000 cases) |  |  |  |  | ok | diff agree |
| searching/Ada/Introselect | agree (vs searching/SPARK4/Ada-SPARK-Introselect, 1000 cases) |  |  |  |  | ok | diff agree |
| searching/Ada/Jump-Search | agree (vs searching/SPARK4/Ada-SPARK-Jump-Search, 1000 cases) |  |  |  |  | ok | diff agree |
| searching/Ada/Linear-Search | agree (vs searching/SPARK4/Ada-SPARK-Linear-Search, 1000 cases) |  |  |  |  | ok | diff agree |
| searching/Ada/Quickselect | agree (vs searching/SPARK4/Ada-SPARK-Quickselect, 1000 cases) |  |  |  |  | ok | diff agree |
| searching/Ada/Ternary-Search | agree (vs searching/SPARK4/Ada-SPARK-Ternary-Search, 1000 cases) |  |  |  |  | ok | diff agree |
| searching/Ada/Trigram-Search |  | 18/20 |  |  |  | ok | own tests |
| searching/SPARK2/Ada-SPARK-Design-Add-And-Search-Words |  | 10/13 |  |  | own wildcard matcher; 4000 random dictionaries; own full-dictionary check: Max_Words distinct words then one more must be rejected | ok | own tests |
| searching/SPARK2/Ada-SPARK-Exponential-Search |  | 12/17 |  |  | own linear-scan membership (index holds target or 0); 5000 random sorted | ok | own tests |
| searching/SPARK2/Ada-SPARK-Insert-Into-A-Binary-Search-Tree |  |  |  |  |  | weak |  |
| searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix |  | 10/11 |  |  | own linear-scan membership on row-major sorted matrices; 4000 random | ok | own tests |
| searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees-II-Lite |  |  |  |  |  | weak |  |
| searching/SPARK2/Ada-SPARK-Validate-Binary-Search-Tree |  | 14/19 |  |  | own all-pairs subtree check; 4000 random trees (valid; perturbed; shuffled) | ok | own tests |
| searching/SPARK2/Ada-SPARK-Word-Search-II-Lite |  | 7/7 |  |  | own left-to-right row scan; 5000 random boards | ok | own tests |
| searching/SPARK2/Bst-Insert-Search |  | 8/10 |  |  | own set reference; ascending/descending/zig-zag chains 1..31 keys; 6000 random sequences of any shape incl. repeated keys | ok | own tests |
| searching/SPARK4/Ada-SPARK-Binary-Search | agree (vs searching/Ada/Binary-Search, 1000 cases) | 17/20 | - / 25/30 |  | Find/Find_First/Find_Last vs own linear scan; 6000 random sorted arrays with duplicates (twin-only) | ok | own tests, diff agree |
| searching/SPARK4/Ada-SPARK-Fibonacci-Search | agree (vs searching/Ada/Fibonacci-Search, 1000 cases) | 10/18 |  |  |  | ok | diff agree |
| searching/SPARK4/Ada-SPARK-Interpolation-Search | agree (vs searching/Ada/Interpolation-Search, 1000 cases) | 10/16 |  |  |  | ok | diff agree |
| searching/SPARK4/Ada-SPARK-Introselect | agree (vs searching/Ada/Introselect, 1000 cases) | 6/14 |  |  |  | ok | diff agree |
| searching/SPARK4/Ada-SPARK-Jump-Search | agree (vs searching/Ada/Jump-Search, 1000 cases) | 12/18 |  |  |  | ok | diff agree |
| searching/SPARK4/Ada-SPARK-Linear-Search | agree (vs searching/Ada/Linear-Search, 1000 cases) | 5/5 |  |  | backward own scan for Find/Find_From/Contains; 8000 random arrays (twin-only) | ok | own tests, diff agree |
| searching/SPARK4/Ada-SPARK-Quickselect | agree (vs searching/Ada/Quickselect, 1000 cases) | 7/10 |  |  |  | ok | diff agree |
| searching/SPARK4/Ada-SPARK-Ternary-Search | agree (vs searching/Ada/Ternary-Search, 1000 cases) | 10/20 |  |  |  | ok | diff agree |
| sorting/Ada/Bead-Sort | agree (vs sorting/SPARK4/Bead-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Bitonic-Sorter | agree (vs sorting/SPARK4/Ada-SPARK-Bitonic-Sorter, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Bogosort | agree (vs sorting/SPARK4/Ada-SPARK-Bogosort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Bubble-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Bubble-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Bucket-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Bucket-Sort, 1000 cases) | 14/20 |  |  | order + own multiset match; 4000 random arrays (sample_ada_30) | ok | own tests, diff agree |
| sorting/Ada/Cocktail-Shaker-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Cocktail-Shaker-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Comb-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Comb-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Counting-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Counting-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Cycle-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Cycle-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Flashsort | agree (vs sorting/SPARK4/Ada-SPARK-Flashsort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Gnome-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Gnome-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Heapsort | agree (vs sorting/SPARK4/Ada-SPARK-Heapsort, 1000 cases) | 17/20 |  |  | Sort vs own insertion sort; Heapify heap property; Sift_Down Pre rejects out-of-range calls (contract gap) | ok | own tests, diff agree |
| sorting/Ada/Insertion-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Insertion-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Introsort | agree (vs sorting/SPARK4/Ada-SPARK-Introsort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Library-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Library-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Merge-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Merge-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Odd-Even-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Odd-Even-Sort, 1000 cases) | 12/20 |  |  | order + own multiset match; 4000 random arrays (sample_ada_30) | ok | own tests, diff agree |
| sorting/Ada/Pancake-Sorting | agree (vs sorting/SPARK4/Ada-SPARK-Pancake-Sorting, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Patience-Sorting | agree (vs sorting/SPARK4/Ada-SPARK-Patience-Sorting, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Pigeonhole-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Pigeonhole-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Postman-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Postman-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Quantum-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Quantum-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Quicksort | agree (vs sorting/SPARK4/Ada-SPARK-Quicksort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Radix-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Radix-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Samplesort | agree (vs sorting/SPARK4/Ada-SPARK-Samplesort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Selection-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Selection-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Shell-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Shell-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Slowsort | agree (vs sorting/SPARK4/Ada-SPARK-Slowsort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Smoothsort | agree (vs sorting/SPARK4/Ada-SPARK-Smoothsort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Spaghetti-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Spaghetti-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Stooge-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Stooge-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Strand-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Strand-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Timsort | agree (vs sorting/SPARK4/Ada-SPARK-Timsort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/Ada/Tree-Sort | agree (vs sorting/SPARK4/Ada-SPARK-Tree-Sort, 1000 cases) |  |  |  |  | ok | diff agree |
| sorting/SPARK2/Ada-SPARK-Bitonic-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Block-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Circle-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Cocktail-Sort |  | 8/9 | - / 30/30 |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Exchange-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Find-Median-Sorted-Arrays-Lite |  | 14/18 |  |  | own sorted-merge median (odd exact; even exact when integer mean; else between middles); every NA;NB | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array |  |  |  |  |  | weak |  |
| sorting/SPARK2/Ada-SPARK-Flash-Sort | agree (vs sorting/Ada/Flashsort, 1000 cases) | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests, diff agree |
| sorting/SPARK2/Ada-SPARK-Heap-Sort | agree (vs sorting/Ada/Heapsort, 1000 cases) | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests, diff agree |
| sorting/SPARK2/Ada-SPARK-Intro-Sort | agree (vs sorting/Ada/Introsort, 1000 cases) | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests, diff agree |
| sorting/SPARK2/Ada-SPARK-Median-Of-Two-Sorted-Arrays-Lite |  | 1/2 |  |  | own sorted-merge median (exact when integer mean; else between middles); 6000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Merge-K-Sorted-Lists-Stub |  | 0/1 |  |  | own insertion-sort reference; 3000 random three-run inputs | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Merge-Sorted-Array |  | 7/10 |  |  | own merge-prefix-sum reference; every Length; 6400 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Merge-Sorted-Arrays |  | 12/15 | - / 29/30 |  | own concatenate + insertion-sort reference; 5000 random sorted pairs | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Merge-Two-Sorted-Lists |  | 13/18 |  |  | own concatenate + insertion-sort reference; every split NA+NB<=16; own full-list check: Count'Last appends then one more must be rejected (silent no-op scan); own exact 8 + 8 merge (length and order) and 9 + 8 merge rejection | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Odd-Even-Linked-List |  | 11/14 | - / 29/30 |  | odd-then-even positions vs own reference; all lists of length 0..7 over {0,1,2} + 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Odd-Even-Merge-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Pancake-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Patience-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Quick-Sort | agree (vs sorting/Ada/Quicksort, 1000 cases) | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests, diff agree |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array-II |  | 15/16 |  |  | own keep-at-most-two reference; every Length; 6400 random sorted | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List |  | 8/9 |  |  | own unique reference; every length; 4800 random sorted | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List-II |  | 4/4 |  |  | own occurs-once reference (order kept); hand cases; 5000 random sorted/unsorted lists | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Shaker-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Smooth-Sort | agree (vs sorting/Ada/Smoothsort, 1000 cases) | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests, diff agree |
| sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity |  | 9/9 |  |  | evens before odds + permutation; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity-II |  | 3/3 |  |  | parity at every position + permutation; 3000 random 4-even/4-odd inputs; unbalanced inputs rejected (2003 cases) | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Sort-Characters-By-Frequency |  | 1/3 |  |  | non-increasing input frequency + permutation; 4000 random; equal characters grouped | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Sort-Colors |  | 8/11 |  |  | own insertion-sort reference on Data(1..Length); tail unchanged; every Length + 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Sort-List-Lite |  | 3/8 |  |  | own insertion-sort reference; every length 0..16; 4800 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Squares-Of-A-Sorted-Array |  | 6/8 | - / 28/30 |  | own square + insertion-sort reference on 3000+ sorted inputs; unsorted inputs rejected | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Tim-Sort | agree (vs sorting/Ada/Timsort, 1000 cases) | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests, diff agree |
| sorting/SPARK2/Ada-SPARK-Tim-Sort-Stub |  | 11/14 |  |  | bounds kept + own insertion-sort reference; lengths 0..40; extreme values; high bounds | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Tournament-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK2/Ada-SPARK-Wiggle-Sort |  | 17/19 | - / 30/30 |  | wiggle order on every adjacent pair + permutation; 4000 inputs | ok | own tests |
| sorting/SPARK2/Binary-Insertion-Sort |  | 8/9 |  |  | sorted + permutation + own insertion-sort reference; all 0/1 inputs; 3000 random | ok | own tests |
| sorting/SPARK4/Ada-SPARK-Bitonic-Sorter | agree (vs sorting/Ada/Bitonic-Sorter, 1000 cases) | 9/14 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Bogosort | agree (vs sorting/Ada/Bogosort, 1000 cases) | 9/16 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Bubble-Sort | agree (vs sorting/Ada/Bubble-Sort, 1000 cases) | 11/13 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Bucket-Sort | agree (vs sorting/Ada/Bucket-Sort, 1000 cases) | 11/17 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Cocktail-Shaker-Sort | agree (vs sorting/Ada/Cocktail-Shaker-Sort, 1000 cases) | 5/12 | - / 22/30 |  |  | ok | own tests, diff agree |
| sorting/SPARK4/Ada-SPARK-Comb-Sort | agree (vs sorting/Ada/Comb-Sort, 1000 cases) | 5/8 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Counting-Sort | agree (vs sorting/Ada/Counting-Sort, 1000 cases) | baseline timeout |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Cycle-Sort | agree (vs sorting/Ada/Cycle-Sort, 1000 cases) | 10/14 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Flashsort | agree (vs sorting/Ada/Flashsort, 1000 cases) | 6/16 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Gnome-Sort | agree (vs sorting/Ada/Gnome-Sort, 1000 cases) | 12/15 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Heapsort | agree (vs sorting/Ada/Heapsort, 1000 cases) | 13/19 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Insertion-Sort | agree (vs sorting/Ada/Insertion-Sort, 1000 cases) | 15/18 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Introsort | agree (vs sorting/Ada/Introsort, 1000 cases) | 10/11 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Library-Sort | agree (vs sorting/Ada/Library-Sort, 1000 cases) | 7/17 |  |  |  | ok | own tests, diff agree |
| sorting/SPARK4/Ada-SPARK-Merge-Sort | agree (vs sorting/Ada/Merge-Sort, 1000 cases) | 11/17 | - / 24/30 |  |  | ok | own tests, diff agree |
| sorting/SPARK4/Ada-SPARK-Odd-Even-Sort | agree (vs sorting/Ada/Odd-Even-Sort, 1000 cases) | 7/14 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Pancake-Sorting | agree (vs sorting/Ada/Pancake-Sorting, 1000 cases) | 9/13 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Patience-Sorting | agree (vs sorting/Ada/Patience-Sorting, 1000 cases) | 5/15 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Pigeonhole-Sort | agree (vs sorting/Ada/Pigeonhole-Sort, 1000 cases) | 8/16 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Postman-Sort | agree (vs sorting/Ada/Postman-Sort, 1000 cases) | 6/16 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Quantum-Sort | agree (vs sorting/Ada/Quantum-Sort, 1000 cases) | 11/17 | - / 19/30 |  |  | ok | own tests, diff agree |
| sorting/SPARK4/Ada-SPARK-Quicksort | agree (vs sorting/Ada/Quicksort, 1000 cases) | 12/13 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Radix-Sort | agree (vs sorting/Ada/Radix-Sort, 1000 cases) | 1/18 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Samplesort | agree (vs sorting/Ada/Samplesort, 1000 cases) | 11/19 | - / 25/30 |  |  | ok | own tests, diff agree |
| sorting/SPARK4/Ada-SPARK-Selection-Sort | agree (vs sorting/Ada/Selection-Sort, 1000 cases) | 11/15 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Shell-Sort | agree (vs sorting/Ada/Shell-Sort, 1000 cases) | 14/17 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Slowsort | agree (vs sorting/Ada/Slowsort, 1000 cases) | 7/12 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Smoothsort | agree (vs sorting/Ada/Smoothsort, 1000 cases) | 15/16 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Spaghetti-Sort | agree (vs sorting/Ada/Spaghetti-Sort, 1000 cases) | 5/10 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Stooge-Sort | agree (vs sorting/Ada/Stooge-Sort, 1000 cases) | 8/12 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Strand-Sort | agree (vs sorting/Ada/Strand-Sort, 1000 cases) | 5/15 |  |  |  | ok | diff agree |
| sorting/SPARK4/Ada-SPARK-Timsort | agree (vs sorting/Ada/Timsort, 1000 cases) | 12/16 | - / 25/30 |  |  | ok | own tests, diff agree |
| sorting/SPARK4/Ada-SPARK-Tree-Sort | agree (vs sorting/Ada/Tree-Sort, 1000 cases) | 13/16 |  |  |  | ok | diff agree |
| sorting/SPARK4/Bead-Sort | agree (vs sorting/Ada/Bead-Sort, 1000 cases) | 6/13 |  |  |  | ok | diff agree |
| strings/Ada/Boyer-Moore | agree (vs strings/SPARK2/Ada-SPARK-Boyer-Moore, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/Ada/Damerau-Levenshtein-Distance | agree (vs strings/SPARK2/Ada-SPARK-Damerau-Levenshtein-Distance, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/Ada/Hamming-Distance | agree (vs strings/SPARK2/Ada-SPARK-Hamming-Distance, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/Ada/Knuth-Morris-Pratt | agree (vs strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/Ada/Levenshtein-Distance | agree (vs strings/SPARK3/Levenshtein-Distance, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/Ada/Longest-Common-Subsequence | agree (vs strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/Ada/Rabin-Karp | agree (vs strings/SPARK2/Ada-SPARK-Rabin-Karp, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/Ada/String-Metrics |  | 18/20 |  |  |  | ok | own tests |
| strings/SPARK2/Ada-SPARK-Boyer-Moore | agree (vs strings/Ada/Boyer-Moore, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/SPARK2/Ada-SPARK-Count-The-Number-Of-Consistent-Strings |  | 7/7 |  |  | own count of symbols <= Allowed; exhaustive 32768 | ok | own tests |
| strings/SPARK2/Ada-SPARK-Damerau-Levenshtein-Distance | agree (vs strings/Ada/Damerau-Levenshtein-Distance, 1000 cases) | 14/17 |  |  |  | ok | diff agree |
| strings/SPARK2/Ada-SPARK-Edit-Distance |  | 16/16 |  |  | own recursive Levenshtein reference; every length pair; 3750 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Encode-And-Decode-Strings-Lite |  | no sites |  |  | round trip both ways + constant non-zero XOR key; all 256 bytes | ok | own tests |
| strings/SPARK2/Ada-SPARK-Find-All-Anagrams-In-A-String |  | 13/13 |  |  | own window count reference; 5000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Hamming-Distance | agree (vs strings/Ada/Hamming-Distance, 1000 cases) | 5/5 |  |  | exhaustive 64 pairs vs own position count (twin-only) | ok | own tests, diff agree |
| strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt | agree (vs strings/Ada/Knuth-Morris-Pratt, 1000 cases) | 9/11 |  |  |  | ok | diff agree |
| strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence | agree (vs strings/Ada/Longest-Common-Subsequence, 1000 cases) |  |  |  |  | ok | diff agree |
| strings/SPARK2/Ada-SPARK-Make-The-String-Great |  | 3/16 |  |  | own repeated leftmost-pair removal reference; 4000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Multiply-Strings-Stub |  | 18/18 |  |  | 2000 random pairs vs Long_Long_Integer + hand arithmetic + (10^30-1)^2 by algebra | ok | own tests |
| strings/SPARK2/Ada-SPARK-Number-Of-Lines-To-Write-String |  | 5/6 |  |  | own width-100 line-filling simulation; 4000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-One-Edit-Distance |  | 19/19 |  |  | own Levenshtein = 1 reference; random strings with 0-2 edits | ok | own tests |
| strings/SPARK2/Ada-SPARK-Rabin-Karp | agree (vs strings/Ada/Rabin-Karp, 1000 cases) | 8/11 |  |  |  | ok | diff agree |
| strings/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-In-String |  | 7/8 |  |  | own repeated leftmost-pair removal reference; 4000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Repeated-String-Match |  | 2/2 |  |  | own brute force (concatenate K copies + naive search); hand cases; 20000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Reverse-Vowels-Of-A-String |  | 5/5 |  |  | swap of positions 2 and 5; rest unchanged; 4000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String-III |  | 8/16 |  |  | own per-word reversal reference; 4000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Rotate-String |  | 7/7 |  |  | own every-shift reference; 4000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Sum-Of-Digits-Of-String-After-Convert |  | 3/3 |  |  | own digit sum via decimal image; exhaustive 0..9999 | ok | own tests |
| strings/SPARK2/Ada-SPARK-Total-Hamming-Distance |  | 3/3 |  |  | own bit-by-bit reference; single bits + 5000 random | ok | own tests |
| strings/SPARK2/Ada-SPARK-Z-Algorithm |  | 8/10 |  |  | own longest-common-prefix reference for I>=2; 5000 random | ok | own tests |
| strings/SPARK3/Levenshtein-Distance | agree (vs strings/Ada/Levenshtein-Distance, 1000 cases) |  |  |  |  | ok | diff agree |
| trees/SPARK2/Ada-SPARK-Balanced-Binary-Tree |  | 11/14 | - / 15/30 |  | own recursive height reference; hand cases incl. cycle; 20000 random trees | ok | own tests |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Inorder |  | 6/7 |  |  | own recursive subtree sum; 4000 random trees + empty | ok | own tests |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Level-Order |  | 13/17 |  |  | own recursive subtree sum; 4000 random trees + empty | ok | own tests |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Max-Depth |  | 12/19 |  |  | own recursive height (convention fixed by one-node tree); 4000 random trees | ok | own tests |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Min-Depth |  | 12/17 |  |  | own recursive min root-to-leaf depth (convention fixed by one-node tree); 4000 random trees | ok | own tests |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Postorder |  | 13/20 |  |  | own recursive subtree-sum reference; empty tree; 4000 random shapes | ok | own tests |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Preorder |  | 13/15 |  |  | own recursive subtree sum; 4000 random trees + empty | ok | own tests |
| trees/SPARK2/Ada-SPARK-Convert-BST-To-Greater-Tree |  | 1/1 |  |  | own sum of values >= each element for strictly increasing sequences; 4000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Count-Binary-Substrings |  | 8/19 |  |  | own all-substrings k-zeros/k-ones check; 4000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Diameter-Of-Binary-Tree |  | 9/19 |  |  | own recursive longest path (edges/nodes fixed by one-node tree); 4000 random trees | ok | own tests |
| trees/SPARK2/Ada-SPARK-Get-Equal-Substrings-Within-Budget |  | 11/15 |  |  | own all-windows cost check; 5000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Implement-Trie |  | 12/13 |  |  | own exact-membership reference; 4000 random word sets; own full-structure check: Max_Words distinct words then one more must be rejected | ok | own tests |
| trees/SPARK2/Ada-SPARK-Insert-Into-BST |  | 8/10 |  |  | own set reference + own reference BST shape (insertion order) + separate order check; 4000 random runs incl. duplicates | ok | own tests |
| trees/SPARK2/Ada-SPARK-Invert-Binary-Tree |  | no sites |  |  | children swapped at every node; 4000 random trees | ok | own tests |
| trees/SPARK2/Ada-SPARK-Longest-Common-Substring |  | 7/9 |  |  | own all-start-pairs reference; all string pairs up to length 4 over {a;b} and {a;b;c} (exhaustive) | ok | own tests |
| trees/SPARK2/Ada-SPARK-Longest-Palindromic-Substring |  | 12/12 |  |  | own all-substrings palindrome check; 5000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeat |  | 9/10 |  |  | own all-substrings distinctness check; 5000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeating |  | 10/10 |  |  | own all-substrings distinctness check; 5000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-BST |  | 7/8 |  |  | own parent-climbing LCA on generated BSTs; 4000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-Of-BST |  | 7/8 |  |  | own parent-climbing LCA on generated BSTs; 4000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-Binary-Tree |  | 13/20 |  |  | own recursive height (convention fixed by one-node tree); 4000 random trees | ok | own tests |
| trees/SPARK2/Ada-SPARK-Merge-Two-Binary-Trees |  | 4/9 |  |  | own overlay reference per heap position; result walked from its root; 4000 random pairs | ok | own tests |
| trees/SPARK2/Ada-SPARK-Minimum-Depth-Of-Binary-Tree |  | 15/20 |  |  | own recursive min root-to-leaf depth (convention fixed by one-node tree); 4000 random trees | ok | own tests |
| trees/SPARK2/Ada-SPARK-Minimum-Window-Substring |  | 7/7 |  |  | own all-windows A/B/C check; 5000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Number-Of-Substrings-Containing-All-Three-Characters |  | 7/7 |  |  | own all-substrings check; exhaustive 6561 | ok | own tests |
| trees/SPARK2/Ada-SPARK-Range-Sum-BST |  | 6/8 | - / 20/30 |  | own full-traversal reference; hand cases; 20000 random BSTs + ranges | ok | own tests |
| trees/SPARK2/Ada-SPARK-Range-Sum-Of-BST |  | 16/20 |  |  | own whole-tree range sum with odd bounds; 4000 random BSTs | ok | own tests |
| trees/SPARK2/Ada-SPARK-Same-Tree |  | 10/15 |  |  | own recursive comparison vs renumbered copies; 4000 pairs | ok | own tests |
| trees/SPARK2/Ada-SPARK-Subtree-Of-Another-Tree |  | 13/19 |  |  | own identical-subtree check (copied/absent patterns); 5000 random | ok | own tests |
| trees/SPARK2/Ada-SPARK-Symmetric-Tree |  | 10/15 |  |  | own mirror comparison; 4000 trees (half built symmetric) | ok | own tests |
| trees/SPARK2/Ada-SPARK-Unique-Paths-With-Obstacles |  | 9/9 |  |  | own recursive path enumeration; exhaustive 65536 grids | ok | own tests |

| Folder | Make | B14 | B12 | T14 | T12 | W14 | W12 | Silver | Checks (func) | Training-ready | Pair | Duplicate of |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| clustering/Ada/Average-Linkage-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/Canopy-Clustering | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |  |  |
| clustering/Ada/Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/Clustering-Algorithms | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| clustering/Ada/Complete-Linkage-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/DBSCAN | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/FLAME-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/Fuzzy-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/K-Means-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/K-Means-Plus-Plus | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| clustering/Ada/Lloyds-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/OPTICS | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/Single-Linkage-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/WACA-Clustering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/Ada/Wards-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| clustering/SPARK2/K-Means-Step | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| compression/Ada/Adaptive-Huffman | yes | yes | yes | yes | yes | 13 | 13 | no SPARK |  |  |  |  |
| compression/Ada/Arithmetic-Coding | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |  |  |
| compression/Ada/Audio-Compression | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| compression/Ada/Berlekamp-Massey-Algorithm | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |  |  |
| compression/Ada/Berlekamp-Root-Finding | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| compression/Ada/Burrows-Wheeler-Transform | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  | compression/SPARK2/Burrows-Wheeler-Transform |  |
| compression/Ada/Deflate | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |  |  |
| compression/Ada/Dynamic-Markov-Compression | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |  |  |
| compression/Ada/Earley-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| compression/Ada/Fast-Efficient-Lossless-Image-Compression-System | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |  |  |
| compression/Ada/Fractal-Compression | yes | yes | yes | yes | yes | 36 | 37 | no SPARK |  |  |  |  |
| compression/Ada/Huffmann-Coding | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| compression/Ada/Image-Compression | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |  |  |
| compression/Ada/LZ77-LZ78 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| compression/Ada/LZWL | yes | yes | yes | yes | yes | 35 | 35 | no SPARK |  |  |  |  |
| compression/Ada/LZX | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |  |  |
| compression/Ada/Peterson-Gorenstein-Zierler-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| compression/Ada/Run-Length-Encoding | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  | compression/SPARK2/Ada-SPARK-Run-Length-Encoding |  |
| compression/Ada/Speech-Compression | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |  |  |
| compression/Ada/Verlet-Integration | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |  |  |
| compression/Ada/Video-Compression | yes | yes | yes | yes | yes | 27 | 27 | no SPARK |  |  |  |  |
| compression/Ada/Wavelet-Compression | yes | yes | yes | yes | yes | 31 | 31 | no SPARK |  |  |  |  |
| compression/SPARK2/Ada-SPARK-Compress-String | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| compression/SPARK2/Ada-SPARK-Interleaving-String | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| compression/SPARK2/Ada-SPARK-LZ77 | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| compression/SPARK2/Ada-SPARK-Move-To-Front | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| compression/SPARK2/Ada-SPARK-Run-Length-Encoding | yes | yes | yes | yes | yes | 0 | 0 | proven | 14 (1) |  | compression/Ada/Run-Length-Encoding |  |
| compression/SPARK2/Ada-SPARK-String-Compression | yes | yes | yes | yes | yes | 0 | 0 | proven | 12 |  |  |  |
| compression/SPARK2/Burrows-Wheeler-Transform | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  | compression/Ada/Burrows-Wheeler-Transform |  |
| compression/SPARK3/Huffman-Coding | yes | yes | yes | yes | yes | 0 | 0 | proven | 16 (2) |  |  |  |
| concurrency/Ada/Dekker | no | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| concurrency/Ada/Lamport-Ordering | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |  |  |
| concurrency/Ada/Paxos-Algorithm | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| concurrency/Ada/Vector-Clocks | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |  |  |
| concurrency/Ada/lamport | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |  |  |
| concurrency/Ada/lds-scheduler | no | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| concurrency/Ada/mlfq | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| concurrency/Ada/peterson | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| concurrency/Ada/sjn | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| concurrency/SPARK2/Ada-SPARK-Course-Schedule-II (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| concurrency/SPARK2/Ada-SPARK-Course-Schedule-II-Stub (stub) | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 1 |  |  |  |
| concurrency/SPARK2/Ada-SPARK-Dekkers-Algorithm | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| concurrency/SPARK2/Ada-SPARK-Lamports-Bakery-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| concurrency/SPARK2/Ada-SPARK-Petersons-Algorithm | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| concurrency/SPARK2/Ada-SPARK-Task-Scheduler | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| concurrency/SPARK2/Ada-SPARK-Task-Scheduler-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven | 5 |  |  |  |
| concurrency/SPARK2/Course-Schedule | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| cryptography/Ada/Aes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Argon2 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Asymetric-Public-Key-Encryption | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/BLAKE | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Bcrypt | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Blowfish | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/ChaCha20 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Data-Encryption-Standard | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/ECDSA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Elliptic-Curve-Diffie-Hellman | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Fortuna | yes | yes | yes | yes | yes | 1 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/HMAC | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/IDEA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Lenstra-Elliptic-Curve-Factorization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/MD5 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | cryptography/SPARK2/Ada-SPARK-MD5 |  |
| cryptography/Ada/NTRUEncrypt | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| cryptography/Ada/RC4 | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| cryptography/Ada/RSA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/SHA3 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Shamirs-Secret-Sharing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Stochastic-Universal-Sampling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Symetric-Encryption | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Threefish | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Tiny-Encryption-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Twofish | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Universal-Coding | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |  |  |
| cryptography/Ada/Universal-Variable-Formulation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/WHIRLPOOL | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/Ada/Yarrow-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| cryptography/SPARK2/Ada-SPARK-Level-Order-Traversal-Stub (stub) | yes | yes | yes | yes | yes | 7 | 7 | proven | 21 |  |  |  |
| cryptography/SPARK2/Ada-SPARK-MD5 (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  | cryptography/Ada/MD5 |  |
| cryptography/SPARK2/Ada-SPARK-SHA-1 (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| cryptography/SPARK2/Bit-Reversal | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| geometry/Ada/Adaptive-Histogram-Equalization | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |  |  |
| geometry/Ada/Ambient-Occlusion | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Bresenhams-Line-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | 25 unproved |  |  |  |  |
| geometry/Ada/Canny-Edge-Detector | yes | yes | yes | yes | yes | 51 | 51 | no SPARK |  |  |  |  |
| geometry/Ada/Clipping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Closest-Pair-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Cohen-Sutherland | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Constructive-Solid-Geometry | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Convex-Hull-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Delaunay-Triangulation | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |  |  |
| geometry/Ada/Dithering | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| geometry/Ada/Fast-Clipping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Generalised-Hough-Transform | yes | no | no | yes | yes | 31 | 31 | no SPARK |  |  |  |  |
| geometry/Ada/Gift-Wrapping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Gouraud-Shading | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Grabcut | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| geometry/Ada/Graham-Scan | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Histogram-Equalization | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |  |  |
| geometry/Ada/Hough-Transform | yes | yes | yes | yes | yes | 46 | 46 | no SPARK |  |  |  |  |
| geometry/Ada/Isosurfaces | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Kirkpatrick-Seidel | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Liang-Barsky | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Line-Clipping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Line-Segment-Intersection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Marching-Cubes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Ordered-Dithering | yes | yes | yes | yes | yes | 20 | 20 | no SPARK |  |  |  |  |
| geometry/Ada/Phong-Shading | yes | yes | yes | yes | yes | 0 | 0 | timeout |  |  |  |  |
| geometry/Ada/Point-In-Polygon | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | geometry/SPARK2/Ada-SPARK-Point-In-Polygon |  |
| geometry/Ada/Polygon-Triangulation | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |  |  |
| geometry/Ada/Quasitriangulation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Quickhull | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Radiosity | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Ramer-Douglas-Peucker-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Ray-Tracing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Riemersma-Dithering | yes | yes | yes | yes | yes | 29 | 29 | no SPARK |  |  |  |  |
| geometry/Ada/Segmentation | yes | no | no | yes | yes | 45 | 45 | no SPARK |  |  |  |  |
| geometry/Ada/Shading | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| geometry/Ada/Slerp | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Sutherland-Hodgman | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Triangulation | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |  |  |
| geometry/Ada/Vatti | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Vincenty | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Voronoi-Diagrams | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Warnock-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Watershed-Transformation | yes | no | no | yes | yes | 52 | 52 | no SPARK |  |  |  |  |
| geometry/Ada/Weiler-Atherton | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/Ada/Xiaolin-Wus-Line-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| geometry/SPARK2/Ada-SPARK-Convex-Hull-Graham | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| geometry/SPARK2/Ada-SPARK-Point-In-Polygon | yes | yes | yes | yes | yes | 0 | 0 | proven | 22 |  | geometry/Ada/Point-In-Polygon |  |
| geometry/SPARK2/Closest-Pair-Brute | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| graphs/Ada/A-Star | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | graphs/SPARK4/A-Star |  |
| graphs/Ada/Bellman-Ford-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | graphs/SPARK2/Bellman-Ford-Algorithm |  |
| graphs/Ada/Boruvkas-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Cliques | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Coin-Graph | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Cryptographically-Secure-Pseudo-Random-Number-Generators | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Cryptographically-Secure-Pseudorandom-Number-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Dijkstra-Scholten-Algorithm | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| graphs/Ada/Dijkstras-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | graphs/SPARK4/Ada-SPARK-Dijkstras-Algorithm |  |
| graphs/Ada/Dinics-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Edmonds-Karp-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Elliptic-Curve-Cryptography | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Euclidean-Minimum-Spanning-Tree | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Floyd-Steinberg-Dithering | yes | yes | yes | yes | yes | 23 | 23 | no SPARK |  |  |  |  |
| graphs/Ada/Floyd-Warshall-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | graphs/SPARK2/Ada-SPARK-Floyd-Warshall |  |
| graphs/Ada/Floyds-Cycle-Finding-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | graphs/SPARK4/Ada-SPARK-Floyds-Cycle-Finding-Algorithm |  |
| graphs/Ada/Ford-Fulkerson-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Hungarian-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Hungarian-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Kosarajus-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Kruskals-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | graphs/SPARK2/Ada-SPARK-Kruskals-Algorithm |  |
| graphs/Ada/MaxCliqueDyn | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Minimum-Spanning-Tree | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/PageRank | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Post-Quantum-Cryptography | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Prims-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | graphs/SPARK2/Ada-SPARK-Prims-Algorithm |  |
| graphs/Ada/Shortest-Path-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Tarjans-Off-Line-Lowest-Common-Ancestors | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/Tarjans-Strongly-Connected-Components | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| graphs/Ada/subgraph-isomorphism | n/a | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  |  |  |
| graphs/SPARK2/Ada-SPARK-Bellman-Ford-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Clone-Graph | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Clone-Graph-Stub (stub) | yes | yes | yes | yes | yes | 5 | 5 | proven (trivial) | 1 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Dijkstra-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Find-Center-Of-Star-Graph | yes | yes | yes | yes | yes | 2 | 2 | proven | 4 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Find-If-Path-Exists-In-Graph | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Floyd-Warshall | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  | graphs/Ada/Floyd-Warshall-Algorithm |  |
| graphs/SPARK2/Ada-SPARK-Floyd-Warshall-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Is-Graph-Bipartite | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Kruskal-MST-Lite (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| graphs/SPARK2/Ada-SPARK-Kruskals-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | proven | 13 |  | graphs/Ada/Kruskals-Algorithm |  |
| graphs/SPARK2/Ada-SPARK-Number-Of-Islands-DFS | yes | yes | yes | yes | yes | 0 | 0 | proven | 87 (17) |  |  |  |
| graphs/SPARK2/Ada-SPARK-Prims-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  | graphs/Ada/Prims-Algorithm |  |
| graphs/SPARK2/Ada-SPARK-Shortest-Path-In-Binary-Matrix (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| graphs/SPARK2/Bellman-Ford-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  | graphs/Ada/Bellman-Ford-Algorithm |  |
| graphs/SPARK4/A-Star | yes | yes | yes | yes | yes | 0 | 0 | proven | 234 (7) |  | graphs/Ada/A-Star |  |
| graphs/SPARK4/Ada-SPARK-Dijkstras-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | 224 (6) |  | graphs/Ada/Dijkstras-Algorithm |  |
| graphs/SPARK4/Ada-SPARK-Floyds-Cycle-Finding-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | 183 (35) |  | graphs/Ada/Floyds-Cycle-Finding-Algorithm |  |
| hashing/Ada/Bloom-Filter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | hashing/SPARK2/Bloom-Filter |  |
| hashing/Ada/Geohash | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| hashing/Ada/Geometric-Hashing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| hashing/Ada/Hash-Functions | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |  |  |
| hashing/Ada/Hash-Join | yes | no | no | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| hashing/Ada/Locality-Sensitive-Hashing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| hashing/Ada/Pearson-Hashing | yes | yes | yes | yes | yes | 18 | 18 | no SPARK |  |  | hashing/SPARK2/Ada-SPARK-Pearson-Hashing |  |
| hashing/Ada/SipHash | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| hashing/Ada/Tiger-Hash | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| hashing/Ada/Zobrist-Hashing | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  | hashing/SPARK2/Ada-SPARK-Zobrist-Hashing |  |
| hashing/SPARK2/Ada-SPARK-Design-HashMap | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| hashing/SPARK2/Ada-SPARK-Design-HashMap-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| hashing/SPARK2/Ada-SPARK-Design-HashSet | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| hashing/SPARK2/Ada-SPARK-Design-HashSet-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| hashing/SPARK2/Ada-SPARK-FNV-Hash | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| hashing/SPARK2/Ada-SPARK-Pearson-Hashing | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  | hashing/Ada/Pearson-Hashing |  |
| hashing/SPARK2/Ada-SPARK-Zobrist-Hashing | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  | hashing/Ada/Zobrist-Hashing |  |
| hashing/SPARK2/Bloom-Filter | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  | hashing/Ada/Bloom-Filter |  |
| logic/Ada/Automated-Theorem-Proving | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| logic/Ada/Chaff | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| logic/Ada/Constraint-Satisfaction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| logic/Ada/DPLL | yes | yes | yes | yes | yes | 0 | 0 | proven | 56 (12) |  |  |  |
| logic/Ada/DPLL-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| logic/Ada/Davis-Putnam | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| logic/Ada/Verified-Unification-Engine | yes | yes | yes | yes | yes | 0 | 0 | proven | 176 (39) |  |  |  |
| matrices/Ada/Chain-Matrix-Multiplication | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| matrices/Ada/Eigenvalue-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| matrices/Ada/Gaussian-Elimination | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | matrices/SPARK2/Ada-SPARK-Gaussian-Elimination |  |
| matrices/Ada/Jacobi-Eigenvalue | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| matrices/Ada/Matrix-Multiplication | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| matrices/Ada/Quantum-Singular-Value-Transformation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| matrices/Ada/SMAWK | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| matrices/Ada/Schonhage-Strassen | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| matrices/Ada/Sparse-Matrix | yes | yes | yes | yes | yes | 0 | 8 | no SPARK |  |  |  |  |
| matrices/Ada/Strassen | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| matrices/Ada/Symbolic-Cholesky-Decomposition | yes | yes | yes | yes | yes | 24 | 24 | no SPARK |  |  |  |  |
| matrices/SPARK2/Ada-SPARK-Check-If-Matrix-Is-X-Matrix | yes | yes | yes | yes | yes | 10 | 10 | proven (trivial) | 1 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Gaussian-Elimination | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 (1) |  | matrices/Ada/Gaussian-Elimination |  |
| matrices/SPARK2/Ada-SPARK-Lucky-Numbers-In-A-Matrix | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Matrix-Cells-In-Distance-Order | yes | yes | yes | yes | yes | 0 | 0 | proven | 18 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Matrix-Chain-Multiplication | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 1 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Matrix-Diagonal-Sum | yes | yes | yes | yes | yes | 6 | 6 | proven (trivial) | 3 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Matrix-Multiply | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Num-Matrix-Block-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Reshape-The-Matrix | yes | yes | yes | yes | yes | 11 | 11 | proven (trivial) | 1 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Set-Matrix-Zeroes | yes | yes | yes | yes | yes | 10 | 10 | proven (trivial) | 0 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Spiral-Matrix | yes | yes | yes | yes | yes | 6 | 6 | proven (trivial) | 2 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Spiral-Matrix-II | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| matrices/SPARK2/Ada-SPARK-The-K-Weakest-Rows-In-A-Matrix | yes | yes | yes | yes | yes | 5 | 5 | proven (trivial) | 2 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Toeplitz-Matrix | yes | yes | yes | yes | yes | 12 | 12 | proven (trivial) | 1 |  |  |  |
| matrices/SPARK2/Ada-SPARK-Transpose-Matrix | yes | yes | yes | yes | yes | 10 | 10 | proven (trivial) | 1 |  |  |  |
| matrices/SPARK2/Matrix-01 | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/Ada/A-Law-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/AC-3 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/ACORN-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK4/Acorn-Generator |  |
| misc/Ada/Adaptive-Additive-Algorithm | yes | yes | yes | yes | yes | 37 | 37 | no SPARK |  |  |  |  |
| misc/Ada/Addition-Chain-Exponentiation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Adler-32 | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Adler32 |  |
| misc/Ada/Aharonov-Jones-Landau-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Algorithm-X | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Algorithms-For-Calculating-Variance | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Alpha-Beta-Pruning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Alpha-Max-Plus-Beta-Min | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Amplitude-Amplification | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Ant-Colony-Optimization | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Approximate-Counting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Apriori-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Association-Rule-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Automated-Planning-And-Scheduling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Automatic-Train-Operation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/B-Star | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/BCH-Codes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/BCJR-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/BHT-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/BLAST | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Baby-Step-Giant-Step | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Backtracking | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Backward-Euler | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Backward-Induction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Baillie-PSW | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bankers-Algorithm | yes | yes | yes | yes | yes | 188 | 188 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Bankers-Algorithm |  |
| misc/Ada/Banzhaf-Power-Index | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Barnes-Hut | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Baum-Welch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bayesian-Nash-Equilibrium | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bayesian-Statistics | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Beam-Tracing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bees-Algorithm | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Beginner-Embedded-API | yes | yes | yes | yes | yes | 0 | 0 | proven | 26 (7) |  |  |  |
| misc/Ada/Bensons-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bentley-Ottmann | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Berkeley-Algorithm | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |  |  |
| misc/Ada/Bernstein-Varizani-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Best-Bin-First | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Binary-Space-Partitioning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Binary-Splitting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Birkhoff-von-Neumann | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bitap-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Black-Scholes-Model | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| misc/Ada/Blind-Deconvolution | yes | yes | yes | yes | yes | 52 | 52 | no SPARK |  |  |  |  |
| misc/Ada/Block-Nested-Loop | yes | yes | yes | yes | yes | 14 | 14 | no SPARK |  |  |  |  |
| misc/Ada/Block-Truncation-Coding | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Blossom-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Blum-Blum-Shub | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK4/Ada-SPARK-Blum-Blum-Shub |  |
| misc/Ada/Booth-Multiplication | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bootstrap-Aggregating | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Boson-Sampling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Boundary-Representation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bowyer-Watson | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |  |  |
| misc/Ada/Branch-and-Bound | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Branch-and-Cut | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bron-Kerbosch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Buchbergers-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Buddy-Memory-Allocation | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Buddy-Memory-Allocation |  |
| misc/Ada/Buechi-Automaton | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Bully-Algorithm | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |  |  |
| misc/Ada/Buzens-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/C4.5-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/CHS-Conversion | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Cannons-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Chaitins-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Chandra-Toueg | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Chans-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Chase | yes | yes | yes | yes | yes | 60 | 60 | no SPARK |  |  |  |  |
| misc/Ada/Cheneys-Algorithm | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |  |  |
| misc/Ada/Chews-Second-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Chinese-Whispers | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Christofides-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Code-Excited-Linear-Prediction | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |  |  |
| misc/Ada/Collision-Detection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Coloring-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Combinatorial-Auction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Combinatorial-Optimization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Communications-Based-Train-Control | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Computation-Of-Pi | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Computer-Vision | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Computus | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Cone-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Cone-Tracing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Conflict-Driven-Clause-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Congruence-Of-Squares | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Connected-Component-Labeling | yes | yes | yes | yes | yes | 39 | 39 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Connected-Component-Labeling |  |
| misc/Ada/Constraint-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Contour-Lines | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Coppersmith-Winograd | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Core | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Corporate-Wars-Sim | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Correlated-Equilibrium | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Crank-Nicolson | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Cristians-Algorithm | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |  |  |
| misc/Ada/Cross-Entropy-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Cuthill-McKee | yes | yes | yes | yes | yes | 0 | 7 | no SPARK |  |  |  |  |
| misc/Ada/Cutting-Plane-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Cyclic-Redundancy-Check | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Cyrus-Beck | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/D-Star | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/DDA-Line-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/DSA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Damm-Algorithm | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |  |  |
| misc/Ada/Dancing-Links | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Dantzig-Wolfe-Decomposition | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Darwin-Godel-Machine | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Data-Flow-Analysis | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/De-Boor | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/De-Casteljau | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Delayed-Column-Generation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Delivery-Mission-FSM | no | no | no | no | no | 0 | 0 | proven | 9 (1) |  |  |  |
| misc/Ada/Delivery-Safety-Supervisor | no | no | no | no | no | 0 | 0 | 8 unproved |  |  |  |  |
| misc/Ada/Delta-Encoding | yes | yes | yes | yes | yes | 21 | 21 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Delta-Encoding |  |
| misc/Ada/Demon-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Description-Logic | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |  |  |
| misc/Ada/Deutsch-Josza-Algorithm | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| misc/Ada/Dice-Coefficient | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Dice-Coefficient |  |
| misc/Ada/Dictionary-Coder | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Difference-Map | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Differential-Evolution | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Diffie-Hellman-Key-Exchange | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Discrete-Event-Simulation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Discrete-Fourier-Transformation | yes | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  |  |  |
| misc/Ada/Discrete-Logarithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Division-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Doomsday | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Double-Dabble | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| misc/Ada/Dynamic-Programming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Dynamic-Time-Warping | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/EIGamal | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/ESC-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Eclat-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/EdDSA | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Edmonds-Algorithm | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Elevator-Algorithm | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Elevator-Algorithm |  |
| misc/Ada/Elias-Delta-Coding | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |  |  |
| misc/Ada/Elias-Gamma-Coding | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Elias-Omega-Coding | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |  |  |
| misc/Ada/Ellipsoid-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Elser-Difference-Map-Algorithm | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| misc/Ada/Entropy-Coding | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Entropy-Coding-With-Known-Entropy-Characteristics | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |  |  |
| misc/Ada/Error-Diffusion | yes | yes | yes | yes | yes | 19 | 19 | no SPARK |  |  |  |  |
| misc/Ada/Espresso-Heuristic-Logic-Minimizer | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Estimation-Theory | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Euclidean-Distance-Transform | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Euler-Integration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Evolution-Strategy | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Evolutionary-Computation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Exact-Cover | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Exponential-Backoff | yes | yes | yes | yes | yes | 67 | 67 | no SPARK |  |  |  |  |
| misc/Ada/Exponential-Golomb-Coding | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |  |  |
| misc/Ada/Exponentiating-By-Squaring | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/FP-Growth-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/False-Nearest-Neighbor | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/False-Position-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Fast-Cosine-Transform-Algorithms | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Fast-Folding-Algorithm | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |  |  |
| misc/Ada/Fast-Multipole-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Faugere-F4 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Featherstone | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Feature-Detection | yes | yes | yes | yes | yes | 10 | 10 | no SPARK |  |  |  |  |
| misc/Ada/Fermat-Factorization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Fibonacci-Coding | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |  |  |
| misc/Ada/Fictitious-Play | yes | yes | yes | yes | yes | 38 | 38 | no SPARK |  |  |  |  |
| misc/Ada/Filtered-Back-Projection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Financial-Information-Exchange | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Financial-Risk-Modeling | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| misc/Ada/Finite-Difference-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/First-Order-Logic | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Fisher-Yates-Shuffle | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle |  |
| misc/Ada/Fitness-Proportionate-Selection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Fletchers-Checksum | yes | yes | yes | yes | yes | 13 | 13 | no SPARK |  |  |  |  |
| misc/Ada/Flood-Fill | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Flood-Fill |  |
| misc/Ada/Flow-Networks | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Force-Based-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Fortunes-Algorithm | yes | yes | yes | yes | yes | 18 | 18 | no SPARK |  |  |  |  |
| misc/Ada/Forward-Error-Correction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Foundations-Curriculum | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Fowler-Noll-Vo | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Frank-Wolfe-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Freivalds | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Fuzzy-C-Means | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/GNAT-Studio-Notes | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 (1) |  |  |  |
| misc/Ada/GPU-Work-Queue | yes | yes | yes | yes | yes | 0 | 0 | proven | 28 (7) |  |  |  |
| misc/Ada/GRASP | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Gale-Shapley-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Gauss-Jordan | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Gauss-Seidel | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Gene-Expression-Programming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/General-Problem-Solver | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Generational-Garbage-Collector | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| misc/Ada/Genetic-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Gerchberg-Saxton-Algorithm | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  |  |  |
| misc/Ada/Gibbs-Sampling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Gilbert-Johnson-Keerthi | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Glauber-Dynamics | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Global-Illumination | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Goertzel-Algorithm | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |  |  |
| misc/Ada/Goldschmidt-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Golomb-Coding | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Gospers-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Gram-Schmidt | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Gray-Code | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Gray-Code |  |
| misc/Ada/Ground-State | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Grovers-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |  |  |
| misc/Ada/GrowCut | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| misc/Ada/HHL-Algorithm | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |  |  |
| misc/Ada/Hadamard-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hadamard-Transform | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Half-Toning | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |  |  |
| misc/Ada/Halleys-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hamiltonian-Simulation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hamming-7-4 | yes | yes | yes | yes | yes | 37 | 37 | no SPARK |  |  |  |  |
| misc/Ada/Hamming-Code | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Hamming-Code |  |
| misc/Ada/Hamming-Weight | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Hamming-Weight |  |
| misc/Ada/Heaps-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK4/Ada-SPARK-Heaps-Algorithm |  |
| misc/Ada/Hidden-Linear-Function-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hidden-Shift-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hidden-Subgroup-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hidden-Surface-Removal | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hindley-Milner-Type-Inference-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hindley-Milner-Type-System | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hirschbergs-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hopcroft-Karp-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hopcrofts-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Hopfield-Net | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Huangs-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |  |  |
| misc/Ada/Hybrid-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/ID3-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/ITP-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Image-Based-Lighting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Incremental-Encoding | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Index-Calculus | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Inside-Out-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Integer-Factorization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Integer-Linear-Programming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Intersection-Algorithm | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Inverse-Iteration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Johnsons-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Jump-And-Walk | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/K-Nearest-Neighbours | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/K-Way-Merge | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK4/Ada-SPARK-K-Way-Merge |  |
| misc/Ada/Kabsch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Kadanes-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Kadanes-Algorithm |  |
| misc/Ada/Kahan-Summation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Kalman-Filter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Kargers-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Karmarkars-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Karn-Algorithm | yes | yes | yes | yes | yes | 37 | 37 | no SPARK |  |  |  |  |
| misc/Ada/Key-Derivation-Function | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Key-Exchange | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Knuth-Bendix-Completion | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/Ada/Krauss-Matching-Wildcards | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Lagged-Fibonacci-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK4/Ada-SPARK-Lagged-Fibonacci-Generator |  |
| misc/Ada/Laplacian-Smoothing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Lax-Wendroff | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Lemke-Howson | yes | yes | yes | yes | yes | 95 | 95 | no SPARK |  |  | misc/SPARK4/Ada-SPARK-Lemke-Howson |  |
| misc/Ada/Lempel-Ziv-Jeff-Bonwick | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Lempel-Ziv-Markov-Chain-Algorithm | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |  |  |
| misc/Ada/Lempel-Ziv-Oberhurmer | yes | yes | yes | yes | yes | 23 | 23 | no SPARK |  |  |  |  |
| misc/Ada/Lempel-Ziv-Ross-Williams | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  |  |  |
| misc/Ada/Lempel-Ziv-Stac | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| misc/Ada/Lempel-Ziv-Storer-Szymanski | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| misc/Ada/Lempel-Ziv-Welch | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |  |  |
| misc/Ada/Lenstra-Lenstra-Lovasz | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Lesk | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Level-Set-Method | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |  |  |
| misc/Ada/Levinson-Recursion | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Lexical-Analysis | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Linde-Buzo-Gray | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Linde-Buzo-Gray-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Line-Drawing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Linear-Feedback-Shift-Register | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Linear-Multistep-Methods | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Linear-Predictive-Coding | yes | yes | yes | yes | yes | 26 | 26 | no SPARK |  |  |  |  |
| misc/Ada/Linear-Programming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/List-Scheduling | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Locomotion-Mode-Interlock | no | no | no | no | no | 0 | 0 | proven | 15 (1) |  |  |  |
| misc/Ada/Long-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Longest-Increasing-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence |  |
| misc/Ada/Longest-Path-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Longitudinal-Redundacy-Check | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |  |  |
| misc/Ada/Luhn-Algorithm | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Luhn-Mod-N-Algorithm | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Luleas-Algorithm | no | no | no | no | no | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Maekawas-Algorithm | no | yes | yes | no | no | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Manning-Criteria | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Marching-Squares | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Marching-Tetrahedrons | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Marching-Triangles | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Mark-Compact-Algorithm | yes | yes | yes | yes | yes | 11 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Mark-and-Sweep | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Mark-And-Sweep |  |
| misc/Ada/Marr-Hildreth-Algorithm | yes | yes | yes | yes | yes | 59 | 59 | no SPARK |  |  |  |  |
| misc/Ada/Marzullos-Algorithm | yes | yes | yes | yes | yes | 24 | 24 | no SPARK |  |  |  |  |
| misc/Ada/Match-Rating-Approach | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Matching-Wildcards | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Maximum-Parsimony | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Mechanistic-Interpretability | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Median-Filtering | yes | yes | yes | yes | yes | 51 | 51 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Median-Filtering |  |
| misc/Ada/Memetic-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Memory-Channel-Model | yes | yes | yes | yes | yes | 0 | 0 | proven | 32 (9) |  |  |  |
| misc/Ada/Message-Authentication-Codes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Midpoint-Circle-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Min-Conflicts | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Minimax | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Minimum-Bounding-Box | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Minimum-Degree | yes | yes | yes | yes | yes | 0 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Mirror-Descent | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Modular-Square-Root | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Montgomery-Reduction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Moores-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Mu-Law-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Mullers-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Multigrid-Methods | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Multiplication-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Multiplicative-Inverse-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Multiplicative-Weight-Update-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Multivariate-Division-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/N-Body-Problems | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/NEF-Adaptive-OSC | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/NEF-Neurorobotics-Core | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Nagles-Algorithm | yes | yes | yes | yes | yes | 14 | 14 | no SPARK |  |  |  |  |
| misc/Ada/Naimi-Trehel | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Nearest-Neighbor-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Nelder-Mead | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Nested-Loop-Join | yes | no | no | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Nested-Sampling | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Nesting-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Newton-Multiplicative-Inverse | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Newtons-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Newtons-Method-in-Optimization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Nicholl-Lee-Nicholl | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Non-Local-Quantum-Computation | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Non-Restoring-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Nonblocking-Minimal-Spanning-Switch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Nonlinear-Optimization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Nth-Root | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Nucleolus | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Odds-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Odlyzko-Schonhage | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/One-Attribute-Rule | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Operations-Research | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Orbital-Mechanics | yes | yes | yes | yes | yes | 0 | 0 | timeout |  |  |  |  |
| misc/Ada/Ordered-Subset-EM | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/PBKDF2 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/PCIe-Transfer-Model | yes | yes | yes | yes | yes | 0 | 1 | proven | 60 (4) |  |  |  |
| misc/Ada/Package-Merge-Algorithm | yes | yes | yes | yes | yes | 30 | 30 | no SPARK |  |  | misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm |  |
| misc/Ada/Painters-Algorithm | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  |  |  |
| misc/Ada/Parity-Bit | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |  |  |
| misc/Ada/Partial-Differential-Equation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Particle-Swarm | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Path-Based-Strong-Component | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Path-Tracing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Petricks-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Phonetic-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Photon-Mapping | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| misc/Ada/Planning-Domain-Definition-Language | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Pohlig-Hellman | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Point-Set-Registration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Poly1305 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Polynomial-Long-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Power-Iteration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Powerset-Construction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Prediction-By-Partial-Matching | yes | yes | yes | yes | yes | 23 | 23 | no SPARK |  |  |  |  |
| misc/Ada/Program-Synthesis | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Progressive-Jackpot | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Proof-Of-Work-Algorithms | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |  |  |
| misc/Ada/Prufer-Coding | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Pseudorandom-Number-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Pulmonary-Embolism-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Push-Relabel-Algorithm | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |  |  |
| misc/Ada/QR-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Quantum-Annealing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Quantum-Artificial-Life | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Quantum-Counting-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Quantum-Fourier-Transform | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Quantum-Optimization-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Quantum-Phase-Estimation-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Queuing-Theory | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Quine-McCluskey-Algorithm | yes | yes | yes | yes | yes | 25 | 25 | no SPARK |  |  |  |  |
| misc/Ada/RANSAC | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| misc/Ada/RIPEMD-160 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Radial-Basis-Function-Network | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Rainflow-Counting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Random-Restart-Hill-Climbing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Random-Walker | yes | yes | yes | yes | yes | 54 | 54 | no SPARK |  |  |  |  |
| misc/Ada/Range-Encoding | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |  |  |
| misc/Ada/Rayleigh-Quotient-Iteration | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Rayleigh-Ritz-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Raymonds-Algorithm | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Recovery-Exploiting-Semantics | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |  |  |
| misc/Ada/Redundancy-Checks | yes | yes | yes | yes | yes | 10 | 10 | no SPARK |  |  |  |  |
| misc/Ada/Reed-Solomon-Error-Correction | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Reference-Counting | yes | yes | yes | yes | yes | 45 | 45 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Reference-Counting |  |
| misc/Ada/Region-Growing | yes | yes | yes | yes | yes | 34 | 34 | no SPARK |  |  |  |  |
| misc/Ada/Regret-Minimization | yes | yes | yes | yes | yes | 33 | 33 | no SPARK |  |  |  |  |
| misc/Ada/Relevance-Vector-Machine | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Replicator-Equation | yes | yes | yes | yes | yes | 52 | 52 | no SPARK |  |  |  |  |
| misc/Ada/Restoring-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Rete-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Reverse-Delete-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Ricart-Agrawala-Algorithm | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |  |  |
| misc/Ada/Rice-Coding | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Richardson-Lucy-Deconvolution | yes | yes | yes | yes | yes | 40 | 40 | no SPARK |  |  |  |  |
| misc/Ada/Ridders-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Risch-Algorithm | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Rotating-Calipers | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Rounding-Functions | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Rupperts-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Ruzzo-Tompa | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/SEQUITUR-Algorithm | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |  |  |
| misc/Ada/SRT-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/SSS-Star | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/SUBCLU | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Salsa20 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Scale-Invariant-Feature-Transform | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Scanline-Rendering | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Schensted | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Schreier-Sims | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Scoring-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Seam-Carving | yes | yes | yes | yes | yes | 19 | 19 | no SPARK |  |  |  |  |
| misc/Ada/Secret-Sharing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Selection-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | misc/SPARK4/Ada-SPARK-Selection-Algorithm |  |
| misc/Ada/Self-Organizing-Map | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Semi-Space-Collectors | yes | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  |  |  |
| misc/Ada/Sethi-Ullman-Algorithm | yes | no | no | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Shannon-Fano-Coding | yes | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  |  |  |
| misc/Ada/Shannon-Fano-Elias-Coding | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |  |  |
| misc/Ada/Shapley-Value | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Shoelace-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Shors-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Shortest-Common-Supersequence-Problem | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |  |  |
| misc/Ada/Simons-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Simulated-Annealing | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Sinkhorn-Knopp-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Slot-Machine | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |  |  |
| misc/Ada/Spectral-Layout | yes | yes | yes | yes | yes | 23 | 23 | no SPARK |  |  |  |  |
| misc/Ada/Speeded-Up-Robust-Features | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Spigot-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Square-Root-Algorithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/State-Action-Reward-State-Action | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Steinhaus-Johnson-Trotter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Stochastic-Tunneling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Stones-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Strongly-Connected-Components | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Structured-SVM | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Subset-Sum-Algorithm | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  |  |  |
| misc/Ada/Successive-Over-Relaxation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Sukhotin | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Summed-Area-Table | yes | yes | yes | yes | yes | 14 | 14 | no SPARK |  |  |  |  |
| misc/Ada/Supervised-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Swap-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Swarm-Intelligence | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Sweep-And-Prune | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/System-of-Linear-Equations | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Tarski-Kuratowski-Algorithm | yes | yes | yes | yes | yes | 15 | 15 | no SPARK |  |  |  |  |
| misc/Ada/Temporal-Difference-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Term-Rewriting | yes | yes | yes | yes | yes | 2 | 1 | no SPARK |  |  |  |  |
| misc/Ada/Texas-Medication-Algorithm-Project | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  |  |  |
| misc/Ada/Thomas-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Todd-Coxeter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Tomasulo-Algorithm | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |  |  |
| misc/Ada/Toom-Cook | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Top-Nodes-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | no SPARK |  |  | misc/SPARK2/Ada-SPARK-Top-Nodes-Algorithm |  |
| misc/Ada/Top-Trading-Cycle | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Traffic-Light-Controller | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Traffic-Simulation | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| misc/Ada/Transform-Coding | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |  |  |
| misc/Ada/Transitive-Closure | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Trapezoidal-Rule-DE | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Travelling-Salesman-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Trial-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Truncated-Binary-Encoding | yes | yes | yes | yes | yes | 8 | 8 | no SPARK |  |  |  |  |
| misc/Ada/Truncated-Binary-Exponential-Backoff | yes | yes | yes | yes | yes | 61 | 61 | no SPARK |  |  |  |  |
| misc/Ada/Truncation-Selection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/TrustRank | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/TurboQuant | yes | yes | yes | yes | yes | 61 | 61 | no SPARK |  |  |  |  |
| misc/Ada/Ukkonens-Algorithm | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |  |  |
| misc/Ada/Unary-Coding | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |  |  |
| misc/Ada/Unicode-Collation-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Unrestricted-Algorithm | yes | yes | yes | yes | yes | 32 | 32 | no SPARK |  |  |  |  |
| misc/Ada/VEGAS-Algorithm | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |  |  |
| misc/Ada/Variational-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Variational-Quantum-Eigensolver | yes | yes | yes | yes | yes | 19 | 19 | no SPARK |  |  |  |  |
| misc/Ada/Vector-Quantization | yes | yes | yes | yes | yes | 69 | 69 | no SPARK |  |  |  |  |
| misc/Ada/Vehicle-Routing-Problem | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Velvet | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Verhoeff-Algorithm | yes | yes | yes | yes | yes | 21 | 21 | no SPARK |  |  |  |  |
| misc/Ada/Vickrey-Clarke-Groves-Mechanism | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Wang-Landau | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Warnsdorffs-Rule | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| misc/Ada/Warped-Linear-Predictive-Coding | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  |  |  |
| misc/Ada/Xor-Swap-Algorithm | yes | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/Yamartino-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Zellers-Congruence-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Zero-Attribute-Rule | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/Zhu-Takaoka | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/arc-cache | yes | yes | yes | yes | yes | 9 | 9 | no SPARK |  |  |  |  |
| misc/Ada/clock-replacement | no | no | no | no | no | 0 | 0 | no SPARK |  |  |  | misc/Ada/Adaptive-Additive-Algorithm (identical) |
| misc/Ada/docs | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/earliest-deadline | no | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/fair-share | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| misc/Ada/page-replacement-algorithms | no | yes | yes | yes | yes | 12 | 12 | no SPARK |  |  |  |  |
| misc/Ada/rate-monotonic | yes | yes | yes | yes | yes | 16 | 16 | no SPARK |  |  |  |  |
| misc/Ada/round-robin | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/scripts | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| misc/Ada/srt-simulation | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| misc/SPARK2/Ada-SPARK-3Sum-Closest | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-4Sum-II | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Accounts-Merge-Lite | yes | yes | yes | yes | yes | 3 | 3 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Accounts-Merge-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Add-Binary | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Add-Digits | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Add-Two-Numbers | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Add-Two-Numbers-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Add-Without-Plus | yes | yes | yes | yes | yes | 0 | 0 | proven | 17 |  |  |  |
| misc/SPARK2/Ada-SPARK-Adler32 | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  | misc/Ada/Adler-32 |  |
| misc/SPARK2/Ada-SPARK-Alert-Using-Same-Key-Card-Stub (stub) | yes | yes | yes | yes | yes | 5 | 7 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Alien-Dictionary-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Alien-Dictionary-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-All-Paths-From-Source-To-Target | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Argmax | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Arranging-Coins | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Array-Partition-I | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-As-Far-From-Land-As-Possible | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Assign-Cookies (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Asteroid-Collision | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Authentication-Manager-Stub (stub) | yes | yes | yes | yes | yes | 2 | 3 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Available-Captures-For-Rook | yes | yes | yes | yes | yes | 5 | 5 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bankers-Algorithm | yes | yes | yes | yes | yes | 11 | 11 | proven | 8 (2) |  | misc/Ada/Bankers-Algorithm |  |
| misc/SPARK2/Ada-SPARK-Base64-Decode | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Base64-Encode | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Baseball-Game | yes | yes | yes | yes | yes | 0 | 0 | proven | 12 |  |  |  |
| misc/SPARK2/Ada-SPARK-Basic-Calculator | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Basic-Calculator-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Basic-Calculator-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Beautiful-Arrangement | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Beautiful-Array-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Best-Time-To-Buy-And-Sell-Stock-With-Cooldownoldown | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Binary-Number-With-Alternating-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Binary-To-Integer | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Binary-Watch | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Binomial-Coefficient | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bitset | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bitwise-AND-Of-Numbers-Range | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bitwise-OR-Of-Numbers-Range | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bitwise-ORs-Of-Subarrays-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bitwise-XOR-Of-All-Pairings | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Boats-To-Save-People | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bounding-Box | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bray-Curtis | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Broken-Calculator | yes | yes | yes | yes | yes | 0 | 0 | proven | 19 |  |  |  |
| misc/SPARK2/Ada-SPARK-Browser-History-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Buddy-Memory-Allocation (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 7 |  | misc/Ada/Buddy-Memory-Allocation |  |
| misc/SPARK2/Ada-SPARK-Bulb-Switcher | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bulb-Switcher-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Bump-Arena | yes | yes | yes | yes | yes | 0 | 0 | proven | 108 (10) |  |  |  |
| misc/SPARK2/Ada-SPARK-CRC32 | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-CSR-Row-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Can-Place-Flowers | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Canberra-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | 14 |  |  |  |
| misc/SPARK2/Ada-SPARK-Candy (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Capacity-To-Ship-Packages | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Car-Pooling | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Cheapest-Flights | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Cheapest-Flights-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Cheapest-Flights-Within-K-Stops | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Check-If-Number-Is-A-Sum-Of-Powers-Of-Three | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Check-If-The-Sentence-Is-Pangram | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Checksum-Ones-Complement | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Cherry-Pickup-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Circular-Deque-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Circular-Queue | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Clamp | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Climbing-Stairs | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Clock-Page-Replacement | yes | yes | yes | yes | yes | 1 | 1 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Coin-Change | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Coin-Change-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Iterator-Stub (stub) | yes | yes | yes | yes | yes | 4 | 4 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Sum-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Sum-III | yes | yes | yes | yes | yes | 0 | 0 | proven | 21 |  |  |  |
| misc/SPARK2/Ada-SPARK-Combination-Sum-IV | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Complement-Of-Base-10 | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Complement-Of-Base-10-Integer | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Connected-Component-Labeling | yes | yes | yes | yes | yes | 0 | 1 | proven | 18 (3) |  | misc/Ada/Connected-Component-Labeling |  |
| misc/SPARK2/Ada-SPARK-Container-With-Most-Water | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Contains-Duplicate | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Contains-Duplicate-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Contiguous-Array | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Continuous-Subarray-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Convert-1D-Array-Into-2D-Array | yes | yes | yes | yes | yes | 7 | 7 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Convert-A-Number-To-Hexadecimal | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Convert-Binary-Number-In-A-Linked-List-To-Integer | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Copy-List-With-Random-Pointer-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Corporate-Flight-Bookings | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Cosine-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Cosine-Similarity | yes | yes | yes | yes | yes | 2 | 2 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Count-And-Say | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Count-And-Say-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven | 42 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Count-Odd-Numbers-In-An-Interval | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Count-Of-Smaller-Numbers-After-Self-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Count-Operations-To-Obtain-Zero | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Count-Square-Submatrices-With-All-Ones | yes | yes | yes | yes | yes | 10 | 10 | proven | 30 (17) |  |  |  |
| misc/SPARK2/Ada-SPARK-Count-Sub-Islands (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Count-Triplets-That-Can-Form-Two-Arrays-Of-Equal-XOR | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Counting-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Covariance | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Crawler-Log-Folder | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Create-Maximum-Number-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Critical-Connections-In-A-Network-Lite | yes | yes | yes | yes | yes | 1 | 2 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Daily-Temperatures | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Decode-Ways | yes | yes | yes | yes | yes | 0 | 0 | proven | 30 (9) |  |  |  |
| misc/SPARK2/Ada-SPARK-Decode-Ways-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Decode-XORed-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Defanging-An-IP-Address | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Degree-Of-An-Array | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Delete-And-Earn | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Delete-And-Earn-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Delete-Node-In-A-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Delete-The-Middle-Node | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Delta-Encoding | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 (1) |  | misc/Ada/Delta-Encoding |  |
| misc/SPARK2/Ada-SPARK-Deque-Bounded | yes | yes | yes | yes | yes | 0 | 0 | proven | 14 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-A-Leaderboard | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment | yes | yes | yes | yes | yes | 4 | 4 | proven | 18 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-A-Stack-With-Increment-Operation | yes | yes | yes | yes | yes | 0 | 0 | proven | 14 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-An-Ordered-Stream | yes | yes | yes | yes | yes | 4 | 4 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Bitset | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Browser-History | yes | yes | yes | yes | yes | 2 | 2 | proven | 14 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Circular-Deque | yes | yes | yes | yes | yes | 2 | 2 | proven | 12 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Circular-Queue | yes | yes | yes | yes | yes | 2 | 2 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Circular-Queue-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Food-Rating-System | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Front-Middle-Back-Queue-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Hit-Counter-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Linked-List | yes | yes | yes | yes | yes | 2 | 2 | proven | 13 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Number-Container-System | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Ordered-Stream | yes | yes | yes | yes | yes | 4 | 4 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Parking-System-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Skiplist-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven | 12 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Twitter-Lite | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Design-Underground-System-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 18 |  |  |  |
| misc/SPARK2/Ada-SPARK-Detect-Capital | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Diagonal-Traverse | yes | yes | yes | yes | yes | 8 | 8 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Dice-Coefficient | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  | misc/Ada/Dice-Coefficient |  |
| misc/SPARK2/Ada-SPARK-Difference-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Different-Ways-To-Add-Parentheses-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Disjoint-Set-Forest | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Distinct-Subsequences | yes | yes | yes | yes | yes | 2 | 2 | tool crash |  |  |  |  |
| misc/SPARK2/Ada-SPARK-Divisor-Game | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Domino-And-Tromino-Tiling-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Dot-Product | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Dungeon-Game-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Duplicate-Zeros | yes | yes | yes | yes | yes | 3 | 3 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Dutch-National-Flag | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Earliest-Deadline-First-Scheduling | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Elevator-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 (1) |  | misc/Ada/Elevator-Algorithm |  |
| misc/SPARK2/Ada-SPARK-Eliminate-Maximum-Number-Of-Monsters | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Encode-And-Decode-TinyURL-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Euclidean-Distance | yes | yes | yes | yes | yes | 2 | 2 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Eval-RPN | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Evaluate-Division-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Evaluate-Division-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Evaluate-Reverse-Polish-Notation | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Excel-Sheet-Column | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Excel-Sheet-Column-Title | yes | yes | yes | yes | yes | 2 | 2 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Exclusive-Time-Of-Functions-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Factorial | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Factorial-Trailing-Zeroes | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Fair-Candy-Swap | yes | yes | yes | yes | yes | 2 | 2 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Fast-Pow | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Fibonacci-DP | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Fibonacci-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Final-Prices-With-A-Special-Discount | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-All-Duplicates-In-An-Array | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-All-Numbers-Disappeared | yes | yes | yes | yes | yes | 2 | 2 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-Common-Characters (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-First-And-Last-Position | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-K-Closest-Elements | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-Median-Data-Stream-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 13 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-Median-From-Data-Stream | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-Peak-Element | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-City | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-City-With-Smallest-Number-Of-Neighbors | yes | yes | yes | yes | yes | 1 | 2 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Difference | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Duplicate-Number | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Original-Array-Of-Prefix-XOR | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Smallest-Divisor | yes | yes | yes | yes | yes | 0 | 0 | proven | 30 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-The-Town-Judge | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Find-Words-That-Can-Be-Formed | yes | yes | yes | yes | yes | 1 | 1 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-First-Bad-Version | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-First-Unique-Char | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-First-Unique-Character | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 1 |  | misc/Ada/Fisher-Yates-Shuffle |  |
| misc/SPARK2/Ada-SPARK-Fixed-Point-Iteration (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Fizz-Buzz | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Flatten-Nested-List-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Flipping-An-Image | yes | yes | yes | yes | yes | 10 | 10 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Flood-Fill | yes | yes | yes | yes | yes | 2 | 2 | proven | 8 |  | misc/Ada/Flood-Fill |  |
| misc/SPARK2/Ada-SPARK-Four-Sum | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Fruit-Into-Baskets | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Game-Of-Life-Step | yes | yes | yes | yes | yes | 12 | 12 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Gas-Station (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Generate-Parentheses | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Get-Maximum-In-Generated-Array (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Goat-Latin | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Gray-Code | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  | misc/Ada/Gray-Code |  |
| misc/SPARK2/Ada-SPARK-Greatest-Common-Divisor | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Group-Anagrams | yes | yes | yes | yes | yes | 0 | 0 | proven | 15 |  |  |  |
| misc/SPARK2/Ada-SPARK-Group-Anagrams-Stub (stub) | yes | yes | yes | yes | yes | 5 | 5 | proven | 15 |  |  |  |
| misc/SPARK2/Ada-SPARK-Grumpy-Bookstore-Owner | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Guess-Number-Higher-Or-Lower | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Hamming-Code | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  | misc/Ada/Hamming-Code |  |
| misc/SPARK2/Ada-SPARK-Hamming-Weight | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  | misc/Ada/Hamming-Weight |  |
| misc/SPARK2/Ada-SPARK-Hand-Of-Straights-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Happy-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Heap-Push-Pop (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 18 |  |  |  |
| misc/SPARK2/Ada-SPARK-Heaters | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Height-Checker | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Histogram-Bin | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Hit-Counter-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Horner-Scheme | yes | yes | yes | yes | yes | 1 | 1 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-House-Robber | yes | yes | yes | yes | yes | 0 | 0 | proven | 12 |  |  |  |
| misc/SPARK2/Ada-SPARK-House-Robber-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 17 |  |  |  |
| misc/SPARK2/Ada-SPARK-House-Robber-III-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-House-Robber-III-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-How-Many-Numbers-Are-Smaller (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-IPO-Lite | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Image-Smoother | yes | yes | yes | yes | yes | 0 | 0 | proven | 17 |  |  |  |
| misc/SPARK2/Ada-SPARK-Implement-Queue-Using-Stacks | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Implement-Stack-Using-Queues | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Implement-StrStr | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Insert-Delete-GetRandom-O1 | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Insert-Interval (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Int-To-Roman-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Integer-Break | yes | yes | yes | yes | yes | 0 | 0 | proven | 831 (240) |  |  |  |
| misc/SPARK2/Ada-SPARK-Integer-To-English-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Integer-To-Roman | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays | yes | yes | yes | yes | yes | 4 | 4 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Arrays-II (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Intersection-Of-Two-Linked-Lists | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Is-Palindrome | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Is-Subsequence (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Island-Perimeter | yes | yes | yes | yes | yes | 2 | 2 | proven | 83 |  |  |  |
| misc/SPARK2/Ada-SPARK-Jaccard-Index | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Jump-Game | yes | yes | yes | yes | yes | 0 | 0 | proven | 23 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Jump-Game-II (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-K-Closest-Points-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-K-Closest-Points-To-Origin | yes | yes | yes | yes | yes | 3 | 3 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Kadanes-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  | misc/Ada/Kadanes-Algorithm |  |
| misc/SPARK2/Ada-SPARK-Keyboard-Row | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Keys-And-Rooms | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Knapsack-01 | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Knight-Probability-In-Chessboard-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Koko-Eating-Bananas | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-Element | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-Element-In-A-Stream | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-Element-In-An-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Kth-Largest-In-Stream-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-L1-Norm | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-L2-Norm-Squared | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-LFU-Cache-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 29 (6) |  |  |  |
| misc/SPARK2/Ada-SPARK-LFU-Cache-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-LRU-Cache-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 26 (4) |  |  |  |
| misc/SPARK2/Ada-SPARK-LRU-Cache-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Largest-Number | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Largest-Rectangle-In-Histogram | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Last-Stone-Weight | yes | yes | yes | yes | yes | 2 | 2 | proven | 18 (2) |  |  |  |
| misc/SPARK2/Ada-SPARK-Last-Stone-Weight-II | yes | yes | yes | yes | yes | 3 | 3 | proven | 97 |  |  |  |
| misc/SPARK2/Ada-SPARK-Least-Common-Multiple | yes | yes | yes | yes | yes | 0 | 0 | proven | 12 |  |  |  |
| misc/SPARK2/Ada-SPARK-Lemonade-Change | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Length-Of-Last-Word | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Letter-Case-Permutation | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Letter-Combinations-Of-A-Phone-Number | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-License-Key-Formatting | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Line-Intersection | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Line-Reflection | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Linked-List-Cycle | yes | yes | yes | yes | yes | 5 | 5 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Linked-List-Cycle-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Logger-Rate-Limiter-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Increasing-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  | misc/Ada/Longest-Increasing-Subsequence |  |
| misc/SPARK2/Ada-SPARK-Longest-Mountain-In-Array | yes | yes | yes | yes | yes | 1 | 1 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Ones | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Palindromic-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | proven | 24 |  |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Repeating-Character-Replacement | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Longest-Word-In-Dictionary | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Magnetic-Force-Between-Two-Balls | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Majority-Element | yes | yes | yes | yes | yes | 0 | 0 | proven | 12 |  |  |  |
| misc/SPARK2/Ada-SPARK-Majority-Element-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Manacher | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Manhattan-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Map-Sum-Pairs | yes | yes | yes | yes | yes | 3 | 3 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Mark-And-Sweep | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  | misc/Ada/Mark-and-Sweep |  |
| misc/SPARK2/Ada-SPARK-Matchsticks-To-Square-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Area-Of-Island (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones-II | yes | yes | yes | yes | yes | 3 | 3 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Consecutive-Ones-III | yes | yes | yes | yes | yes | 0 | 0 | proven | 95 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Heap | yes | yes | yes | yes | yes | 1 | 1 | proven | 23 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Path-Sum-Stub (stub) | yes | yes | yes | yes | yes | 6 | 6 | proven | 19 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Points-On-A-Line-Lite | yes | yes | yes | yes | yes | 0 | 1 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Product-Subarray | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Stack | yes | yes | yes | yes | yes | 0 | 0 | proven | 13 |  |  |  |
| misc/SPARK2/Ada-SPARK-Max-Stack-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximal-Rectangle | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximal-Square | yes | yes | yes | yes | yes | 15 | 15 | proven | 32 (17) |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Candies-Allocated-To-K-Children | yes | yes | yes | yes | yes | 1 | 1 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Ice-Cream-Bars | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Points-You-Can-Obtain-From-Cards | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Product-Of-Word-Lengths | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Product-Subarray | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Subarray | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Subarray-Circular | yes | yes | yes | yes | yes | 0 | 0 | proven | 12 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Twin-Sum-Of-A-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-Units-On-A-Truck | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Maximum-XOR-Of-Two-Numbers | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Mean-Variance | yes | yes | yes | yes | yes | 0 | 0 | proven | 13 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Median-Filtering | yes | yes | yes | yes | yes | 0 | 0 | proven | 34 (9) |  | misc/Ada/Median-Filtering |  |
| misc/SPARK2/Ada-SPARK-Median-Of-Three | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Meeting-Rooms | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Meeting-Rooms-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Merge-In-Between-Linked-Lists | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Merge-Intervals (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Middle-Of-The-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Min-Cost-Climbing-Stairs | yes | yes | yes | yes | yes | 0 | 0 | proven | 21 (8) |  |  |  |
| misc/SPARK2/Ada-SPARK-Min-Cost-Connect-Cities-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Min-Cost-To-Connect-All-Points | yes | yes | yes | yes | yes | 4 | 4 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Min-Heap | yes | yes | yes | yes | yes | 1 | 1 | proven | 23 |  |  |  |
| misc/SPARK2/Ada-SPARK-Min-Max-Normalize | yes | yes | yes | yes | yes | 1 | 1 | proven | 23 |  |  |  |
| misc/SPARK2/Ada-SPARK-Min-Stack | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-ASCII-Delete-Sum | yes | yes | yes | yes | yes | 2 | 2 | tool crash |  |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Bit-Flips-To-Convert-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Cost-To-Move-Chips | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Deletions-To-Make-Character-Frequencies-Unique | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Arrows | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Days-To-Make-M-Bouquets | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Number-Of-Moves-To-Seat | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Operations-To-Make-The-Array-Increasing | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Path-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven | 33 |  |  |  |
| misc/SPARK2/Ada-SPARK-Minimum-Sum-Of-Four-Digit-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Missing-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Missing-Ranges-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Monotonic-Stack | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Most-Common-Word | yes | yes | yes | yes | yes | 0 | 1 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Move-Zeroes | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Moving-Average | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Moving-Average-From-Data-Stream | yes | yes | yes | yes | yes | 2 | 2 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-My-Calendar-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-My-Linked-List-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-N-Queens-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-N-Repeated-Element-In-Size-2N-Array (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-N-th-Tribonacci | yes | yes | yes | yes | yes | 1 | 1 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Nearest-Exit-From-Entrance-In-Maze | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Neighboring-Bitwise-XOR | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Nested-Iterator-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven | 13 |  |  |  |
| misc/SPARK2/Ada-SPARK-Network-Delay-Time | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Network-Delay-Time-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-New-21-Game-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Next-Greater-Element-I | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Next-Greater-Element-II | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Next-Greater-Node-In-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Next-Permutation-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Nim-Game | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Non-Decreasing-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Non-Overlapping-Intervals (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Nth-Digit | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Nth-Digit-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven | 26 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Nth-Ugly-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 14 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Complement | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-1-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-1-Bits-In-Range | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Connected-Components | yes | yes | yes | yes | yes | 1 | 1 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Good-Pairs (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Islands (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Provinces | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Recent-Calls | yes | yes | yes | yes | yes | 2 | 3 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Steps-To-Reduce-A-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Number-Of-Steps-To-Reduce-A-Number-In-Binary-Representation | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-One-Hot | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Ones-And-Zeroes | yes | yes | yes | yes | yes | 6 | 6 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Online-Stock-Span | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Online-Stock-Span-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Open-The-Lock | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Ordered-Stream-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Out-Of-Boundary-Paths-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Overlap-Coefficient | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-PN-Counter | yes | yes | yes | yes | yes | 0 | 0 | proven | 23 (4) |  |  |  |
| misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Flow (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Pacific-Atlantic-Water-Stub (stub) | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Paint-Fence-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Paint-House-Lite (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Paint-House-Stub (stub) | yes | yes | yes | yes | yes | 7 | 7 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Number | yes | yes | yes | yes | yes | 2 | 3 | proven | 14 |  |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Pairs-Lite | yes | yes | yes | yes | yes | 3 | 3 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Partitioning | yes | yes | yes | yes | yes | 0 | 0 | proven | 20 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Palindrome-Partitioning-II | yes | yes | yes | yes | yes | 3 | 3 | tool crash |  |  |  |  |
| misc/SPARK2/Ada-SPARK-Parity-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Parking-System-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Partition-Around-Pivot | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Partition-Equal-Subset-Sum | yes | yes | yes | yes | yes | 3 | 3 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Partition-Labels | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Partition-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 | yes |  |  |
| misc/SPARK2/Ada-SPARK-Pascal-Triangle | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Pascal-Triangle-II | yes | yes | yes | yes | yes | 1 | 1 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Path-Sum | yes | yes | yes | yes | yes | 7 | 7 | proven | 20 |  |  |  |
| misc/SPARK2/Ada-SPARK-Path-Sum-III-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Path-With-Minimum-Effort | yes | yes | yes | yes | yes | 2 | 2 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Peak-Index-In-Mountain-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Pearson-Correlation | yes | yes | yes | yes | yes | 0 | 0 | proven | 19 |  |  |  |
| misc/SPARK2/Ada-SPARK-Peeking-Iterator-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Permutations | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Permutations-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Plus-One | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Population-Count | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Pow-X-N | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Pow-X-N-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven | 15 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Power-Of-Four | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Power-Of-Three | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Power-Of-Two | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Powx-N | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Prefix-Sums | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Prim-MST-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Priority-Queue-Binary-Heap | yes | yes | yes | yes | yes | 0 | 0 | proven | 22 |  |  |  |
| misc/SPARK2/Ada-SPARK-Product-Except-Self | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Product-Of-Array-Except-Self | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Product-Of-Numbers-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Projection-Area-Of-3D-Shapes | yes | yes | yes | yes | yes | 3 | 3 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Queue-Reconstruction-By-Height | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Queue-Using-Stacks | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Random-Pick-With-Weight-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Randomized-Collection | yes | yes | yes | yes | yes | 3 | 3 | proven | 12 |  |  |  |
| misc/SPARK2/Ada-SPARK-Randomized-Set | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Range-Addition | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Range-Module-Stub (stub) | yes | yes | yes | yes | yes | 3 | 5 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Range-Sum-Query | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Range-Sum-Query-2D-Immutable | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Range-Sum-Query-Immutable | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Ransom-Note | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Rate-Monotonic-Scheduling | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Ravenscar-Job-Pool | yes | yes | yes | yes | yes | 0 | 1 | proven | 85 (16) |  |  |  |
| misc/SPARK2/Ada-SPARK-Reach-A-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Recent-Counter | yes | yes | yes | yes | yes | 2 | 3 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Rectangle-Area | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Rectangle-Overlap | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reduce-Array-Size-To-The-Half | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Redundant-Connection | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Redundant-Connection-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Redundant-Connection-II-Lite | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reference-Counting | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  | misc/Ada/Reference-Counting |  |
| misc/SPARK2/Ada-SPARK-Regular-Expression-Matching-Lite | yes | yes | yes | yes | yes | 2 | 2 | tool crash |  |  |  |  |
| misc/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Remove-Duplicate-Letters | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Remove-Element | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Remove-K-Digits (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Remove-Linked-List-Elements | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Remove-Nth-Node-From-End | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reorder-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Replace-Elements-With-Greatest-On-Right | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Replace-Words | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reservoir-Sampling | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Restore-IP-Addresses | yes | yes | yes | yes | yes | 1 | 1 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Integer | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Linked-List-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 | yes |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Only-Letters | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Pairs-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Vowels | yes | yes | yes | yes | yes | 2 | 3 | proven | 17 |  |  |  |
| misc/SPARK2/Ada-SPARK-Reverse-Words | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Ring-Buffer | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Robot-Return-To-Origin | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Roman-To-Int | yes | yes | yes | yes | yes | 0 | 0 | proven | 16 |  |  |  |
| misc/SPARK2/Ada-SPARK-Roman-To-Integer | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Rotate-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Rotate-Image | yes | yes | yes | yes | yes | 8 | 8 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Rotate-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 | yes |  |  |
| misc/SPARK2/Ada-SPARK-Rotting-Oranges | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Round-Robin-Scheduling | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Seat-Manager-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Seat-Reservation-Manager | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Self-Dividing-Numbers | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sequence-Reconstruction-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Shift-2D-Grid | yes | yes | yes | yes | yes | 13 | 13 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Bridge | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Common-Supersequence-Lite | yes | yes | yes | yes | yes | 2 | 2 | tool crash |  |  |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Completing-Word | yes | yes | yes | yes | yes | 0 | 0 | proven | 16 |  |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Job-Next | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Remaining-Time | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Shortest-Word-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sigmoid | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Simplify-Path-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Single-Number | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Single-Number-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Single-Number-III | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Sliding-Window-Max | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sliding-Window-Maximum | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sliding-Window-Median | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Smallest-Integer-Divisible-By-K | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Snapshot-Array-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Softmin | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Soup-Servings-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Spearman-Rank-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Special-Array-With-X-Elements | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Split-Array-Largest-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sqrt-Integer | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sqrt-X | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sqrtx | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Stack-Bounded | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| misc/SPARK2/Ada-SPARK-Stack-Using-Queues-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Standard-Score | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Stock-Spanner-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Stream-Of-Characters-Lite | yes | yes | yes | yes | yes | 4 | 4 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Strstr-Naive | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Student-Attendance-Record-I | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Subarray-Sum-Equals-K | yes | yes | yes | yes | yes | 0 | 0 | proven | 23 |  |  |  |
| misc/SPARK2/Ada-SPARK-Subarrays-With-K-Different-Integers | yes | yes | yes | yes | yes | 3 | 3 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Subsets | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Subsets-Bitmask | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Subsets-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Subtract-Product-Sum-Digits | yes | yes | yes | yes | yes | 0 | 0 | proven | 20 |  |  |  |
| misc/SPARK2/Ada-SPARK-Subtract-The-Product-And-Sum | yes | yes | yes | yes | yes | 2 | 2 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sudoku-Solver-Lite | yes | yes | yes | yes | yes | 5 | 5 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sum-Of-Left-Leaves | yes | yes | yes | yes | yes | 6 | 6 | proven | 20 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sum-Of-Subarray-Minimums | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Sum-Of-Two-Integers | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Sum-Root-To-Leaf-Numbers | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Summary-Ranges | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Super-Ugly-Number | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Super-Ugly-Number-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Surface-Area-Of-3D-Shapes | yes | yes | yes | yes | yes | 3 | 3 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Surrounded-Regions (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 0 |  |  |  |
| misc/SPARK2/Ada-SPARK-Swap-Nodes-In-Pairs | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 | yes |  |  |
| misc/SPARK2/Ada-SPARK-Swapping-Nodes-In-A-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Swim-In-Rising-Water-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Tanimoto | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Target-Sum | yes | yes | yes | yes | yes | 4 | 4 | proven | 17 |  |  |  |
| misc/SPARK2/Ada-SPARK-Target-Sum-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-The-Skyline-Problem-Lite | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Third-Maximum-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Three-Divisors | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Three-Sum | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Three-Sum-Closest-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Tic-Tac-Toe-Stub (stub) | yes | yes | yes | yes | yes | 12 | 12 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Time-Based-Key-Value-Store | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Time-Map-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Title-To-Number | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-To-Lower-Case | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Top-K-Frequent-Elements | yes | yes | yes | yes | yes | 1 | 1 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Top-K-Frequent-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| misc/SPARK2/Ada-SPARK-Top-K-Frequent-Words | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Top-Nodes-Algorithm | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 1 |  | misc/Ada/Top-Nodes-Algorithm |  |
| misc/SPARK2/Ada-SPARK-Trapezoidal-Rule | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Trapping-Rain-Water | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Trapping-Rain-Water-II-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Triangle | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Triangle-Min-Path | yes | yes | yes | yes | yes | 0 | 0 | proven | 15 |  |  |  |
| misc/SPARK2/Ada-SPARK-Tribonacci | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Tribonacci-Number | yes | yes | yes | yes | yes | 1 | 1 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Tweet-Counts-Stub (stub) | yes | yes | yes | yes | yes | 2 | 3 | proven | 8 |  |  |  |
| misc/SPARK2/Ada-SPARK-Two-City-Scheduling | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Two-Pointers-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Two-Sum | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-UTF-8-Validation | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| misc/SPARK2/Ada-SPARK-Ugly-Number | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Ugly-Number-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 475 (21) |  |  |  |
| misc/SPARK2/Ada-SPARK-Uncommon-Words-From-Two-Sentences (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Underground-System-Stub (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Union-Find | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Unique-Email-Addresses | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| misc/SPARK2/Ada-SPARK-Unique-Morse-Code-Words (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Unique-Paths | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Unique-Paths-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Anagram | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-IP-Address-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Number-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Palindrome | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Palindrome-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 22 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Parentheses | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Square | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Sudoku-Stub (stub) | yes | yes | yes | yes | yes | 8 | 8 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Valid-Word-Abbreviation | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Validate-Stack-Sequences | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| misc/SPARK2/Ada-SPARK-Vector-2D-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 18 |  |  |  |
| misc/SPARK2/Ada-SPARK-Vector-Dot-Cross | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Water-Bottles | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Wiggle-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Wildcard-Matching-Lite | yes | yes | yes | yes | yes | 2 | 2 | tool crash |  |  |  |  |
| misc/SPARK2/Ada-SPARK-Word-Break | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Word-Break-II | yes | yes | yes | yes | yes | 5 | 5 | proven | 7 |  |  |  |
| misc/SPARK2/Ada-SPARK-Word-Break-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-Word-Ladder-II-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| misc/SPARK2/Ada-SPARK-Word-Ladder-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Word-Ladder-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 1 |  |  |  |
| misc/SPARK2/Ada-SPARK-Word-Pattern | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| misc/SPARK2/Ada-SPARK-XOR-Of-Numbers-Range | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-XOR-Operation-In-An-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| misc/SPARK2/Ada-SPARK-Zigzag-Iterator-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven | 9 |  |  |  |
| misc/SPARK2/Pattern-132 | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| misc/SPARK4/Acorn-Generator | yes | yes | yes | yes | yes | 0 | 0 | proven | 231 (63) |  | misc/Ada/ACORN-Generator |  |
| misc/SPARK4/Ada-SPARK-Accumulator | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 (2) |  |  |  |
| misc/SPARK4/Ada-SPARK-Blum-Blum-Shub | yes | yes | yes | yes | yes | 0 | 0 | proven | 261 (84) |  | misc/Ada/Blum-Blum-Shub |  |
| misc/SPARK4/Ada-SPARK-Heaps-Algorithm | yes | yes | yes | yes | yes | 0 | 9 | proven | 235 (65) |  | misc/Ada/Heaps-Algorithm |  |
| misc/SPARK4/Ada-SPARK-K-Way-Merge | yes | yes | yes | yes | yes | 0 | 0 | proven | 606 (restored) |  | misc/Ada/K-Way-Merge |  |
| misc/SPARK4/Ada-SPARK-Lagged-Fibonacci-Generator | yes | yes | yes | yes | yes | 0 | 0 | proven | 318 (107) |  | misc/Ada/Lagged-Fibonacci-Generator |  |
| misc/SPARK4/Ada-SPARK-Lemke-Howson | yes | yes | yes | yes | yes | 0 | 0 | proven | 247 (22) |  | misc/Ada/Lemke-Howson |  |
| misc/SPARK4/Ada-SPARK-Package-Merge-Algorithm | yes | yes | yes | yes | yes | 0 | 6 | proven | 195 (10) |  | misc/Ada/Package-Merge-Algorithm |  |
| misc/SPARK4/Ada-SPARK-Selection-Algorithm | yes | yes | yes | yes | yes | 0 | 8 | proven | 419 (104) |  | misc/Ada/Selection-Algorithm |  |
| misc/SPARK4/Ada-SPARK-Shortest-Seek-First | n/a | no | no | no | no | 0 | 0 | no SPARK |  |  |  |  |
| misc/SPARK4/demo | n/a | no | no | no | no | 0 | 0 | skipped (no SPARK_Mode) |  |  |  |  |
| ml/Ada/AdaBoost | yes | yes | yes | yes | yes | 1 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Alopex | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Backpropagation | yes | yes | yes | yes | yes | 0 | 0 | proven | 27 |  |  |  |
| ml/Ada/Boosting-Meta-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/BrownBoost | yes | yes | yes | yes | yes | 1 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Expectation-Maximization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Forward-Backward | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Hidden-Markov-Model | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| ml/Ada/LPBoost | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 1 |  |  |  |
| ml/Ada/LogitBoost | yes | yes | yes | yes | yes | 115 | 115 | no SPARK |  |  |  |  |
| ml/Ada/Naive-Bayes-Classifier | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Neural-Network | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Perceptron | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Policy-Iteration | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |  |  |
| ml/Ada/Pulse-Coupled-Neural-Networks | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Q-Learning | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| ml/Ada/Random-Forest | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Reinforcement-Learning | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Support-Vector-Machine | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Value-Iteration | yes | yes | yes | yes | yes | 0 | 3 | no SPARK |  |  |  |  |
| ml/Ada/Viterbi | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| ml/Ada/Winnow-Algorithm | yes | yes | yes | yes | yes | 17 | 17 | no SPARK |  |  |  |  |
| ml/SPARK2/Ada-SPARK-ReLU | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| ml/SPARK2/Ada-SPARK-Softmax | yes | yes | yes | yes | yes | 1 | 1 | proven | 9 |  |  |  |
| ml/SPARK2/Linear-Regression | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| numerical/Ada/Aks-Primality-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Arnoldi | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/BBP | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/BFGS | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/BKM | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Biconjugate-Gradient | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Bicubic-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Bilinear-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Binary-GCD | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK4/Binary-Gcd |  |
| numerical/Ada/Birkhoff-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Bisection-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK2/Ada-SPARK-Bisection-Method |  |
| numerical/Ada/Bluesteins-FFT-Algorithm | yes | yes | yes | yes | yes | 28 | 28 | no SPARK |  |  |  |  |
| numerical/Ada/Borwein | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Brents-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK4/Ada-SPARK-Brents-Algorithm |  |
| numerical/Ada/Bruuns-FFT-Algorithm | yes | yes | yes | yes | yes | 21 | 21 | no SPARK |  |  |  |  |
| numerical/Ada/CORDIC | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Cantor-Zassenhaus | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Chakravala | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Chudnovsky | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Cipolla | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Conjugate-Gradient | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Cooley-Tukey-FFT-Algorithm | yes | yes | yes | yes | yes | 11 | 11 | no SPARK |  |  | numerical/SPARK2/Ada-SPARK-Cooley-Tukey-FFT |  |
| numerical/Ada/Cubic-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Dixon | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Euclidean-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK4/Ada-SPARK-Euclidean-Algorithm |  |
| numerical/Ada/Extended-Euclidean-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK2/Ada-SPARK-Extended-Euclidean numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm |  |
| numerical/Ada/Fast-Fourier-Transform | yes | yes | yes | yes | yes | 6 | 6 | no SPARK |  |  |  |  |
| numerical/Ada/Fermat-Primality-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Furer | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Gauss-Legendre | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Gauss-Newton | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/General-Number-Field-Sieve | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Gradient-Descent | yes | yes | yes | yes | yes | 0 | 0 | not built |  |  |  |  |
| numerical/Ada/Hermite-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Hybrid-Monte-Carlo | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Interior-Point-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Karatsuba | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Lagrange-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK2/Ada-SPARK-Lagrange-Interpolation |  |
| numerical/Ada/Lanczos | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Lanczos-Resampling | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Levenberg-Marquardt | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Linear-Congruential-Generator | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK4/Ada-SPARK-Linear-Congruential-Generator |  |
| numerical/Ada/Linear-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Lucas-Primality-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/MISER | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Mersenne-Twister | yes | yes | yes | yes | yes | 6 | 8 | no SPARK |  |  | numerical/SPARK4/Ada-SPARK-Mersenne-Twister |  |
| numerical/Ada/Metropolis-Hastings | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Metropolis-Light-Transport | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| numerical/Ada/Miller-Rabin | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Monotone-Cubic-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Multivariate-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Nearest-Neighbor-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Neville | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Newells-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Newton-Raphson-Division | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Pareto-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Partial-Least-Squares | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Pollards-Kangaroo-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Pollards-P-1 | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Pollards-Rho | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Pollards-Rho-Logarithms | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Polynomial-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Primality-Test | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Prime-Factor-FFT-Algorithm | yes | yes | yes | yes | yes | 24 | 24 | no SPARK |  |  |  |  |
| numerical/Ada/Prime-Factorization | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Quadratic-Sieve | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Raders-FFT-Algorithm | yes | yes | yes | yes | yes | 27 | 27 | no SPARK |  |  |  |  |
| numerical/Ada/Runge-Kutta | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Secant-Method | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK2/Ada-SPARK-Secant-Method |  |
| numerical/Ada/Sieve-Of-Atkin | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Sieve-Of-Eratosthenes | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | numerical/SPARK2/Ada-SPARK-Sieve-Of-Eratosthenes |  |
| numerical/Ada/Sieve-Of-Sundaram | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| numerical/Ada/Special-Number-Field-Sieve | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Spline-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Tonelli-Shanks | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Tricubic-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/Ada/Trigonometric-Interpolation | yes | yes | yes | yes | yes | 13 | 13 | no SPARK |  |  |  |  |
| numerical/Ada/Ziggurat-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| numerical/SPARK2/Ada-SPARK-Bisection-Method | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  | numerical/Ada/Bisection-Method |  |
| numerical/SPARK2/Ada-SPARK-Chebyshev-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Cooley-Tukey-FFT | yes | yes | yes | yes | yes | 0 | 0 | proven | 81 (18) |  | numerical/Ada/Cooley-Tukey-FFT-Algorithm |  |
| numerical/SPARK2/Ada-SPARK-Count-Primes | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Count-Primes-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 23 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Extended-Euclidean | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  | numerical/Ada/Extended-Euclidean-Algorithm |  |
| numerical/SPARK2/Ada-SPARK-Lagrange-Interpolation | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  | numerical/Ada/Lagrange-Interpolation |  |
| numerical/SPARK2/Ada-SPARK-Maximum-Performance-Of-A-Team-Lite | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 1 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Minimum-Limit-Of-Balls-In-A-Bag | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Modular-Exponentiation | yes | yes | yes | yes | yes | 0 | 0 | proven | 20 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Newton-Raphson | yes | yes | yes | yes | yes | 0 | 0 | proven | 24 (1) |  |  |  |
| numerical/SPARK2/Ada-SPARK-Perfect-Number | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Perfect-Squares | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Prime-Check | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Prime-Number-Of-Set-Bits | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 (1) |  |  |  |
| numerical/SPARK2/Ada-SPARK-Prime-Number-Of-Set-Bits-In-Binary-Representation | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Secant-Method | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  | numerical/Ada/Secant-Method |  |
| numerical/SPARK2/Ada-SPARK-Sieve-Of-Eratosthenes | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  | numerical/Ada/Sieve-Of-Eratosthenes |  |
| numerical/SPARK2/Ada-SPARK-Simpson-Rule | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Successful-Pairs-Of-Spells-And-Potions | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Valid-Perfect-Square | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| numerical/SPARK2/Ada-SPARK-Walls-And-Gates | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| numerical/SPARK2/Babylonian-Sqrt | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| numerical/SPARK4/Ada-SPARK-Brents-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | 190 (31) |  | numerical/Ada/Brents-Algorithm |  |
| numerical/SPARK4/Ada-SPARK-Euclidean-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | 70 (6) |  | numerical/Ada/Euclidean-Algorithm |  |
| numerical/SPARK4/Ada-SPARK-Extended-Euclidean-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | 85 (9) |  | numerical/Ada/Extended-Euclidean-Algorithm |  |
| numerical/SPARK4/Ada-SPARK-Linear-Congruential-Generator | yes | yes | yes | yes | yes | 0 | 0 | proven | 192 (63) |  | numerical/Ada/Linear-Congruential-Generator |  |
| numerical/SPARK4/Ada-SPARK-Mersenne-Twister | yes | yes | yes | yes | yes | 0 | 1 | proven | 102 (25) |  | numerical/Ada/Mersenne-Twister |  |
| numerical/SPARK4/Ada-SPARK-Modular-Arithmetic | yes | yes | yes | yes | yes | 0 | 0 | proven | 1629 (325) |  |  |  |
| numerical/SPARK4/Binary-Gcd | yes | yes | yes | yes | yes | 0 | 0 | proven | 77 (7) |  | numerical/Ada/Binary-GCD |  |
| parsing/Ada/Canonical-LR-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Cyk-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/GLR-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/LALR | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/LL-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/LR-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Operator-Precedence-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Packrat-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Pratt-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Recursive-Descent-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Shunting-Yard-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Simple-LR-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Simple-Precdence-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Simplex-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/Ada/Step-Parser | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| parsing/SPARK2/Ada-SPARK-Sparse-Set | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| parsing/SPARK2/Ada-SPARK-Sparse-Vector-Dot-Stub (stub) | yes | yes | yes | yes | yes | 5 | 5 | proven | 6 |  |  |  |
| parsing/SPARK2/Sparse-Dot | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| searching/Ada/Beam-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Best-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Best-First-Search |  |
| searching/Ada/Bidirectional-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Binary-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Binary-Search |  |
| searching/Ada/Breadth-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Brute-Force-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Chien-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Depth-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Eytzinger-Binary-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Fibonacci-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Fibonacci-Search |  |
| searching/Ada/Golden-Section-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Grid-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Harmony-Search | yes | yes | yes | yes | yes | 0 | 2 | no SPARK |  |  |  |  |
| searching/Ada/Hyperlink-Induced-Topic-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Interpolation-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Interpolation-Search |  |
| searching/Ada/Introselect | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Introselect |  |
| searching/Ada/Iterative-Deepening-Depth-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Jump-Point-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Jump-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Jump-Search |  |
| searching/Ada/Lexicographic-Breadth-First-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Line-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Linear-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Linear-Search |  |
| searching/Ada/Local-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Monte-Carlo-Tree-Search | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| searching/Ada/Nearest-Neighbor-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Quantum-Walk-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Quickselect | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Quickselect |  |
| searching/Ada/Random-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Substring-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Tabu-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Ternary-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Ternary-Search |  |
| searching/Ada/Trigram-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | searching/SPARK2/Ada-SPARK-Trigram-Search |  |
| searching/Ada/Uniform-Binary-Search | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| searching/Ada/Uniform-Cost-Search | yes | no | no | yes | yes | 4 | 4 | no SPARK |  |  | searching/SPARK4/Ada-SPARK-Uniform-Cost-Search |  |
| searching/SPARK2/Ada-SPARK-Binary-Search-Lower-Bound | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Binary-Search-Upper-Bound (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Design-Add-And-Search-Words | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| searching/SPARK2/Ada-SPARK-Exponential-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | 25 |  |  |  |
| searching/SPARK2/Ada-SPARK-Increasing-Order-Search-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| searching/SPARK2/Ada-SPARK-Insert-Into-A-Binary-Search-Tree | yes | yes | yes | yes | yes | 8 | 8 | proven (trivial) | 1 |  |  |  |
| searching/SPARK2/Ada-SPARK-Naive-String-Search | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Search-2D-Matrix | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| searching/SPARK2/Ada-SPARK-Search-A-2D-Matrix-II | yes | yes | yes | yes | yes | 9 | 9 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Search-In-A-Binary-Search-Tree | yes | yes | yes | yes | yes | 9 | 9 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Search-Insert-Position | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Trigram-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  | searching/Ada/Trigram-Search |  |
| searching/SPARK2/Ada-SPARK-Trim-A-Binary-Search-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Unique-Binary-Search-Trees-II-Lite (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Validate-Binary-Search-Tree | yes | yes | yes | yes | yes | 0 | 0 | proven | 23 |  |  |  |
| searching/SPARK2/Ada-SPARK-Word-Search (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| searching/SPARK2/Ada-SPARK-Word-Search-II-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| searching/SPARK2/Bst-Insert-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | 53 (8) |  |  |  |
| searching/SPARK4/Ada-SPARK-Binary-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | 105 (6) |  | searching/Ada/Binary-Search |  |
| searching/SPARK4/Ada-SPARK-Fibonacci-Search | yes | yes | yes | yes | yes | 0 | 1 | proven | 61 (3) |  | searching/Ada/Fibonacci-Search |  |
| searching/SPARK4/Ada-SPARK-Interpolation-Search | yes | yes | yes | yes | yes | 0 | 1 | proven | 62 (4) |  | searching/Ada/Interpolation-Search |  |
| searching/SPARK4/Ada-SPARK-Introselect | yes | yes | yes | yes | yes | 0 | 12 | proven | 584 (138) |  | searching/Ada/Introselect |  |
| searching/SPARK4/Ada-SPARK-Jump-Search | yes | yes | yes | yes | yes | 0 | 2 | proven | 88 (11) |  | searching/Ada/Jump-Search |  |
| searching/SPARK4/Ada-SPARK-Linear-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | 31 (5) |  | searching/Ada/Linear-Search |  |
| searching/SPARK4/Ada-SPARK-Quickselect | yes | yes | yes | yes | yes | 0 | 8 | proven | 419 (104) |  | searching/Ada/Quickselect |  |
| searching/SPARK4/Ada-SPARK-Ternary-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | 99 (4) |  | searching/Ada/Ternary-Search |  |
| searching/SPARK4/Ada-SPARK-Uniform-Cost-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | 224 (6) |  | searching/Ada/Uniform-Cost-Search |  |
| searching/SPARK4/Best-First-Search | yes | yes | yes | yes | yes | 0 | 0 | proven | 180 (5) |  | searching/Ada/Best-First-Search |  |
| sorting/Ada/Bead-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Bead-Sort |  |
| sorting/Ada/Bitonic-Sorter | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Bitonic-Sorter |  |
| sorting/Ada/Bogosort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Bogosort |  |
| sorting/Ada/Bubble-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Bubble-Sort |  |
| sorting/Ada/Bucket-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Bucket-Sort |  |
| sorting/Ada/Burstsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Burstsort |  |
| sorting/Ada/Cocktail-Shaker-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Cocktail-Shaker-Sort |  |
| sorting/Ada/Comb-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Comb-Sort |  |
| sorting/Ada/Counting-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Counting-Sort |  |
| sorting/Ada/Cycle-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Cycle-Sort |  |
| sorting/Ada/Flashsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK2/Ada-SPARK-Flash-Sort sorting/SPARK4/Ada-SPARK-Flashsort |  |
| sorting/Ada/Gnome-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Gnome-Sort |  |
| sorting/Ada/Heapsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK2/Ada-SPARK-Heap-Sort sorting/SPARK4/Ada-SPARK-Heapsort |  |
| sorting/Ada/Insertion-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Insertion-Sort |  |
| sorting/Ada/Introsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK2/Ada-SPARK-Intro-Sort sorting/SPARK4/Ada-SPARK-Introsort |  |
| sorting/Ada/Library-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Library-Sort |  |
| sorting/Ada/Merge-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Merge-Sort |  |
| sorting/Ada/Odd-Even-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Odd-Even-Sort |  |
| sorting/Ada/Pancake-Sorting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Pancake-Sorting |  |
| sorting/Ada/Patience-Sorting | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Patience-Sorting |  |
| sorting/Ada/Pigeonhole-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Pigeonhole-Sort |  |
| sorting/Ada/Postman-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Postman-Sort |  |
| sorting/Ada/Quantum-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Quantum-Sort |  |
| sorting/Ada/Quicksort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK2/Ada-SPARK-Quick-Sort sorting/SPARK4/Ada-SPARK-Quicksort |  |
| sorting/Ada/Radix-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Radix-Sort |  |
| sorting/Ada/Samplesort | yes | yes | yes | yes | yes | 7 | 7 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Samplesort |  |
| sorting/Ada/Selection-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Selection-Sort |  |
| sorting/Ada/Shell-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Shell-Sort |  |
| sorting/Ada/Slowsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Slowsort |  |
| sorting/Ada/Smoothsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK2/Ada-SPARK-Smooth-Sort sorting/SPARK4/Ada-SPARK-Smoothsort |  |
| sorting/Ada/Sort-Merge-Join | yes | no | no | yes | yes | 24 | 24 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Sort-Merge-Join |  |
| sorting/Ada/Sorted-List | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Sorted-List |  |
| sorting/Ada/Spaghetti-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Spaghetti-Sort |  |
| sorting/Ada/Stooge-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Stooge-Sort |  |
| sorting/Ada/Strand-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Strand-Sort |  |
| sorting/Ada/Timsort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK2/Ada-SPARK-Tim-Sort sorting/SPARK4/Ada-SPARK-Timsort |  |
| sorting/Ada/Topological-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Topological-Sort |  |
| sorting/Ada/Tournament-Selection | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| sorting/Ada/Tree-Sort | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | sorting/SPARK4/Ada-SPARK-Tree-Sort |  |
| sorting/SPARK2/Ada-SPARK-Bitonic-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Block-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Circle-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Cocktail-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Convert-Sorted-Array-To-BST | yes | yes | yes | yes | yes | 7 | 7 | proven (trivial) | 3 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Count-Negative-Numbers-In-A-Sorted-Matrix | yes | yes | yes | yes | yes | 5 | 5 | proven (trivial) | 3 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Count-Sorted-Vowel-Strings | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Exchange-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Find-Median-Sorted-Arrays-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 14 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Flash-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  | sorting/Ada/Flashsort |  |
| sorting/SPARK2/Ada-SPARK-Heap-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  | sorting/Ada/Heapsort |  |
| sorting/SPARK2/Ada-SPARK-Intro-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  | sorting/Ada/Introsort |  |
| sorting/SPARK2/Ada-SPARK-Kth-Smallest-Element-In-A-Sorted-Matrix | yes | yes | yes | yes | yes | 8 | 8 | proven (trivial) | 3 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Median-Of-Two-Sorted-Arrays-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Merge-K-Sorted-Lists-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 5 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Merge-Sorted-Array | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Merge-Sorted-Arrays | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Merge-Two-Sorted-Lists | yes | yes | yes | yes | yes | 0 | 0 | proven | 22 (5) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Odd-Even-Linked-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Odd-Even-Merge-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Pancake-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Patience-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Quick-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  | sorting/Ada/Quicksort |  |
| sorting/SPARK2/Ada-SPARK-Relative-Sort-Array | yes | yes | yes | yes | yes | 5 | 5 | proven (trivial) | 1 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-Array-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-From-Sorted-List-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 39 (7) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Remove-Duplicates-Sorted | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Search-In-Rotated-Sorted-Array | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Search-In-Rotated-Sorted-Array-II | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Shaker-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Shortest-Unsorted-Continuous-Subarray | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 3 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Smooth-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  | sorting/Ada/Smoothsort |  |
| sorting/SPARK2/Ada-SPARK-Sort-An-Array | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Array-By-Parity-II | yes | yes | yes | yes | yes | 0 | 0 | proven | 38 (4) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Characters-By-Frequency | yes | yes | yes | yes | yes | 0 | 0 | proven | 44 (restored) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Colors | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-Integers-By-The-Number-Of-1-Bits | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Sort-List-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Sorted-Array-To-BST | yes | yes | yes | yes | yes | 9 | 9 | proven | 31 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Squares-Of-A-Sorted-Array | yes | yes | yes | yes | yes | 0 | 0 | proven | 31 (3) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Tim-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (1) |  | sorting/Ada/Timsort |  |
| sorting/SPARK2/Ada-SPARK-Tim-Sort-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven | 39 (6) |  |  |  |
| sorting/SPARK2/Ada-SPARK-Topological-Sort-Lite (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Tournament-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Two-Sum-II-Input-Array-Is-Sorted | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| sorting/SPARK2/Ada-SPARK-Wiggle-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| sorting/SPARK2/Binary-Insertion-Sort (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| sorting/SPARK4/Ada-SPARK-Bitonic-Sorter | yes | yes | yes | yes | yes | 0 | 6 | proven | 294 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Bitonic-Sorter |  |
| sorting/SPARK4/Ada-SPARK-Bogosort | yes | yes | yes | yes | yes | 0 | 2 | proven | 294 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Bogosort |  |
| sorting/SPARK4/Ada-SPARK-Bubble-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 291 (restored) |  | sorting/Ada/Bubble-Sort |  |
| sorting/SPARK4/Ada-SPARK-Bucket-Sort | yes | yes | yes | yes | yes | 0 | 10 | proven | 177 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Bucket-Sort |  |
| sorting/SPARK4/Ada-SPARK-Burstsort | yes | yes | yes | yes | yes | 0 | 12 | proven | 449 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Burstsort |  |
| sorting/SPARK4/Ada-SPARK-Cocktail-Shaker-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 204 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Cocktail-Shaker-Sort |  |
| sorting/SPARK4/Ada-SPARK-Comb-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | 194 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Comb-Sort |  |
| sorting/SPARK4/Ada-SPARK-Counting-Sort | yes | yes | yes | yes | yes | 0 | 7 | proven | 279 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Counting-Sort |  |
| sorting/SPARK4/Ada-SPARK-Cycle-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 274 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Cycle-Sort |  |
| sorting/SPARK4/Ada-SPARK-Flashsort | yes | yes | yes | yes | yes | 0 | 6 | proven | 350 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Flashsort |  |
| sorting/SPARK4/Ada-SPARK-Gnome-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | 204 (restored) |  | sorting/Ada/Gnome-Sort |  |
| sorting/SPARK4/Ada-SPARK-Heapsort | yes | yes | yes | yes | yes | 0 | 8 | proven | 529 (restored) |  | sorting/Ada/Heapsort |  |
| sorting/SPARK4/Ada-SPARK-Insertion-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | 91 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Insertion-Sort |  |
| sorting/SPARK4/Ada-SPARK-Introsort | yes | yes | yes | yes | yes | 0 | 12 | proven | 860 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Introsort |  |
| sorting/SPARK4/Ada-SPARK-Library-Sort | yes | yes | yes | yes | yes | 0 | 17 | proven | 360 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Library-Sort |  |
| sorting/SPARK4/Ada-SPARK-Merge-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 433 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Merge-Sort |  |
| sorting/SPARK4/Ada-SPARK-Odd-Even-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 209 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Odd-Even-Sort |  |
| sorting/SPARK4/Ada-SPARK-Pancake-Sorting | yes | yes | yes | yes | yes | 0 | 0 | proven | 577 (restored) |  | sorting/Ada/Pancake-Sorting |  |
| sorting/SPARK4/Ada-SPARK-Patience-Sorting | yes | yes | yes | yes | yes | 0 | 9 | proven | 301 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Patience-Sorting |  |
| sorting/SPARK4/Ada-SPARK-Pigeonhole-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | 254 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Pigeonhole-Sort |  |
| sorting/SPARK4/Ada-SPARK-Postman-Sort | yes | yes | yes | yes | yes | 0 | 1 | proven | 324 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Postman-Sort |  |
| sorting/SPARK4/Ada-SPARK-Quantum-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 441 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Quantum-Sort |  |
| sorting/SPARK4/Ada-SPARK-Quicksort | yes | yes | yes | yes | yes | 0 | 1 | proven | 412 (restored) |  | sorting/Ada/Quicksort |  |
| sorting/SPARK4/Ada-SPARK-Radix-Sort | yes | yes | yes | yes | yes | 0 | 6 | proven | 283 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Radix-Sort |  |
| sorting/SPARK4/Ada-SPARK-Samplesort | yes | yes | yes | yes | yes | 0 | 0 | proven | 259 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Samplesort |  |
| sorting/SPARK4/Ada-SPARK-Selection-Sort | yes | yes | yes | yes | yes | 0 | 0 | proven | 392 (restored) |  | sorting/Ada/Selection-Sort |  |
| sorting/SPARK4/Ada-SPARK-Shell-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | 131 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Shell-Sort |  |
| sorting/SPARK4/Ada-SPARK-Slowsort | yes | yes | yes | yes | yes | 0 | 1 | proven | 187 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Slowsort |  |
| sorting/SPARK4/Ada-SPARK-Smoothsort | yes | yes | yes | yes | yes | 0 | 5 | proven | 205 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Smoothsort |  |
| sorting/SPARK4/Ada-SPARK-Sort-Merge-Join | yes | yes | yes | yes | yes | 0 | 0 | proven | 310 (withdrawn: Post proves trivial body empty, see contract_scan.csv) |  | sorting/Ada/Sort-Merge-Join |  |
| sorting/SPARK4/Ada-SPARK-Sorted-List | yes | yes | yes | yes | yes | 0 | 3 | proven | 405 (restored) |  | sorting/Ada/Sorted-List |  |
| sorting/SPARK4/Ada-SPARK-Spaghetti-Sort | yes | yes | yes | yes | yes | 0 | 1 | proven | 219 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Spaghetti-Sort |  |
| sorting/SPARK4/Ada-SPARK-Stooge-Sort | yes | yes | yes | yes | yes | 0 | 1 | proven | 189 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Stooge-Sort |  |
| sorting/SPARK4/Ada-SPARK-Strand-Sort | yes | yes | yes | yes | yes | 0 | 10 | proven | 314 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Strand-Sort |  |
| sorting/SPARK4/Ada-SPARK-Timsort | yes | yes | yes | yes | yes | 0 | 0 | proven | 636 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Timsort |  |
| sorting/SPARK4/Ada-SPARK-Topological-Sort | yes | yes | yes | yes | yes | 0 | 10 | proven | 68 (withdrawn: Post proves trivial body not_found, see contract_scan.csv) |  | sorting/Ada/Topological-Sort |  |
| sorting/SPARK4/Ada-SPARK-Tree-Sort | yes | yes | yes | yes | yes | 0 | 3 | proven | 294 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Tree-Sort |  |
| sorting/SPARK4/Bead-Sort | yes | yes | yes | yes | yes | 0 | 2 | proven | 249 (withdrawn: Post lacks permutation, see contract_scan.csv) |  | sorting/Ada/Bead-Sort |  |
| strings/Ada/Aho-Corasick | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/Boyer-Moore | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | strings/SPARK2/Ada-SPARK-Boyer-Moore |  |
| strings/Ada/Boyer-Moore-Horspool | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/Daitch-Mokotoff-Soundex | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/Damerau-Levenshtein-Distance | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | strings/SPARK2/Ada-SPARK-Damerau-Levenshtein-Distance |  |
| strings/Ada/Double-Metaphone | yes | yes | yes | yes | yes | 0 | 1 | no SPARK |  |  |  |  |
| strings/Ada/Hamming-Distance | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  | strings/SPARK2/Ada-SPARK-Hamming-Distance |  |
| strings/Ada/Jaro-Winkler-Distance | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/Karplus-Strong-String-Synthesis | yes | yes | yes | yes | yes | 4 | 4 | no SPARK |  |  |  |  |
| strings/Ada/Knuth-Morris-Pratt | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt |  |
| strings/Ada/Levenshtein-Coding | yes | yes | yes | yes | yes | 1 | 1 | no SPARK |  |  |  |  |
| strings/Ada/Levenshtein-Distance | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | strings/SPARK3/Levenshtein-Distance |  |
| strings/Ada/Longest-Common-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence |  |
| strings/Ada/Metaphone | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/NYSIIS | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/Needleman-Wunsch | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/Rabin-Karp | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | strings/SPARK2/Ada-SPARK-Rabin-Karp |  |
| strings/Ada/Smith-Waterman | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/Soundex | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/Stemming | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/Ada/String-Metrics | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| strings/SPARK2/Ada-SPARK-Bounded-String-Builder | yes | yes | yes | yes | yes | 0 | 0 | proven | 192 (16) |  |  |  |
| strings/SPARK2/Ada-SPARK-Boyer-Moore | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  | strings/Ada/Boyer-Moore |  |
| strings/SPARK2/Ada-SPARK-Check-If-Two-String-Arrays-Are-Equivalent | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Count-The-Number-Of-Consistent-Strings (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| strings/SPARK2/Ada-SPARK-Damerau-Levenshtein-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | 24 |  | strings/Ada/Damerau-Levenshtein-Distance |  |
| strings/SPARK2/Ada-SPARK-Decode-String | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 3 |  |  |  |
| strings/SPARK2/Ada-SPARK-Decode-String-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Delete-Operation-For-Two-Strings | yes | yes | yes | yes | yes | 2 | 2 | tool crash |  |  |  |  |
| strings/SPARK2/Ada-SPARK-Edit-Distance | yes | yes | yes | yes | yes | 1 | 1 | proven | 15 |  |  |  |
| strings/SPARK2/Ada-SPARK-Encode-And-Decode-Strings-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| strings/SPARK2/Ada-SPARK-Find-All-Anagrams-In-A-String | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| strings/SPARK2/Ada-SPARK-First-Unique-Character-In-A-String | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Hamming-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  | strings/Ada/Hamming-Distance |  |
| strings/SPARK2/Ada-SPARK-Isomorphic-Strings | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| strings/SPARK2/Ada-SPARK-Knuth-Morris-Pratt | yes | yes | yes | yes | yes | 0 | 0 | proven | 21 |  | strings/Ada/Knuth-Morris-Pratt |  |
| strings/SPARK2/Ada-SPARK-Longest-Common-Prefix | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Longest-Common-Subsequence | yes | yes | yes | yes | yes | 0 | 0 | tool crash |  |  | strings/Ada/Longest-Common-Subsequence |  |
| strings/SPARK2/Ada-SPARK-Make-The-String-Great | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| strings/SPARK2/Ada-SPARK-Multiply-Strings-Lite | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Multiply-Strings-Stub | yes | yes | yes | yes | yes | 0 | 0 | proven | 62 (1) |  |  |  |
| strings/SPARK2/Ada-SPARK-Number-Of-Lines-To-Write-String | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| strings/SPARK2/Ada-SPARK-One-Edit-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | 13 |  |  |  |
| strings/SPARK2/Ada-SPARK-Permutation-In-String | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 3 |  |  |  |
| strings/SPARK2/Ada-SPARK-Rabin-Karp | yes | yes | yes | yes | yes | 0 | 0 | proven | 22 (2) |  | strings/Ada/Rabin-Karp |  |
| strings/SPARK2/Ada-SPARK-Remove-All-Adjacent-Duplicates-In-String | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| strings/SPARK2/Ada-SPARK-Reorganize-String | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Reorganize-String-Stub (stub) | yes | yes | yes | yes | yes | 1 | 1 | proven | 5 |  |  |  |
| strings/SPARK2/Ada-SPARK-Repeated-String-Match | yes | yes | yes | yes | yes | 0 | 0 | proven | 24 (8) |  |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-String | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-String-II | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-Vowels-Of-A-String | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-Reverse-Words-In-A-String-III | yes | yes | yes | yes | yes | 0 | 0 | proven | 23 |  |  |  |
| strings/SPARK2/Ada-SPARK-Rotate-String | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  | strings/SPARK2/Ada-SPARK-String-To-Integer-Atoi (near-identical) |
| strings/SPARK2/Ada-SPARK-Sum-Of-Digits-Of-String-After-Convert | yes | yes | yes | yes | yes | 0 | 0 | proven | 13 |  |  |  |
| strings/SPARK2/Ada-SPARK-Total-Hamming-Distance | yes | yes | yes | yes | yes | 0 | 0 | proven | 6 |  |  |  |
| strings/SPARK2/Ada-SPARK-Z-Algorithm | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| strings/SPARK2/Add-Strings | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| strings/SPARK3/Levenshtein-Distance | yes | yes | yes | yes | yes | 0 | 0 | 3 unproved |  |  | strings/Ada/Levenshtein-Distance |  |
| trees/Ada/Abstract-Interpretation | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| trees/Ada/Abstract-Syntax-Tree | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| trees/Ada/Context-Tree-Weighting | yes | yes | yes | yes | yes | 5 | 5 | no SPARK |  |  |  |  |
| trees/Ada/Decision-Trees | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  |  |  |
| trees/Ada/Embedded-Zerotree-Wavelet | yes | yes | yes | yes | yes | 30 | 30 | no SPARK |  |  |  |  |
| trees/Ada/Longest-Common-Substring | yes | yes | yes | yes | yes | 0 | 0 | no SPARK |  |  | trees/SPARK2/Ada-SPARK-Longest-Common-Substring |  |
| trees/Ada/Red-Black-Tree | yes | yes | yes | yes | yes | 3 | 3 | no SPARK |  |  | trees/SPARK2/Ada-SPARK-Red-Black-Tree |  |
| trees/Ada/Set-Partitioning-In-Hierarchical-Trees | yes | yes | yes | yes | yes | 40 | 40 | no SPARK |  |  |  |  |
| trees/SPARK2/Ada-SPARK-BST-Iterator-Stub (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven | 13 |  |  |  |
| trees/SPARK2/Ada-SPARK-Balanced-Binary-Tree | yes | yes | yes | yes | yes | 0 | 0 | proven | 52 (withdrawn: lenient Spec_Balanced / Is_Balanced, see checker_scan.csv) |  |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Inorder | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Level-Order | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Max-Depth | yes | yes | yes | yes | yes | 1 | 1 | proven | 20 |  |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Min-Depth | yes | yes | yes | yes | yes | 1 | 1 | proven | 20 |  |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Paths | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Postorder | yes | yes | yes | yes | yes | 0 | 0 | proven | 21 |  |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Preorder | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| trees/SPARK2/Ada-SPARK-Binary-Tree-Right-Side-View (stub) | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Construct-Binary-Tree-From-Inorder-And-Postorder-Lite | yes | yes | yes | yes | yes | 9 | 9 | proven | 5 |  |  |  |
| trees/SPARK2/Ada-SPARK-Construct-Binary-Tree-From-Preorder-And-Inorder-Lite | yes | yes | yes | yes | yes | 9 | 9 | proven | 5 |  |  |  |
| trees/SPARK2/Ada-SPARK-Convert-BST-To-Greater-Tree | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| trees/SPARK2/Ada-SPARK-Count-Binary-Substrings | yes | yes | yes | yes | yes | 0 | 0 | proven | 12 |  |  |  |
| trees/SPARK2/Ada-SPARK-Count-Complete-Tree-Nodes | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Delete-Node-BST-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| trees/SPARK2/Ada-SPARK-Delete-Node-In-A-BST-Lite | yes | yes | yes | yes | yes | 8 | 8 | proven (trivial) | 1 |  |  |  |
| trees/SPARK2/Ada-SPARK-Diameter-Of-Binary-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven | 25 |  |  |  |
| trees/SPARK2/Ada-SPARK-Find-Mode-In-BST | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Flatten-Binary-Tree-To-Linked-List-Lite (stub) | yes | yes | yes | yes | yes | 2 | 2 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Get-Equal-Substrings-Within-Budget | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| trees/SPARK2/Ada-SPARK-Implement-Trie (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| trees/SPARK2/Ada-SPARK-Insert-Into-BST | yes | yes | yes | yes | yes | 0 | 0 | proven | 53 (8) |  |  |  |
| trees/SPARK2/Ada-SPARK-Invert-Binary-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven | 4 |  |  |  |
| trees/SPARK2/Ada-SPARK-Kth-Smallest-BST-Stub (stub) | yes | yes | yes | yes | yes | 5 | 5 | proven | 11 |  |  |  |
| trees/SPARK2/Ada-SPARK-Leaf-Similar-Trees | yes | yes | yes | yes | yes | 3 | 3 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Longest-Common-Substring | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  | trees/Ada/Longest-Common-Substring |  |
| trees/SPARK2/Ada-SPARK-Longest-Palindromic-Substring | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeat | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 (2) |  |  |  |
| trees/SPARK2/Ada-SPARK-Longest-Substring-Without-Repeating | yes | yes | yes | yes | yes | 0 | 0 | proven | 9 |  |  |  |
| trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-BST | yes | yes | yes | yes | yes | 0 | 0 | proven | 5 |  |  |  |
| trees/SPARK2/Ada-SPARK-Lowest-Common-Ancestor-Of-BST | yes | yes | yes | yes | yes | 0 | 0 | proven | 7 |  |  |  |
| trees/SPARK2/Ada-SPARK-Maximum-Binary-Tree | yes | yes | yes | yes | yes | 7 | 7 | proven (trivial) | 3 |  |  |  |
| trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-Binary-Tree | yes | yes | yes | yes | yes | 0 | 0 | proven | 21 |  |  |  |
| trees/SPARK2/Ada-SPARK-Maximum-Depth-Of-N-Ary-Tree | yes | yes | yes | yes | yes | 9 | 9 | proven (trivial) | 3 |  |  |  |
| trees/SPARK2/Ada-SPARK-Merge-Two-Binary-Trees | yes | yes | yes | yes | yes | 0 | 0 | proven | 8 |  |  |  |
| trees/SPARK2/Ada-SPARK-Minimum-Depth-Of-Binary-Tree | yes | yes | yes | yes | yes | 0 | 0 | proven | 21 |  |  |  |
| trees/SPARK2/Ada-SPARK-Minimum-Height-Trees | yes | yes | yes | yes | yes | 0 | 1 | proven | 10 |  |  |  |
| trees/SPARK2/Ada-SPARK-Minimum-Window-Substring | yes | yes | yes | yes | yes | 0 | 0 | proven | 10 |  |  |  |
| trees/SPARK2/Ada-SPARK-N-Ary-Tree-Level-Order-Traversal | yes | yes | yes | yes | yes | 11 | 11 | proven | 11 |  |  |  |
| trees/SPARK2/Ada-SPARK-N-Ary-Tree-Postorder-Traversal | yes | yes | yes | yes | yes | 12 | 12 | proven | 13 |  |  |  |
| trees/SPARK2/Ada-SPARK-N-Ary-Tree-Preorder-Traversal | yes | yes | yes | yes | yes | 11 | 11 | proven | 11 |  |  |  |
| trees/SPARK2/Ada-SPARK-Number-Of-Substrings-Containing-All-Three-Characters | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  |  |  |
| trees/SPARK2/Ada-SPARK-Range-Sum-BST | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| trees/SPARK2/Ada-SPARK-Range-Sum-Of-BST | yes | yes | yes | yes | yes | 1 | 1 | proven | 14 |  |  |  |
| trees/SPARK2/Ada-SPARK-Red-Black-Tree (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 4 |  | trees/Ada/Red-Black-Tree |  |
| trees/SPARK2/Ada-SPARK-Repeated-Substring-Pattern | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Same-Tree | yes | yes | yes | yes | yes | 0 | 0 | proven | 17 |  |  |  |
| trees/SPARK2/Ada-SPARK-Subtree-Of-Another-Tree | yes | yes | yes | yes | yes | 0 | 0 | proven | 21 |  |  |  |
| trees/SPARK2/Ada-SPARK-Symmetric-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven | 18 |  |  |  |
| trees/SPARK2/Ada-SPARK-Trim-BST-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven | 11 |  |  |  |
| trees/SPARK2/Ada-SPARK-Two-Sum-BST-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Unique-BSTs-Stub (stub) | yes | yes | yes | yes | yes | 0 | 0 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Unique-Paths-With-Obstacles | yes | yes | yes | yes | yes | 0 | 0 | proven | 12 |  |  |  |
| trees/SPARK2/Ada-SPARK-Univalued-Binary-Tree | yes | yes | yes | yes | yes | 1 | 1 | proven (trivial) | 2 |  |  |  |
| trees/SPARK2/Ada-SPARK-Validate-BST-Stub (stub) | yes | yes | yes | yes | yes | 7 | 7 | proven | 19 |  |  |  |
| trees/SPARK2/Average-Of-Levels-In-Binary-Tree | yes | yes | yes | yes | yes | 4 | 4 | proven (trivial) | 3 |  |  |  |
