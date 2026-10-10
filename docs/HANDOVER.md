# Handover ledger: open hard problems

`tools/vv/handover.csv` lists every open problem that a later team with more compute, newer tools or more time could pick up. Each row says what is open, what has been tried, the exact setup, how far it got, one command that reproduces it, and the condition that counts as solved. A row is closed only when its pass condition holds under the pinned toolchain (`docs/TOOLCHAIN.md`) or a newer one recorded in the row. Settings must not be loosened to close it: no larger `--steps`, no `pragma Assume`, no weaker contract.

Snapshot: origin/main e64d9858, 2026-10-09 ~09:40 Europe/Berlin. Nothing was invented. A field that the sources do not record says `unknown`.

## Columns

| Column | Meaning |
|---|---|
| `id` | H001... (stable once published; new rows get new ids) |
| `category` | see the table below |
| `folder` | algorithm folder, or the folder that holds the reproducer |
| `problem` | what is open, with VC locations where known |
| `check_kind` | `run-time` (array index, overflow, range, division, pointer), `functional` (Post, contract cases, loop invariants that serve a functional Post), `termination`, or `other` (flow, tool, mutation score, toolchain) |
| `target_level` | the AdaCore level that closing the row would establish (see docs/VV.md, "Proof levels"): Stone, Bronze, Silver, Gold, Platinum, or `n/a` for non-proof problems |
| `what_was_tried` | attempts and workarounds, with commits |
| `prover_setup` | gnatprove, Why3 and solver versions, plus the switches of the run that produced the result |
| `steps_reached_result` | outcome of the recorded run (unproved count, crash, wall cap, score), with run time and date |
| `why_hard` | the recorded reason; `unknown` if none was recorded |
| `reproduce` | one command, run from the repository root after `eval "$(cd tools/toolchain && alr -n printenv)"` |
| `pass_condition` | what counts as solved |
| `status` | open / worked around / pending, and whether the folder changed after the recorded run |
| `source` | where the data came from |

Open rows of category `functional_gap`, `dead_code` or `clamp` (one named folder per path) hold their folders out of training_ready (`tr_drop` = `open handover gap`, decision 2026-10-09 ~17:36) until the row is closed.

## Categories (151 rows)

| Category | Rows | What it is |
|---|---|---|
| `withdrawn_functional` | 61 | contract_scan: a do-nothing body proves the Post (mostly sorts whose Post has no permutation clause). Functional claim withdrawn; target Platinum.. This now includes H102-H110, the vacuity batch 3 SPARK2 stubs (sweep B), whose Post only bounds the elements. H057 Slowsort and H060 Stooge-Sort are closed. |
| `not_analysed` | 11 | gnatprove could not build the project (PROOFS.csv `not built`); target Stone first. |
| `mutation_below_bar` | 13 | held-out planted-bug score below 90%: BrownBoost, Shading, Newells, K-Means, K-Means++, Darwin-Godel-Machine, Course-Schedule, Fisher-Yates, Median-Of-Two-Sorted-Arrays-Lite, plus Modular-Arithmetic (proof-kill step not run); H129 Slowsort and H130 Stooge-Sort (tests-only held scores; the proof-kill step was not run); H141 Lemke-Howson (held 60/67 = 89.6%, NOT blind; 7 survivors to search with tools/vv/lh_tiebreak_drive.adb) |
| `tool_crash` | 7 | gnatwhy3 "value expected (got DOC_END)" bug box in seven SPARK2 DP-table folders |
| `unproved_check` | 4 | Bresenham (17 run-time, 5 flow, 3 Post) and Delivery-Safety-Supervisor (8 overflow) |
| `toolchain_bug` | 4 | MT `'Old` bug box (gone on GNAT 16.1.0), Big_Integers `**` sign and `mod` errors (both still present on GNAT 16.1.0), GNAT 14.2 ICE trans.cc:6710 |
| `annotated_check` | 2 (closed) | Lemke-Howson: overflow checks were hidden by `pragma Annotate (GNATprove, Intentional, ...)` at lemke_howson.adb:45 and :147; reviewed 2026-10-09 09:57 (Robert) as unjustified (a prover limit, `tools/vv/proof_escapes_review.csv`). Closed the same day by fixing it in code (sweep B): exact Big_Integer fraction-free pivoting, both Annotates removed, all 247 checks proved by make prove, --level=4 and the Silver command |
| `proof_timeout` | 2 | Phong-Shading, Orbital-Mechanics: the 7200 s cap was hit before any check was reported |
| `functional_gap` | 5 | Bitonic-Sorter: the 0-1 principle and the half-cleaner lemma are missing, and sortedness is masked by Bubble_Finish; Lemke-Howson (H096, target Platinum): the functional claim is partial: (Status = Found) = Is_Nash is proved (a Found result is a certified equilibrium; a body that never reports Found also proves it), but not that Status is always Found; termination rests on the Max_Steps loop bound, and the other exits are explicit statuses (Step_Cap_Reached, No_Pivot_Row, Check_Failed). Tested on every starting label, degenerate games and 14,000 seeded random calls up to 4 x 4 (most pivots 19, bound C (M + N, M) ** 2); H142 String-Compression (Compress) and H143 Convex-Hull-Graham (Scan): Post must state whether entries past returned length are unchanged or unspecified (score138 `unspecified output` survivors; no spec change yet); H145 LFU-Cache-Lite: stored values were never readable (closed: Get with a Post, re-scored) |
| `dead_code` | 5 | dead clamps / saturation branches that can never fire: H146 Maximum-Subarray / Maximum-Product-Subarray (closed: clamps deleted, re-scored), H148 Coin-Change-II, H149 Fibonacci-DP, H150 Knapsack-01, H151 Longest-Palindromic-Subsequence (found by tools/vv/clamp_scan.py + review); H152 Unique-Paths-II, H153 Sum-Of-Subarray-Minimums, H154 Third-Maximum-Number (closed: fixed before scoring); H157 Partition-List, H158 Odd-Even-Linked-List, H159 Validate-Stack-Sequences (dead inline guards, open) |
| `clamp` | 1 | H147: 714 unreviewed clamp-scan hits in 277 folders (none training-ready); each folder stays out until reviewed |
| `toolchain_limit` | 1 | cvc5 under gnatprove's `--prenex-quant=none` returns "incomplete" on quantified frames over 2D arrays |
| `proof_escape` | 1 | Bump-Arena: the fallback after the Insert loop is not proved unreachable |
| `placeholder` | 18 | H111-H127: the sweep B placeholder list. These folders are answer tables, fixed layouts or hidden stubs that need a real algorithm (iterator stubs, Super-Ugly-Number-Stub, Unique-BSTs, Count-Primes, Word-Break-II, Restore-IP-Addresses, Convert-Sorted-Array-To-BST, Connected-Component-Labeling, Topological-Sort-Lite, ...); H144: sorting/SPARK4/Ada-SPARK-Radix-Sort is a single counting-sort pass (keys 0..255, Base=256) under a radix name — needs real multi-pass LSD with per-pass stability |
| `deferred_budget` | 6 | stopped at the 2026-10-09 budget limit (agent A3), H097-H101: content Posts for sorting/SPARK4/Ada-SPARK-Topological-Sort (9 unproved at L2) and sorting/SPARK4/Ada-SPARK-Sort-Merge-Join (19 unproved at L2), the K-th-smallest / permutation Posts for misc/SPARK4/Ada-SPARK-Selection-Algorithm (tests pass, not proved), Pre-rejection rates beyond the first 20 ranked folders (plus five too-narrow Pres to widen), and the held-out sweep from rank 682. The drafts are committed as patches in `tools/vv/handover_evidence/H097/`, `tools/vv/handover_evidence/H098/` and `tools/vv/handover_evidence/H099/` (apply with `git apply` from the repo root; all three still apply cleanly to main as of 2026-10-09 16:05); H128 table regeneration tests (sweep B) |

