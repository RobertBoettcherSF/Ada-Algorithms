#!/usr/bin/env bash
# Per-folder gate for the whole-repo sweep (docs/VV.md 3i):
# make test on GNAT 14 and GNAT 12 (clean git-archive copy, so only committed
# or staged-in-worktree files count), the do-nothing check, and mutation
# testing over every operator site.  usage: sweep_check.sh FOLDER
set -u
F=$1; ROOT=$(cd "$(dirname "$0")/../.." && pwd); cd "$ROOT"
G12=$(ls -d ~/.local/alr/gnat_native_12*/bin | head -1); GPR=$(ls -d ~/.local/alr/gprbuild_*/bin | head -1)
W=$(mktemp -d /tmp/sweepchk.XXXX)
mkdir -p "$W/14" "$W/12"
cp -r "$F/." "$W/14/"; cp -r "$F/." "$W/12/"; rm -rf "$W"/1?/obj "$W"/1?/bin
r14=$( (cd "$W/14" && make -s test >log 2>&1) && echo pass || echo FAIL)
r12=$( (cd "$W/12" && PATH="$G12:$GPR:$PATH" make -s test >log 2>&1) && echo pass || echo FAIL)
w14=$(grep -c "warning:" "$W/14/log"); w12=$(grep -c "warning:" "$W/12/log")
echo "gnat14=$r14 warnings=$w14  gnat12=$r12 warnings=$w12"
[ "$r14" = pass ] || tail -5 "$W/14/log"; [ "$r12" = pass ] || tail -5 "$W/12/log"
python3 tools/vv/donothing.py --folders "$F" --out "$W/dn.csv" --work "$W/dn" -j 2 >/dev/null 2>&1; python3 -c "import csv,sys; [print('donothing main=%s main_result=%s verdict=%s' % (r['main'], r['main_result'], r['verdict'])) for r in csv.DictReader(open(sys.argv[1]))]" "$W/dn.csv"
python3 tools/vv/sweep_mutate.py "$F" --max 400 -j 4 --out "$W/mut.csv" --work "$W/mut" >/dev/null 2>&1
tail -n +2 "$W/mut.csv"
grep ",survived$" "$W/mut_detail.csv" | cut -c1-240
rm -rf "$W"
