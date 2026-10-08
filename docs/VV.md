# Verification and validation (V&V) plan

Modelled on the Ada-Terminal-UI approach (one command runs every check and writes one report), scaled to the ~1,840 algorithm folders in this repo. Nothing here runs in CI yet; everything runs locally with `make vv`.

## What `make vv` does

| Stage | What | Tool | Result columns (PROOFS.csv) |
|---|---|---|---|
| 1. Build + tests | `make test` and a uniform `gnatmake -gnatwa -gnat2022 tests.adb` per folder, on GNAT 14 (system) and GNAT 12 (Alire `gnat_native`) | `tools/audit/build_folder.sh` | `make_test`, `build_gnat14/12`, `tests_pass_gnat14/12`, `warnings_gnat14/12` |
| 2. Verification | `gnatprove --mode=silver --level=2 --timeout=0 --steps=N --counterexamples=off -j2` on the folder's own .gpr | `tools/audit/prove_folder.sh` with `AA_PROVE_STEPS=N` | `silver`, `checks`, `functional_checks`, `trivial`, `proof_run` |
| 3a. Validation: differential | Ada and SPARK versions of the same algorithm get the same seeded random inputs; any differing output is flagged | `tools/vv/difftest.py` | `diff_test` |
| 3b. Validation: known answers | published standard vectors (RFC, NIST, OEIS) in each folder's `tests.adb`, registered with their source | `tools/vv/kat_registry.csv` | `kat` |
| 3c. Validation: mutation | a seeded sample of folders; a few operators per folder are mutated one at a time; the tests must fail | `tools/vv/mutate.py` | `mutation` |
| 3d. Validation: do-nothing check | each public subprogram gets a trivial body (identity / constant / zero-filled result) in a scratch copy; the tests must notice when the main one does nothing | `tools/vv/donothing.py` | `do_nothing` |
| 3e. Validation: own tests | self-written property checks and brute-force references (`own_checks.adb`, `tests/SOURCES.txt`), never the program's own output | `tools/vv/own_tests.csv` | `own_tests`, `known_answer` |
| 4. Report | `PROOFS.md` (summary, V&V section) and `PROOFS.csv` (one row per folder) | `tools/proof_index.py` | - |

Step budgets (`--steps`) instead of wall-clock timeouts make proof results independent of machine load: the same tree gives the same verdicts on any machine.

```sh
make vv                                   # everything (hours: ~1,840 builds x 2 compilers, ~1,500 proofs)
make vv VV_IDS=ids.txt VV_JOBS=8          # a subset, more parallel
make vv-validate                          # stage 3 only, then refresh the index from existing results
VV_SKIP="build prove" VV_MUT_SAMPLE=50 tools/vv/run_vv.sh
```

Knobs: `VV_OUT` (results dir, default `/tmp/vv`), `VV_JOBS`, `VV_STEPS` (default 1,000,000), `VV_SKIP`, `VV_SEED` (default 20261008), `VV_MUT_SAMPLE`, `VV_MUT_PER`.

## 3a. Differential testing (Ada <-> SPARK pairs)

The index pairs 110 Ada folders with SPARK counterparts. Their APIs differ (unconstrained vs bounded arrays, `Float` vs integers, extra variants), so every pair needs a small adapter. Each adapter is two drivers that speak the same text protocol, so the two sides never have to link together (many pairs use the same package name):

```
tools/vv/diff/<Pair>/pair.json            {"ada": ..., "spark": ..., "gen": "array:MINLEN:MAXLEN:LO:HI", "cases": N}
tools/vv/diff/<Pair>/vv_ada_driver.adb    stdin: one case per line (count, values); stdout: one result per line
tools/vv/diff/<Pair>/vv_spark_driver.adb  same, calling the SPARK package
```

The generator puts edge values first (`LO`, `HI`, 0, neighbours), then small values, then uniform random values, all from `random.Random("<seed>:<pair>")`, so a run can be repeated exactly. Drivers are built with `-gnata`, so contract violations on either side show up as crashes. Pairs that compute different things on purpose can carry `known_difference` in `pair.json` and are reported as `DISAGREE (known)` (none at the moment; Pearson-Hashing had one until its SPARK twin got the real 256-entry table).

