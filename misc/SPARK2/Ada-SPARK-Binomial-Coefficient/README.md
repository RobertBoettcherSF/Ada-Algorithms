# Ada-SPARK Binomial Coefficient

Binomial coefficients in SPARK. `Choose (N, K)` returns C (N, K) for N, K in 0 .. 30 (0 when K > N). It builds Pascal's triangle one row at a time in a single array, updating each row from right to left so that `Row (J - 1)` still holds the previous row: O(N ** 2) additions, no multiplication or division.

**Range widened:** the first version was a case table of the answers for N in 0 .. 10. The input is now 0 .. 30. Since C (N, K) <= 2 ** N, every value (largest C (30, 15) = 155_117_520) fits `Result` = 0 .. 2 ** 30, and no intermediate can overflow.

The proved contract is `Choose (N, K) = Pascal_Row (N) (K)`, where the ghost `Pascal_Row` defines row N from row N - 1 by Pascal's rule and carries the bound `<= 2 ** N` (25 checks). The ghost spec builds each row once, so the contract stays cheap to check at run time.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
