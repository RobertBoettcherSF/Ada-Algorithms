# Audit scripts

Per-folder runners used to produce `PROOFS.md` / `PROOFS.csv`. They copy the folder to a scratch
directory, so the repo tree is never written to.

* `build_folder.sh <topic/LEVEL/Folder>` - `make test` with GNAT 14 (system `/usr/bin`) and GNAT 12
  (`GNAT12_BIN`, default: Alire `~/.local/alr/gnat_native_12*/bin`), plus a uniform
  `gnatmake -gnatwa -gnat2022 tests.adb` build on both for the warning count. Prints one JSON line.
  It refuses to run (JSON line with `error`, exit 2) unless the first line of `gnatmake --version` says
  14 on the GNAT 14 PATH and 12 on the GNAT 12 PATH (gcc's version too). It records both strings
  (`ver14`, `ver12`; PROOFS.csv `compiler_14_version` / `compiler_12_version`). The warning count
  (`wall14`, `wall12`) is the number of distinct warnings over the uniform build and the folder's own
  `make test` build, because some warnings only appear with the folder's flags (e.g. `-gnata`).
  `make test` timeouts default to 900 s (`AA_MAKE_TIMEOUT`); `timeout` kills the whole process group.
* `prove_folder.sh <topic/LEVEL/Folder>` - `gnatprove --mode=silver --level=2` on the folder's own
  .gpr (Makefile `PROOF_PROJECT`, else `proof*.gpr`, else the Makefile project, else the only .gpr;
  generates `aa_generated.gpr` only when there is none). Prints one JSON line.
* Optional `AA_DEPS=deps.json` maps folder -> shared loose files (at `topic/LEVEL/`) copied in first.

```sh
ls -d */{Ada,SPARK2,SPARK4}/*/ | sed 's#/$##' > /tmp/ids.txt
xargs -P4 -n1 tools/audit/build_folder.sh < /tmp/ids.txt > /tmp/res/build.jsonl
xargs -P4 -n1 tools/audit/prove_folder.sh < /tmp/ids.txt > /tmp/res/prove.jsonl
python3 tools/proof_index.py --results /tmp/res --logs /tmp/aa_prove    # or: make proof-index RESULTS=/tmp/res
```
