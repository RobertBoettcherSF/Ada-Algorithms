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

## Categories (101 rows)

| Category | Rows | What it is |
|---|---|---|
| `withdrawn_functional` | 52 | contract_scan: a do-nothing body proves the Post (mostly sorts whose Post has no permutation clause). Functional claim withdrawn; target Platinum. |
| `not_analysed` | 11 | gnatprove could not build the project (PROOFS.csv `not built`); target Stone first. |
| `mutation_below_bar` | 10 | held-out planted-bug score below 90%: BrownBoost, Shading, Newells, K-Means, K-Means++, Darwin-Godel-Machine, Course-Schedule, Fisher-Yates, Median-Of-Two-Sorted-Arrays-Lite, plus Modular-Arithmetic (proof-kill step not run) |
| `tool_crash` | 7 | gnatwhy3 "value expected (got DOC_END)" bug box in seven SPARK2 DP-table folders |
| `unproved_check` | 4 | Bresenham (17 run-time, 5 flow, 3 Post) and Delivery-Safety-Supervisor (8 overflow) |
| `toolchain_bug` | 4 | MT `'Old` bug box (gone on GNAT 16.1.0), Big_Integers `**` sign and `mod` errors (both still present on GNAT 16.1.0), GNAT 14.2 ICE trans.cc:6710 |
| `annotated_check` | 2 (closed) | Lemke-Howson: overflow checks were hidden by `pragma Annotate (GNATprove, Intentional, ...)` at lemke_howson.adb:45 and :147; reviewed 2026-10-09 09:57 (Robert) as unjustified (a prover limit, `tools/vv/proof_escapes_review.csv`). Closed the same day by fixing it in code (sweep B): exact Big_Integer fraction-free pivoting, both Annotates removed, all 247 checks proved by make prove, --level=4 and the Silver command |
| `proof_timeout` | 2 | Phong-Shading, Orbital-Mechanics: the 7200 s cap was hit before any check was reported |
| `functional_gap` | 2 | Bitonic-Sorter: the 0-1 principle and the half-cleaner lemma are missing, and sortedness is masked by Bubble_Finish; Lemke-Howson (H096, target Platinum): the functional claim is partial: (Status = Found) = Is_Nash is proved (a Found result is a certified equilibrium; a body that never reports Found also proves it), but not that Status is always Found; termination rests on the Max_Steps loop bound, and the other exits are explicit statuses (Step_Cap_Reached, No_Pivot_Row, Check_Failed). Tested on every starting label, degenerate games and 14,000 seeded random calls up to 4 x 4 (most pivots 19, bound C (M + N, M) ** 2) |
| `toolchain_limit` | 1 | cvc5 under gnatprove's `--prenex-quant=none` returns "incomplete" on quantified frames over 2D arrays |
| `proof_escape` | 1 | Bump-Arena: the fallback after the Insert loop is not proved unreachable |
| `deferred_budget` | 5 | stopped at the 2026-10-09 budget limit (agent A3), H097-H101: content Posts for sorting/SPARK4/Ada-SPARK-Topological-Sort (9 unproved at L2) and sorting/SPARK4/Ada-SPARK-Sort-Merge-Join (19 unproved at L2), the K-th-smallest / permutation Posts for misc/SPARK4/Ada-SPARK-Selection-Algorithm (tests pass, not proved), Pre-rejection rates beyond the first 20 ranked folders (plus five too-narrow Pres to widen), and the held-out sweep from rank 682. The drafts are patches in `/workspace/inbox/a3_drafts/` (box path outside the repo; apply with `git apply` from the repo root) |

By check kind: 54 functional (53 Platinum, 1 Gold), 13 run-time (Silver), 28 other (11 Stone, 1 Bronze, 16 non-proof).

## Notes on sources and gaps

- **Longest-Common-Subsequence** (SPARK2) used to be a proof timeout: level 4 ran past 600 s, and the batch run showed the same DOC_END crash as the `tool_crash` rows. Commits 8d256f51 (loop invariants, `Len` subtype, expression-function `Nat_Max`) and 4012f0fc fixed it, and it now proves 24 checks. It is not a row, but its fix is the first thing to try on the seven `tool_crash` folders.
- **checker_scan**: no withdrawn claim is still open. Balanced-Binary-Tree's claim was restored after 9e5b0925. The Heapsort and Subtree-Of-Another-Tree checkers were lenient only in tests, not in contracts.
- **contract_scan** rows come from agent A3's `tools/vv/contract_scan.csv` in `/workspace/aa-sweepA3`, read at 09:24. That file was not yet on main. When it lands, compare the two, and close or add rows by id.
- **proof_warnings**: `tools/vv/proof_warnings.csv` does not exist yet. The `--proof-warnings=on` sweep is claimed to run after the re-proof. Each warning it raises becomes a sticky row here (category `proof_warning`), and it stays open until fixed in code, even if a later or faster run no longer reports it.
- **Re-proof** (`reproof.csv`, run reproof-20261009-1): 96 folders so far, all `holds`, so no rows yet. A folder that hits the cap or leaves a check unproved becomes a row.
- **Open findings** (68 in `tools/vv/findings.csv`: First-relative indexing, midpoint overflow, harnesses that cannot fail) are ordinary work, not compute-bound, and stay in the findings registry.
- The `unproved_check`, `tool_crash` and `proof_timeout` results come from the 2026-10-08 steps run (`/workspace/aa/v2/prove_steps.jsonl`, logs `/tmp/aa2s/<folder>/prove.log`; box paths outside the repo). That run used `-j2` and a 7200 s cap. The current canonical settings are in `prove_settings.txt` (`-j1`, 3600 s cap, `-j4` retry). The step budget, 1,000,000, is the same.
- The toolchain-bug rows were rechecked on 2026-10-09 against Alire `gnat_native 16.1.0` (GNATLS 16.1.0), which is not pinned and was only used for this check.

- **Closed withdrawn_functional rows** (2026-10-09, agent A3): 17 rows (H027, H028, H036, H037, H043, H051, H054, H055, H058, H065-H069, H073, H076, H077) are `closed <commit>`: the Post was strengthened (permutation / content) and proved in that commit, and PROOFS.csv `functional_checks` is restored. sorting/SPARK4/Ada-SPARK-Bogosort (H027) was reworked as a bounded random shuffle with an explicit Sorted / Gave_Up outcome (22bdaf31).

## How to work a row

1. Restore the toolchain (`docs/TOOLCHAIN.md`) and run the row's `reproduce` command on a cold copy (delete `obj/`, `gnatprove/`).
   Some projects use shared sources from the level directory. The bulk run copied them in (`/workspace/aa/inv_by_id.json`). If gnatprove cannot find a unit, use the folder's `make prove`.
2. Prefer proof hints to compute: loop invariants, ghost lemmas, tighter subtypes, splitting a subprogram. Steps are never raised above 1,000,000 to close a row, and a wall cap is a safety stop, never a result.
3. When the pass condition holds, close the row: set `status` to `closed <commit>`, keep the row, and update PROOFS.csv through the normal re-proof.
