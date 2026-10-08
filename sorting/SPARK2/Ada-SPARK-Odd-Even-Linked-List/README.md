# Ada-SPARK-Odd-Even-Linked-List

A bounded, array-backed Ada SPARK implementation of the Odd Even Linked List
exercise: `Solve (L)` puts the nodes at odd positions (1st, 3rd, ...) first and the
nodes at even positions after them, each group in its original order. Grouping is
by position, not by value (earlier versions grouped by odd/even value). The list
capacity is 16 and uses no access types.

```text
make test    # own tests (tests/main.adb, sources in tests/SOURCES.txt)
make prove   # GNATprove level 2 with cvc5
make check   # both
```