By check kind: 54 functional (53 Platinum, 1 Gold), 13 run-time (Silver), 28 other (11 Stone, 1 Bronze, 16 non-proof).

## Notes on sources and gaps

- **Longest-Common-Subsequence** (SPARK2) used to be a proof timeout: level 4 ran past 600 s, and the batch run showed the same DOC_END crash as the `tool_crash` rows. Commits 8d256f51 (loop invariants, `Len` subtype, expression-function `Nat_Max`) and 4012f0fc fixed it, and it now proves 24 checks. It is not a row, but its fix is the first thing to try on the seven `tool_crash` folders.
- **checker_scan**: no withdrawn claim is still open. Balanced-Binary-Tree's claim was restored after 9e5b0925. The Heapsort and Subtree-Of-Another-Tree checkers were lenient only in tests, not in contracts.
- **contract_scan** rows come from agent A3's `tools/vv/contract_scan.csv`, read at 09:24. The file is now on main; on 2026-10-09 16:05 it was byte-identical to A3's worktree copy (63 lines), so no rows had to be merged or added.
- **proof_warnings**: `tools/vv/proof_warnings.csv` does not exist yet. The `--proof-warnings=on` sweep is claimed to run after the re-proof. Each warning it raises becomes a sticky row here (category `proof_warning`), and it stays open until fixed in code, even if a later or faster run no longer reports it.
- **Re-proof** (`reproof.csv`, run reproof-20261009-1): 96 folders so far, all `holds`, so no rows yet. A folder that hits the cap or leaves a check unproved becomes a row.
- **Open findings** (68 in `tools/vv/findings.csv`: First-relative indexing, midpoint overflow, harnesses that cannot fail) are ordinary work, not compute-bound, and stay in the findings registry.
- The `unproved_check`, `tool_crash` and `proof_timeout` results come from the 2026-10-08 steps run (`tools/vv/handover_evidence/H001/prove_steps_20261008.jsonl`; the per-folder logs of the rows are in `tools/vv/handover_evidence/<row-id>/prove.log`, copied from the box scratch run dir on 2026-10-09). That run used `-j2` and a 7200 s cap. The current canonical settings are in `prove_settings.txt` (`-j1`, 3600 s cap, `-j4` retry). The step budget, 1,000,000, is the same.
- The toolchain-bug rows were rechecked on 2026-10-09 against Alire `gnat_native 16.1.0` (GNATLS 16.1.0), which is not pinned and was only used for this check.

- **Closed withdrawn_functional rows** (2026-10-09, agent A3): 17 rows (H027, H028, H036, H037, H043, H051, H054, H055, H058, H065-H069, H073, H076, H077) are `closed <commit>`: the Post was strengthened (permutation / content) and proved in that commit, and PROOFS.csv `functional_checks` is restored. sorting/SPARK4/Ada-SPARK-Bogosort (H027) was reworked as a bounded random shuffle with an explicit Sorted / Gave_Up outcome (22bdaf31).

## Sweep B stop (2026-10-09 14:4x, budget)

