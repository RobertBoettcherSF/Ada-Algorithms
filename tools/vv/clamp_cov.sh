#!/bin/bash
# usage: tools/vv/clamp_cov.sh FOLDER FILE LINE... -> gcov execution counts of those lines under the folder's own tests (GNAT 14, scratch copy)
set -u; R=$(git -C "$(dirname "$0")" rev-parse --show-toplevel); F=$1; f=$2; shift 2
W=$(mktemp -d); cp -r $R/$F/. $W/; cd $W; rm -rf obj bin
main=$(for c in tests.adb test*.adb tests/main.adb src/tests.adb; do [ -f $c ] && { echo $c; break; }; done)
mkdir -p obj bin; cd obj
gnatmake -q -gnat2022 -gnata -fprofile-arcs -ftest-coverage -I.. -I../src -I../tests ../$main -o ../bin/t -largs -fprofile-arcs >/dev/null 2>&1 || { echo BUILD-FAIL; exit 1; }
../bin/t >/dev/null 2>&1; echo "tests rc=$?"
gcov -o . ../$f >/dev/null 2>&1
f=$(basename $f)
for l in "$@"; do printf "%s:%s " $f $l; rg "^\s*\S+:\s*$l:" $f.gcov | head -1 | awk -F: '{print "count="$1}'; done
