--  Sorted_List — Ada/SPARK Level 4 educational package for a bounded
--  sorted-list ADT (array-backed ordered multiset of Integers,
--  nondecreasing). Insert / delete shift array slots; membership uses
--  inline binary search (do not `with` Binary_Search). Capacity Max_N.
--  Invariant: always sorted.
--
--  SPARK port of Ada-Sorted-List: hard Max_N = 64, no exceptions,
--  Success / Pre contracts replace Overflow / Invalid_Argument.
--  Type_Invariant => Is_Sorted_Rep proved preserved by Insert / Delete /
--  Clear. Non-SPARK sibling uses Max_N = 1024 and raises exceptions.
--
--  Reference: https://en.wikipedia.org/wiki/Sorted_list
--  (Wikipedia may redirect; this package implements the sorted-list ADT.)

package Sorted_List
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / shift VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on list length. Smaller than the non-SPARK sibling
   --  (Max_N = 1024) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. Len with Len ≤ Max_N. 0 is the Find miss
   --  sentinel. Ext_Index covers the half-open upper bound Len + 1 used
   --  by Lower_Bound.
   subtype Index is Natural range 0 .. Max_N;
   subtype Ext_Index is Natural range 0 .. Max_N + 1;

   type List is private
     with Default_Initial_Condition =>
       Length (List) = 0;

   ---------------------------------------------------------------------------
   -- Sortedness (ghost / Type_Invariant companion)
   ---------------------------------------------------------------------------

   --  Public ghost view of the representation invariant: adjacent
   --  nondecreasing on the live prefix. Vacuous when Length ≤ 1.
   --  Outside this package every List satisfies Is_Sorted (Type_Invariant).
   function Is_Sorted (L : List) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Construction / queries
   ---------------------------------------------------------------------------

   function Empty return List
     with
       Global => null,
       Post   => Length (Empty'Result) = 0
                 and then Is_Empty (Empty'Result)
                 and then Is_Sorted (Empty'Result);
   --  A fresh empty list (Length = 0).

   function Length (L : List) return Index
     with Global => null;
   --  Number of stored elements in 0 .. Max_N.

   function Is_Empty (L : List) return Boolean
     with
       Global => null,
       Post   => Is_Empty'Result = (Length (L) = 0);
   --  True iff Length (L) = 0.

   function Is_Full (L : List) return Boolean
     with
       Global => null,
       Post   => Is_Full'Result = (Length (L) = Max_N);
   --  True iff Length (L) = Max_N.

   procedure Clear (L : in out List)
     with
       Global => null,
       Post   => Length (L) = 0
                 and then Is_Empty (L)
                 and then Is_Sorted (L);
   --  Reset to empty. Capacity unchanged.

   ---------------------------------------------------------------------------
   -- Mutation (no exceptions — Success / Pre replace Overflow /
   -- Invalid_Argument from the non-SPARK sibling)
   ---------------------------------------------------------------------------

   procedure Insert (L : in out List; X : Integer; Success : out Boolean)
     with
       Global => null,
       Post   =>
         Is_Sorted (L)
         and then
           (if Success then
              Length (L) = Length (L'Old) + 1
              and then Contains (L, X)
              and then not Is_Full (L'Old)
            else
              Length (L) = Length (L'Old)
              and then Is_Full (L'Old)
              and then (for all K in 1 .. Length (L) =>
                          Element (L, K) = Element (L'Old, K)));
   --  Insert X so the list stays nondecreasing. Inline binary search
   --  (Lower_Bound) then shift the right tail by one. Success is False
   --  when Is_Full (L'Old); the list is unchanged. Duplicates kept
   --  (multiset).

   procedure Delete (L : in out List; X : Integer; Success : out Boolean)
     with
       Global => null,
       Post   =>
         Is_Sorted (L)
         and then
           (if Success then
              Length (L) = Length (L'Old) - 1
              and then Contains (L'Old, X)
            else
              Length (L) = Length (L'Old)
              and then not Contains (L'Old, X)
              and then (for all K in 1 .. Length (L) =>
                          Element (L, K) = Element (L'Old, K)));
   --  Remove the first (leftmost) occurrence of X. Success is False when
   --  X is absent; the list is unchanged.

   procedure Delete_First (L : in out List; X : Integer)
     with
       Global => null,
       Pre    => Contains (L, X),
       Post   =>
         Is_Sorted (L)
         and then Length (L) = Length (L'Old) - 1;
   --  Same as successful Delete: remove the first occurrence of X.
   --  Pre replaces Invalid_Argument.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Contains (L : List; X : Integer) return Boolean
     with
       Global => null,
       Post   =>
         Contains'Result =
           (for some K in 1 .. Length (L) => Element (L, K) = X);
   --  True iff some stored element equals X. Inline binary search O(log n).

   function Find (L : List; X : Integer) return Index
     with
       Global => null,
       Post   =>
         Find'Result <= Length (L)
         and then
           (if Find'Result > 0 then
              Element (L, Find'Result) = X
              and then (for all K in 1 .. Find'Result - 1 =>
                          Element (L, K) < X)
            else
              not Contains (L, X));
   --  1-based index of the leftmost occurrence of X, or 0 if absent.
   --  Inline binary search O(log n).

   ---------------------------------------------------------------------------
   -- Ends / indexed access
   ---------------------------------------------------------------------------

   function Min (L : List) return Integer
     with
       Global => null,
       Pre    => not Is_Empty (L),
       Post   =>
         Min'Result = Element (L, 1)
         and then (for all K in 1 .. Length (L) =>
                     Min'Result <= Element (L, K));
   --  Smallest element (front). O(1). Pre replaces Invalid_Argument.
   --  Extremum vs whole prefix is proved via a ghost lemma in the body.

   function Max (L : List) return Integer
     with
       Global => null,
       Pre    => not Is_Empty (L),
       Post   =>
         Max'Result = Element (L, Length (L))
         and then (for all K in 1 .. Length (L) =>
                     Max'Result >= Element (L, K));
   --  Largest element (back). O(1). Pre replaces Invalid_Argument.
   --  Extremum vs whole prefix is proved via a ghost lemma in the body.

   function Element (L : List; Position : Positive) return Integer
     with
       Global => null,
       Pre    => Position <= Length (L);
   --  1-based access into the sorted content: Element (L, 1) = Min (L),
   --  Element (L, Length (L)) = Max (L). Pre replaces Invalid_Argument.

private

   type Store is array (1 .. Max_N) of Integer;

   --  Representation invariant: live prefix Data (1 .. Len) is adjacent
   --  nondecreasing. Vacuous when Len ≤ 1.
   function Is_Sorted_Rep (Data : Store; Len : Index) return Boolean is
     (Len <= 1
      or else (for all I in 1 .. Len - 1 => Data (I) <= Data (I + 1)))
   with Global => null;

   type List is record
      Data : Store   := [others => 0];
      Len  : Index   := 0;
   end record
     with Type_Invariant => Is_Sorted_Rep (Data, Len);

   function Length (L : List) return Index is (L.Len);

   function Is_Empty (L : List) return Boolean is (L.Len = 0);

   function Is_Full (L : List) return Boolean is (L.Len = Max_N);

   function Element (L : List; Position : Positive) return Integer is
     (L.Data (Position));

   function Is_Sorted (L : List) return Boolean is
     (Is_Sorted_Rep (L.Data, L.Len));

end Sorted_List;
