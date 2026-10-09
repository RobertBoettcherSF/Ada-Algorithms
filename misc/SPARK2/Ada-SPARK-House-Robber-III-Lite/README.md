# Ada-SPARK-House-Robber-III-Lite

Houses form a binary tree, each worth some value; a robber may not rob a
house together with one of its children. What is the largest total, and
which houses give it?

* The tree of N houses is given in preorder: house 1 is the root, the
  left child of house I (if any) is I + 1, and its right child (if any)
  comes right after the left subtree; `Left (I)` / `Right (I)` = 0 means
  no child. `Good_Tree` (a predicate on `Tree`, checked when a tree is
  passed in) accepts exactly these shapes, so every house is in the tree
  once.
* `Max_Loot (T)`: the take/skip dynamic program over subtrees. For each
  house, Take = its value + Skip of its children, Skip = the better of
  Take and Skip of each child, summed; the answer is the better of the
  two at the root.
* `Best_Choice (T)`: the houses to rob, chosen from the root down (a
  house is robbed when its parent is not and Take >= Skip).

Range: N in 0 .. 100 houses, values in 0 .. 10_000. Totals stay at most
1_000_000, far from overflow (Natural would allow about 214_000 houses
of 10_000). N is limited by run time with assertions on (the tests and
mutation runs use them): the shape check and the contracts follow
subtrees, about N ** 3 steps on a path; one call on a path takes about
0.2 s for 100 houses and 0.9 s for 200 (measured on the sweep machine).
(The old version was a case table ceil (K / 2) for a path of K <= 16
houses worth 1.)

Proof (`make prove`, level 2, cvc5, 178 checks): `Best_Choice` is
`Independent` (no robbed house has a robbed child) and its `Loot` (the
ghost sum of the robbed values in the subtree of the root, which is the
whole tree) equals `Max_Loot`; the ghost lemma `Lemma_Optimal` proves
that no independent choice has a larger `Loot`. Together these say
`Max_Loot` is the maximum. No overflow anywhere, and `Max_Loot <=
10_000 * N`.

Tests: `make test` (hand-derived values, see tests/SOURCES.txt) and
`own_checks.adb` (own brute force over all choices, own iterative
program, own shape check, seeded random trees and corruptions; seed
printed, AA_SEED overrides).
