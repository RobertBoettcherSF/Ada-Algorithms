# Ada-SPARK-Domino-And-Tromino-Tiling-Lite

Domino and tromino tiling in SPARK. `Number_Of_Tilings (N)` counts the tilings of a 2 x N board with 2 x 1 dominoes (either way) and L-trominoes (any rotation).

The code walks the columns and keeps three counts: full boards of length I and I - 1, and partial boards (length I - 1 plus one cell of column I). A full board ends in a vertical domino, two horizontal dominoes, or a tromino over a partial board (two mirror images). A partial board ends in a tromino or a horizontal domino. O(N) additions.

**Range widened:** the first version was a case table for N in 0 .. 16. N now goes to 28. The limit comes from the arithmetic: T (28) = 1_914_332_891 fits `Natural`, and T (29) = 4_222_194_104 does not.

The proved contract is `Number_Of_Tilings (N) = Tiles (N).Full`, where the ghost `Tiles` is the full/partial recurrence (26 checks). To show that nothing overflows, the proof needs the size of each count. Two ghost tables give the values for N <= 28, and the proof checks every entry against the recurrence. The code never reads them, and the tests regenerate them.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
