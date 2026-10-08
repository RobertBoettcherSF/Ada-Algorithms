--  Gnome_Sort body — SPARK Level 4 classic gnome / stupid sort.
--  Outer loop grows a sorted prefix; inner gnome step bubbles A(I) left
--  by adjacent swaps (strict `<` so equals keep relative order). Loop
--  invariants track sortedness of the active prefix; Loop_Variant on Pos.

package body Gnome_Sort
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
       and then L >= 1
       and then R <= A'Last;

   procedure Swap (A : in out Element_Array; X, Y : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then X in 1 .. A'Last
         and then Y in 1 .. A'Last,
       Post   =>
         In_Bounds (A)
         and then A (X) = A'Old (Y)
         and then A (Y) = A'Old (X)
         and then
           (for all K in 1 .. A'Last =>
              (if K /= X and then K /= Y then A (K) = A'Old (K)))
   is
      T : Integer;
   begin
      if X = Y then
         return;
      end if;
      T     := A (X);
      A (X) := A (Y);
      A (Y) := T;
   end Swap;

   --  Bubble A(I) left into the sorted prefix A(1 .. I-1) by adjacent
   --  swaps, yielding sorted A(1 .. I). Strict A(Pos) < A(Pos-1) keeps
   --  equal-key order (stable-ish gnome advance on >=).
   procedure Gnome_Step (A : in out Element_Array; I : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then I in 2 .. A'Last
         and then Sorted_Slice (A, 1, I - 1),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, 1, I)
         and then (for all K in I + 1 .. A'Last => A (K) = A'Old (K))
   is
      Pos : Index := I;
   begin
      --  Key sits at Pos. Left of Pos is sorted; right of Pos up to I
      --  are the bumped predecessors (all > Key, sorted).
      while Pos > 1 and then A (Pos) < A (Pos - 1) loop
         pragma Loop_Invariant (Pos in 2 .. I);
         pragma Loop_Invariant (Sorted_Slice (A, 1, Pos - 1));
         pragma Loop_Invariant (Sorted_Slice (A, Pos + 1, I));
         pragma Loop_Invariant
           (for all K in Pos + 1 .. I => A (K) > A (Pos));
         pragma Loop_Invariant
           (for all K in Pos + 1 .. I => A (Pos - 1) <= A (K));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Decreases => Pos);

         Swap (A, Pos, Pos - 1);
         Pos := Pos - 1;
      end loop;

      pragma Assert (Pos in 1 .. I);
      pragma Assert (Sorted_Slice (A, 1, Pos - 1));
      pragma Assert (Sorted_Slice (A, Pos + 1, I));
      pragma Assert (for all K in Pos + 1 .. I => A (K) > A (Pos));
      pragma Assert (Pos = 1 or else A (Pos - 1) <= A (Pos));
      pragma Assert (if Pos > 1 then A (Pos - 1) <= A (Pos));
      pragma Assert (if Pos < I then A (Pos) <= A (Pos + 1));
      pragma Assert (Sorted_Slice (A, 1, I));
   end Gnome_Step;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, 1, 1));

      for I in 2 .. A'Last loop
         Gnome_Step (A, I);

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, I));
         pragma Loop_Invariant (Is_Sorted (A (1 .. I)));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last =>
              A (K) = A'Loop_Entry (K));
      end loop;
   end Sort;

end Gnome_Sort;
