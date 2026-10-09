# Ada-SPARK-Delete-And-Earn

Delete and Earn in SPARK. `Max_Earn (Nums)` takes an array of up to 100 numbers in 1 .. 100: pick a number X, earn X, and every copy of X - 1 and X + 1 is deleted; repeat until the array is empty, and return the best total. `Maximum (N)` is `Max_Earn` on 1, 2, .., N (each value once).

Once one copy of X is taken, the other copies can be taken for free, so the answer is the best total of Points (X) = X * (copies of X) over a set of values with no two adjacent. The code sums the points per value in one pass, then walks the values 1 .. 100 keeping the best totals with and without the previous value (skip X, or take it and leave out X - 1). O(length + 100) time.

**Range widened:** the first version was a case table of `Maximum (N)` for N in 1 .. 16 and had no array input. It now takes real arrays (duplicates, gaps, any order), and N goes to 100.

The proved contract is `Max_Earn (Nums) = Best (Points_Of (Nums), 100).Upto`, where the ghost `Points_Of` sums each value's copies and the ghost `Best` is the skip/take recurrence; the bounds Points (X) <= 10_000 and Best <= K * 10_000 are proved, so nothing overflows (61 checks). `Maximum (N)` is proved against the points of 1 .. N.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
