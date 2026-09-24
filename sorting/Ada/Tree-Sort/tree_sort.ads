--  Tree_Sort — Ada 2023 educational package for tree sort on Integer
--  arrays with a bounded length.
--  Insert every element into a binary search tree, then in-order traverse
--  back into the array. Average O(n log n); worst O(n²) on sorted /
--  reverse-sorted input (unbalanced BST; this package does not AVL-balance).
--  Reference: https://en.wikipedia.org/wiki/Tree_sort

pragma Ada_2022;

package Tree_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  The body uses a fixed node pool of this many BST nodes (no unbounded
   --  heap). Unbalanced insert is O(n²) on sorted input, so keep Max_N
   --  modest for interactive demos.
   Max_N : constant Positive := 4_096;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (BST insert + in-order dump)
   ---------------------------------------------------------------------------
   --  1. Allocate a fixed node pool of Max_N BST nodes (index 0 = null).
   --  2. Insert A(A'First) .. A(A'Last) into an unbalanced binary search
   --     tree. Convention: left < node <= right (strictly smaller keys go
   --     left; equal and larger keys go right). Putting equals on the
   --     RIGHT makes in-order traversal stable: earlier equal keys come
   --     out first.
   --  3. In-order walk (left, node, right) writes values back into A in
   --     nondecreasing order.
   --
   --  Without rotations the tree can degenerate to a linked list (already
   --  sorted, reverse-sorted, or all-equal input) and both insert and the
   --  walk cost Θ(n²). Average random input is O(n log n). Self-balancing
   --  (AVL / red-black) would restore O(n log n) worst case; it is omitted
   --  here so the classic educational algorithm stays visible.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending tree sort (BST insert, then in-order dump).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Tree_Sort;
