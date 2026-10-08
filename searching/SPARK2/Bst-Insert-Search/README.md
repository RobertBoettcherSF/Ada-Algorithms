# Bst-Insert-Search

Binary search tree insert and search in SPARK, keys -1000 .. 1000, up to 31 nodes in a fixed array:
slot 1 is the root, child index 0 means no child, nodes are appended in insertion order (a child's slot
is always greater than its parent's). `Insert` walks from the root (smaller left, larger right) and hangs
the new key under the last node; a key that is already present leaves the tree unchanged. `Contains`
follows one root-to-leaf path. Any shape fits, including a 31-deep chain from sorted input (the earlier
version kept node K's children at slots 2K / 2K + 1 and silently lost keys more than 5 levels deep).

- `Insert` needs `Size (T) < Capacity` (31); nothing is dropped silently.
- Postconditions, proved at Silver level 2 (53 checks): `Insert` keeps the BST order (`Ordered`: each node's
  open value interval is inherited from its parent), keeps every stored key in its slot, and either appends
  the key or it was already stored; `Contains` returning True means the key is stored.
- Same design as `trees/SPARK2/Ada-SPARK-Insert-Into-BST` (which uses keys -100 .. 100).

## Verification

```text
make test     # own set reference, chains of 1 .. 31 keys, 6,000 random sequences (tests/SOURCES.txt)
gnatprove -P proof.gpr --mode=silver --level=2
```
