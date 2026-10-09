# Ada-SPARK-BST-Iterator-Stub

Binary search tree of up to 1000 values (smaller values go left, equal and larger go right) with an in-order iterator: `Next` returns the values in ascending order, moving to the in-order successor through parent links (leftmost node of the right subtree, else the first ancestor reached from its left side). (The folder name keeps its old `-Stub` suffix; the code is a real BST and iterator.)

Proof (SPARK Silver, `make prove`, cvc5 level 2, 70 checks): no run-time error and termination of every walk. Nodes are numbered in insertion order, and a type invariant (`Valid`) keeps every child numbered after its parent with a matching parent link, so walks down increase and walks up decrease the node number. Not stated in the contracts (partial claim, `tools/vv/contract_scan.csv`): the BST order and the ascending output; `own_checks.adb` checks them.

Tests: `tests.adb` (original; its expected order was corrected from the insertion order 5, 2, 8 to 2, 5, 8) and `own_checks.adb` (every insertion order of 1 .. 7 with and without duplicates, 2,000 random sequences of length 0 .. 1000, against insertion-sorted values, seed 20261009).
