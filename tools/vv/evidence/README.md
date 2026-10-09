# V&V evidence (verbatim copies)

Files that docs or records cited from box scratch directories outside the repo, committed
2026-10-09 so a fresh clone can see them. They are kept byte-for-byte as recorded, so they may
still name the box paths they ran in; `tools/vv/check_paths.py` skips this directory for that reason.

| file | cited by |
|---|---|
| flaky/f14_p23.csv | docs/VV.md (flakiness passes 2-3, GNAT 14, 1758 folders) |
| flaky/g12_tr.csv | docs/vv_status/aa_round_status.md (GNAT 12 three-pass, 271 folders; merged into tools/vv/flaky.csv) |
| flagship_phase2/flag_heldout.py, flag_mutate.py | tools/vv/flagship_mutation_phase2.csv (alt-family held-out set). Historical: they load each other and `sweep_mutate` from the box paths they were written for; to rerun, point those two paths at `tools/vv/`. |
