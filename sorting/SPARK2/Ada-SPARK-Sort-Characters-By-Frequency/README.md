# Ada-SPARK-Sort-Characters-By-Frequency

Sort Characters By Frequency in SPARK for 8 characters: the output holds the input characters by decreasing
frequency, with equal characters next to each other (as the problem requires); characters with the same
frequency are ordered by character code, so the result is deterministic. Selection sort on the key
`Rank = (8 - frequency in Input) * 256 + character code`. (An earlier version could leave characters with
equal frequency interleaved, e.g. a b a b.)

- Postcondition: the output is sorted by `Rank` (decreasing frequency, equal characters grouped); proved at
  Silver level 2 with the default level-2 provers (42 checks; cvc5 alone gives up on two invariants). That
  the output is a permutation of the input is checked by the tests, not proved.

```sh
make test    # own frequency-order, grouping and permutation checks (tests/SOURCES.txt)
make prove
```
