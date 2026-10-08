# Ada-SPARK-Find-The-Smallest-Divisor

Find the smallest divisor D such that the sum of the rounded-up quotients
ceil(v / D) over eight values (1 .. 1000) is at most a limit.

The limit is of subtype `Threshold` (8 .. 8000): every quotient is at least 1, so a
limit below the number of values can never be met and is rejected by the type
(Constraint_Error); earlier versions returned 1000 for it as if it were an answer.
The postcondition states the answer: its quotient sum meets the limit and D - 1's
does not (ghost `Quotient_Sum`).

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 (its default provers), warnings as errors,
and checks as errors. Test sources: tests/SOURCES.txt.
