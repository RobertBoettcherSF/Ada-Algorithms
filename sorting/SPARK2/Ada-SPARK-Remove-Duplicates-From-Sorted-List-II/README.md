# Ada-SPARK-Remove-Duplicates-From-Sorted-List-II

Remove Duplicates From Sorted List II with a bounded, array-backed list (capacity 16, no access types):
`Solve` removes every value that occurs more than once and keeps the values that occur exactly once, in
their input order (1 1 1 2 3 3 -> 2). It does not rely on the list being sorted.

- Postcondition (proved at Silver level 2 with cvc5, 33 checks): the result holds exactly the values that
  occur once in the input (every output value is a once-only input value and every once-only input value
  is in the output). That the order is kept is checked by the tests, not stated in the contract.

```text
make test    # tests/main.adb + own occurs-once reference, 5,000 random lists (tests/SOURCES.txt)
make prove   # GNATprove level 2 with cvc5 (make check = prove + test)
```
