# Ada-SPARK-Queue-Using-Stacks

Bounded Ada/SPARK implementation of a bounded SPARK FIFO queue using stack-shaped storage. `make test` runs the checks; `make prove` runs level-2 cvc5 proof.

`Enqueue` needs room (`Q.Size < Capacity`); `Dequeue` and `Front` need a
non-empty queue. These are preconditions, so a full or empty queue is
rejected instead of silently dropping a value or returning a stale one.
