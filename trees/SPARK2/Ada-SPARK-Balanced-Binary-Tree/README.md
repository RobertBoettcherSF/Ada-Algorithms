# Ada-SPARK-Balanced-Binary-Tree

Height-balance check for a binary tree stored in a fixed 31-node array (child index 0 = no child).
`Is_Balanced (T, Root)` is True when, at every node, the heights of the left and right subtrees differ by
at most 1. `Root = 0` (or an unset root slot) is the empty tree, which is balanced. A node more than 31
levels deep can only come from a cycle; such a structure is not a tree and gives False.

A shared child is not a tree either, and it cannot be built: `Set_Node` has `Pre => Can_Link`, which
refuses a link into a node that some other node already links to (or `Left = Right`), and the private
`Tree` carries a type invariant (`No_Shared_Child`) proved to hold after `Empty` and every `Set_Node`.
So every node has at most one link into it, and the recursive `Spec_Balanced` judges a real tree
(earlier versions accepted e.g. a node whose left and right child were the same node).

- `Walk` is a post-order recursion (depth-bounded, `Subprogram_Variant`) returning height and balance.
- Postcondition (functional): `Is_Balanced` equals the ghost specification `Spec_Balanced`, the textbook
  recursive definition over `Spec_Height`; proved at Silver level 2 (68 checks, with the type invariant and `Set_Node`'s precondition).

## Verification

```text
make test     # shared-children cases, all 394,806 link assignments on 1 .. 4 nodes, hand cases + 20,000 random trees against an own height reference (tests/SOURCES.txt)
make prove
```
