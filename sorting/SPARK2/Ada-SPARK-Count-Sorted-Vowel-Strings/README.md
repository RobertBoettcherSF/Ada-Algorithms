# Ada-SPARK-Count-Sorted-Vowel-Strings

How many strings of length N over the vowels a, e, i, o, u are sorted, that is, each letter is at least the one before it. In SPARK.

`Number_Of_Strings (N, From)` counts the sorted strings that use only the vowels `From` .. `U`; `From` defaults to `A`, which means all five vowels. The count comes from the vowel dynamic program. A sorted string over `From` .. `U` either does not use `From` at all, so it is a sorted string over the later vowels, or it starts with `From` and goes on with a sorted string of length N - 1 over `From` .. `U`.

**Range widened:** the first version was a case table of C (n + 4, 4) for n <= 16. The limit is now n <= 473, and it comes from arithmetic: C (477, 4) = 2_130_031_575 fits `Natural`, and C (478, 4) = 2_148_006_525 does not. Every value the program computes along the way is at most the final one.

The proved contracts (339 checks):
- `Weight (From) * result = Rising (N, From)`, the closed form C (N + k, k) with k = 4 - position of `From`, kept scaled so that no division is needed;
- no overflow;
- `Lemma_Closed_Form`: the closed form equals the ghost recursive definition `Sorted_Count` (the two cases above). The lemma is proof only, because `Sorted_Count` takes exponential time to run.

## Checks

```text
make test
make prove
```

`make prove` runs level-2 GNATprove with cvc5, warnings as errors and checks as errors, on `proof.gpr` (the package only). `make test` runs `tests.adb` and the own checks (see `tests/SOURCES.txt`).
