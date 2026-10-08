# Ada-SPARK-Insert-Into-A-Binary-Search-Tree

Small bounded SPARK implementation of the named algorithm. The model is capped at 16 nodes and uses `pragma SPARK_Mode (On)`.

`Insert (T, Root, Node, V)` adds value `V` as the new leaf `Node` (smaller values go left, others right). `Root = 0` is the empty tree. The precondition asks for a well-formed tree and a fresh `Node`. `Well_Formed` means `Root` is 0 or a used node, child links point to used nodes other than `Root`, and no node has two parents. The postcondition says:

* `Node` is now a used leaf holding `V`;
* the root is kept, or becomes `Node`;
* `Node` has a parent unless it is the new root;
* the tree is still well formed;
* nothing else changed except one empty child link, which now points to `Node`.

The search loop has no step cap. A ghost set of the nodes already passed on the path grows by one each step (a revisited node would be the root or have two parents), and the loop variant on its size proves that the walk ends.

`Empty` and `Set_Node` state their effect in postconditions. `Set_Node` checks nothing, so building a well-formed tree is up to the caller. `Is_Used`, `Value_Of`, `Left_Of` and `Right_Of` give read-only access to a node.

`make test` builds and runs the tests (`tests.adb`, plus the own checks in `own_checks.adb` against an independent reference BST; see `tests/SOURCES.txt`). `make prove` runs the level-2 CVC5 proof (40 checks).
