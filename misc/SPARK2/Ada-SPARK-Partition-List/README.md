# Ada-SPARK-Partition-List

A bounded, array-backed Ada SPARK implementation of the Partition List exercise:
`Solve (L, Pivot)` rearranges the list so that the values below `Pivot` come
first and the values at or above it follow, each group in its original order.
The list capacity is 16 and uses no access types.

```text
make test    # own tests (tests/main.adb, sources in tests/SOURCES.txt)
make prove   # GNATprove level 2 with cvc5
make check   # both
```
