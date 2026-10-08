--  Strand_Sort body: SPARK Level 4 strand sort with static buffers.
--  Strand_Phase is proved to sort on its own: every strand is
--  nondecreasing, the merge keeps Output nondecreasing, and each outer
--  iteration moves at least one element, so Input is empty after at most
--  N iterations and Output holds all N elements. No fallback pass.

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

   --  Strand extraction + merge into Output, then copy back to A.
   procedure Strand_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A) and then Is_Sorted (A)
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
         pragma Loop_Invariant (N >= 2);
         pragma Loop_Invariant (Input_Len + Iter - 1 <= N);
         pragma Loop_Invariant (Sorted_Slice (Output, 1, Output_Len));

         exit when Input_Len = 0;

         --  Extract one nondecreasing strand from Input(1 .. Input_Len).
         Strand_Len := 1;
         Strand (1) := Input (1);
         Last_Taken := Input (1);
         Remaining_Len := 0;

         for X in 2 .. Input_Len loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (Strand_Len >= 1);
            pragma Loop_Invariant (Strand_Len <= X - 1);
            pragma Loop_Invariant (Remaining_Len <= X - 2);
            pragma Loop_Invariant (Strand_Len + Remaining_Len = X - 1);
            pragma Loop_Invariant (Input_Len <= N);
            pragma Loop_Invariant (Output_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len = N);
            pragma Loop_Invariant (Strand (Strand_Len) = Last_Taken);
            pragma Loop_Invariant (Sorted_Slice (Strand, 1, Strand_Len));
            pragma Loop_Invariant (Sorted_Slice (Output, 1, Output_Len));

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
            pragma Loop_Invariant (Remaining_Len <= Input_Len);
            pragma Loop_Invariant (Input_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len = N);
            pragma Loop_Invariant (Strand_Len + Remaining_Len = Input_Len);
            pragma Loop_Invariant (Output_Len + Strand_Len <= N);
            pragma Loop_Invariant (Sorted_Slice (Strand, 1, Strand_Len));
            pragma Loop_Invariant (Sorted_Slice (Output, 1, Output_Len));

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
            pragma Loop_Invariant (Sorted_Slice (Strand, 1, Strand_Len));
            pragma Loop_Invariant (Sorted_Slice (Output, 1, Output_Len));
            pragma Loop_Invariant (Sorted_Slice (Remaining, 1, K - 1));
            pragma Loop_Invariant
              (if K > 1 and then I <= Output_Len
               then Remaining (K - 1) <= Output (I));
            pragma Loop_Invariant
              (if K > 1 and then J <= Strand_Len
               then Remaining (K - 1) <= Strand (J));
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
            pragma Loop_Invariant (Sorted_Slice (Strand, 1, Strand_Len));
            pragma Loop_Invariant (Sorted_Slice (Output, 1, Output_Len));
            pragma Loop_Invariant (Sorted_Slice (Remaining, 1, K - 1));
            pragma Loop_Invariant
              (if K > 1 and then I <= Output_Len
               then Remaining (K - 1) <= Output (I));
            pragma Loop_Invariant
              (if K > 1 and then J <= Strand_Len
               then Remaining (K - 1) <= Strand (J));
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
            pragma Loop_Invariant (Sorted_Slice (Strand, 1, Strand_Len));
            pragma Loop_Invariant (Sorted_Slice (Output, 1, Output_Len));
            pragma Loop_Invariant (Sorted_Slice (Remaining, 1, K - 1));
            pragma Loop_Invariant
              (if K > 1 and then I <= Output_Len
               then Remaining (K - 1) <= Output (I));
            pragma Loop_Invariant
              (if K > 1 and then J <= Strand_Len
               then Remaining (K - 1) <= Strand (J));
            pragma Loop_Variant (Decreases => Strand_Len + 1 - J);

            Remaining (K) := Strand (J);
            J := J + 1;
            K := K + 1;
         end loop;

         pragma Assert (K = Merged_Len + 1);
         pragma Assert (Sorted_Slice (Remaining, 1, Merged_Len));
         Output_Len := Merged_Len;
         pragma Assert (Input_Len + Output_Len = N);

         for X in 1 .. Output_Len loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (Output_Len <= N);
            pragma Loop_Invariant (Input_Len + Output_Len = N);
            pragma Loop_Invariant (Sorted_Slice (Remaining, 1, Output_Len));
            pragma Loop_Invariant
              (for all T in 1 .. X - 1 => Output (T) = Remaining (T));

            Output (X) := Remaining (X);
         end loop;
         pragma Assert (Sorted_Slice (Output, 1, Output_Len));
      end loop;

      --  Every iteration moved at least one element, so Input is empty.
      pragma Assert (Input_Len = 0);
      pragma Assert (Output_Len = N);

      for X in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant
           (for all T in 1 .. X - 1 => A (T) = Output (T));

         A (X) := Output (X);
      end loop;
      pragma Assert (Sorted_Slice (Output, 1, N));
   end Strand_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Strand_Phase (A);
   end Sort;

end Strand_Sort;
