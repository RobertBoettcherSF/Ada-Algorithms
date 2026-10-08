#!/bin/bash
# make vv: verification + validation over the whole repo (docs/VV.md).
#   1. build + tests on GNAT 14 and GNAT 12           tools/audit/build_folder.sh
#   2. Silver proofs, deterministic step budget       tools/audit/prove_folder.sh (AA_PROVE_STEPS)
#   3. validation: differential tests of Ada/SPARK pairs, sampled mutation testing, do-nothing check
#   4. PROOFS.md / PROOFS.csv refresh                 tools/proof_index.py
# Knobs (environment):
#   VV_OUT=/tmp/vv          results + logs
#   VV_JOBS=4               parallel build jobs (proofs use VV_JOBS/2, each gnatprove -j2)
#   VV_IDS=file             folder ids to run (default: every topic/LEVEL/Folder)
#   VV_STEPS=1000000        gnatprove --steps budget
#   VV_SKIP="build prove diff mutation donothing"   stages to skip
#   VV_PROVE_LOGS, VV_STEPS_LOGS   proof log dirs for the index when the prove stage is skipped
#   VV_MUT_SAMPLE=20 VV_MUT_PER=8 VV_SEED=20261008
set -u
R=$(git rev-parse --show-toplevel); cd "$R"
OUT=${VV_OUT:-/tmp/vv}; J=${VV_JOBS:-4}; PJ=$(( J / 2 > 0 ? J / 2 : 1 ))
STEPS=${VV_STEPS:-1000000}; SKIP=" ${VV_SKIP:-} "; SEED=${VV_SEED:-20261008}
mkdir -p "$OUT"
if [ -n "${VV_IDS:-}" ]; then cp "$VV_IDS" "$OUT/ids.txt"; else ls -d */{Ada,SPARK*}/*/ 2>/dev/null | sed 's#/$##' > "$OUT/ids.txt"; fi
echo "vv: $(wc -l < "$OUT/ids.txt") folders, results in $OUT"
case "$SKIP" in *" build "*) ;; *)
  echo "[1/4] build + tests (GNAT 14, GNAT 12)"
  xargs -P"$J" -n1 tools/audit/build_folder.sh < "$OUT/ids.txt" > "$OUT/build.jsonl" ;;
esac
case "$SKIP" in *" prove "*) ;; *)
  echo "[2/4] Silver proofs, --steps=$STEPS"
  gnatprove --version > "$OUT/toolinfo.txt" 2>&1 || true
  AA_PROVE_STEPS=$STEPS AA_PROVE_WORK="$OUT/prove" xargs -P"$PJ" -n1 tools/audit/prove_folder.sh < "$OUT/ids.txt" > "$OUT/prove.jsonl" ;;
esac
case "$SKIP" in *" diff "*) ;; *)
  echo "[3a/4] differential tests (tools/vv/diff/*)"
  python3 tools/vv/difftest.py --seed "$SEED" -j "$J" --out vv/results/diff.csv ;;
esac
case "$SKIP" in *" mutation "*) ;; *)
  echo "[3b/4] sampled mutation testing"
  python3 tools/vv/mutate.py --seed "$SEED" --sample "${VV_MUT_SAMPLE:-20}" --per-folder "${VV_MUT_PER:-8}" --out vv/results/mutation.csv ;;
esac
case "$SKIP" in *" donothing "*) ;; *)
  echo "[3d/4] do-nothing check (writes vv/results/donothing.csv for the folders in ids.txt)"
  python3 tools/vv/donothing.py --from-file "$OUT/ids.txt" -j "$J" --out vv/results/donothing.csv ;;
esac
echo "[4/4] index"
args=(--results "$OUT" --vv vv/results)
PL=${VV_PROVE_LOGS:-$OUT/prove}; [ -d "$PL" ] && args+=(--logs "$PL")
[ -n "${VV_STEPS_LOGS:-}" ] && args+=(--steps-logs "$VV_STEPS_LOGS")
[ -s "$OUT/toolinfo.txt" ] && args+=(--tool-info "$OUT/toolinfo.txt")
python3 tools/proof_index.py "${args[@]}" \
  --batch-cmd "gnatprove -P <folder gpr> --mode=silver --level=2 --timeout=0 --steps=$STEPS --counterexamples=off -j2 --output=oneline -k"
