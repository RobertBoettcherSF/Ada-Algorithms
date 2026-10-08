#!/bin/sh
#  Named-phase check (docs/VV.md 3i, pattern 7): the cycle phase must sort
#  on its own, not through the selection-sort safety net at the end of
#  Cycle_Step.  Builds a scratch copy in which that net is replaced by a
#  failing assertion, runs the test suite against it, and exits non-zero
#  on failure.  The net is dead at run time, so this passes; it is not a
#  bug, and it comes first so the proof change that removes the net is
#  tested against it.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
cp "$here"/cycle_sort.ads "$here"/tests.adb "$d"/
python3 - "$here/cycle_sort.adb" "$d/cycle_sort.adb" <<'PY'
import sys
s=open(sys.argv[1]).read()
a=s.index('      --  Unreachable for n')
b=s.index('   end Cycle_Step;')
s=s[:a]+'''      pragma Assert (False);  --  removed by tests/phase_alone.sh

'''+s[b:]
open(sys.argv[2],'w').write(s)
PY
cd "$d"
gnatmake -q -gnat2022 -gnata -gnatwa tests.adb -o phase_alone
echo "Named-phase check (Cycle_Step without the selection-sort safety net):"
./phase_alone
