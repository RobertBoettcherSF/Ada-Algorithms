#!/bin/sh
#  Named-phase check (docs/VV.md 3i, pattern 7): the library-sort phase must
#  sort on its own, not only through a final fallback pass.  Builds a
#  scratch copy of the library in which a Bubble_Finish call in the body
#  (if there is one) is replaced by null, runs the own property checks
#  (sorted + same multiset) against it, and exits non-zero on failure.
set -eu
here=$(cd "$(dirname "$0")/.." && pwd)
if ! grep -q '^ *Bubble_Finish (A);' "$here"/library_sort.adb; then
  #  No fallback call in the body: the scratch copy would be the library
  #  itself, which the main test run has just checked.
  echo "Named-phase check: Sort has no Bubble_Finish call; the main test run covers the library phase alone."
  exit 0
fi
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
cp "$here"/library_sort.ads "$here"/library_sort.adb "$here"/own_checks.adb "$d"/
sed 's/^\( *\)Bubble_Finish (A);/\1null;  --  removed by tests\/phase_alone.sh/' \
  "$here"/library_sort.adb > "$d"/library_sort.adb
cat > "$d"/phase_alone.adb <<'EOF'
with Own_Checks;
procedure Phase_Alone is
begin
   Own_Checks;
end Phase_Alone;
EOF
cd "$d"
gnatmake -q -gnat2022 -gnata -gnatwa phase_alone.adb -o phase_alone
echo "Named-phase check (Sort without any Bubble_Finish call):"
./phase_alone
