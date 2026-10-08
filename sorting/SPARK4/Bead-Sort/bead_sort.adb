--  Bead_Sort body — SPARK Level 4 bead sort with static Rods.
--  The bead (drop / reconstruct) phase is proved to sort on its own;
--  there is no finishing pass.

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

   --  Number of rods among 1 .. U carrying at least H beads (the bead
   --  count of row H when U = Max_Value).
   subtype Rod_Upto is Natural range 0 .. Max_Value;

   function Row_Count (R : Rod_Array; H : Positive; U : Rod_Upto) return Natural is
     (if U = 0 then 0
      else Row_Count (R, H, U - 1) + (if R (U) >= H then 1 else 0))
   with
     Ghost              => True,
     Global             => null,
     Post               => Row_Count'Result <= U,
     Subprogram_Variant => (Decreases => U);

   --  A higher row has no more beads than a lower one.
   procedure Lemma_Row_Mono (R : Rod_Array; H : Positive; U : Rod_Upto)
     with
       Ghost              => True,
       Global             => null,
       Pre                => H < Positive'Last,
       Post               => Row_Count (R, H + 1, U) <= Row_Count (R, H, U),
       Subprogram_Variant => (Decreases => U)
   is
   begin
      if U > 0 then
         Lemma_Row_Mono (R, H, U - 1);
      end if;
   end Lemma_Row_Mono;

   --  Educational bead sort: drop beads on static rods, reconstruct
   --  ascending rows. Proved to sort on its own: row H holds
   --  Row_Count (Rods, H, Max_Value) beads, rows are read from the top
   --  (H = N) down, and a higher row never holds more beads than a lower
   --  one (Lemma_Row_Mono).
   procedure Bead_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 2
         and then Values_Ok (A),
       Post   => In_Bounds (A) and then Is_Sorted (A)
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
         pragma Assert (for all K in 1 .. N => A (K) = 0);
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
         pragma Loop_Invariant (Sorted_Slice (A, 1, Idx - 1));
         pragma Loop_Invariant
           (if Idx > 1 then A (Idx - 1) = Row_Count (Rods, H + 1, Max_Value));

         Count := 0;
         for J in Rod_Index loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (N = A'Last);
            pragma Loop_Invariant (Idx in 1 .. N);
            pragma Loop_Invariant (Count <= J - 1);
            pragma Loop_Invariant (Count <= Max_Value);
            pragma Loop_Invariant
              (for all K in Rod_Index => Rods (K) <= N);
            pragma Loop_Invariant (Count = Row_Count (Rods, H, J - 1));
            pragma Loop_Invariant (Sorted_Slice (A, 1, Idx - 1));
            pragma Loop_Invariant
              (if Idx > 1 then A (Idx - 1) = Row_Count (Rods, H + 1, Max_Value));

            if Rods (J) >= H then
               Count := Count + 1;
            end if;
         end loop;

         pragma Assert (Count <= Max_Value);
         pragma Assert (Idx in 1 .. N);
         pragma Assert (Count = Row_Count (Rods, H, Max_Value));
         Lemma_Row_Mono (Rods, H, Max_Value);
         pragma Assert (if Idx > 1 then A (Idx - 1) <= Count);
         A (Idx) := Count;
         Idx := Idx + 1;
      end loop;

      pragma Assert (Idx = N + 1);
      pragma Assert (Sorted_Slice (A, 1, N));
   end Bead_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Bead_Phase (A);
   end Sort;

end Bead_Sort;
