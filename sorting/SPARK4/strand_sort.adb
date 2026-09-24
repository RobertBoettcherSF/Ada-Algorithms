--  Strand_Sort body — SPARK Level 4 strand sort with static buffers.
--  Strand extraction + merge prove only In_Bounds / RTE; the final gap-1
--  bubble finish reuses Bubble_Pass / Sorted_Slice / Prefix_Leq_Suffix so
--  Sort proves Is_Sorted (same split as Comb_Sort / Odd_Even_Sort).

package body Strand_Sort
  with SPARK_Mode => On
is

   --  Cursor one past the live range (merge drain sentinels).
   subtype Cursor is Natural range 0 .. Max_N + 1;

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

   --  Strand extraction + merge into Output, then copy back to A.
   --  Only In_Bounds / RTE are proved here (sortedness from Bubble_Finish).
   procedure Strand_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      N : constant Index := A'Last;

      Input     : Element_Array (1 .. Max_N) := [others => 0];
      Strand    : Element_Array (1 .. Max_N) := [others => 0];
      Output    : Element_Array (1 .. Max_N) := [others => 0];
      Remaining : Element_Array (1 .. Max_N) := [others => 0];

      Input_Len     : Index := N;
      Strand_Len    : Index;
      Output_Len    : Index := 0;
      Remaining_Len : Index;
      Last_Taken    : Integer;
      I, J, K       : Cursor;
      Merged_Len    : Index;
   begin
      for X in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all T in 1 .. X - 1 => Input (T) = A (T));

         Input (X) := A (X);
      end loop;

      --  Cap outer strand iterations at Max_N (each iteration removes ≥1
      --  element from Input, so Input_Len = 0 within ≤ N ≤ Max_N steps).
      for Iter in 1 .. Max_N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Input_Len <= N);
         pragma Loop_Invariant (Output_Len <= N);
         pragma Loop_Invariant (Input_Len + Output_Len = N);
         pragma Loop_Invariant (N in 2 .. Max_N);

         exit when Input_Len = 0;

         --  Extract one nondecreasing strand from Input(1 .. Input_Len).
         Strand_Len := 1;
         Strand (1) := Input (1);
         Last_Taken := Input (1);
         Remaining_Len := 0;

         for X in 2 .. Input_Len loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (X in 2 .. Input_Len + 1);
            pragma Loop_Invariant (Strand_Len >= 1);
            pragma Loop_Invariant (Strand_Len <= X - 1);
            pragma Loop_Invariant (Remaining_Len <= X - 2);
            pragma Loop_Invariant (Strand_Len + Remaining_Len = X - 1);
            pragma Loop_Invariant (Strand_Len <= Max_N);
            pragma Loop_Invariant (Remaining_Len <= Max_N);
            pragma Loop_Invariant (Input_Len <= N);
            pragma Loop_Invariant (Output_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len = N);

            if Input (X) >= Last_Taken then
               Strand_Len := Strand_Len + 1;
               Strand (Strand_Len) := Input (X);
               Last_Taken := Input (X);
            else
               Remaining_Len := Remaining_Len + 1;
               Remaining (Remaining_Len) := Input (X);
            end if;
         end loop;

         pragma Assert (Strand_Len + Remaining_Len = Input_Len);
         pragma Assert (Strand_Len >= 1);
         pragma Assert (Strand_Len <= Input_Len);
         pragma Assert (Output_Len + Strand_Len <= N);

         for X in 1 .. Remaining_Len loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (X in 1 .. Remaining_Len + 1);
            pragma Loop_Invariant (Remaining_Len <= Input_Len);
            pragma Loop_Invariant (Input_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len = N);
            pragma Loop_Invariant (Strand_Len + Remaining_Len = Input_Len);
            pragma Loop_Invariant (Output_Len + Strand_Len <= N);

            Input (X) := Remaining (X);
         end loop;
         Input_Len := Remaining_Len;

         --  Merge Strand(1 .. Strand_Len) into Output(1 .. Output_Len)
         --  using Remaining as the merged scratch. Prefer left on ≤.
         Merged_Len := Output_Len + Strand_Len;
         I := 1;
         J := 1;
         K := 1;

         while I <= Output_Len and then J <= Strand_Len loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (I in 1 .. Output_Len + 1);
            pragma Loop_Invariant (J in 1 .. Strand_Len + 1);
            pragma Loop_Invariant (K = (I - 1) + (J - 1) + 1);
            pragma Loop_Invariant (K in 1 .. Merged_Len);
            pragma Loop_Invariant (Merged_Len = Output_Len + Strand_Len);
            pragma Loop_Invariant (Merged_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len + Strand_Len = N);
            pragma Loop_Variant
              (Decreases => (Output_Len + 1 - I) + (Strand_Len + 1 - J));

            if Output (I) <= Strand (J) then
               Remaining (K) := Output (I);
               I := I + 1;
            else
               Remaining (K) := Strand (J);
               J := J + 1;
            end if;
            K := K + 1;
         end loop;

         while I <= Output_Len loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (I in 1 .. Output_Len + 1);
            pragma Loop_Invariant (J = Strand_Len + 1);
            pragma Loop_Invariant (K = (I - 1) + (J - 1) + 1);
            pragma Loop_Invariant (K in 1 .. Merged_Len);
            pragma Loop_Invariant (Merged_Len = Output_Len + Strand_Len);
            pragma Loop_Invariant (Merged_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len + Strand_Len = N);
            pragma Loop_Variant (Decreases => Output_Len + 1 - I);

            Remaining (K) := Output (I);
            I := I + 1;
            K := K + 1;
         end loop;

         while J <= Strand_Len loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (J in 1 .. Strand_Len + 1);
            pragma Loop_Invariant (I = Output_Len + 1);
            pragma Loop_Invariant (K = (I - 1) + (J - 1) + 1);
            pragma Loop_Invariant (K in 1 .. Merged_Len);
            pragma Loop_Invariant (Merged_Len = Output_Len + Strand_Len);
            pragma Loop_Invariant (Merged_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len + Strand_Len = N);
            pragma Loop_Variant (Decreases => Strand_Len + 1 - J);

            Remaining (K) := Strand (J);
            J := J + 1;
            K := K + 1;
         end loop;

         pragma Assert (K = Merged_Len + 1);
         Output_Len := Merged_Len;
         pragma Assert (Input_Len + Output_Len = N);

         for X in 1 .. Output_Len loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (X in 1 .. Output_Len + 1);
            pragma Loop_Invariant (Output_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len = N);

            Output (X) := Remaining (X);
         end loop;
      end loop;

      for X in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));

         A (X) := Output (X);
      end loop;
   end Strand_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Strand_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (same role as Comb / Odd_Even).
      Bubble_Finish (A);
   end Sort;

end Strand_Sort;
