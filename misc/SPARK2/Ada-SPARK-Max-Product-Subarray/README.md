# Ada-SPARK-Max-Product-Subarray

Bounded Ada/SPARK maximum-product-subarray dynamic program: `Compute` returns the
largest product of a non-empty contiguous subarray of six elements.

Elements are of subtype `Element` (-6 .. 6), so every subarray product fits
`Result` (6 ** 6 = 46_656) and the proof shows no product is ever capped.
Larger elements are rejected by the type (Constraint_Error); earlier versions
accepted -10 .. 10 and silently capped products at 100_000.

`make test` runs the own tests (sources in tests/SOURCES.txt); `make prove` runs
SPARK level-2 proof with cvc5.
