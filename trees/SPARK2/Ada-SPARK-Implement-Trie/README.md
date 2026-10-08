# Ada-SPARK-Implement-Trie

A bounded dictionary with trie-style insert and exact lookup operations. Implemented as a small bounded Ada SPARK example with `SPARK_Mode => On`.

```sh
make test
make prove
```

`Insert` of a word already present changes nothing; a new word needs a
free slot (precondition `T.Used < Max_Words or else Contains (T, W)`), so
a full structure rejects it instead of silently dropping it. Note: the
storage is a flat word list, not trie nodes (see tools/vv/hidden_stub.csv).
