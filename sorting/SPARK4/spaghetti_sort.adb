--  Spaghetti_Sort body — SPARK Level 4 height-bin spaghetti sort with
--  static Counts (0 .. Max_Key). Height-bin (tally / emit) phase proves
--  only In_Bounds / RTE; the final gap-1 bubble finish reuses
--  Bubble_Pass / Sorted_Slice / Prefix_Leq_Suffix so Sort proves
--  Is_Sorted (same split as Pigeonhole_Sort / Bead_Sort / Strand_Sort /
--  Comb_Sort / Flashsort).

package body Spaghetti_Sort
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

   --  Map Integer key into Count_Index. Callers must ensure Keys_Ok;
   --  defensive clamp keeps RTE local if a value somehow escapes.
   function Bin_Of (X : Integer) return Count_Index
     with
       Global => null
   is
   begin
      if X < 0 then
         return 0;
      elsif X > Max_Key then
         return Max_Key;
      else
         return Count_Index (X);
      end if;
   end Bin_Of;

   --  Educational height-bin: tally rod lengths, emit short→tall.
   --  Only In_Bounds / RTE are proved.
   procedure Height_Bin_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Keys_Ok (A),
       Post   => In_Bounds (A)
   is
      subtype Cursor is Natural range 0 .. Max_N + 1;

      N      : constant Index := A'Last;
      Counts : Count_Array := [others => 0];
      Pos    : Cursor;
      H      : Count_Index;
      C      : Natural;
      Pos0   : Cursor;
   begin
      --  Tally: Counts (H) = number of rods of length H.
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Keys_Ok (A));
         pragma Loop_Invariant
           (for all K in Count_Index => Counts (K) <= I - 1);
         pragma Loop_Invariant
           (for all K in Count_Index => Counts (K) <= Max_N);

         H := Bin_Of (A (I));
         Counts (H) := Counts (H) + 1;
      end loop;

      pragma Assert (for all K in Count_Index => Counts (K) <= N);
      pragma Assert (for all K in Count_Index => Counts (K) <= Max_N);

      --  Emit ascending: read bins from short to tall.
      --  Cap the write cursor at N so RTE stays local (sum is n at
      --  run time; we do not prove the cardinality lemma).
      Pos := 1;

      for HH in Count_Index loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Pos in 1 .. N + 1);
         pragma Loop_Invariant
           (for all K in Count_Index => Counts (K) <= Max_N);
         pragma Loop_Invariant
           (for all K in Count_Index => Counts (K) <= N);

         C := 0;
         Pos0 := Pos;

         while C < Counts (HH) loop
            pragma Loop_Invariant (C in 0 .. Counts (HH));
            pragma Loop_Invariant (Pos = Pos0 + C or else Pos = N + 1);
            pragma Loop_Invariant (Pos in 1 .. N + 1);
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (N = A'Last);
            pragma Loop_Invariant
              (for all K in Count_Index => Counts (K) <= Max_N);
            pragma Loop_Variant (Decreases => Counts (HH) - C);

            if Pos in 1 .. N then
               A (Pos) := HH;
               Pos := Pos + 1;
            end if;
            C := C + 1;
         end loop;
      end loop;
   end Height_Bin_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Height_Bin_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (Pigeonhole / Bead L4 pattern).
      Bubble_Finish (A);
   end Sort;

end Spaghetti_Sort;
