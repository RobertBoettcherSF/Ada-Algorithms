# Verification and validation (V&V) plan

Modelled on the Ada-Terminal-UI approach (one command runs every check and writes one report), scaled to the ~1,840 algorithm folders in this repo. Nothing here runs in CI yet; everything runs locally with `make vv`.

## What `make vv` does

| Stage | What | Tool | Result columns (PROOFS.csv) |
|---|---|---|---|
| 1. Build + tests | `make test` and a uniform `gnatmake -gnatwa -gnat2022 tests.adb` per folder, on GNAT 14 (system) and GNAT 12 (Alire `gnat_native`) | `tools/audit/build_folder.sh` | `make_test`, `build_gnat14/12`, `tests_pass_gnat14/12`, `warnings_gnat14/12` |
| 2. Verification | `gnatprove --mode=silver --level=2 --timeout=0 --steps=N --counterexamples=off -j2` on the folder's own .gpr | `tools/audit/prove_folder.sh` with `AA_PROVE_STEPS=N` | `silver`, `checks`, `functional_checks`, `trivial`, `proof_run` |
| 3a. Validation: differential | Ada and SPARK versions of the same algorithm get the same seeded random inputs; any differing output is flagged | `tools/vv/difftest.py` | `diff_test` |
| 3b. Validation: known answers | published vectors (RFCs, OEIS, textbook / LeetCode examples) in each folder's `tests.adb`, registered with their source | `tools/vv/kat_registry.csv` | `kat` |
| 3c. Validation: mutation | a seeded sample of folders; a few operators per folder are mutated one at a time; the tests must fail | `tools/vv/mutate.py` | `mutation` |
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

Status (2026-10-08): 74 of the 117 Ada <-> SPARK pair edges have adapters (67 of the 110 paired Ada folders; some Ada folders have two SPARK twins), 1,000 seeded cases each (seed 20261008). 72 agree on every case; 2 disagree (findings, not fixed):

* `Sort-Library-Sort` (fixed): 6/1000 cases where the Ada `Library_Sort.Sort` returned an unsorted permutation. Cause: when no gap was left at or after the insertion point, `Try_Insert` shifted the run up to and including `W (Pos)` one slot left and put X at `Pos`, i.e. behind an element >= X. Now the run before `Pos` moves left and X goes to `Pos - 1`. The 6 inputs are regression tests in the folder; the pair agrees on all 1,000 cases.
* `Run-Length-Encoding`: 32/1000, all the empty input. Ada `Encode_Binary` gives 0 runs, SPARK `Number_Of_Runs` gives 1 (its result subtype `Run_Count` starts at 1, so the contract cannot say 0). All non-empty inputs agree.

Covered: the 10 earlier pairs; all 40 sorting pairs (`Sort-*`; SPARK2 twins use their fixed 8-element arrays, SPARK4 twins `1 .. Max_N`); searching (Binary, Jump, Interpolation, Fibonacci, Ternary, Linear search: the "any index" `Find`s are compared as found/absent with the hit checked, `Find_First`/`Find_Last`/linear `Find` by index) and selection (Quickselect, Introselect, Selection-Algorithm: k-th smallest + median); strings (Levenshtein, Damerau-Levenshtein (both OSA), LCS length, KMP prefix table, Boyer-Moore first match, Rabin-Karp found, Hamming distance); numerical (Extended-Euclidean x2 incl. the Bezout coefficients, Sieve, Mersenne-Twister outputs 1, 2, 624, 625, 1300 per seed); RLE run count; Floyd-Warshall (4x4) and Bellman-Ford (4 nodes, 16 non-negative edges); Package-Merge (weighted code length of both Ada variants vs the SPARK one, 2 .. 32 symbols, L from the feasible minimum to 16). Outputs are compared token by token (Ada `'Image` glues negative numbers together; `"-3-1"` equals `"-3 -1"`). The full run takes about 35 minutes with `-j 5`, almost all of it `Sort-Counting-Sort`: its SPARK twin's ghost contracts, checked under `-gnata`, cost about 1 s per case. Cases run in chunks of 50 (a crash re-runs only its chunk case by case) and pairs in parallel (`difftest.py -j`).