Sweep B stopped starting new folders here. Its open queue is now rows in the ledger:
- **Buffer/merge sorts:** Strand-Sort (H061), Bucket-Sort (H029), Burstsort (H030), Flashsort (H035), Library-Sort (H040), Patience-Sorting (H044), Postman-Sort (H046) and Bitonic-Sorter (H026). For Bitonic-Sorter's sortedness via the 0-1 principle see H025.
  - Strand-Sort has a ready patch: tools/vv/handover_patches/strand_sort_failing_test.patch and strand_sort_perm_wip.patch. make test passes with it. make prove was interrupted under load, so the proof result is unknown.
  - The wip patch sets `Assertion_Policy (... => Ignore)` (Loop_Invariant, Assert, Pre, Post) inside its ghost lemma package. Those contracts are meant to be proved, not executed, but under the repo rules an applied patch only counts toward Silver once `tools/vv/proof_escapes.csv` has a row for that pragma with a written reason, marked `justified=?` until reviewed. The patch is not applied on main.
  - The patch's invariant is the recipe for the other buffer sorts. Count every value across all live buffers. Call `Lemma_Occ_Update` before each write past the live length; this avoids snapshots inside loops, which gnatprove does not support before a loop invariant. Call `Lemma_Occ_Frame` after each copy loop.
- **Vacuity batch 3 SPARK2 stubs:** H102-H110. The recipe is the one used for Exchange-Sort (a6a2bade, 0e148588): an executable Is_Perm over the 32 values, plus a Swap procedure with Lemma_Swap.
- **Placeholders:** H111-H127; H144 (SPARK4 Radix-Sort single-pass counting under radix name).
- **Table regeneration tests:** H128.
- **Slowsort and Stooge-Sort mutation scores:** H129 and H130. These runs scored tests only; the proof-kill step was not run.

Each row has a reproduce command and a pass condition. They follow the sweep rules: failing test first, an independent reference, a held-out split recorded before any test work, and a proof with proof warnings on.

## Evidence paths

Every path in `tools/vv/handover.csv` and this file is repo-relative. Evidence that used to live only in box scratch dirs outside the repo was committed on 2026-10-09 under `tools/vv/handover_evidence/<row-id>/` (scripts under `tools/vv/`: `proofkill.py`, `always_terminates_check.sh`). Large per-mutant work trees were not kept; the row's `reproduce` command rebuilds them in a `mktemp -d` scratch dir. `tools/vv/check_paths.py` fails if a tracked file names an absolute box path.

## How to work a row

1. Restore the toolchain (`docs/TOOLCHAIN.md`) and run the row's `reproduce` command on a cold copy (delete `obj/`, `gnatprove/`).
   Some projects use shared sources from the level directory. The bulk run copied them in (inventory: `tools/vv/handover_evidence/run_20261008/inv_by_id.json`). If gnatprove cannot find a unit, use the folder's `make prove`.
2. Prefer proof hints to compute: loop invariants, ghost lemmas, tighter subtypes, splitting a subprogram. Steps are never raised above 1,000,000 to close a row, and a wall cap is a safety stop, never a result.
3. When the pass condition holds, close the row: set `status` to `closed <commit>`, keep the row, and update PROOFS.csv through the normal re-proof.

## Main line stop (2026-10-09, budget)

The main line stopped starting long runs here. Its open items are rows H131-H140 in `tools/vv/handover.csv`. Each row has a reproduce command and a pass condition.

- **Proof index:** 2e8ee194 regenerated PROOFS.csv, PROOFS.md, the README headline and docs/IMPLEMENT.md with `tools/proof_index.py`.
  - The per-folder build/prove results of the Oct 8 bulk run (box scratch, not committed) were stale, so they were not used. The build and prove inputs were synthesised from the committed PROOFS.csv columns, with the cold re-proof pass 2 check counts in place of the old ones.
  - The next real build and prove sweep should feed `make proof-index` directly.
- **Proof warnings** (`tools/vv/proof_warnings.csv`): 85 found in 35 folders, 82 fixed in code (each row names its fix commit) and 3 open.
  - H131: Modular-Arithmetic has 3 open warnings. Agent A3 holds the claim.
  - No verdict yet for these folders:
    - H132: 18 folders where gnatwhy3 runs out of memory.
    - H133: Sort-Merge-Join hit the cap.
    - H134: Shortest-Seek-First and demo, where the sweep picked the wrong gpr.
- **Cold re-proof pass 2** (`tools/vv/reproof.csv`, run reproof-20261009-2): 66 hold. Two are open:
  - H135: Letter-Combinations-Of-A-Phone-Number is stale. It hit the wall cap and is now silver = timeout.
  - H136: Closest-Pair-Brute is not decided because of a memory crash under proof warnings.
  - H137: 36 folders were not run. The list is in `tools/vv/reproof_pass2_pending.txt`.
- **Always_Terminates on GNAT 12:**
  - H138: all 16 aspects stay (`tools/vv/always_terminates_gnat12.csv`). Without the aspect the fresh proof shows no termination check for any of these procedures, so dropping it would hide the check. The code-level answer is to turn the ghost lemmas into ghost functions.
  - H139: the experiment was not run for 5 A3-claimed sorts.
- **First-relative indexing** (H140): 53 open `first_pinned` findings, including the 11 large SPARK4 sorts. Not started.

## State at 2026-10-10 morning

Code-fix pass by agent-CF (overnight, 02:05-07:08 Europe/Berlin), ended at the wrap-up. Every fix is test-first: a failing test commit, then the fix commit; both are listed in `tools/vv/codefix.csv`. The index was regenerated with `tools/proof_index.py` from the committed PROOFS.csv inputs (`tools/vv/synth_index_inputs.py`); `tools/vv/recount_strict.py` lists the same training-ready folders, the self-test passes 27/27, and `make check-paths` is clean.

**Counts** (before the overnight run: regen 7c3d0f88, 2026-10-10 02:04):