Adding a pair takes 10-20 minutes: copy a similar pair, adjust the two call sites and the generator. Inputs are limited to the SPARK side's bounds (e.g. 4 or 8 elements), which keeps the comparison honest but narrow. Pairs with `Float` outputs need a tolerance (not implemented yet).

Status (2026-10-08): 74 of the 117 Ada <-> SPARK pair edges have adapters (67 of the 110 paired Ada folders; some Ada folders have two SPARK twins), 1,000 seeded cases each (seed 20261008). all 74 agree on every case after the two fixes below (first run: 72 agree, 2 disagree):

* `Sort-Library-Sort` (fixed): 6/1000 cases where the Ada `Library_Sort.Sort` returned an unsorted permutation. Cause: when no gap was left at or after the insertion point, `Try_Insert` shifted the run up to and including `W (Pos)` one slot left and put X at `Pos`, i.e. behind an element >= X. Now the run before `Pos` moves left and X goes to `Pos - 1`. The 6 inputs are regression tests in the folder; the pair agrees on all 1,000 cases.
* `Run-Length-Encoding` (fixed): 32/1000, all the empty input: Ada 0 runs, SPARK 1, because `Run_Count` started at 1. `Run_Count` is now `Natural range 0 .. Max_Length`, the empty input returns 0, and a postcondition says 0 for empty / `1 .. Input'Length` otherwise (proved, Silver level 2). The pair agrees on all 1,000 cases.

Covered: the 10 earlier pairs; all 40 sorting pairs (`Sort-*`; SPARK2 twins use their fixed 8-element arrays, SPARK4 twins `1 .. Max_N`); searching (Binary, Jump, Interpolation, Fibonacci, Ternary, Linear search: the "any index" `Find`s are compared as found/absent with the hit checked, `Find_First`/`Find_Last`/linear `Find` by index) and selection (Quickselect, Introselect, Selection-Algorithm: k-th smallest + median); strings (Levenshtein, Damerau-Levenshtein (both OSA), LCS length, KMP prefix table, Boyer-Moore first match, Rabin-Karp found, Hamming distance); numerical (Extended-Euclidean x2 incl. the Bezout coefficients, Sieve, Mersenne-Twister outputs 1, 2, 624, 625, 1300 per seed); RLE run count; Floyd-Warshall (4x4) and Bellman-Ford (4 nodes, 16 non-negative edges); Package-Merge (weighted code length of both Ada variants vs the SPARK one, 2 .. 32 symbols, L from the feasible minimum to 16). Outputs are compared token by token (Ada `'Image` glues negative numbers together; `"-3-1"` equals `"-3 -1"`). The full run takes about 35 minutes with `-j 5`, almost all of it `Sort-Counting-Sort`: its SPARK twin's ghost contracts, checked under `-gnata`, cost about 1 s per case. Cases run in chunks of 50 (a crash re-runs only its chunk case by case) and pairs in parallel (`difftest.py -j`).

