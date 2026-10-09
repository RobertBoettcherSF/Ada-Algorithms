#!/bin/bash
# Cold, reproducible Silver re-proof of one folder with the canonical settings
# in tools/vv/prove_settings.txt.  usage: reproof.sh FOLDER GPR WORKROOT
# Cold start: the folder is copied to a fresh work dir, its obj/, bin/,
# gnatprove/ and any proof/ session dirs are deleted before proving, and
# gnatprove runs with -f (no reuse of earlier results; no --replay).
set -u
F=$1; GPR=$2; WR=$3; R=$(git rev-parse --show-toplevel)
export PATH=$(ls -d "${AA_ALR_DIR:-$HOME/.local/alr}"/gnatprove_* | head -1)/bin:$(ls -d "${AA_ALR_DIR:-$HOME/.local/alr}"/gprbuild_* | head -1)/bin:/usr/bin:/bin
STEPS=$(sed -n 's/^steps=//p' "$R/tools/vv/prove_settings.txt")
CAP=$(sed -n 's/^wall_cap_seconds=//p' "$R/tools/vv/prove_settings.txt")
PROVERS=$(sed -n 's/^provers=//p' "$R/tools/vv/prove_settings.txt")
# Jobs: jobs_per_folder from the settings; AA_REPROOF_JOBS overrides it for the
# wall-cap retry pass (see prove_settings.txt: same steps, same provers).
JOBS=${AA_REPROOF_JOBS:-$(sed -n 's/^jobs_per_folder=//p' "$R/tools/vv/prove_settings.txt")}
W="$WR/$(echo "$F" | tr '/' '_')"; rm -rf "$W"; mkdir -p "$W"
# AA_REPROOF_EXTRA: switches appended after the canonical ones; only used as
# AA_REPROOF_EXTRA=--proof-warnings=off for a folder whose project-level proof
# warnings exhaust memory (prove_settings.txt, pass reproof-20261009-2).
S=${AA_REPROOF_SRC:-$R}   # snapshot root (git archive of one commit) or the work tree
cp -r "$S/$F"/. "$W/"; cd "$W"
find . -depth -type d \( -name obj -o -name bin -o -name gnatprove -o -name proof \) -exec rm -rf {} +
[ -f "$GPR" ] || GPR=$(ls *.gpr | head -1)
s=$(date +%s)
timeout "$CAP" gnatprove -P "$GPR" -f --mode=silver --level=2 --prover="$PROVERS" \
  --timeout=0 --steps="$STEPS" --counterexamples=off --report=statistics \
  --output=oneline -k -j"$JOBS" ${AA_REPROOF_EXTRA:-} > prove.log 2>&1
echo "rc=$? secs=$(( $(date +%s) - s )) gpr=$GPR j=$JOBS${AA_REPROOF_EXTRA:+ extra=${AA_REPROOF_EXTRA// /_}}" > result.txt