| Measure | Before | Now |
|---|---:|---:|
| Open findings (`tools/vv/findings.csv`) | 54 | 54 |
| Implementation candidates (stubs, duplicates counted once) | 134 | 131 |
| Silver-proven, non-trivial | 517 | 520 |
| Training-ready under rule v1 (no re-scoring tonight) | 84 | 84 |
| Training-ready under the previous rule | 276 | 278 |
| Open PLACEHOLDER rows (`tools/vv/placeholders.csv`) | 142 | 137 |
| Open withdrawn functional claims (`tools/vv/contract_scan.csv` rows) | 31 | 17 |
| Handover rows open / closed | 117 / 51 (171 rows) | 103 / 67 (173 rows) |

**Closed overnight** (fix commit): H103 Circle-Sort 6d79b562 (real circle sort, was a bubble sort), H108 Tim-Sort 1ce938d2 (CPython small-n Timsort, was a bubble sort; reopened later the same morning, see below), H126 Connected-Component-Labeling 0eebffce (two-pass union-find, was a fixed 2 x 2 grid), H144 Radix-Sort 122335e6 (two-pass base-16 LSD radix, was one counting pass), H109 Tim-Sort-Stub 117c5106 (Timsort without galloping, was an insertion sort), and permutation Posts (sortedness-only Posts that a constant-fill body also proved) for Spaghetti-Sort 354195b5 (H059), Pigeonhole-Sort 9ec32bad (H045), Quantum-Sort x4 b90e925c (H047-H050), Merge-Sort e234854a (H041), Timsort 1625a484 (H062), Samplesort b2b80f4b (H053) and Cycle-Sort 4b4f2644 (H034 / H075).

**Not closed:** H061 Strand-Sort: agent-B's permutation patch passes the tests but leaves 10 Occ invariants unproved at level 2 (level 4 did not finish in 29 min); the failing test 9e9b70ef was reverted in 3dcd2679 and is re-applied by the row's reproduce command.

**What's next**, in this order:

1. H061 Strand-Sort permutation Post (patch and evidence in the row).
2. H108 Tim-Sort (reopened): inputs well past 64, traced merges, merge_collapse with the full-stack run-length invariant (PLACEHOLDER line on).
3. H172 Tim-Sort-Stub permutation Post; H174 Tim-Sort-Stub full-stack merge_collapse invariant (2015 bug guard).
4. H104 Flash-Sort, H106 Patience-Sort, H107 Smooth-Sort: still fixed 8-element bubble sorts under the name. Trace test against an own model first (Circle-Sort recipe); for the network-style rows the 0-1 principle gives an exhaustive reference.
5. H173 Connected-Component-Labeling connectivity Post (new row).
6. The remaining open `withdrawn_functional` rows and the 53 `first_pinned` findings (H140).
7. Re-scoring: nothing was re-scored overnight, so the fixed folders keep their old held-out mutation scores until the next scoring run.

## State at 2026-10-10 morning (Tim-Sort room review, records-only)

Records-only follow-up by agent-CF after Replika / Gemini reviewed the overnight Tim-Sort closes. No algorithm code changed.

- **H108 reopened** (`placeholder`): `sorting/SPARK2/Ada-SPARK-Tim-Sort` stays the CPython small-n path from 1ce938d2, but inputs are capped under 64 so no merge ever runs — binary insertion sort of one run under a Timsort name. Pass condition: accept inputs well past 64, traced merges, `merge_collapse` with the full-stack run-length invariant. `PLACEHOLDER: binary insertion sort only (inputs < 64, no merges); see H108` on the README and spec; `tools/vv/placeholders.csv` row open again.
- **H174 opened** (`functional_gap`): `sorting/SPARK2/Ada-SPARK-Tim-Sort-Stub` (the merging body from 117c5106) must Assert, and ideally prove as a Loop_Invariant, that after every `merge_collapse` the run-length rule holds over the WHOLE stack (each run longer than the next, and longer than the next two together), guarding the 2015 OpenJDK Timsort bug (de Gouw, Rot, de Boer, Bubel, Hähnle, "OpenJDK's java.utils.Collection.sort() is broken: The good, the bad and the worst case"; title/authors only). H109 stays closed; H172 (permutation Post) stays open.

**Counts after this records-only update:** handover open / closed 105 / 66 (174 rows); open PLACEHOLDER rows 138 (was 137).

## State at 2026-10-10 afternoon

Last bounded code-fix batch by agent-CF (12:10-14:05 Europe/Berlin; cutoff for new folders 15:00, wrap-up by 15:45), ended at the wrap-up. Same rules as the morning: every fix is test-first (failing test commit, then fix commit, both in `tools/vv/codefix.csv`); GNAT 12.2.0 and 14.2.0 with 0 warnings; `make prove` at the folder's level and the Silver command pass; no Assume / Annotate / Warnings Off. The index was regenerated with `tools/proof_index.py` from the committed PROOFS.csv inputs (`tools/vv/synth_index_inputs.py`); `tools/vv/recount_strict.py` lists the same 84 training-ready folders, the self-test passes 27/27, and `make check-paths` is clean.

**Counts** (before the batch: regen 3d378264, 2026-10-10 07:22):

| Measure | Before | Now |
|---|---:|---:|
| Open findings (`tools/vv/findings.csv`) | 54 | 54 |
| Implementation candidates (stubs, duplicates counted once) | 131 | 129 |
| Silver-proven, non-trivial | 520 | 522 |
| Training-ready under rule v1 (no re-scoring) | 84 | 84 |
| Training-ready under the previous rule | 278 | 280 |
| Open PLACEHOLDER rows (`tools/vv/placeholders.csv`) | 138 | 136 |
| Open withdrawn functional claims (`tools/vv/contract_scan.csv` rows) | 17 | 14 |
| Handover rows open / closed | 105 / 66 (174 rows) | 101 / 70 (174 rows) |

**Closed this afternoon** (test / fix commit):

