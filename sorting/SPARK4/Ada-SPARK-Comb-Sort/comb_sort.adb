--  Comb_Sort body — SPARK Level 4 classic comb sort. Shrinking gap
--  passes (Gap > 1) only need RTE / In_Bounds; the gap-1 passes run in
--  the same comb loop (until one makes no swap) and Bubble_Pass /
--  Sorted_Slice / Prefix_Leq_Suffix prove Is_Sorted. No iteration cap:
--  the loop variant is (Gap, Bound).

package body Comb_Sort
  with SPARK_Mode => On
is

   --  Shrink factor k ≈ 1.3: floor(gap / 1.3) = floor(gap * 10 / 13).
   Shrink_Num : constant := 10;
   Shrink_Den : constant := 13;

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

   --  Every element of A (Lo_P .. Hi_P) is <= every element of A (Lo_S .. Hi_S).
   function Prefix_Leq_Suffix
     (A                      : Element_Array;
      Lo_P, Hi_P, Lo_S, Hi_S : Natural) return Boolean
   is
     (Hi_P < Lo_P
      or else Hi_S < Lo_S
      or else
        (for all K in Lo_P .. Hi_P =>
           (for all L in Lo_S .. Hi_S => A (K) <= A (L))))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Lo_P >= A'First
       and then Hi_P <= A'Last
       and then Lo_S >= A'First
       and then Hi_S <= A'Last;

   procedure Swap (A : in out Element_Array; X, Y : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then X in A'Range
         and then Y in A'Range,
       Post   =>
         In_Bounds (A)
         and then A (X) = A'Old (Y)
         and then A (Y) = A'Old (X)
         and then
           (for all K in A'Range =>
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

   --  One comb pass for Gap > 1: compare/swap A(I) with A(I+Gap).
   --  Only In_Bounds / RTE are proved (sortedness comes from gap 1).
   procedure Comb_Pass (A : in out Element_Array; Gap : Positive)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Gap in 2 .. A'Length - 1,
       Post   => In_Bounds (A)
   is
   begin
      for I in A'First .. A'Last - Gap loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I + Gap <= A'Last);

         if A (I) > A (I + Gap) then
            Swap (A, I, I + Gap);
         end if;
      end loop;
   end Comb_Pass;

   --  One forward pass over A (A'First .. Bound): bubble the maximum of that
   --  range to index Bound via adjacent swaps. Preserves the already-
   --  sorted / partitioned suffix Bound+1 .. A'Last. Swapped is True
   --  iff at least one adjacent pair was exchanged (False ⇒ A(A'First .. Bound)
   --  was already adjacent-sorted).
   procedure Bubble_Pass
     (A       : in out Element_Array;
      Bound   : Index;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Bound in A'First + 1 .. A'Last
         and then Sorted_Slice (A, Bound + 1, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Bound, A'Last)
         and then Prefix_Leq_Suffix (A, A'First, Bound - 1, Bound, A'Last)
         and then
           (if not Swapped then Sorted_Slice (A, A'First, Bound))
   is
   begin
      Swapped := False;

      for I in A'First .. Bound - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in A'First .. I => A (K) <= A (I));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (if not Swapped then Sorted_Slice (A, A'First, I));

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         end if;

         pragma Assert (for all K in A'First .. I + 1 => A (K) <= A (I + 1));
         pragma Assert (if not Swapped then Sorted_Slice (A, A'First, I + 1));
      end loop;

      pragma Assert (for all K in A'First .. Bound => A (K) <= A (Bound));
      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last));
      pragma Assert (Bound = A'Last or else A (Bound) <= A (Bound + 1));
      pragma Assert (Sorted_Slice (A, Bound, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, A'First, Bound - 1, Bound, A'Last));
      pragma Assert (if not Swapped then Sorted_Slice (A, A'First, Bound));
   end Bubble_Pass;

   procedure Sort (A : in out Element_Array) is
      Gap     : Index;
      Bound   : Index;
      Swapped : Boolean;
   begin
      if A'Length <= 1 then
         return;
      end if;

      --  Classic comb sort in one loop: gap := max (1, floor (gap / 1.3))
      --  before each pass (from Gap >= 2 the shrink never goes below 1);
      --  once the gap is 1, gap-1 passes repeat until one makes no swap.
      --  A gap-1 pass leaves the maximum of A (A'First .. Bound) at Bound, so
      --  each later gap-1 pass stops one element earlier.
      Gap   := A'Length;
      Bound := A'Last;

      loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Gap in 1 .. A'Length);
         pragma Loop_Invariant (Bound in A'First + 1 .. A'Last);
         pragma Loop_Invariant (if Gap > 1 then Bound = A'Last);
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, A'First, Bound, Bound + 1, A'Last));
         pragma Loop_Variant (Decreases => Gap, Decreases => Bound);

         if Gap > 1 then
            Gap := (Gap * Shrink_Num) / Shrink_Den;
         end if;

         if Gap > 1 then
            Comb_Pass (A, Gap);
         else
            Bubble_Pass (A, Bound, Swapped);
            pragma Assert (Sorted_Slice (A, Bound, A'Last));
            pragma Assert
              (Prefix_Leq_Suffix (A, A'First, Bound - 1, Bound, A'Last));

            if not Swapped or else Bound = A'First + 1 then
               pragma Assert
                 (if not Swapped then Sorted_Slice (A, A'First, Bound)
                  else Sorted_Slice (A, A'First + 1, A'Last)
                       and then Prefix_Leq_Suffix (A, A'First, A'First, A'First + 1, A'Last));
               pragma Assert (Is_Sorted (A));
               exit;
            end if;

            Bound := Bound - 1;
         end if;
      end loop;
   end Sort;

end Comb_Sort;
