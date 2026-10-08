# Ada-SPARK-Design-Add-And-Search-Words

A bounded add-and-search dictionary supporting the dot wildcard. Implemented as a small bounded Ada SPARK example with `SPARK_Mode => On`.

```sh
make test
make prove
```

`Add_Word` stores the word in the next free slot. It requires a free slot
(precondition `D.Used < Max_Words`), so a full dictionary rejects the call
instead of silently dropping the word.
