--  Odd_Even_Sort body — SPARK Level 4 sequential odd–even / brick sort.
--  Capped odd-then-even adjacent-swap cycles (Wikipedia 0-based order)
--  prove only In_Bounds / RTE; the final gap-1 bubble finish reuses
--  Bubble_Pass / Sorted_Slice / Prefix_Leq_Suffix so Sort proves Is_Sorted
--  (same split as Comb_Sort).

package body Odd_Even_Sort
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

   --  One odd phase (1-based pairs (2,3), (4,5), …). Only In_Bounds / RTE.
   procedure Odd_Phase (A : in out Element_Array; Swapped : in out Boolean)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      I : Index;
   begin
      --  Wikipedia 0-based offsets 1,3,5,… → 1-based indices 2,4,6,…
      I := 2;
      while I < A'Last loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I >= 2);
         pragma Loop_Invariant (I rem 2 = 0);
         pragma Loop_Invariant (I <= A'Last);
         pragma Loop_Variant (Increases => I);

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         end if;

         exit when A'Last - I < 2;
         I := I + 2;
      end loop;
   end Odd_Phase;

   --  One even phase (1-based pairs (1,2), (3,4), …). Only In_Bounds / RTE.
   procedure Even_Phase (A : in out Element_Array; Swapped : in out Boolean)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      I : Index;
   begin
      --  Wikipedia 0-based offsets 0,2,4,… → 1-based indices 1,3,5,…
      I := 1;
      while I < A'Last loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I >= 1);
         pragma Loop_Invariant (I rem 2 = 1);
         pragma Loop_Invariant (I <= A'Last);
         pragma Loop_Variant (Increases => I);

         if A (I) > A (I + 1) then
            Swap (A, I, I + 1);
            Swapped := True;
         end if;

         exit when A'Last - I < 2;
         I := I + 2;
      end loop;
   end Even_Phase;

   --  One full odd-then-even cycle. Swapped is True iff any adjacent pair
   --  was exchanged in either phase.
   procedure Odd_Even_Cycle
     (A       : in out Element_Array;
      Swapped : out Boolean)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
   begin
      Swapped := False;
      Odd_Phase (A, Swapped);
      Even_Phase (A, Swapped);
   end Odd_Even_Cycle;

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

   procedure Sort (A : in out Element_Array) is
      Swapped : Boolean;
   begin
      if A'Length <= 1 then
         return;
      end if;

      --  Cap outer odd–even cycles at Max_N so termination proves
      --  (n ≤ Max_N phases suffice in theory; early exit on a clean cycle).
      for Iter in 1 .. Max_N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (A'Length >= 2);

         Odd_Even_Cycle (A, Swapped);
         exit when not Swapped;
      end loop;

      --  Gap-1 bubble finish → Is_Sorted (same role as Comb / Shell).
      Bubble_Finish (A);
   end Sort;

end Odd_Even_Sort;
