# Ada-SPARK-Insert-Into-BST

Insert into a binary search tree, in SPARK. The tree lives in a fixed array of 31 slots: slot 1 is the
root, child index 0 means no child, and nodes are appended in insertion order (a child's slot is always
greater than its parent's). `Insert` walks from the root (smaller to the left, larger to the right) and
hangs the new value under the last node; a value that is already present leaves the tree unchanged.
`Contains` follows one root-to-leaf path. Observers: `Size`, `Root`, `Value_At`, `Left_Of`, `Right_Of`.

- `Ordered` (BST order): every node carries the open interval its value must lie in, inherited from its
  parent ((Lo, parent value) on the left, (parent value, Hi) on the right).
- Postconditions, proved at Silver level 2 with cvc5 (53 checks): `Insert` keeps the tree `Ordered`, keeps
  every stored value in its slot, and either appends `V` or `V` was already stored; `Contains` returning
  True means the value is stored (that a False answer means "absent" relies on the BST order and is checked
  by the tests, not proved).
- `Insert` needs `Size (T) < Capacity` (a container bound, so it stays a precondition).

## Verification

```text
make test     # own reference set + own reference BST shape, 4,000 runs (tests/SOURCES.txt)
make prove
```
