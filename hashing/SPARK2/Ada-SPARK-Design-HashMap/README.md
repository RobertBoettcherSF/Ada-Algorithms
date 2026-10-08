# Ada-SPARK-Design-HashMap

A small bounded Ada/SPARK implementation with a runnable test and level-2 proof target.

Keys are `1 .. 4`, values `-100 .. 100`. `Put` inserts or overwrites; `Get`
needs `Contains` and returns the last value put for the key.
