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

Status (2026-10-08): 10 pairs: Adler-32, Binary-GCD, Delta-Encoding (Ada encode summed vs SPARK `Net_Delta`), Euclidean-Algorithm, Gray-Code (encode + decode), Hamming-Weight, Kadane, Longest-Increasing-Subsequence, Median-Filtering (8x8, 3x3 kernel), Pearson-Hashing. all 10 agree on every case (1,000-5,000 cases each); Pearson-Hashing agrees since its SPARK twin uses the real 256-entry table.

## 3b. Known-answer vectors

Each folder's `tests.adb` should contain at least one vector from an outside source: RFC test vectors (hashes, checksums, ciphers), OEIS terms (integer sequences), textbook / Wikipedia worked examples, LeetCode examples. `tools/vv/kat_registry.csv` records `folder, source, where`; the `kat` column shows the source. A registry entry is only added after checking that the vector is really in the tests and passes. Targets, in order: cryptography and hashing (RFC vectors exist for almost all), compression (round trips + published examples), numerical (OEIS), then the rest. The registry currently lists the 4 pilot folders that gained OEIS / LeetCode vectors.

## 3c. Mutation testing (sampled)

`tools/vv/mutate.py` takes a seeded sample of folders with a `tests.adb`, finds operator sites in the non-test `.adb` files (`+ -`, `< <=`, `> >=`, `= /=`, `and then / or else`, `*`, `+ 1 / - 1`), skips comments, strings and pragmas (including multi-line loop invariants and assertions), and applies up to K mutations one at a time in a scratch copy. Each mutant is rebuilt (GNAT 14, `-gnat2022 -gnata`) and the tests are run: `killed` (non-zero exit, a `FAIL` line, an exception, or a hang), `survived` (tests still pass), or `stillborn` (does not compile; not counted). Score = killed / (killed + survived). Per-mutant details go to `vv/results/mutation_detail.csv`.

Surviving mutants are leads, not verdicts: some are equivalent (for example changing the rolling-hash multiplier in Rabin-Karp still finds every match, because each hash hit is confirmed by a string compare), others show real gaps in the tests (for example no test that would notice `Len /= 0` flipped in the KMP prefix table). A full run on all folders would mean roughly 1,840 x 8 rebuilds; the sample keeps it to minutes.

Status (2026-10-08): 12 random folders x 8 mutants: 64 killed, 18 survived (78%); 1 folder's baseline already fails with `-gnata` (Chinese-Whispers: the tests break a precondition). Pilot set (5 generalised stubs + KMP, Rabin-Karp, Package-Merge): see `vv/results/mutation_pilot.csv`.

## Not done yet

* CI / GitHub Actions (deliberately not added).
* Adapters for the other ~100 pairs; `Float` tolerance in the comparison.
* Filling the known-answer registry beyond the pilot folders.
* GNAT 12 for the differential and mutation stages (they use GNAT 14 only; stage 1 covers both compilers).
