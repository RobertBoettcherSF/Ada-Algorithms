#!/bin/bash
# Build and run every Pre-rejection driver (GNAT 14 on PATH); prints one
# line per subprogram: folder|subprogram|generator|sample|rejected.
set -e
cd "$(dirname "$0")"; R=$(cd ../../.. && pwd)
declare -A DIR=( [pr_merge_sort]=sorting/SPARK4/Ada-SPARK-Merge-Sort [pr_samplesort]=sorting/SPARK4/Ada-SPARK-Samplesort
 [pr_timsort]=sorting/SPARK4/Ada-SPARK-Timsort [pr_library_sort]=sorting/SPARK4/Ada-SPARK-Library-Sort
 [pr_quantum_sort]=sorting/SPARK4/Ada-SPARK-Quantum-Sort [pr_burstsort]=sorting/SPARK4/Ada-SPARK-Burstsort
 [pr_trigram]=searching/SPARK2/Ada-SPARK-Trigram-Search [pr_sstf]=misc/SPARK4/demo
 [pr_heaps]=misc/SPARK4/Ada-SPARK-Heaps-Algorithm [pr_guess]=misc/SPARK2/Ada-SPARK-Guess-Number-Higher-Or-Lower
 [pr_reduce]=misc/SPARK2/Ada-SPARK-Reduce-Array-Size-To-The-Half
 [pr_rotated]=sorting/SPARK2/Ada-SPARK-Find-Minimum-In-Rotated-Sorted-Array
 [pr_modular]=numerical/SPARK4/Ada-SPARK-Modular-Arithmetic [pr_lemke]=misc/SPARK4/Ada-SPARK-Lemke-Howson
 [pr_bst]=searching/SPARK2/Ada-SPARK-Insert-Into-A-Binary-Search-Tree [pr_pathsum]=misc/SPARK2/Ada-SPARK-Path-Sum
 [pr_stack]=misc/SPARK2/Ada-SPARK-Stack-Bounded [pr_fisher]=misc/SPARK2/Ada-SPARK-Fisher-Yates-Shuffle )
W=$(mktemp -d)
for d in $(printf '%s\n' "${!DIR[@]}" | sort); do
  mkdir -p $W/$d
  gnatmake -q -gnat2022 -gnata -gnatwa -D $W/$d -o $W/$d/run -aI. -aI$R/${DIR[$d]} $d.adb >$W/$d/build.log 2>&1 || { echo "BUILD FAIL $d" >&2; cat $W/$d/build.log >&2; continue; }
  $W/$d/run
done
rm -rf $W
