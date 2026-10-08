# Ada-SPARK-Cheapest-Flights-Within-K-Stops

Bounded SPARK dynamic programming for cheapest flights with K stops.

The implementation uses fixed-size arrays (`n <= 16`) and is checked with GNATprove at level 2 using cvc5.

`Compute (Edges, Source, Destination, K, Result)` uses all 16 flights in
`Edges` (directed `U -> V` at `Price`) and returns the cheapest fare from
`Source` to `Destination` with at most `K` stops, i.e. at most `K + 1`
flights; `Source = Destination` costs 0, and `Result = Infinity` (1000) when
no such route exists.
