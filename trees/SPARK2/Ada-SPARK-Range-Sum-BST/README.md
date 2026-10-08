# Ada-SPARK-Range-Sum-BST

Range sum over a binary search tree stored in a fixed 31-node array (child index 0 = no child, unset
slots count as absent). `Range_Sum (T, Root, Low, High)` adds the values in `Low .. High` of all nodes of
the tree at `Root`. The tree must be a binary search tree (left values <= node value <= right values):
a left subtree is entered only when the node value >= `Low`, a right subtree only when it is <= `High`.

- Nodes are first marked (31 rounds over the 31 slots), then the marked in-range values are summed, so
  every node counts at most once; at most 31 values of magnitude <= 1000 fit `Sum` without any capping.
- Proved at Silver level 2 with cvc5 (11 checks). A functional postcondition would need a ghost BST
  predicate and reachability; not added (checked by the tests instead).

## Verification

```text
make test     # hand cases + 20,000 random BSTs against an own full traversal (tests/SOURCES.txt)
make prove
```
