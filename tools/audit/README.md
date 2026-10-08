# Audit scripts

Per-folder runners used to produce `PROOFS.md` / `PROOFS.csv`. They copy the folder to a scratch
directory, so the repo tree is never written to.

* `build_folder.sh <topic/LEVEL/Folder>` - `make test` with GNAT 14 (system `/usr/bin`) and GNAT 12
  (`GNAT12_BIN`, default: Alire `~/.local/alr/gnat_native_12*/bin`), plus a uniform
  `gnatmake -gnatwa -gnat2022 tests.adb` build on both for the warning count. Prints one JSON line.
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
