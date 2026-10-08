# Ada-SPARK-Merge-Two-Sorted-Lists

Small bounded SPARK implementation using arrays with a maximum of 16 nodes or elements.

`Merge` requires `Length (A) + Length (B) <= 16` and guarantees the result
holds every element of both lists (`Length (Merge'Result) = Length (A) +
Length (B)`); before, a merge that did not fit was silently cut short.