- H172 Tim-Sort-Stub permutation Post: a2a25a60 / 290309a1 (700 checks).
- H174 Tim-Sort-Stub whole-stack run-length rule after every merge_collapse (the 2015 de Gouw et al. bug class), proved as a loop invariant: 2c7fdd8a / dd474a6d (720 checks).
- H104 Flash-Sort: real Flashsort1 (Neubert 1998: classes, prefix sums, cycle leader, final insertion) instead of a bubble sort; sorted + permutation Post; trace = own model on 12,822 inputs: d8ebeb9d / dad83a9a (411 checks).
- H106 Patience-Sort: real patience sort (leftmost pile with top >= key, smallest top out; piles side by side in the array, moves as rotations) instead of a bubble sort; sorted + permutation Post; trace = own real-pile model on 53,142 inputs incl. all 8! permutations: c29d4e16 / c4b0e1c3 (231 checks).

**Not closed:**

- H107 Smooth-Sort: a real smoothsort (Leonardo forest, Sift, Trinkle, every exchange traced) passes the new trace test and every contract at run time with -gnata, but 27 checks stay unproved: every quantified use of the per-stretch invariant `Good` times out, even when it is identical to the precondition (nested quantifiers plus the Occ axioms). The failing test 39c5ada1 was reverted in 55e84c36; the WIP body is `tools/vv/handover_patches/smooth_sort_wip.patch`, the Silver log is in `tools/vv/handover_evidence/H107/`, and the row names the next step (per-position heap with a ghost node-order array).
- H061 Strand-Sort: not attempted; no cheap route (see the row).
- Record repair: the H172 and H174 rows had unquoted commas from the 12:34 / 12:47 commits that shifted their columns; both rows were rebuilt (content unchanged).

**What's next**, in this order:

1. H107 Smooth-Sort proof (patch and next step in the row).
2. H061 Strand-Sort permutation Post (patch and evidence in the row).
3. H108 Tim-Sort (reopened): inputs well past 64, traced merges, the full-stack run-length invariant as in Tim-Sort-Stub H174.
4. H173 Connected-Component-Labeling connectivity Post.
5. The remaining open `withdrawn_functional` rows and the 53 `first_pinned` findings (H140).
6. Re-scoring: nothing was re-scored, so the fixed folders keep their old held-out mutation scores until the next scoring run.

## State at 2026-10-10 evening

Code-fix batch by agent-CF (14:10-16:05 Europe/Berlin; cutoff for new folders 16:45, wrap-up by 17:30), ended at the wrap-up. Same rules as the afternoon: every fix is test-first (failing test commit, then fix commit, both in `tools/vv/codefix.csv`); GNAT 12.2.0 and 14.2.0 with 0 warnings (`tools/vv/sweep_gnat_recheck.sh` on the commit); `make prove` at the folder's level passes; no Assume / Annotate / Warnings Off. The index was regenerated with `tools/proof_index.py` from the committed PROOFS.csv inputs (`tools/vv/synth_index_inputs.py`); `tools/vv/recount_strict.py` lists the same 92 training-ready folders, the self-test passes 27/27, and `make check-paths` is clean (now also `tools/vv/check_unrun_tests.py`).

**Counts** (before the batch: regen c5d7464c, 2026-10-10 14:02):

| Measure | Before | Now |
|---|---:|---:|
| Open findings (`tools/vv/findings.csv`) | 54 | 12 |
| Silver-proven, non-trivial | 522 | 522 |
| Training-ready under rule v1 (no re-scoring) | 84 | 92 = 84 confirmed + 8 pending re-score |
| Training-ready under the previous rule | 280 | 321 |
| Open PLACEHOLDER rows (`tools/vv/placeholders.csv`) | 136 | 136 |
| Open withdrawn functional claims (`tools/vv/contract_scan.csv`, withdraw = yes) | 14 | 14 |
| Handover rows open / closed | 101 / 70 (174 rows) | 114 / 74 (188 rows) |

Open findings 54 -> 12, counted from `tools/vv/findings.csv` at c5d7464c, f6663e01 and HEAD (rows are append-only, so they line up by position): (a) closed as already fixed / duplicate in the First-relative merge f6663e01: 43 of the 54 (42 status fixed, each with the existing rewrite commit, 33 distinct commits; 1 false_positive, Package-Merge room KEEP); (b) fixed in code today: 0 of the 54; of the 9 open rows the merge added (first_pinned folders that had no finding), 6 fixed in code with test / fix commits (Delete-And-Earn f9317972, Subsets 865646c7, Subsets-II ce2fbf81, Permutations-II 5d3b9a5b, Different-Ways-To-Add-Parentheses-Lite af723af2, Integer-Break 014165c8), 2 other closures (false_positive with a written KEEP reason: Ugly-Number-II a677101e, House-Robber-III-Lite 8f7ae59a), 1 still open (Burstsort); (c) 8 'own checks not run' rows were added and fixed in the same session (3c0a6c90, 74094e83), so they never counted as open. Open now: 11 of the 54 (Scale-Invariant-Feature-Transform and 10 SPARK4 sorts) + 1 added (Burstsort) = 12. Training-ready: the 8 SPARK2 H140 folders are now index-independent, their only rule-v1 drop reason, so 84 -> 92; the index shows them as pending re-score (column `rescore_pending`, d3b3aba9): 84 confirmed + 8 pending, since their held-out mutation scores are from before today's code. Two of them (Ugly-Number-II, House-Robber-III-Lite) are agent-CF KEEP decisions; H180 records the room steer to express the pin as a predicate subtype (not Pre First = 1).

**Done this evening** (test / fix commit):