Not covered yet (43 edges), by obstacle: `Float` results that need a tolerance (Point-In-Polygon, Gaussian-Elimination, Bisection, Brent, Secant, FFT, Lagrange; Dice-Coefficient's SPARK twin scores 3-bit vectors instead of bigrams); graph APIs with private graph types or records (A-Star, Dijkstra, Best-First, Uniform-Cost, Kruskal, Prim, Floyd cycle finding, Topological-Sort, Connected-Component-Labeling, Flood-Fill); generators and shuffles with differing parameter sets (ACORN, Blum-Blum-Shub, Lagged-Fibonacci, LCG, Fisher-Yates); stateful structures and simulations (Bloom filter, Buddy allocator, Mark-and-Sweep, Reference-Counting, Red-Black-Tree, Sorted-List, Banker's, Elevator, Lemke-Howson); SPARK twins that expose only a helper or a different slice of the algorithm (Burrows-Wheeler rotations, MD5 padding length, Zobrist, Hamming-Code, Top-Nodes, Trigram-Search, Longest-Common-Substring, Heap's algorithm, K-Way-Merge, Burstsort, Sort-Merge-Join). These need bigger adapters, not more runtime.

## 3b. Known-answer vectors

Each folder's `tests.adb` should contain at least one vector from an outside source: RFC test vectors (hashes, checksums, ciphers), OEIS terms (integer sequences), textbook / Wikipedia worked examples, LeetCode examples. `tools/vv/kat_registry.csv` records `folder, source, where`; the `kat` column shows the source. A registry entry is only added after checking that the vector is really in the tests and passes. Targets, in order: cryptography and hashing (RFC vectors exist for almost all), compression (round trips + published examples), numerical (OEIS), then the rest. The registry currently lists the 4 pilot folders that gained OEIS / LeetCode vectors.

## 3c. Mutation testing (sampled)

`tools/vv/mutate.py` takes a seeded sample of folders with a `tests.adb`, finds operator sites in the non-test `.adb` files (`+ -`, `< <=`, `> >=`, `= /=`, `and then / or else`, `*`, `+ 1 / - 1`), skips comments, strings and pragmas (including multi-line loop invariants and assertions), and applies up to K mutations one at a time in a scratch copy. Each mutant is rebuilt (GNAT 14, `-gnat2022 -gnata`) and the tests are run: `killed` (non-zero exit, a `FAIL` line, an exception, or a hang), `survived` (tests still pass), or `stillborn` (does not compile; not counted). Score = killed / (killed + survived). Per-mutant details go to `vv/results/mutation_detail.csv`.

Surviving mutants are leads, not verdicts: some are equivalent (for example changing the rolling-hash multiplier in Rabin-Karp still finds every match, because each hash hit is confirmed by a string compare), others show real gaps in the tests (for example no test that would notice `Len /= 0` flipped in the KMP prefix table). A full run on all folders would mean roughly 1,840 x 8 rebuilds; the sample keeps it to minutes.

Status (2026-10-08): 12 random folders x 8 mutants: 66 killed, 19 survived (77%); Chinese-Whispers now runs (7/8) since its tests accept the `-gnata` precondition failure. Pilot set (5 generalised stubs + KMP, Rabin-Karp, Package-Merge, same seed): `vv/results/mutation_pilot.csv`. All operator sites for the two folders whose test gaps were closed: `vv/results/mutation_sites_all.csv`.

* KMP: sample 6/8 -> 8/8, all sites 9/11 -> 11/11 (new tests: textbook prefix tables and every A/B pattern up to length 10, A/B/C up to 7, against the definition).
* Package-Merge: all sites 68/101 -> 70/101; sample unchanged at 2/7 because the 5 sampled survivors are equivalent: `Top < Max_Nodes` -> `<=` / `or else` (capacity guards that valid inputs never reach), insertion sort `>` -> `>=` (tie order only; costs equal), `Safe_Add` `- B` -> `+ B` (no package weight exceeds the sum of all frequencies, so saturation never triggers), and `Weight_Value` range `*` -> `+` (saturated package weights stay in nondecreasing order, so the merge picks the same items; 7,000 random cases with weights up to `Max_Freq` gave identical lengths). Most of the remaining 31 all-site survivors are in contracts of internal subprograms or in capacity guards.

## Not done yet

* CI / GitHub Actions (deliberately not added).
* Adapters for the remaining 43 pair edges (see 3a); `Float` tolerance in the comparison.
* Filling the known-answer registry beyond the pilot folders.
* GNAT 12 for the differential and mutation stages (they use GNAT 14 only; stage 1 covers both compilers).
