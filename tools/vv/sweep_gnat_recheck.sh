#!/usr/bin/env bash
# Recheck "builds, tests pass, zero warnings" on GNAT 14 (system) and GNAT 12
# (Alire) for each folder, from a clean git-archive copy of HEAD, and log the
# compiler version actually used for every result.  The GNAT 14 run strips
# Alire toolchains from PATH (an interactive PATH with gnat_native_12 first
# silently turns "GNAT 14" runs into GNAT 12 runs).
#
# compiler_*_version = first line of `gnatls --version` on that toolchain PATH.
# GNAT 12 = Alire ~/.local/alr/gnat_native_12* → GNATLS 12.2.0. Never gcc-12
# (Debian C 12.4.0) or /home/box/deps/gnat12 (also 12.4.0).
# usage: sweep_gnat_recheck.sh OUT.csv FOLDER...
set -u
OUT=$1; shift
ROOT=$(cd "$(dirname "$0")/../.." && pwd); cd "$ROOT"
P14=$(echo "$PATH" | tr ':' '\n' | grep -v -e gnat_native -e gprbuild_ | paste -sd:)
P12="$(ls -d ~/.local/alr/gnat_native_12*/bin | head -1):$(ls -d ~/.local/alr/gprbuild_*/bin | head -1):$P14"
REV=$(git rev-parse --short HEAD)
echo "folder,expected,gnatls_version,make_test_exit,warnings,last_line,commit" > "$OUT"
for F in "$@"; do
  for c in 14 12; do
    if [ $c = 14 ]; then P=$P14; else P=$P12; fi
    D=$(mktemp -d); git archive HEAD "$F" | tar -x -C "$D"
    gl=$(PATH=$P gnatls --version | head -1)
    if [ $c = 14 ]; then
      case "$gl" in "GNATLS 14."*) ;; *) gl="WRONG COMPILER: $gl";; esac
    else
      case "$gl" in "GNATLS 12.2."*) ;; *) gl="WRONG COMPILER: $gl";; esac
    fi
    (cd "$D/$F" && PATH=$P timeout 300 make test > out.txt 2>&1); e=$?
    w=$(grep -c "warning" "$D/$F/out.txt")
    last=$(grep -v '^\s*$' "$D/$F/out.txt" | tail -1 | tr ',"' ';'"'" | cut -c1-120)
    echo "$F,GNAT $c,$gl,$e,$w,\"$last\",$REV" >> "$OUT"
    rm -rf "$D"
  done
done
