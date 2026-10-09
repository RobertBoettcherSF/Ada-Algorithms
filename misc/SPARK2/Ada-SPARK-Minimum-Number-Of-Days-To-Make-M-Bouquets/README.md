# Ada-SPARK-Minimum-Number-Of-Days-To-Make-M-Bouquets

Minimum number of days to make M bouquets, in SPARK. Flower `I` (of `Length` = 8) blooms on day `Bloom_Days (I)` (days 1 .. 1000). A bouquet takes `Size` flowers that stand next to each other and have all bloomed. Each flower goes into at most one bouquet. The question is the first day on which `Bouquets` bouquets can be made, and whether any day works.

`Count (Bloom_Days, D, Size)` is the specification of how many bouquets day `D` gives. It scans left to right and cuts a bouquet as soon as `Size` bloomed flowers stand in a row. It is written as a recursive expression function, `Scan` over prefixes with `Step` per flower. Cutting as early as possible is optimal, because an earlier cut never leaves fewer flowers for the rest. The own checks compare `Count` with a dynamic program over all window placements.

`Minimum_Day (Bloom_Days, Bouquets, Size)` works in two steps:
1. If even day 1000 gives fewer than `Bouquets` bouquets, it reports that no day works.
2. Otherwise it binary-searches the days. `Bouquets_By` computes the count with two counters, and its loop invariant ties it to `Scan`.

The postcondition is proved:
- `Possible = (Bouquets * Size <= Length)`.
- If `Possible`, then `First_Day` gives enough bouquets, and the day before it (if any) does not.
- Otherwise `First_Day = Day'Last`, and even that day gives too few.

`Lemma_Monotone` (ghost, proved) says that a later day never gives fewer bouquets. Together with the postcondition, this means that no day before `First_Day` works, and that nothing works when `Possible` is false. The monotonicity proof keeps the later day's scan "ahead" at every flower: it has more bouquets, or as many and at least as long a run.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (73 checks).

`make test` runs `tests.adb` and the folder's own checks: 1,486,154 checks against a dynamic program over window placements (see `tests/SOURCES.txt`).

The first version had no `Bouquets` parameter: it found the first day with a single run of `Size` bloomed flowers by trying every day from 1 to 1000. It had no contract, and its README claimed n <= 32 while `Length` was 8.
