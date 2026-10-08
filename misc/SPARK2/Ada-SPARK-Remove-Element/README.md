# Remove Element in SPARK

A bounded Ada/SPARK implementation with arrays limited to 32 elements.

`Remove (Data, Length, Target)` packs the elements of `Data (1 .. Length)`
that differ from `Target` to the front (keeping their order) and sets
`Length` to their number; this includes the full length 32.
