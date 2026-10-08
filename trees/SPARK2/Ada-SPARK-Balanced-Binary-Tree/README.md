# Ada-SPARK-Balanced-Binary-Tree

Height-balance check for a binary tree stored in a fixed 31-node array (child index 0 = no child).
`Is_Balanced (T, Root)` is True when, at every node, the heights of the left and right subtrees differ by
at most 1. `Root = 0` (or an unset root slot) is the empty tree, which is balanced. A node more than 31
levels deep can only come from a cycle; such a structure is not a tree and gives False.

- `Walk` is a post-order recursion (depth-bounded, `Subprogram_Variant`) returning height and balance.
- Postcondition (functional): `Is_Balanced` equals the ghost specification `Spec_Balanced`, the textbook
  recursive definition over `Spec_Height`; proved at Silver level 2 with cvc5 (52 checks).

## Verification

```text
make test     # hand cases + 20,000 random trees against an own height reference (tests/SOURCES.txt)
make prove
```
