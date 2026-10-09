# Ada-SPARK-Task-Scheduler-Stub

Non-preemptive shortest-job-first scheduling: `Shortest_First` returns the order in which to run the tasks, shortest duration first, equal durations in submission (index) order. Any number of tasks up to `Max_Tasks`, any lower bound. Insertion sort of the task indices by (duration, index).

The package is compiled with `SPARK_Mode => On`. The Post states the real result: every slot names a task and consecutive slots are strictly in (duration, index) order, which also means every task appears exactly once. Proved at mode all, level 2 with cvc5, no Assume.

`make test` compares against a simple reference (walk durations 1..20, list matching tasks in index order) on every array of length 0..7 with durations 1..3, 20,000 seeded random arrays (seed 20261009, length up to 30, random lower bound), and named cases.

## Verification

```text
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
