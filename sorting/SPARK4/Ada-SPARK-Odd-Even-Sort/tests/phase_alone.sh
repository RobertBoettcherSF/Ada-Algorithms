#!/bin/sh
#  Named-phase check (docs/VV.md 3i, pattern 7): the odd-even transposition phase must
#  sort on its own, not only through a final fallback pass.  Builds a
#  scratch copy of the library in which a Bubble_Finish call in the body
#  (if there is one) is replaced by null, runs the test suite (sorted, with
#  Sort's postcondition checked at run time, and same multiset) against
#  it, and exits non-zero on failure.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
cp "$here"/odd_even_sort.ads "$here"/tests.adb "$d"/
sed 's/^\( *\)Bubble_Finish (A);/\1null;  --  removed by tests\/phase_alone.sh/' \
  "$here"/odd_even_sort.adb > "$d"/odd_even_sort.adb
cd "$d"
gnatmake -q -gnat2022 -gnata -gnatwa tests.adb -o phase_alone
echo "Named-phase check (Sort without any Bubble_Finish call):"
./phase_alone
