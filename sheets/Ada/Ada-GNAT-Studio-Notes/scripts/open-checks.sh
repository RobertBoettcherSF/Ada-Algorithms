#!/usr/bin/env bash
# Smoke-check that this GNAT Studio notes sheet still has its GPR + Makefile targets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

if [[ ! -f sample.gpr ]]; then
  echo "FAIL: sample.gpr missing"
  fail=1
else
  echo "OK: sample.gpr present"
fi

if [[ ! -f proof.gpr ]]; then
  echo "FAIL: proof.gpr missing"
  fail=1
else
  echo "OK: proof.gpr present"
fi

if [[ ! -f Makefile ]]; then
  echo "FAIL: Makefile missing"
  fail=1
else
  echo "OK: Makefile present"
fi

for t in test prove build clean; do
  if grep -qE "^${t}:" Makefile; then
    echo "OK: Makefile target '${t}'"
  else
    echo "FAIL: Makefile target '${t}' missing"
    fail=1
  fi
done

if [[ ! -f studio_probe.ads || ! -f studio_probe.adb ]]; then
  echo "FAIL: studio_probe sources missing"
  fail=1
else
  echo "OK: studio_probe sources present"
fi

if [[ ! -f docs/gnatstudio-linux.md || ! -f docs/alire-edit-pitfalls.md ]]; then
  echo "FAIL: docs missing"
  fail=1
else
  echo "OK: docs present"
fi

exit "$fail"
