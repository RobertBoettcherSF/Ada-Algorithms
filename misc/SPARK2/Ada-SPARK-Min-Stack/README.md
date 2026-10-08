# Ada-SPARK-Min-Stack

Bounded Ada/SPARK implementation of a bounded SPARK minimum stack. `make test` runs the checks; `make prove` runs level-2 cvc5 proof.

`Push` needs room (`S.Size < Capacity`); `Pop`, `Top_Value` and
`Min_Value` need a non-empty stack. These are preconditions, so a full or
empty stack is rejected instead of silently dropping a value or answering 0.
