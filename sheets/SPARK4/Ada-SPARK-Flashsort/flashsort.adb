--  Flashsort body — SPARK Level 4 Neubert flashsort with static borders.
--  Classification / cycle-follow permute / per-class insertion prove only
--  In_Bounds / RTE; the final gap-1 bubble finish reuses Bubble_Pass /
--  Sorted_Slice / Prefix_Leq_Suffix so Sort proves Is_Sorted (same split
--  as Strand_Sort / Comb_Sort / Odd_Even_Sort).

package body Flashsort
  with SPARK_Mode => On
is

   --  Static border vector: live slots are 1 .. M with M ≤ Max_N
   --  (actually M ≤ max(2, Max_N / Class_Divisor) ≤ Max_N).
   type Border_Array is array (Positive range 1 .. Max_N) of Natural;

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
   --  range to index Bound via adjacent swaps.
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

   --  m = max(2, n / Class_Divisor). For n >= 2 this is <= n <= Max_N.
   function Class_Count (N : Index) return Positive
     with
       Global => null,
       Pre    => N >= 2,
       Post   =>
         Class_Count'Result in 2 .. N
         and then Class_Count'Result <= Max_N
   is
      M : constant Natural := N / Class_Divisor;
   begin
      if M < 2 then
         return 2;
      end if;
      return M;
   end Class_Count;

   --  Educational flashsort: min/max, histogram, cycle-follow permute,
   --  per-class insertion. Only In_Bounds / RTE are proved here.
   procedure Flashsort_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      N       : constant Index := A'Last;
      Min_Val : Integer;
      Max_Val : Integer;
      M       : Positive;
      L       : Border_Array := [others => 0];
      Upper   : Border_Array := [others => 0];
      J       : Natural;
      B       : Positive;
      T, Hold : Integer;
      Lo, Hi  : Natural;
      Steps   : Natural;
      Key     : Integer;
      P       : Index;
   begin
      Min_Val := A (1);
      Max_Val := A (1);

      for X in 2 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Min_Val <= Max_Val);

         if A (X) < Min_Val then
            Min_Val := A (X);
         elsif A (X) > Max_Val then
            Max_Val := A (X);
         end if;
      end loop;

      pragma Assert (Min_Val <= Max_Val);

      --  All equal: already sorted; denominator would be zero.
      if Min_Val = Max_Val then
         return;
      end if;

      pragma Assert (Min_Val < Max_Val);

      M := Class_Count (N);
      pragma Assert (M in 2 .. N);
      pragma Assert (M <= Max_N);
      pragma Assert (Min_Val < Max_Val);

      --  K = 1 + floor((m-1)*(X-min)/(max-min)). Long_Long_Integer keeps
      --  (m-1)*(X-min) from overflowing 32-bit Integer. Clamp to 1 .. M
      --  so RTE VCs discharge without a full interpolation lemma.
      declare
         function Class_Of
           (X                : Integer;
            Class_M          : Positive;
            Lo_Val, Hi_Val   : Integer) return Positive
           with
             Global => null,
             Pre    =>
               Class_M in 2 .. Max_N
               and then Lo_Val < Hi_Val,
             Post   => Class_Of'Result in 1 .. Class_M
         is
            Num : constant Long_Long_Integer :=
              Long_Long_Integer (Class_M - 1)
              * (Long_Long_Integer (X) - Long_Long_Integer (Lo_Val));
            Den : constant Long_Long_Integer :=
              Long_Long_Integer (Hi_Val) - Long_Long_Integer (Lo_Val);
            K   : Long_Long_Integer;
         begin
            pragma Assert (Den > 0);
            K := 1 + Num / Den;
            if K < 1 then
               return 1;
            elsif K > Long_Long_Integer (Class_M) then
               return Class_M;
            else
               return Positive (K);
            end if;
         end Class_Of;
      begin
         --  Histogram: count elements per class into L (1 .. M).
         for X in 1 .. N loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (M in 2 .. Max_N);
            pragma Loop_Invariant (Min_Val < Max_Val);
            pragma Loop_Invariant
              (for all K in 1 .. M => L (K) <= X - 1);
            pragma Loop_Invariant
              (for all K in 1 .. M => L (K) <= Max_N);

            B := Class_Of (A (X), M, Min_Val, Max_Val);
            pragma Assert (B in 1 .. M);
            L (B) := L (B) + 1;
         end loop;

         pragma Assert (for all K in 1 .. M => L (K) <= N);
         pragma Assert (for all K in 1 .. M => L (K) <= Max_N);

         --  Prefix-sum: L(K) becomes inclusive 1-based upper border of
         --  class K. Cap each write at N so RTE stays local (sum is n
         --  at run time; we do not prove the cardinality lemma).
         for K in 2 .. M loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (M in 2 .. Max_N);
            pragma Loop_Invariant (Min_Val < Max_Val);
            pragma Loop_Invariant (K in 2 .. M + 1);
            pragma Loop_Invariant
              (for all KK in 1 .. M => L (KK) <= Max_N);

            if L (K) <= Max_N - L (K - 1) then
               L (K) := L (K) + L (K - 1);
            else
               L (K) := N;
            end if;

            if L (K) > N then
               L (K) := N;
            end if;
         end loop;

         for K in 1 .. M loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (M in 2 .. Max_N);
            pragma Loop_Invariant (Min_Val < Max_Val);
            pragma Loop_Invariant
              (for all KK in 1 .. M => L (KK) <= Max_N);
            pragma Loop_Invariant
              (for all KK in 1 .. K - 1 => Upper (KK) = L (KK));
            pragma Loop_Invariant
              (for all KK in 1 .. K - 1 => Upper (KK) <= Max_N);

            Upper (K) := L (K);
         end loop;

         pragma Assert
           (for all KK in 1 .. M => Upper (KK) <= Max_N);
         pragma Assert (Min_Val < Max_Val);

         --  In-place permutation by cycle-following (Neubert / Wikipedia).
         --  Iteration caps + index guards keep Level-4 RTE dischargeable;
         --  sortedness comes from Bubble_Finish, not from this phase.
         for I in 1 .. N loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (M in 2 .. Max_N);
            pragma Loop_Invariant (Min_Val < Max_Val);
            pragma Loop_Invariant
              (for all K in 1 .. M => L (K) <= Max_N);
            pragma Loop_Invariant
              (for all K in 1 .. M => Upper (K) <= Max_N);

            B := Class_Of (A (I), M, Min_Val, Max_Val);
            pragma Assert (B in 1 .. M);

            if I <= L (B) then
               T     := A (I);
               Steps := 0;

               loop
                  pragma Loop_Invariant (In_Bounds (A));
                  pragma Loop_Invariant (M in 2 .. Max_N);
                  pragma Loop_Invariant (Min_Val < Max_Val);
                  pragma Loop_Invariant (Steps <= N);
                  pragma Loop_Invariant
                    (for all K in 1 .. M => L (K) <= Max_N);
                  pragma Loop_Invariant
                    (for all K in 1 .. M => Upper (K) <= Max_N);
                  pragma Loop_Variant (Decreases => N - Steps);

                  B := Class_Of (T, M, Min_Val, Max_Val);
                  pragma Assert (B in 1 .. M);

                  if L (B) in 1 .. N then
                     J    := L (B);
                     Hold := A (J);
                     A (J) := T;
                     T    := Hold;
                     L (B) := L (B) - 1;
                     exit when J = I;
                  else
                     exit;
                  end if;

                  Steps := Steps + 1;
                  exit when Steps >= N;
               end loop;
            end if;
         end loop;

         --  Insertion-sort within each class (empty classes skipped).
         --  Only RTE / In_Bounds (Bubble_Finish proves Is_Sorted).
         for K in 1 .. M loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (M in 2 .. Max_N);
            pragma Loop_Invariant (Min_Val < Max_Val);
            pragma Loop_Invariant
              (for all KK in 1 .. M => Upper (KK) <= Max_N);

            if K = 1 then
               Lo := 1;
            elsif Upper (K - 1) < N then
               Lo := Upper (K - 1) + 1;
            else
               --  Previous class already ends at N: remaining classes empty.
               Lo := N + 1;
            end if;
            Hi := Upper (K);

            if Lo <= N and then Hi <= N and then Hi >= Lo then
               if Hi > Lo then
                  for X in Lo + 1 .. Hi loop
                     pragma Loop_Invariant (In_Bounds (A));
                     pragma Loop_Invariant (X in Lo + 1 .. Hi + 1);
                     pragma Loop_Invariant (Lo in 1 .. N);
                     pragma Loop_Invariant (Hi in Lo .. N);

                     Key := A (X);
                     P   := X;

                     while P > Lo and then Key < A (P - 1) loop
                        pragma Loop_Invariant (P in Lo + 1 .. X);
                        pragma Loop_Invariant (In_Bounds (A));
                        pragma Loop_Variant (Decreases => P);

                        A (P) := A (P - 1);
                        P     := P - 1;
                     end loop;

                     A (P) := Key;
                  end loop;
               end if;
            end if;
         end loop;
      end;
   end Flashsort_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Flashsort_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (Strand / Bucket L4 pattern).
      Bubble_Finish (A);
   end Sort;

end Flashsort;
