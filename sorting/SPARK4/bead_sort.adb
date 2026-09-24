--  Bead_Sort body — SPARK Level 4 bead sort with static Rods.
--  Bead (drop / reconstruct) phase proves only In_Bounds / RTE; the
--  final gap-1 bubble finish reuses Bubble_Pass / Sorted_Slice /
--  Prefix_Leq_Suffix so Sort proves Is_Sorted (same split as
--  Pigeonhole_Sort / Strand_Sort / Comb_Sort / Flashsort).
--  Bubble_Finish on Natural arrays — same adjacent-swap pattern as
--  Integer sorts.

package body Bead_Sort
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
      T : Natural;
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

   --  Educational bead sort: drop beads on static rods, reconstruct
   --  ascending rows. Only In_Bounds / RTE are proved.
   procedure Bead_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Values_Ok (A),
       Post   => In_Bounds (A)
   is
      subtype Cursor is Natural range 0 .. Max_N + 1;

      N       : constant Index := A'Last;
      Max_Val : Natural := 0;
      Rods    : Rod_Array := [others => 0];
      Idx     : Cursor;
      Count   : Natural;
      V       : Natural;
   begin
      --  Find M = max(A). Values_Ok ⇒ Max_Val ≤ Max_Value.
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Max_Val <= Max_Value);
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => A (K) <= Max_Value);
         pragma Loop_Invariant
           (for all K in 1 .. I - 1 => A (K) <= Max_Val);

         if A (I) > Max_Val then
            Max_Val := A (I);
         end if;
      end loop;

      pragma Assert (Max_Val <= Max_Value);

      --  All zeros: already sorted; nothing to drop.
      if Max_Val = 0 then
         return;
      end if;

      --  Drop a_i beads onto rods 1 .. a_i (column counts = gravity).
      --  Each rod height is at most N (one bead per input element).
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Max_Val in 1 .. Max_Value);
         pragma Loop_Invariant
           (for all K in Rod_Index => Rods (K) <= I - 1);
         pragma Loop_Invariant
           (for all K in Rod_Index => Rods (K) <= Max_N);

         V := A (I);
         if V > 0 then
            pragma Assert (V <= Max_Value);
            for J in 1 .. V loop
               pragma Loop_Invariant (In_Bounds (A));
               pragma Loop_Invariant (N = A'Last);
               pragma Loop_Invariant (V in 1 .. Max_Value);
               pragma Loop_Invariant (J in 1 .. V + 1);
               pragma Loop_Invariant
                 (for all K in Rod_Index => Rods (K) <= Max_N);
               pragma Loop_Invariant
                 (for all K in Rod_Index =>
                    (if K < J then Rods (K) <= I
                     else Rods (K) <= I - 1));

               Rods (J) := Rods (J) + 1;
            end loop;
         end if;
      end loop;

      pragma Assert (for all K in Rod_Index => Rods (K) <= N);
      pragma Assert (for all K in Rod_Index => Rods (K) <= Max_N);

      --  Read rows from top (H = N) to bottom (H = 1): few beads →
      --  small values first (ascending). Row H has a bead on rod J
      --  iff Rods (J) >= H; the row's value is that bead count
      --  (at most Max_Value rods can contribute).
      Idx := 1;
      for H in reverse 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (N = A'Last);
         pragma Loop_Invariant (Idx in 1 .. N + 1);
         pragma Loop_Invariant (Idx <= Max_N + 1);
         pragma Loop_Invariant (Idx = N - H + 1);
         pragma Loop_Invariant
           (for all K in Rod_Index => Rods (K) <= N);
         pragma Loop_Invariant
           (for all K in Rod_Index => Rods (K) <= Max_N);

         Count := 0;
         for J in Rod_Index loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (N = A'Last);
            pragma Loop_Invariant (Idx in 1 .. N);
            pragma Loop_Invariant (Count <= J - 1);
            pragma Loop_Invariant (Count <= Max_Value);
            pragma Loop_Invariant
              (for all K in Rod_Index => Rods (K) <= N);

            if Rods (J) >= H then
               Count := Count + 1;
            end if;
         end loop;

         pragma Assert (Count <= Max_Value);
         pragma Assert (Idx in 1 .. N);
         A (Idx) := Count;
         Idx := Idx + 1;
      end loop;

      pragma Assert (Idx = N + 1);
   end Bead_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Bead_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (Pigeonhole / Strand L4 pattern).
      Bubble_Finish (A);
   end Sort;

end Bead_Sort;