Not covered yet (43 edges), by obstacle: `Float` results that need a tolerance (Point-In-Polygon, Gaussian-Elimination, Bisection, Brent, Secant, FFT, Lagrange; Dice-Coefficient's SPARK twin scores 3-bit vectors instead of bigrams); graph APIs with private graph types or records (A-Star, Dijkstra, Best-First, Uniform-Cost, Kruskal, Prim, Floyd cycle finding, Topological-Sort, Connected-Component-Labeling, Flood-Fill); generators and shuffles with differing parameter sets (ACORN, Blum-Blum-Shub, Lagged-Fibonacci, LCG, Fisher-Yates); stateful structures and simulations (Bloom filter, Buddy allocator, Mark-and-Sweep, Reference-Counting, Red-Black-Tree, Sorted-List, Banker's, Elevator, Lemke-Howson); SPARK twins that expose only a helper or a different slice of the algorithm (Burrows-Wheeler rotations, MD5 padding length, Zobrist, Hamming-Code, Top-Nodes, Trigram-Search, Longest-Common-Substring, Heap's algorithm, K-Way-Merge, Burstsort, Sort-Merge-Join). These need bigger adapters, not more runtime.

## 3b. Known-answer vectors

A known-answer vector is an expected value from an outside source whose licence fits the repository's MIT licence: RFC and NIST test vectors (hashes, checksums, ciphers), OEIS terms (integer sequences), values that follow directly from arithmetic (exact powers). Not used: Rosetta Code, LeetCode, Wikipedia text, and GPL/GFDL sources. `tools/vv/kat_registry.csv` records `folder, source, where`; the `kat` column shows the source. A registry entry is only added after checking that the vector is really in the tests and passes. The registry currently lists 2 folders (Count-And-Say-Stub: OEIS A005150/A005341; Pow-X-N-Stub: exact powers). Two earlier pilot entries cited LeetCode examples; Nth-Digit-Stub and Multiply-Strings-Stub now have own tests instead (3e) and the LeetCode rows were removed. Older tests elsewhere in the repository may still contain such examples; they are not counted as known answers.

## 3c. Mutation testing (sampled)

`tools/vv/mutate.py` takes a seeded sample of folders with a `tests.adb`, finds operator sites in the non-test `.adb` files (`+ -`, `< <=`, `> >=`, `= /=`, `and then / or else`, `*`, `+ 1 / - 1`), skips comments, strings and pragmas (including multi-line loop invariants and assertions), and applies up to K mutations one at a time in a scratch copy. Each mutant is rebuilt (GNAT 14, `-gnat2022 -gnata`) and the tests are run: `killed` (non-zero exit, a `FAIL` line, an exception, or a hang), `survived` (tests still pass), or `stillborn` (does not compile; not counted). Score = killed / (killed + survived). Per-mutant details go to `vv/results/mutation_detail.csv`.

Surviving mutants are leads, not verdicts: some are equivalent (for example changing the rolling-hash multiplier in Rabin-Karp still finds every match, because each hash hit is confirmed by a string compare), others show real gaps in the tests (for example no test that would notice `Len /= 0` flipped in the KMP prefix table). A full run on all folders would mean roughly 1,840 x 8 rebuilds; the sample keeps it to minutes.

Status (2026-10-08): 12 random folders x 8 mutants: 66 killed, 19 survived (77%); Chinese-Whispers now runs (7/8) since its tests accept the `-gnata` precondition failure. Pilot set (5 generalised stubs + KMP, Rabin-Karp, Package-Merge, same seed): `vv/results/mutation_pilot.csv`. All operator sites for the two folders whose test gaps were closed: `vv/results/mutation_sites_all.csv`.

* KMP: sample 6/8 -> 8/8, all sites 9/11 -> 11/11 (new tests: textbook prefix tables and every A/B pattern up to length 10, A/B/C up to 7, against the definition).
* Package-Merge: all sites 68/101 -> 70/101; sample unchanged at 2/7 because the 5 sampled survivors are equivalent: `Top < Max_Nodes` -> `<=` / `or else` (capacity guards that valid inputs never reach), insertion sort `>` -> `>=` (tie order only; costs equal), `Safe_Add` `- B` -> `+ B` (no package weight exceeds the sum of all frequencies, so saturation never triggers), and `Weight_Value` range `*` -> `+` (saturated package weights stay in nondecreasing order, so the merge picks the same items; 7,000 random cases with weights up to `Max_Freq` gave identical lengths). Most of the remaining 31 all-site survivors are in contracts of internal subprograms or in capacity guards.

## 3d. Do-nothing check

Question asked of every folder's tests: would they notice if the code did nothing? `tools/vv/donothing.py` takes each public subprogram (declared in a non-test `.ads`, body in the matching `.adb`) and, one at a time in a scratch copy, replaces its body with the most trivial thing that compiles: `null;` for procedures (so `in out` data comes back unchanged), `return False` / `return True` for Boolean functions, otherwise the first parameter of the result type (identity), a default object (scalars zero-filled through `pragma Initialize_Scalars` and `gnatbind -S00`) or `[]`. Postconditions, contract cases and type invariants are switched off, so the tests and not the spec have to notice; preconditions and the tests' own `pragma Assert` stay on (`-gnata`). Folders whose unmodified tests fail under `-gnata` but pass without it (the stage-1 build does not use `-gnata`) are checked without it (column `gnata` = `no`).

The *main* subprogram is picked heuristically: the public one that takes input and whose name shares a word with the folder name (`Sort`, `Run_Chinese_Whispers`), or an entry point (`Solve`, `Run`, ...), else the one the tests mention most. Container and test plumbing comes last unless its name matches the folder: `Append`, `Get`, `Empty`, tree and graph accessors (`Set_Node`, `Node_Value`, `Left_Child`, `Add_Edge`, `Edge_Count`, `Vertex_Count`), `Get_*`, `Set_*`, `Seed_*`, `Default_*` and set-up helpers such as `Seed_RNG` and `Start_Point`. Boolean predicates count only when nothing else is called or when the predicate is the algorithm itself (`Is_Balanced`). A folder is flagged `weak` when the do-nothing version of its main subprogram still passes the tests; survivors among the other subprograms are listed in `vv/results/donothing_detail.csv` for information. `unchecked` means no trivial body of the main subprogram compiles (e.g. limited or private result types).

Main-pick change (2026-10-08): the 56 folders whose recorded main was such a helper (23 x `Add_Edge`, 6 x `Seed_RNG`, `Set_Node`, `Node_Value`, `Start_Point`, ...) were rerun; 45 picks changed (e.g. Balanced-Binary-Tree `Set_Node` -> `Is_Balanced`, the max-flow folders `Add_Edge` -> `Max_Flow`), all to `ok`; D-Star and Evolutionary-Computation went from weak to ok (the weak verdict was on `Start_Point` / `Seed_RNG`). Optimiser change (2026-10-08): test fitness functions (`Sphere`, `Rosenbrock`, `Ones_Count`, `All_Ones`, ...) and `Fitness_*` / `Cost_*` helpers are now plumbing and `Minimize*` / `Maximize*` / `Optimize*` count as entry points; 19 picks changed (e.g. Cross-Entropy-Method -> `Minimize_Isotropic`, Genetic-Algorithm -> `Maximize_OneMax`, Harmony-Search -> `Minimize_Box`, ILP -> `Maximize_LP`), all to `ok`; Gradient-Descent went from weak to ok. Folders not rerun keep the earlier pick; the refinement only affects folders whose recorded main is plumbing.

Status (2026-10-08; full run over 1,837 folders with GNAT 14, then reruns of changed folders): 1,707 checked (1,648 ok, 35 weak, 24 unchecked); 122 of the checked folders only without `-gnata`; not checked: 94 whose unmodified tests fail in the scratch build, 15 whose tests do not build there, 21 without tests. None of the weak folders is Silver-proven non-trivial. Every folder that got own tests (3e) or a fix (3f) is `ok` afterwards. Results: `vv/results/donothing.csv` (one row per folder) and `vv/results/donothing_detail.csv` (one row per subprogram variant). A full run over ~1,800 folders took about 25 minutes with `-j 6` (GNAT 14 only).

Weak folders, by topic:
* concurrency/SPARK2: Course-Schedule (`Can_Finish`).
* cryptography/Ada: RSA (`To_RSA`).
* geometry/Ada: Vatti (`Vatti_Intersection`).
* graphs/Ada: Floyd-Warshall-Algorithm (`Floyd_Warshall`).
* graphs/SPARK2: Clone-Graph (`Clone`), Clone-Graph-Stub (`Clone`).
* matrices/Ada: Sparse-Matrix (`Sparsity`).
* misc/Ada: Banzhaf-Power-Index (`Normalized_Banzhaf`), Cheneys-Algorithm (`Allocate`), Elser-Difference-Map-Algorithm (`Solve`), Johnsons-Algorithm (`Johnson`), Mullers-Method (`Find_Root`), Nagles-Algorithm (`Original_Nagle`), Recovery-Exploiting-Semantics (`Log_Update`), SEQUITUR-Algorithm (`Compress`), Unicode-Collation-Algorithm (`Compare_Standard`).
* misc/SPARK2: Alien-Dictionary-Stub (`Is_Valid`), Assign-Cookies (`Assigned_Count`), Candy (`Candy_Count`), Find-The-City (`Find`), Fisher-Yates-Shuffle (`Shuffle`), Flatten-Nested-List-Stub (`Flatten`), Gas-Station (`Starting_Station`), Guess-Number-Higher-Or-Lower (`Guess_Number`), Jump-Game-II (`Minimum_Jumps`), Merge-Intervals (`Merged_Intervals`), My-Linked-List-Stub (`Length_Of`), Non-Overlapping-Intervals (`Kept_Intervals`), Valid-IP-Address-Stub (`Is_Valid`).
* numerical/Ada: Fermat-Primality-Test (`Is_Fermat_Probable_Prime`), Hybrid-Monte-Carlo (`Grad_U_Std_Normal`).
* parsing/Ada: Cyk-Algorithm (`Free_Parse_Tree`).
* searching/SPARK2: Insert-Into-A-Binary-Search-Tree (`Insert`), Unique-Binary-Search-Trees-II-Lite (`Root_Choices`).
* sorting/SPARK2: Find-Minimum-In-Rotated-Sorted-Array (`Minimum`).

For these the trivial body passes the folder's existing checks; they need tests whose expected answer differs from the trivial result. Among the plain Ada ones some picks are still helpers rather than the algorithm (`Sphere_Grad`, `Grad_U_Std_Normal`, `Free_Parse_Tree`), so there the flag only says that this helper is untested.

## 3e. Own tests

For Silver-proven non-trivial folders without a twin or a known-answer vector, we wrote our own tests, starting from the largest categories (sorting, strings, trees, searching, numerical, compression, then common misc exercises). The rule: assume the code is broken or does nothing, then show that it is not. Expected values come only from

* properties of the result (sorted + permutation of the input, invariants such as BST order, bounds, round trips where an inverse exists);
* small brute-force references written by us in the test (insertion sort, recursive edit distance, exhaustive enumeration of substrings / subsets / trees);
* exhaustive checks where the input space is small (all 0/1 arrays of length 8 for the sorts, all 3,125 samples for Mean-Variance, all string pairs or triples up to length 4 for Longest-Common-Substring and Interleaving-String), and many short random strings over two- or three-letter alphabets so that repeats and ties are common.

Never from the program's own current output, and nothing from Rosetta Code, LeetCode, Wikipedia text or GPL/GFDL sources. Random inputs come from the Park-Miller minimal standard generator (16807 mod 2**31-1, seed 20261008), written inline, so every run is the same. Where a README leaves a convention open (does depth count nodes or edges, are range bounds inclusive), only convention-independent properties are tested, e.g. the one-node tree fixes the convention, and odd range bounds with even node values make inclusivity irrelevant.

Each folder has its own checks in `tests/own_checks.adb` (called from its test main) or in the test main itself, and `tests/SOURCES.txt`, which states where every expected value comes from. `tools/vv/own_tests.csv` lists the folders and checks; the index shows them in column `own_tests`. A folder has a *known answer* (column `known_answer`) when it has a registered vector, own tests or an agreeing differential test, and the do-nothing check did not flag it weak; `training_ready` now requires a known answer.

Status (2026-10-08): 198 folders (83 misc, 35 sorting, 31 trees, 16 strings, 8 numerical, 6 searching, 5 compression, 4 matrices, 3 hashing, 2 ml, 2 graphs, 2 geometry, 1 logic); all pass on GNAT 14 and GNAT 12 and all are `ok` in the do-nothing check. `own_checks.adb` has no `SPARK_Mode`, so it is not proved. Where a project lists its source files, it is outside the project (three build projects now name it explicitly so `make test` still builds); for the 44 own-test folders whose proof project takes every source in the folder, the Silver proof was rerun with the new tests in place and gives the same result as before.

Findings made while writing them are in the registry (3f); all of them are fixed except where 3f says otherwise.

## 3f. Findings registry

`tools/vv/findings.csv` lists every wrong answer, undocumented behaviour or broken `make test` found by the checks above, with columns `folder`, `description`, `status` (open / fixed), `test_commit` and `fix_commit`. A folder with an open finding is never training-ready. Fixes are test-first: one commit adds a test that fails on the old code (its message says so), the next commit fixes the code; where the old behaviour was not clearly a bug against the standard problem statement it is documented in the folder README instead. Touched SPARK folders are re-proved (Silver, level 2, step budget); where cheap, a postcondition that would have caught the bug was added (Jump-Game, Newton-Raphson, Repeated-String-Match, Balanced-Binary-Tree, both BST insert folders, Remove-Duplicates-II, Parity-II, Pascal-Triangle, Decode-Ways, Squares, Min-Cost-Climbing-Stairs, Sort-Characters-By-Frequency, Basic-Calculator-II, Find-The-Smallest-Divisor, Maximum-Ice-Cream-Bars). Not added because they did not prove at level 2 in reasonable time or need a ghost model: Range-Sum-BST (functional sum), permutation for Squares / Parity-II / Sort-Characters, order for Remove-Duplicates-II, completeness of BST `Contains`, Max-Product-Subarray (maximum over all subarrays), the length of Partition-List.

Status (2026-10-08): 38 findings, all fixed. Silent no-op scan (`tools/vv/silent_noop.csv`, first pass over Silver-proven non-stub folders): 122 operations classified, 64 legitimate (Pre in the spec, an out status, a raise, or a base case with a defined answer), 33 legitimate by the scanner, 24 silent-failure candidates, 1 needing review; fixed so far: Min-Stack (Pre). The first-pass commit message (da9de299) gave 62 / 34 / 25 / 1; these counts are the correct ones. Random sample (`tools/vv/sample_30.txt`, seed 20261008, picked before testing; outcomes in `tools/vv/sample_30_results.csv`): 3 bugs in 30 (3 of the 29 testable), Palindrome-Partitioning (`Minimum_Cuts` gave N - 1 for every non-palindrome), Queue-Using-Stacks (full/empty operations silently ignored; now preconditions) and Linear-Regression (mean and slope truncated separately, up to about 2.6 off); 26 pass; trees/SPARK2/Ada-SPARK-Red-Black-Tree is not testable (a self-described stub the index did not mark as one). New this round (all from own tests except the first): Cooley-Tukey-FFT (see 3g); Matrix-Cells-In-Distance-Order (`Order_From` ignored the origin); Gaussian-Elimination SPARK2 (lost the second equation on a zero pivot; now swaps rows); Add-Binary (wrote 0 for 1 + 1 + carry); Broken-Calculator (returned |Start - Target| instead of counting double / decrement operations); Car-Pooling (ignored the trip stops); 3Sum-Closest (answered fewer than three values with 0; now rejected by subtype); Combination-Sum-III (`Count_Choices` returned 1 for every feasible case); Beautiful-Arrangement (accepted values above N).

Update (2026-10-08, later): 65 findings, all fixed (62-65: Middle-Of returned the first middle and 0 for an empty list; Covariance centred on 5, not the means; Lempel-Ziv-Ross-Williams overflow; Prediction-By-Partial-Matching did not compile). Earlier in this update: 61 findings, all fixed (60: Prims-Algorithm chose the first reachable node, not the one with the smallest key; 61: Design-Number-Container-System ignored a full Add and answered 0 from an empty Remove_Last, a silent no-op the textual scan missed; both from own tests, fixed). Every silent no-op candidate is now resolved: the 15 linked-list folders sharing one `Append` scaffold (earlier counted as 17 by mistake) get `Pre => Length (L) < Count'Last` with `pragma Assertion_Policy (Pre => Check)` in the spec, fixed the same way in all 15 after the near-duplicate check below; LRU-Cache-Lite and LFU-Cache-Lite evict for real (least recently used; least frequently used, ties to the least recent), checked against own models; Design-Add-And-Search-Words and Implement-Trie require a free slot (Pre; Trie insertion of a word already present is idempotent). Re-proving Merge-Two-Sorted-Lists after the `Append` fix showed that `Merge` cut results longer than 16 short; it now requires `Length (A) + Length (B) <= 16` and promises the full length. Remove-Element returned a length one short on a full array whose last element was kept (own test; fixed). The tally in `silent_noop.csv`: 98 legitimate (65 by hand, 33 by the scanner), 23 silent failures fixed, 1 other bug fixed.

Stubs: 39 folders whose README calls them a stub are marked `stub` (`tools/readme_stubs.txt`), including 8 sorting folders that are the same adjacent compare-exchange passes. A hidden-stub scan over the Silver-proven folders (README wording, code far below the category median, missing core step; `tools/vv/hidden_stub.csv`, 38 rows with a verdict after a hand look) confirmed 18 more (Fixed-Point-Iteration added later; for example 8 sorts that are bubble sort and a trie stored as a flat word list); they are marked too and not rewritten. Prims-Algorithm was not a stub but wrong (it picked the first reachable unused vertex, not the minimum key); now finding 60, fixed.

Near-duplicates: `tools/vv/near_dup_lists.csv` compares the 15 list folders pairwise after normalising identifiers, whitespace and comments. 11 pairs have token similarity >= 0.85 across the whole file, but only through the shared list scaffold; the main operations reach at most 0.771. They are 15 different algorithms, so `tools/vv/copy_of.csv` (index column `copy_of`) is empty. Nothing was moved or deleted.

## 3g. Saturation scan

Capped arithmetic can make a proof of absence of run-time errors pass while the answer is silently wrong. `tools/vv/saturation.csv` lists every hit of `X'Last` / `X'First` assigned or returned, `'Min (..., X'Last)`, `if A > Max - B then` guards and saturating helpers (`Add_Bounded`, `Clamp`, ...) in the non-test sources of the Silver-proven folders, with a verdict per hit: `silent-wrong-answer`, or `legitimate` with the reason (array bound, identity of a minimum search, infinity sentinel, cursor end, or a cap that the input types make unreachable, e.g. Fib(32) fits).

Status (2026-10-08): 932 Silver-proven folders scanned, 228 hits in 107 folders; 210 legitimate, 18 silent-wrong-answer in 4 folders: Basic-Calculator-II (results clamped to +-1000), Max-Product-Subarray (products capped at 100,000), Find-The-Smallest-Divisor (an infeasible limit answered with 1000) - all three fixed with a tighter input subtype, test-first - and Cooley-Tukey-FFT (butterflies clamped into `Sample`; fixed: inputs limited to +-212 and a per-stage bound proved, 212 -> 424 -> 848 -> 2047, the last stage allowing the sqrt(2) growth of the 45-degree twiddles). Maximum-Ice-Cream-Bars was first flagged, then classed legitimate: the cap is the stock of 32 bars, now documented with a postcondition. Earlier fixes of the same kind: Pascal-Triangle, Decode-Ways, Min-Cost-Climbing-Stairs, Range-Sum-BST, Bst-Insert-Search, Parity-II, Run-Length-Encoding. The scan is textual: guards written differently (e.g. `if Write < Capacity then` around an append) are not matched.

## 3h. All-checks crash run (plain Ada)

`tools/vv/checks_on.py` copies every plain-Ada folder (908, duplicates counted once) to a scratch directory. There it builds the test main and every other main listed in the folder's project with all run-time checks on (`-gnat2022 -gnata -gnato -gnatVa -g`, GNAT 14), then runs each with a 20 s timeout. The folders' own files and Makefiles are not changed. A program that does not build as Ada 2022 is retried as Ada 2012 with the same checks. A run stopped by a failed precondition is repeated with preconditions ignored and every other check on (column `pre_ignored`). Each row of `tools/vv/checks_on.csv` has a hand classification.

Status (2026-10-08): 979 programs in 901 folders (889 test mains, 90 other mains); 7 more folders have neither. 9 programs needed the Ada 2012 fallback.
- 836 ok. A rerun for the fixed folder is included.
- 129 Assertion_Error. 104 of these pass with preconditions ignored: the test violates a precondition on purpose to reach a defensive raise. In most of the rest the test catches the precondition failure and reports "wrong exception". Both are harness artefacts.
- 8 not built. 7 of these fail the normal build too: RC4, Entropy-Coding, Lulea, Photon-Mapping, Quantum-Artificial-Life and Richardson-Lucy are still open; PPM is fixed.
- 3 test failures, 2 Program_Error, 1 timeout, all harness artefacts. Backtracking is slow, not hung.
- 1 Constraint_Error, a real bug: Lempel-Ziv-Ross-Williams overflowed on inputs indexed from `Stream_Element_Offset'First`, which is what every positional aggregate gets, its own `main.adb` included. Fixed by sliding inputs to 1-based buffers.
- A second real defect came from the not-built list: Prediction-By-Partial-Matching did not compile, so its `make test` always failed. Fixed.
- Asymetric-Public-Key-Encryption's test reads an unassigned out parameter (a test bug).
- Association-Rule-Learning test 11.3 also fails in the normal build; it needs review.

Many plain-Ada test mains end with `pragma Assert (Fail_Count = 0)`, and their Makefiles do not pass `-gnata`. In a normal build such a test reports failures but still exits 0. The crash run shows that every such run fails only on contract-versus-defensive-raise checks.

## Not done yet

* CI / GitHub Actions (deliberately not added).
* Adapters for the remaining 43 pair edges (see 3a); `Float` tolerance in the comparison.
* Known-answer vectors (RFC / NIST / OEIS) beyond the 2 registered folders; own tests (3e) for the remaining Silver non-trivial folders without a twin.
* The do-nothing check for the 94 + 15 folders whose unmodified tests fail or do not build in its scratch build.
* GNAT 12 for the differential, mutation and do-nothing stages (they use GNAT 14 only; stage 1 covers both compilers).
