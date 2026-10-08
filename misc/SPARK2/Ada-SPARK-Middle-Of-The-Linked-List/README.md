# Ada-SPARK-Middle-Of-The-Linked-List

Small bounded SPARK implementation using arrays with a maximum of 16 nodes or elements.

`Middle` returns the middle node; for an even length it returns the second
of the two middle nodes (node `Length / 2 + 1`). It requires a non-empty
list (precondition `Length (L) > 0`). Before this change it returned the
first middle and answered 0 for an empty list.
