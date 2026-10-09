# Ada-SPARK-Guess-Number-Higher-Or-Lower

Guess number higher or lower, in SPARK. A number `Secret` in 1 .. `N` (`N` <= 32) is hidden, and every guess is answered only with `Lower`, `Equal` or `Higher` (`Probe`).

`Guess_Number (N, Secret)` binary-searches 1 .. `N`, always guessing the middle of the remaining range. The body reads `Secret` only through `Probe`. It returns the answer and the number of guesses. The postcondition is proved: the answer is `Secret`, and it took between 1 and floor(log2 N) + 1 guesses (`Max_Probes`), which is the best possible worst case. The loop invariant keeps at most 2 ** (guesses left) - 1 candidates.

## Checks

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```

`make prove` runs GNATprove at level 2 with cvc5, warnings as errors, and checks as errors (20 checks).

The first version scanned 1 .. 32 and compared each guess with `Secret` directly. That is neither the higher/lower game nor a binary search.
