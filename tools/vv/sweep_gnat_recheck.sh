#!/usr/bin/env bash
# Recheck "builds, tests pass, zero warnings" on GNAT 14 (system) and GNAT 12
# (Alire) for each folder, from a clean git-archive copy of HEAD, and log the
# compiler version actually used for every result.  The GNAT 14 run strips
# Alire toolchains from PATH (an interactive PATH with gnat_native_12 first
# silently turns "GNAT 14" runs into GNAT 12 runs).
# usage: sweep_gnat_recheck.sh OUT.csv FOLDER...
set -u
OUT=$1; shift
ROOT=$(cd "$(dirname "$0")/../.." && pwd); cd "$ROOT"
P14=$(echo "$PATH" | tr ':' '\n' | grep -v -e gnat_native -e gprbuild_ | paste -sd:)
P12="$(ls -d ~/.local/alr/gnat_native_12*/bin | head -1):$(ls -d ~/.local/alr/gprbuild_*/bin | head -1):$P14"
REV=$(git rev-parse --short HEAD)
echo "folder,expected,gnatmake_version,gcc_version,make_test_exit,warnings,last_line,commit" > "$OUT"
for F in "$@"; do
  for c in 14 12; do
    if [ $c = 14 ]; then P=$P14; else P=$P12; fi
    D=$(mktemp -d); git archive HEAD "$F" | tar -x -C "$D"
    gm=$(PATH=$P gnatmake --version | head -1); gc=$(PATH=$P gcc --version | head -1)
    case "$gm" in *" $c."*) ;; *) gm="WRONG COMPILER: $gm";; esac
    (cd "$D/$F" && PATH=$P timeout 300 make test > out.txt 2>&1); e=$?
    w=$(grep -c "warning" "$D/$F/out.txt")
    last=$(grep -v '^\s*$' "$D/$F/out.txt" | tail -1 | tr ',"' ';'"'" | cut -c1-120)
    echo "$F,GNAT $c,$gm,$gc,$e,$w,\"$last\",$REV" >> "$OUT"
    rm -rf "$D"
  done
done
