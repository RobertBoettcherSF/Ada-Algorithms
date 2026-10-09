# Handover evidence

Verbatim copies of files that `tools/vv/handover.csv` rows cited from box scratch directories
outside the repo (committed 2026-10-09 so a fresh clone can see them). One directory per row id;
files shared by several rows live under the first row that cites them (H001 prove log is also
H002/H003's; `H001/prove_steps_20261008.jsonl` is also cited by H012/H013).

| dir | what | cited by |
|---|---|---|
| H001-H011 | `prove.log` of the 2026-10-08 Silver steps run for the row's folder | H001-H011 |
| H001/prove_steps_20261008.jsonl | per-folder status/rc/seconds of that run | H001, H012, H013 |
| run_20261008/inv_by_id.json | shared-source inventory the bulk run used | docs/HANDOVER.md |
| H097, H098, H099 | agent A3 draft patches (Topological-Sort, Sort-Merge-Join, Selection-Algorithm), diagnostic logs, test source lists | H097-H099 |
| H129 (Slowsort), H130 (Stooge-Sort) | sweep_mutate.py summary + detail CSVs and logs (tune/held std+alt, dummy, sealed top-up) | H129, H130 |
| H141/fr_lh4, H141/fr_lh5 | the same for Lemke-Howson; fr_lh4 also has the proof-kill summary (pk.out, proofkill.csv) | H141 |
| H139 | snapshot of the shared agent claims file | H139 |

Per-mutant work trees (hundreds of MB) were not kept: the row's `reproduce` command rebuilds them
with `tools/vv/sweep_mutate.py` and `tools/vv/proofkill.py` in a `mktemp -d` scratch dir.
Files here are kept as recorded, so they may still mention the box paths they were produced in;
`tools/vv/check_paths.py` skips this directory for that reason.
