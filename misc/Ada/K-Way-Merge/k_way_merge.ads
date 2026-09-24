--  K_Way_Merge — Ada 2023 educational package for the k-way merge
--  algorithm: combine k sorted ascending Integer sequences into one
--  sorted sequence using a binary min-heap of list heads.
--  Time O(N log k) for total N elements across k lists.
--  Reference: https://en.wikipedia.org/wiki/K-way_merge_algorithm

pragma Ada_2022;

package K_Way_Merge
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum number of input lists accepted by Merge.
   Max_K : constant Positive := 64;

   --  Maximum length of any single input list.
   Max_Len : constant Positive := 10_000;

   --  Maximum total number of elements across all lists (also Output size).
   Max_Total : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  One sorted (or to-be-checked) Integer sequence.
   --  Positive index bounds keep educational examples 1-based.
   type Vector is array (Positive range <>) of Integer;

   --  Handle to an immutable input list (caller owns the storage).
   type Vector_Access is access constant Vector;

   --  Up to Max_K input lists (null or empty entries are ignored).
   type Vector_List is array (Positive range <>) of Vector_Access;

   Invalid_Argument : exception;
   --  Raised when:
   --    * Lists'Length > Max_K;
   --    * some list has Length > Max_Len;
   --    * sum of lengths > Max_Total;
   --    * some list is not sorted ascending;
   --    * 2-way Merge Output is too short for A'Length + B'Length.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (binary min-heap of heads)
   ---------------------------------------------------------------------------
   --  Each heap node stores (Value, List_Index, Position_In_List).
   --  1. Validate k, per-list length, total length, and Is_Sorted on each.
   --  2. Insert the head of every non-empty list into a min-heap (size ≤ k).
   --  3. While the heap is non-empty:
   --       extract the minimum head; append Value to Output;
   --       if that list still has a next element, push it as the new head.
   --  4. After N extract-mins the Output is fully sorted.
   --
   --  Heap height is O(log k), so total work is O(N log k).
   --  A naïve repeated pairwise 2-way merge is also O(N log N) in the
   --  worst tree shape but with larger constants when k is large; the
   --  heap of heads keeps the fan-in explicit.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Predicates
   ---------------------------------------------------------------------------

   function Is_Sorted (A : Vector) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton vectors are considered sorted.

   ---------------------------------------------------------------------------
   -- Merge
   ---------------------------------------------------------------------------

   function Merge (Lists : Vector_List) return Vector;
   --  K-way merge of the given sorted ascending lists into one sorted
   --  Vector of length equal to the sum of the input lengths.
   --  Null accesses and empty vectors contribute nothing.
   --  When Lists'Length = 0 the result is empty.
   --  Raises Invalid_Argument on capacity or sortedness violations.

   function Merge (A, B : Vector) return Vector;
   --  Educational 2-way merge (special case of k = 2 without heap).
   --  Equivalent to Merge ((A'Access, B'Access)) when A and B are
   --  aliased, but implemented with a direct two-pointer scan.
   --  Raises Invalid_Argument when either input is unsorted, either
   --  length exceeds Max_Len, or A'Length + B'Length > Max_Total.

   procedure Merge
     (A, B   : Vector;
      Output : out Vector;
      Last   : out Natural);
   --  Stack-friendly 2-way merge into a caller-provided buffer.
   --  Writes the merged sequence into Output (Output'First .. Last).
   --  Requires Output'Length >= A'Length + B'Length; raises
   --  Invalid_Argument otherwise (and for the same checks as Merge).

end K_Way_Merge;
