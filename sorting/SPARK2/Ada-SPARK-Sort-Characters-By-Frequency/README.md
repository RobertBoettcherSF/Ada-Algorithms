# Ada-SPARK-Sort-Characters-By-Frequency

Sort Characters By Frequency in SPARK for 8 characters: the output holds the input characters by decreasing
frequency, with equal characters next to each other (as the problem requires); characters with the same
frequency are ordered by character code, so the result is deterministic. Selection sort on the key
`Rank = (8 - frequency in Input) * 256 + character code`. (An earlier version could leave characters with
equal frequency interleaved, e.g. a b a b.)

- Postcondition: the output is sorted by `Rank` (decreasing frequency, equal characters grouped) and holds
  the characters of the input, each as often as in the input (`Frequency (Result, C) = Frequency (Input, C)`
  for every Character); proved at level 4 and with the Silver command (gnatprove 16.1.0, 44 checks, proof
  warnings on: none). Before 2026-10-09 the Post had the order only, which a result of eight copies of one
  character also met (tools/vv/contract_scan.csv).

```sh
make test    # own frequency-order, grouping and permutation checks (tests/SOURCES.txt)
make prove
```
