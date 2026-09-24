--  Sorted_List — Ada 2023 educational package for a bounded sorted-list
--  ADT (array-backed ordered multiset of Integers, nondecreasing).
--  Insert / delete shift array slots; membership uses inline binary search
--  (do not `with` Binary_Search). Capacity Max_N. Invariant: always sorted.
--  Reference: https://en.wikipedia.org/wiki/Sorted_list
--  (Wikipedia may redirect; this package implements the sorted-list ADT.)

pragma Ada_2022;

package Sorted_List
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Maximum number of elements the list may hold. Pedagogical bound for
   --  the array-backed educational form.
   Max_N : constant Positive := 1024;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Overflow : exception;
   --  Raised by Insert when the list is already full (Length = Max_N).

   Invalid_Argument : exception;
   --  Raised for empty Min / Max, out-of-range Element, or Delete of an
   --  absent key.

   ---------------------------------------------------------------------------
   -- Opaque ADT
   ---------------------------------------------------------------------------

   type List is private;
   --  Bounded sorted multiset of Integers. Representation invariant:
   --  for all I in 1 .. Length−1, Element(I) ≤ Element(I+1).
   --  Duplicates are allowed (multiset).

   ---------------------------------------------------------------------------
   -- Construction / queries
   ---------------------------------------------------------------------------

   function Empty return List
     with Global => null;
   --  A fresh empty list (Length = 0).

   function Length (L : List) return Natural
     with Global => null;
   --  Number of stored elements in 0 .. Max_N.

   function Is_Empty (L : List) return Boolean
     with Global => null;
   --  True iff Length (L) = 0.

   function Is_Full (L : List) return Boolean
     with Global => null;
   --  True iff Length (L) = Max_N.

   procedure Clear (L : in out List)
     with Global => null;
   --  Reset to empty. Capacity unchanged.

   ---------------------------------------------------------------------------
   -- Mutation
   ---------------------------------------------------------------------------

   procedure Insert (L : in out List; X : Integer)
     with Global => null;
   --  Insert X so the list stays nondecreasing. Uses inline binary search
   --  to locate the insertion point, then shifts the right tail by one.
   --  Raises Overflow when Is_Full (L). Duplicates are kept (multiset).

   procedure Delete (L : in out List; X : Integer)
     with Global => null;
   --  Remove the first (leftmost) occurrence of X. Raises Invalid_Argument
   --  if X is absent.

   procedure Delete_First (L : in out List; X : Integer)
     with Global => null;
   --  Same as Delete: remove the first occurrence of X.
   --  Raises Invalid_Argument if X is absent.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Contains (L : List; X : Integer) return Boolean
     with Global => null;
   --  True iff some stored element equals X. Inline binary search O(log n).

   function Find (L : List; X : Integer) return Natural
     with Global => null;
   --  1-based index of the leftmost occurrence of X, or 0 if absent.
   --  Inline binary search O(log n).

   ---------------------------------------------------------------------------
   -- Ends / indexed access
   ---------------------------------------------------------------------------

   function Min (L : List) return Integer
     with Global => null;
   --  Smallest element (front). Raises Invalid_Argument if Is_Empty (L).
   --  O(1).

   function Max (L : List) return Integer
     with Global => null;
   --  Largest element (back). Raises Invalid_Argument if Is_Empty (L).
   --  O(1).

   function Element (L : List; Index : Positive) return Integer
     with Global => null;
   --  1-based access into the sorted content: Element (L, 1) = Min (L),
   --  Element (L, Length (L)) = Max (L). Raises Invalid_Argument when
   --  Index > Length (L).

private

   type Store is array (1 .. Max_N) of Integer;

   type List is record
      Data : Store  := [others => 0];
      Len  : Natural := 0;
   end record;

end Sorted_List;
