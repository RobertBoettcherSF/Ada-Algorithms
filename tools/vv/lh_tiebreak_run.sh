#!/bin/bash
# run.sh VARIANT : all chunks of 20000 games, sequential, nice
cd "$1" || exit 1   # a directory holding the (mutant) lemke_howson.ad? and the drive executable built from tools/vv/lh_tiebreak_drive.adb
: > res.txt
for spec in "a 262144" "b23 531441" "b32 531441"; do
  set -- $spec
  for ((s=0; s<$2; s+=20000)); do
    nice ./drive $1 $s $((s+19999)) >> res.txt 2>&1 || echo "RC $? $1 $s" >> res.txt
  done
done
echo DONE >> res.txt