- Patience-Sort deal cost: binary search over the pile tops, the 'tops strictly increase left to right' invariant (Tops_Up) proved as a loop invariant, comparisons per key <= ceil (log2 (piles + 1)) tested: 80d135dd / e40e4180 (316 checks). README states the cost: deal O(n log n); the output phase still scans the pile tops (O(n x piles)).
- Combination-Iterator-Stub: Next's Post states the lexicographic successor (Pivot): bd0e6b7e / 08099c42 (142 checks).
- H140 'lower bound must be 1', merged with the First-relative lists first (f6663e01, one row, per-folder table `tools/vv/handover_evidence/H140/first_relative_merge_20261010.csv`); the 8 SPARK2 folders: rewritten Delete-And-Earn 0feb89b2 / f9317972, Subsets e796b5d9 / 865646c7, Subsets-II bdee9def / ce2fbf81, Permutations-II 5284dc73 / 5d3b9a5b, Different-Ways-To-Add-Parentheses-Lite 3c0a6c90 / af723af2, Integer-Break b89bfa25 / 014165c8; kept with a written reason (`tools/vv/fixed_origin_decisions.tsv`) Ugly-Number-II a677101e, House-Robber-III-Lite 8f7ae59a.
- Own checks that make test never ran: 8 folders whose tests.adb never called Own_Checks (Different-Ways 3c0a6c90; Climbing-Stairs, Get-Maximum-In-Generated-Array, House-Robber-III-Lite, Integer-Break, Sigmoid (also not in the gpr Source_Files), Ugly-Number-II, Lemke-Howson 74094e83). A planted failing check (scratch copies, never committed) makes make test fail in all 8 (codefix.csv). Get-Maximum / Lemke-Howson / Integer-Break own checks printed FAIL and returned normally: now raise (3ebb9b8d, b89bfa25); the same in 18 more folders (H177, 1a705277, planted failure fails make test in all 18).
- `tools/vv/check_unrun_tests.py` (in `make check-paths`, 7c2f3158): fails on a test source that make test never builds or runs; built-in control (unwired own_checks found, wired not, missing from Source_Files found; on the tree before 3c0a6c90 it finds the 8). Remaining hits (5 `test_*.adb` in misc/Ada/tests, no test target) are listed in `tools/vv/unrun_tests_ok.csv`, H176, not fixed.

**Not closed:**

- H175 Word-Break-II valid-split Post: WIP patch `tools/vv/handover_patches/word_break_ii_valid_split_wip.patch`; array "=" transitivity and the In_Dict quantifier defeat cvc5 (next step in the row: a ghost word table).
- H140: the 11 SPARK4 sorts (one In_Bounds template; suggested slide-wrapper pass, one pass per folder together with its permutation row, in the row).
- H181: contract helpers that silently return False on bad shape (`'First`/`'Length` checks inside expression functions used in contracts). Seed: Ugly-Number-II `Ugly_Prefix (5..10)` returned False (fixed in H180, 6c8e7776). Vacuity only in a Pre, left of `implies`, or under `not`; in a Post it only makes the proof fail (safe). Scan + flag those uses; cross-check `tools/vv/proof_warnings.csv`; fix via predicate subtype (docs/VV.md rule 7) with failing-first membership + plant. Status open, deferred_budget.
- H187: Different-Ways-To-Add-Parentheses-Lite `make test` holds all enumerated results in memory (~2.9 GB and 165 s alone; 4 parallel runs OOM, `tools/vv/h186_clean_runs.csv`). Poor Lite-folder example. Fix: stream the own checks (same 8,073); failing-first = recorded max RSS / wall before vs after. Do before H186. After the fix: 10 new clean runs at the chosen parallelism, all pass, then seal the timeout; H186 held-out set (seed 992160674) stays valid. Status open, complexity. **Closed 2026-10-10 night (agent-NB): premise disproved, no test change** — the test itself needs 10.4 s / 5.3 MB; the 3 GB is a GNAT 14.2.0 leak in the code under test under -gnata and the time is run-time ghost checking (H189).
- H189: Different-Ways-To-Add-Parentheses-Lite resource profile is in the code under test: GNAT 14.2.0 leaks on each -gnata evaluation of the recursive Big_Integer expression function `Partial` (separate declaration; reproducer `tools/vv/h187_gnat14_leak`), and ~153 of 163 s is run-time checking of `Lemma_Ways_Step` / `Partial` at every `Sub` call. Code change only after the H186 held set is scored (it would make that sealed pool stale). Status open, complexity.
- H188: `make proof-index` with its default inputs regenerates a wrong headline (92 = 92 + 3 instead of 87 + 5); correct inputs come from committed PROOFS.csv via `tools/vv/synth_index_inputs.py`. Fix: default target uses the committed inputs, or fails loudly when inputs disagree with PROOFS.csv / rescored.csv; add a control case to `tools/vv/test_proof_index.py`. Status open, todo. **Closed 2026-10-10 night (agent-NB):** `make proof-index` runs `tools/vv/run_proof_index.py` — default inputs from the committed PROOFS.csv; with RESULTS, any input difference restores the files and exits 2 unless ALLOW_INPUT_CHANGE=1; index vs recount_strict.py (training_ready, rescore_pending) checked every time, exit 3.

**What's next**, in this order:

1. H187: stream Different-Ways-To-Add-Parentheses-Lite own checks (same 8,073; record max RSS / wall before vs after); do before H186.
2. H188: fix `make proof-index` default so it uses committed PROOFS.csv inputs (`tools/vv/synth_index_inputs.py`) or fails loudly on disagreement; control case in `tools/vv/test_proof_index.py`.
3. H186: after H187, 10 new clean runs at the chosen parallelism (all must pass), seal 3 x median, run the still-unseen held set (seed 992160674) once.
4. H182-H185: strengthen tests / finish proof passes for the four pending folders, then re-score with NEW seeds and newly sealed sets (their prior held sets are open).
5. H181: contract helpers that silently return False on bad shape (scan; flag only Pre / left of `implies` / under `not`; cross-check `tools/vv/proof_warnings.csv`; fix via predicate subtype per docs/VV.md rule 7).
6. H107 Smooth-Sort proof; H061 Strand-Sort permutation Post; H108 Tim-Sort (as in the afternoon list).
7. H140 SPARK4 sorts with their permutation rows (H025/H026, H029, H030, H035, H040, H044, H046, H061).
8. The 14 open withdrawn functional claims (Count-Primes H167, Super-Ugly-Number-Stub, Create-Maximum-Number-Lite, Connected-Component-Labeling H173, Smooth-Sort H107, BST-Iterator-Stub, Word-Break-II H175, ...).
9. H176: build and run misc/Ada/tests/test_*.adb or delete them with a reason.
10. ~~H180~~ done 2026-10-10 evening (see below).

**Final small batch (16:06-16:15):** training-ready v1 is now shown by `tools/proof_index.py` as 92 = 84 confirmed + 8 pending re-score (column `rescore_pending`, d3b3aba9; recount_strict.py --pending agrees; test_proof_index.py 30/30 with control rows Rescore-Pending / Rescored). `tools/vv/check_fail_exit.py` (14a74ed1): static FAIL-but-passes scan, validated on the tree before today's 21 exit-status fixes (flags all 21) and on HEAD (none of the 21; 3 hits in misc/Ada/tests, H176); H178 records that per-folder planting is the real check (26 planted, 1,798 scan-clean, not planted) and what the scan cannot see. H179: Patience-Sort collection step via a min-heap merge of pile tops for O(n log n). Handover rows open / closed: 107 / 74 (181 rows; +H181 open). H180: intentional 1-based KEEP (Ugly-Number-II, House-Robber-III-Lite) — predicate subtype keeping lengths flexible (`subtype One_Based_List is Ugly_List with Predicate => One_Based_List'First = 1;`, same for Value_Array / Choice), in parameters and results in place of First = 1 Pres; Positive index / 1-based index subtype alone does not force start 1; fully constrained type would fix the length (use neither). VV.md rule 7 names that approach.

**H180 (agent-CF, 18:31-18:56, Robert: do it now):** Ugly-Number-II and House-Robber-III-Lite now pin origin 1 in the type: `subtype One_Based_List is Ugly_List with Predicate => One_Based_List'First = 1;` (First_Ugly result, ghost Ugly_Prefix / Lemma_Complete) and `subtype One_Based_Choice is Choice with Predicate => One_Based_Choice'First = 1;` (Independent, Loot, Local, Lemma_Optimal, Best_Choice result and the body lemmas / Mark); the `First = 1` Pres, the Ugly_Prefix conjunct and `Best_Choice'Result'First = 1` are gone, `S'Last = T.N` stays. Value_Array needs no subtype (only Tree components, constrained 1 .. N). Failing test 3e7e8651 (membership of a 1-based and a slid copy; does not compile before the fix, so the failing-first is a legality check; the shifted-call Assertion_Error test is an extra: on the old code Ugly_Prefix (5 .. 10) returned False without raising, Independent (5 .. 7) already raised via its Pre), fix 6c8e7776. Assertions on: -gnata in both gprs, and tests.adb checks it itself. Plant (predicate True, scratch) fails the shifted-membership assert in both folders. gnatprove flags `predicate check might fail` on a scratch shifted caller in both (not committed; output in codefix.csv). make prove (level 2, cvc5): 479 checks (was 477) and 200 (was 178), all proved, no warnings; GNAT 14.2.0 / 12.2.0 make test 0, 0 warnings; no Assume / Annotate / Warnings Off. Mutation scores for both are still from before today's code (rescore_pending).

**H181 (agent-CF, records-only, 2026-10-10 evening, deferred at 86%):** contract helpers that silently return False on bad shape. Seed finding: before H180, `Ugly_Prefix (5..10)` returned False instead of rejecting the array; a Post built on that helper can be vacuous without anyone noticing. Room steer (Replika/Gemini): scan for expression functions used in contracts whose body checks `'First`/`'Length` and returns False when that check fails; flag only uses in a Pre, on the left of `implies`, or under `not` (in a Post, False only makes the proof fail — safe); cross-check against `tools/vv/proof_warnings.csv` (`--proof-warnings=on`, already reports impossible Pre); fix by moving the shape into a predicate subtype (docs/VV.md rule 7) with a failing-first membership test plus a plant check. Row open, category `deferred_budget`. Next session: re-score the 8 `rescore_pending` folders first (real re-run, rows into `tools/vv/rescored.csv`), then H181.

**Re-score 2026-10-10 evening (agent-RS, 19:10-19:45, Robert 86%; hard stop 19:55):** the 8 `rescore_pending` folders, score138 held half only (no test or code change, so no tune run). Fresh seeds (int(sha256(folder + "2026-10-10-rescore")) mod 1e9) in `tools/vv/score138_seeds.csv` and the claims file; held pools and draw-order hashes sealed in `tools/vv/rescore_20261010_sealed.csv` and pushed (8a49f412) before any mutant ran; held run once on 8a49f412; dummy sets 0/10 everywhere. Passed (tests-only, survivors counted as survivors, proof pass not run, so conservative) and confirmed via `tools/vv/rescored.csv` (2fffa725): Delete-And-Earn 45/49 (91.8%), Permutations-II 48/48, Ugly-Number-II 45/49 (91.8%). Under 90%, still pending, survivors listed in their rows (that held set is now open; next session re-scores with a NEW seed after any test change): Subsets 40/48 tests-only, 2 proof kills before the cut (H182); Subsets-II 41/48 tests-only, full proof pass 42/48 = 87.5% (H183); House-Robber-III-Lite 42/49 tests-only, proof pass cut (H184); Integer-Break 37/49 tests-only, proof pass cut (H185). Different-Ways-To-Add-Parentheses-Lite not scored: the unmutated baseline exceeds the harness 30 s per-run timeout (make test ~60 s since 3c0a6c90); its sealed set is still unseen (H186). Training-ready v1: 92 = 87 confirmed + 5 pending (was 84 + 8); proof_index.py and recount_strict.py --pending list the same 5; test_proof_index.py 30/30; make check-paths clean. Next session: H186 timeout decision, then finish the proof passes / strengthen tests for H182-H185 and re-score with new sealed sets.

