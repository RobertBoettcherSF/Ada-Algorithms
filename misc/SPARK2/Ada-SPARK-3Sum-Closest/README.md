# Ada-SPARK-3Sum-Closest

Bounded SPARK implementation of 3Sum Closest. Inputs are bounded to at most 32 elements.

`Closest (Data, Length, Target)` returns the sum of three values at distinct
positions of `Data (1 .. Length)` closest to `Target`. `Length` is subtype
`Triple_Length` (3 .. 32): fewer values have no triple. When several sums
are equally close, the one of the first triple in position order
(I < J < K, lexicographic) is returned.

```sh
make test
make prove
```
