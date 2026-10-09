# Ada-SPARK-Capacity-To-Ship-Packages

Find the minimum shipping capacity that ships 8 packages (weights 1 .. 100), in order, within a given number of days: a binary search on the answer over heaviest package .. 800, with a greedy feasibility pass per capacity tried (at most 10). Written in SPARK; the Post states the result fits and no smaller capacity does.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors.
