#!/bin/bash
# always_terminates_check.sh FOLDER [WORKDIR]
# Prove the folder as-is (orig) and a copy with every "Always_Terminates => True," line removed (noat),
# then list the termination / variant lines of each run (WORKDIR/<v>/term.txt). Used for handover H138/H139
# (tools/vv/always_terminates_gnat12.csv): an aspect GNAT 12 rejects may only be dropped if the noat run
# raises no termination check.
# Needs gnatprove 16.1.0 on PATH (Alire: tools/toolchain/alire). FOLDER is repo-relative.
# Committed from the box scratch script /tmp/main2/at.sh on 2026-10-09 with the hard-coded
# repo and work paths replaced; prover switches unchanged.
set -u
R=$(cd "$(dirname "$0")/../.." && pwd); F=$1; N=$(echo "$F" | tr / _)
W=${2:-$(mktemp -d)}; B=$W/$N; rm -rf "$B"; mkdir -p "$B"
if ! command -v gnatprove >/dev/null; then
  GP=$(ls -d "$HOME"/.local/alr/gnatprove_16.1.0_*/bin 2>/dev/null | head -1); GB=$(ls -d "$HOME"/.local/alr/gprbuild_*/bin 2>/dev/null | head -1)
  export PATH=$GP:$GB:$PATH
fi
ulimit -v 4194304
for v in orig noat; do
  cp -r "$R/$F" "$B/$v"; cd "$B/$v" || exit 1
  find . -depth -type d \( -name obj -o -name bin -o -name gnatprove -o -name proof \) -exec rm -rf {} +
  if [ $v = noat ]; then for f in $(grep -l Always_Terminates *.ad[sb]); do sed -i '/Always_Terminates *=> *True,/d' "$f"; done; fi
  G=$(ls *.gpr | grep -m1 proof.gpr || ls *.gpr | head -1)
  nice gnatprove -P "$G" -f --mode=silver --level=2 --prover=cvc5,z3,altergo --timeout=0 --steps=1000000 \
    --counterexamples=off --report=all --output=oneline -k -j2 > p.log 2>&1; echo "$v rc=$?"
  grep -i "terminat\|variant" p.log | sed 's/(.*//' > term.txt; grep -E ": (low|medium|high|error|warning)" p.log | head
done
echo "work dir: $B"
