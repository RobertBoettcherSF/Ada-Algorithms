--  Bogosort body — SPARK Level 4 deterministic next-permutation
--  generate-and-test. Bogo phase proves only In_Bounds / RTE /
--  termination (iteration-capped at Max_Perm_Steps); the final gap-1
--  bubble finish reuses Bubble_Pass / Sorted_Slice / Prefix_Leq_Suffix so
--  Sort proves Is_Sorted (same split as Comb_Sort / Strand / Patience /
--  Stooge). No Intentional Annotate.

package body Bogosort
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
       and then Lo_P >= 1
       and then Hi_P <= A'Last
       and then Lo_S >= 1
       and then Hi_S <= A'Last;

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

   --  One forward pass over A (1 .. Bound): bubble the maximum of that
   --  range to index Bound via adjacent swaps. Preserves the already-
   --  sorted / partitioned suffix Bound+1 .. A'Last. Swapped is True
   --  iff at least one adjacent pair was exchanged (False ⇒ A(1 .. Bound)
   --  was already adjacent-sorted).
   procedure Bubble_Pass
     (A       : in out Element_Array;
      Bound   : Index;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Last >= 2
         and then Bound in 2 .. A'Last
         and then Sorted_Slice (A, Bound + 1, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last),
       Post   =>
         In_Bounds (A)
         and then Sorted_Slice (A, Bound, A'Last)
         and then Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last)
         and then
           (if not Swapped then Sorted_Slice (A, 1, Bound))
   is
   begin
      Swapped := False;

      for I in 1 .. Bound - 1 loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all K in 1 .. I => A (K) <= A (I));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
         pragma Loop_Invariant
           (for all K in I + 1 .. A'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (if not Swapped then Sorted_Slice (A, 1, I));

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         end if;

         pragma Assert (for all K in 1 .. I + 1 => A (K) <= A (I + 1));
         pragma Assert (if not Swapped then Sorted_Slice (A, 1, I + 1));
      end loop;

      pragma Assert (for all K in 1 .. Bound => A (K) <= A (Bound));
      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
      pragma Assert (Bound = A'Last or else A (Bound) <= A (Bound + 1));
      pragma Assert (Sorted_Slice (A, Bound, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last));
      pragma Assert (if not Swapped then Sorted_Slice (A, 1, Bound));
   end Bubble_Pass;

   --  Final gap = 1: ordinary bubble sort with early exit. Proves Is_Sorted.
   procedure Bubble_Finish (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
   is
      Bound   : Index;
      Swapped : Boolean;
   begin
      Bound := A'Last;

      pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));

      loop
         pragma Loop_Invariant (Bound in 2 .. A'Last);
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
         pragma Loop_Variant (Decreases => Bound);

         Bubble_Pass (A, Bound, Swapped);

         pragma Assert (Sorted_Slice (A, Bound, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Bound - 1, Bound, A'Last));

         if not Swapped then
            pragma Assert (Sorted_Slice (A, 1, Bound));
            pragma Assert (Sorted_Slice (A, Bound, A'Last));
            pragma Assert (Is_Sorted (A));
            return;
         end if;

         exit when Bound = 2;

         Bound := Bound - 1;

         pragma Assert (Sorted_Slice (A, Bound + 1, A'Last));
         pragma Assert
           (Prefix_Leq_Suffix (A, 1, Bound, Bound + 1, A'Last));
      end loop;

      pragma Assert (Bound = 2);
      pragma Assert (Sorted_Slice (A, 2, A'Last));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 1, 2, A'Last));
      pragma Assert (Is_Sorted (A));
   end Bubble_Finish;

   --  Reverse A (Lo .. Hi) in place. In_Bounds / RTE only.
   procedure Reverse_Range
     (A      : in out Element_Array;
      Lo, Hi : Index)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Lo in 1 .. A'Last
         and then Hi in Lo .. A'Last,
       Post   => In_Bounds (A)
   is
      I : Index := Lo;
      J : Index := Hi;
   begin
      while I < J loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in Lo .. Hi);
         pragma Loop_Invariant (J in Lo .. Hi);
         pragma Loop_Invariant (I <= J);
         pragma Loop_Invariant (I + J = Lo + Hi);
         pragma Loop_Variant (Decreases => J - I);

         Swap (A, I, J);
         I := I + 1;
         J := J - 1;
      end loop;
   end Reverse_Range;

   --  Advance A to the next lexicographic multiset permutation.
   --  When A is already the last permutation, wrap to the first (fully
   --  reverse). Proves In_Bounds / RTE only (educational generate step).
   procedure Next_Permutation (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      I : Index;
      J : Index;
   begin
      --  Find rightmost ascent: largest I with A(I) < A(I+1).
      I := A'Last - 1;

      while I > 1 and then A (I) >= A (I + 1) loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in 1 .. A'Last - 1);
         pragma Loop_Variant (Decreases => I);

         I := I - 1;
      end loop;

      if A (I) >= A (I + 1) then
         --  Entirely nonincreasing: last permutation → wrap to first.
         Reverse_Range (A, 1, A'Last);
         return;
      end if;

      pragma Assert (A (I) < A (I + 1));
      pragma Assert (I in 1 .. A'Last - 1);

      --  Find rightmost successor of A(I) to its right.
      --  Exists because A(I) < A(I+1); stays at J >= I + 1.
      J := A'Last;

      while J > I + 1 and then A (J) <= A (I) loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (J in I + 1 .. A'Last);
         pragma Loop_Invariant (A (I) < A (I + 1));
         pragma Loop_Variant (Decreases => J);

         J := J - 1;
      end loop;

      pragma Assert (J in I + 1 .. A'Last);
      pragma Assert (A (J) > A (I));

      Swap (A, I, J);

      if I < A'Last - 1 then
         Reverse_Range (A, I + 1, A'Last);
      end if;
   end Next_Permutation;

   --  Deterministic bogosort phase: next-permutation until Is_Sorted or
   --  Max_Perm_Steps exhausted. Proves In_Bounds / RTE / termination.
   --  Prefer exit when already Is_Sorted (educational early stop).
   procedure Bogo_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
   begin
      for Step in 1 .. Max_Perm_Steps loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Length >= 2);

         exit when Is_Sorted (A);

         Next_Permutation (A);
      end loop;
   end Bogo_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Bogo_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (same role as Comb / Strand /
      --  Patience / Stooge). If Bogo_Phase already left A sorted, the
      --  first Bubble_Pass reports Swapped = False and returns at once.
      Bubble_Finish (A);
   end Sort;

end Bogosort;
