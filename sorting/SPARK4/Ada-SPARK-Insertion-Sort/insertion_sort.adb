--  Insertion_Sort body — SPARK Level 4 classic stable in-place insertion
--  sort. Outer loop grows a sorted prefix; inner shift loop opens a hole
--  for Key. Loop invariants track sortedness of the active prefix.

package body Insertion_Sort
  with SPARK_Mode => On
is

   --  Adjacent nondecreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all K in L .. R - 1 => A (K) <= A (K + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then L >= A'First
       and then R <= A'Last;

   --  Insert A(I) into the sorted prefix A(A'First .. I-1), yielding
   --  sorted A(A'First .. I). Strict Key < A(J-1) keeps equal-key order (stable).
   procedure Insert_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then I in A'First + 1 .. A'Last
         and then Sorted_Slice (A, A'First, I - 1),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, A'First, I)
         and then (for all K in I + 1 .. A'Last => A (K) = A'Old (K))
   is
      Key : constant Integer := A (I);
      J   : Index := I;
   begin
      --  Shift strictly larger predecessors one slot right.
      --  Hole sits at J: A(A'First .. J-1) untouched sorted prefix; A(J+1 .. I)
      --  are the shifted values (all > Key, sorted); A(J) duplicates
      --  A(J+1) when J < I (or still equals Key when J = I).
      while J > A'First and then Key < A (J - 1) loop
         pragma Loop_Invariant (J in A'First + 1 .. I);
         pragma Loop_Invariant (Sorted_Slice (A, A'First, J - 1));
         pragma Loop_Invariant (Sorted_Slice (A, J + 1, I));
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (K) > Key);
         pragma Loop_Invariant
           (for all K in J + 1 .. I => A (J - 1) <= A (K));
         pragma Loop_Invariant
           (if J < I then A (J) = A (J + 1) else A (J) = Key);
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => J);

         A (J) := A (J - 1);
         J     := J - 1;
      end loop;

      pragma Assert (J in A'First .. I);
      pragma Assert (Sorted_Slice (A, A'First, J - 1));
      pragma Assert (Sorted_Slice (A, J + 1, I));
      pragma Assert (for all K in J + 1 .. I => A (K) > Key);
      pragma Assert (J = A'First or else A (J - 1) <= Key);

      A (J) := Key;

      --  Glue left | Key | right into one adjacent-sorted prefix.
      pragma Assert (if J > A'First then A (J - 1) <= A (J));
      pragma Assert (if J < I then A (J) <= A (J + 1));
      pragma Assert (Sorted_Slice (A, A'First, I));
   end Insert_Step;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, A'First, A'First));

      for I in A'First + 1 .. A'Last loop
         Insert_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, A'First, I));
         pragma Loop_Invariant (Is_Sorted (A (A'First .. I)));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
      end loop;
   end Sort;

end Insertion_Sort;
