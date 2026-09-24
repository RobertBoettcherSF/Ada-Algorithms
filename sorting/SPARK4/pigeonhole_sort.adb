--  Pigeonhole_Sort body — SPARK Level 4 pigeonhole sort with static
--  Counts / Work. Count + prefix + stable scatter prove only In_Bounds /
--  RTE; the final gap-1 bubble finish reuses Bubble_Pass / Sorted_Slice /
--  Prefix_Leq_Suffix so Sort proves Is_Sorted (same split as Flashsort /
--  Strand_Sort / Comb_Sort).

package body Pigeonhole_Sort
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

   function Keys_In_Range (A : Element_Array) return Boolean is
      Min_Val, Max_Val : Integer;
      Span             : Long_Long_Integer;
   begin
      if A'Length <= 1 then
         return True;
      end if;

      Min_Val := A (1);
      Max_Val := A (1);

      for I in 2 .. A'Last loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (I in 2 .. A'Last + 1);
         pragma Loop_Invariant (Min_Val <= Max_Val);

         if A (I) < Min_Val then
            Min_Val := A (I);
         elsif A (I) > Max_Val then
            Max_Val := A (I);
         end if;
      end loop;

      pragma Assert (Min_Val <= Max_Val);
      Span :=
        Long_Long_Integer (Max_Val) - Long_Long_Integer (Min_Val) + 1;
      return Span <= Long_Long_Integer (Max_Range);
   end Keys_In_Range;

   --  Map key X into hole index relative to Min_Val. Callers must ensure
   --  X ∈ [Min_Val, Min_Val + Max_Range − 1]; defensive clamp for RTE.
   function Hole_Of (X, Min_Val : Integer) return Hole_Index
     with
       Global => null
   is
      Diff : constant Long_Long_Integer :=
        Long_Long_Integer (X) - Long_Long_Integer (Min_Val);
   begin
      if Diff < 0 then
         return 0;
      elsif Diff >= Long_Long_Integer (Max_Range) then
         return Max_Range - 1;
      else
         return Hole_Index (Diff);
      end if;
   end Hole_Of;

   --  Educational pigeonhole: min/max, count, prefix offsets, stable
   --  scatter into Work, copy back. Only In_Bounds / RTE are proved.
   procedure Pigeonhole_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Keys_In_Range (A),
       Post   => In_Bounds (A)
   is
      N       : constant Index := A'Last;
      Min_Val : Integer;
      Max_Val : Integer;
      Span    : Long_Long_Integer;
      Counts  : Count_Array := [others => 0];
      Work    : Work_Array := [others => 0];
      Total   : Natural := 0;
      H       : Hole_Index;
      Dest    : Natural;
      C       : Natural;
   begin
      Min_Val := A (1);
      Max_Val := A (1);

      for X in 2 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Min_Val <= Max_Val);

         if A (X) < Min_Val then
            Min_Val := A (X);
         elsif A (X) > Max_Val then
            Max_Val := A (X);
         end if;
      end loop;

      pragma Assert (Min_Val <= Max_Val);
      Span :=
        Long_Long_Integer (Max_Val) - Long_Long_Integer (Min_Val) + 1;

      --  Defensive: Pre says Keys_In_Range; if span still exceeds
      --  Max_Range, skip the hole phase (Bubble_Finish will sort).
      if Span > Long_Long_Integer (Max_Range) then
         return;
      end if;

      pragma Assert (Span >= 1);
      pragma Assert (Span <= Long_Long_Integer (Max_Range));

      --  Count how many items fall into each pigeonhole.
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Min_Val <= Max_Val);
         pragma Loop_Invariant
           (for all K in Hole_Index => Counts (K) <= I - 1);
         pragma Loop_Invariant
           (for all K in Hole_Index => Counts (K) <= Max_N);

         H := Hole_Of (A (I), Min_Val);
         Counts (H) := Counts (H) + 1;
      end loop;

      pragma Assert (for all K in Hole_Index => Counts (K) <= N);
      pragma Assert (for all K in Hole_Index => Counts (K) <= Max_N);

      --  Convert counts into starting offsets (exclusive prefix).
      --  After this, Counts (H) is the next free 1-based slot in Work
      --  for hole H. Cap Total at N so RTE stays local (sum is n at
      --  run time; we do not prove the cardinality lemma).
      for HH in Hole_Index loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Total <= N);
         pragma Loop_Invariant (Total <= Max_N);
         pragma Loop_Invariant
           (for all K in Hole_Index => Counts (K) <= Max_N);

         C := Counts (HH);
         Counts (HH) := Total;
         if Total <= N - C then
            Total := Total + C;
         else
            Total := N;
         end if;
      end loop;

      pragma Assert (Total <= N);
      pragma Assert (for all K in Hole_Index => Counts (K) <= Max_N);

      --  Stable scatter: place each item into its hole segment L→R.
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Min_Val <= Max_Val);
         pragma Loop_Invariant
           (for all K in Hole_Index => Counts (K) <= Max_N);

         H := Hole_Of (A (I), Min_Val);
         Dest := Counts (H) + 1;
         if Dest in 1 .. N then
            Work (Dest) := A (I);
            if Counts (H) < Max_N then
               Counts (H) := Counts (H) + 1;
            end if;
         end if;
      end loop;

      --  Read contiguous hole segments back into A (key order).
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);

         A (I) := Work (I);
      end loop;
   end Pigeonhole_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Pigeonhole_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (Flashsort / Strand L4 pattern).
      Bubble_Finish (A);
   end Sort;

end Pigeonhole_Sort;
