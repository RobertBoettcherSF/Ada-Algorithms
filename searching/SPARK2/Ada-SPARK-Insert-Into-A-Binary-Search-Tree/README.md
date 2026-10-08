# Ada-SPARK-Insert-Into-A-Binary-Search-Tree

Small bounded SPARK implementation of the named algorithm. The model is capped at 16 nodes and uses `pragma SPARK_Mode (On)`.

`Insert (T, Root, Node, V)` adds value `V` as the new leaf `Node` (smaller values go left, others right). `Root = 0` is the empty tree. The precondition asks for a well-formed tree (`Well_Formed`: `Root` is 0 or a used node, child links point to used nodes other than `Root`, no node has two parents) and a fresh `Node`; the postcondition says `Node` is now a used leaf holding `V` and the root is kept (or becomes `Node`). The search loop has no step cap: the nodes reachable from a well-formed root form a tree, so the path ends. `Is_Used`, `Value_Of`, `Left_Of` and `Right_Of` give read-only access to a node.

Build and test with `make test`; run the full level-2 CVC5 proof with `make prove` (18 checks).