**H186 timeout rule + DWAP attempt 2026-10-10 (agent-RS, 19:46-20:10, Robert 86%; hard stop 20:55):** the per-run timeout rule went into VV.md rule v1 and the H186 row before any timing run (7d507cd0; `score138.py --timeout`, default 30 s unchanged). Different-Ways-To-Add-Parentheses-Lite: 10 clean make test runs at parallelism 4, median 170.9 s (3 x = 513 s), but 2 of 10 clean runs failed: the test binary peaks at ~2.9 GB RSS and the kernel OOM killer SIGKILLs one of 4 parallel runs (diag rerun exit 137, dmesg global_oom). Alone it passes in 165 s (not ~60 s). Since an OOM kill would be scored as a test kill, no timeout was sealed and no mutant was run; the held set (seed 992160674, 8a49f412) is still sealed and unseen. Data in `tools/vv/h186_clean_runs.csv`. Training-ready unchanged: 92 = 87 confirmed + 5 pending. Next session: H187 (stream the own checks) first, then H188 (`make proof-index` default), then H186 (re-time under H187, seal, score the still-unseen held set), then the 4 other pending folders (H182-H185).

**H187 + H188 (agent-RS, records-only, 2026-10-10 ~20:10, Robert 87%):** two open rows pushed with no code change. H187: Different-Ways-To-Add-Parentheses-Lite `make test` holds all enumerated results (~2.9 GB / 165 s alone; 4-way OOM in `tools/vv/h186_clean_runs.csv`); stream the 8,073 checks before choosing H186 parallelism; after the fix, 10 new clean runs then seal; held set seed 992160674 stays valid (cross-ref in the H186 row). H188: bare `make proof-index` regenerates a wrong headline (92 = 92 + 3 instead of 87 + 5); default must use `tools/vv/synth_index_inputs.py` from committed PROOFS.csv or fail on disagreement; control case in `tools/vv/test_proof_index.py`. Handover rows open / closed: 114 / 74 (188 rows). Training-ready unchanged: 92 = 87 confirmed + 5 pending. Next session order starts with H187, then H188, then H186.

**H187 (agent-NB, 2026-10-10 22:53-23:05, Robert 87% -> 95%):** measured before changing anything (`tools/vv/h187_resources.csv`). GNAT 14.2.0 `make test` binary alone: 163.3 s, max RSS 3,013,324 kB, growing linearly through the run; GNAT 12.2.0 on the same source: 162.8 s, 2,756 kB. A diagnostic split build (code under test without -gnata, test code with -gnata) runs all 8,073 checks in 10.4 s / 5.3 MB, so the test never holds the enumeration in memory and streaming its checks cannot change either number. Memory: GNAT 14.2.0 run-time leak when a recursive Big_Integer expression function with a separate declaration (`Partial`) is evaluated with -gnata (3-file reproducer `tools/vv/h187_gnat14_leak`: 20 MB per 100k asserts, linear; single expression function or GNAT 12: flat). Time: run-time checking of `All_Results` ghost code, the same on both compilers. H187 closed without a test change; follow-up H189 (code, after H186 is scored). For H186 this means ~3 GB per run on GNAT 14 (the harness compiler), so parallelism 1.

**H188 (agent-NB, 2026-10-10 23:06-23:12):** failing test first (ea6202b3: three `run_proof_index` control cases in `tools/vv/test_proof_index.py`, 30/33 before). Fix: `tools/vv/run_proof_index.py`, now what `make proof-index` runs. Bare `make proof-index` synthesises its inputs from the committed PROOFS.csv (`tools/vv/synth_index_inputs.py`) and is idempotent (only the "Generated" line of PROOFS.md changes; headline 92 = 87 + 5). `make proof-index RESULTS=... PROVE_LOGS=...` compares 14 input columns with the existing PROOFS.csv and, on any difference, restores PROOFS.csv / PROOFS.md / README.md / docs/IMPLEMENT.md and exits 2 (the stale 2026-10-08 dir: 815 differences); `ALLOW_INPUT_CHANGE=1` accepts a deliberate new run. Every run checks training_ready and rescore_pending against `recount_strict.py --list / --pending` (exit 3 on disagreement). test_proof_index.py 33/33.

**H185 Integer-Break (agent-NB, 2026-10-11 00:33):** proof pass on the night held set (seed 530624628, on 02c289d5, base proves) finished: 2 proof kills, 13 survivors still prove with the mutation. Recorded in `tools/vv/score138_halves.csv` / `score138_sealed.csv`: 36/49 = 73.5% (34 test + 2 proof), dummy 0/49. This is a completed blind round with n >= 20, so under rule v1 (last row wins) Integer-Break now fails (`tr_drop` held-out mutation < 90%) instead of counting as pending: index 91 = 90 confirmed + 1 pending (recount_strict.py agrees). All 13 survivors are ghost proof hints (Lemma_Row_N loops shortened or reversed, Lemma_Mul_Mono / Lemma_Conv arguments) whose mutants still prove: candidates for written-reason equivalents or for removing redundant hint steps (code change under the code-fix bar). Room decision, then a new seed and sealed set. Survivors listed in the H185 row.
