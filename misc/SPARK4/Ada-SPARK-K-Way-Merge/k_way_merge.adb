--  K_Way_Merge body — SPARK Level 4 k-way merge via linear scan of k
--  heads, plus educational 2-way Merge. Loop invariants track a sorted
--  Output prefix and head ≥ last so Merge_K / Merge prove Is_Sorted
--  when every input list is sorted (no Bubble_Finish).

package body K_Way_Merge
  with SPARK_Mode => On
is

   --  Cursor into a list: 1 .. Len+1 (Len+1 means exhausted).
   subtype Pos_Cursor is Natural range 0 .. Max_Len + 1;

   type Pos_Array is array (1 .. Max_K) of Pos_Cursor;

   --  Adjacent nondecreasing on A (L .. R). Vacuous when L >= R.
   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all T in L .. R - 1 => A (T) <= A (T + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       A'First = 1
       and then R <= A'Last
       and then L >= 1;

   --  Remaining elements across Pos (1 .. K).
   function Live_Count
     (Pos  : Pos_Array;
      Lens : Len_Array;
      K    : Index_K) return Natural
   is
     (case K is
         when 1 =>
           (if Pos (1) <= Lens (1) then Lens (1) - Pos (1) + 1 else 0),
         when 2 =>
           (if Pos (1) <= Lens (1) then Lens (1) - Pos (1) + 1 else 0)
             + (if Pos (2) <= Lens (2) then Lens (2) - Pos (2) + 1 else 0),
         when 3 =>
           (if Pos (1) <= Lens (1) then Lens (1) - Pos (1) + 1 else 0)
             + (if Pos (2) <= Lens (2) then Lens (2) - Pos (2) + 1 else 0)
             + (if Pos (3) <= Lens (3) then Lens (3) - Pos (3) + 1 else 0),
         when 4 =>
           (if Pos (1) <= Lens (1) then Lens (1) - Pos (1) + 1 else 0)
             + (if Pos (2) <= Lens (2) then Lens (2) - Pos (2) + 1 else 0)
             + (if Pos (3) <= Lens (3) then Lens (3) - Pos (3) + 1 else 0)
             + (if Pos (4) <= Lens (4) then Lens (4) - Pos (4) + 1 else 0),
         when 5 =>
           (if Pos (1) <= Lens (1) then Lens (1) - Pos (1) + 1 else 0)
             + (if Pos (2) <= Lens (2) then Lens (2) - Pos (2) + 1 else 0)
             + (if Pos (3) <= Lens (3) then Lens (3) - Pos (3) + 1 else 0)
             + (if Pos (4) <= Lens (4) then Lens (4) - Pos (4) + 1 else 0)
             + (if Pos (5) <= Lens (5) then Lens (5) - Pos (5) + 1 else 0),
         when 6 =>
           (if Pos (1) <= Lens (1) then Lens (1) - Pos (1) + 1 else 0)
             + (if Pos (2) <= Lens (2) then Lens (2) - Pos (2) + 1 else 0)
             + (if Pos (3) <= Lens (3) then Lens (3) - Pos (3) + 1 else 0)
             + (if Pos (4) <= Lens (4) then Lens (4) - Pos (4) + 1 else 0)
             + (if Pos (5) <= Lens (5) then Lens (5) - Pos (5) + 1 else 0)
             + (if Pos (6) <= Lens (6) then Lens (6) - Pos (6) + 1 else 0),
         when 7 =>
           (if Pos (1) <= Lens (1) then Lens (1) - Pos (1) + 1 else 0)
             + (if Pos (2) <= Lens (2) then Lens (2) - Pos (2) + 1 else 0)
             + (if Pos (3) <= Lens (3) then Lens (3) - Pos (3) + 1 else 0)
             + (if Pos (4) <= Lens (4) then Lens (4) - Pos (4) + 1 else 0)
             + (if Pos (5) <= Lens (5) then Lens (5) - Pos (5) + 1 else 0)
             + (if Pos (6) <= Lens (6) then Lens (6) - Pos (6) + 1 else 0)
             + (if Pos (7) <= Lens (7) then Lens (7) - Pos (7) + 1 else 0),
         when 8 =>
           (if Pos (1) <= Lens (1) then Lens (1) - Pos (1) + 1 else 0)
             + (if Pos (2) <= Lens (2) then Lens (2) - Pos (2) + 1 else 0)
             + (if Pos (3) <= Lens (3) then Lens (3) - Pos (3) + 1 else 0)
             + (if Pos (4) <= Lens (4) then Lens (4) - Pos (4) + 1 else 0)
             + (if Pos (5) <= Lens (5) then Lens (5) - Pos (5) + 1 else 0)
             + (if Pos (6) <= Lens (6) then Lens (6) - Pos (6) + 1 else 0)
             + (if Pos (7) <= Lens (7) then Lens (7) - Pos (7) + 1 else 0)
             + (if Pos (8) <= Lens (8) then Lens (8) - Pos (8) + 1 else 0))
   with
     Ghost  => True,
     Global => null,
     Pre    => (for all I in 1 .. K => Pos (I) in 1 .. Lens (I) + 1),
     Post   => Live_Count'Result <= Natural (K) * Max_Len;

   -------------------------------------------------------------------------
   -- Merge_K — linear scan of k heads
   -------------------------------------------------------------------------

   procedure Merge_K
     (Store  : List_Store;
      Lens   : Len_Array;
      K      : Index_K;
      Output : out Element_Array;
      Last   : out Natural)
   is
      Pos       : Pos_Array := [others => 1];
      Total     : constant Natural := Total_Length (Lens, K);
      Remaining : Natural := Total;
      OI        : Natural := 0;
      Best      : Natural;
      Min_Val   : Integer;
      Old_Pos   : Pos_Cursor;
   begin
      Output := [others => 0];

      pragma Assert (Live_Count (Pos, Lens, K) = Total);

      while Remaining > 0 loop
         pragma Loop_Invariant (OI + Remaining = Total);
         pragma Loop_Invariant (OI <= Total);
         pragma Loop_Invariant (Remaining = Live_Count (Pos, Lens, K));
         pragma Loop_Invariant
           (for all I in 1 .. K => Pos (I) in 1 .. Lens (I) + 1);
         pragma Loop_Invariant
           (for all I in 1 .. K =>
              (Pos (I) >= Lens (I)
               or else
                 (for all J in Pos (I) .. Lens (I) - 1 =>
                    Store (I, J) <= Store (I, J + 1))));
         pragma Loop_Invariant (Sorted_Slice (Output, 1, OI));
         pragma Loop_Invariant
           (OI = 0
            or else
              (for all I in 1 .. K =>
                 (if Pos (I) <= Lens (I)
                  then Output (OI) <= Store (I, Pos (I)))));
         pragma Loop_Variant (Decreases => Remaining);

         Best := 0;
         Min_Val := Integer'Last;

         for I in 1 .. K loop
            pragma Loop_Invariant (Best <= K);
            pragma Loop_Invariant
              (Best = 0
               or else
                 (Best in 1 .. I - 1
                  and then Pos (Best) <= Lens (Best)
                  and then Min_Val = Store (Best, Pos (Best))));
            pragma Loop_Invariant
              (for all J in 1 .. I - 1 =>
                 (if Pos (J) <= Lens (J)
                  then Best /= 0
                    and then Min_Val <= Store (J, Pos (J))));
            pragma Loop_Invariant
              (for all T in 1 .. K => Pos (T) in 1 .. Lens (T) + 1);
            pragma Loop_Invariant (Sorted_Slice (Output, 1, OI));
            pragma Loop_Invariant (OI + Remaining = Total);
            pragma Loop_Invariant
              (Remaining = Live_Count (Pos, Lens, K));
            pragma Loop_Invariant
              (OI = 0
               or else
                 (for all T in 1 .. K =>
                    (if Pos (T) <= Lens (T)
                     then Output (OI) <= Store (T, Pos (T)))));
            pragma Loop_Invariant
              (for all T in 1 .. K =>
                 (Pos (T) >= Lens (T)
                  or else
                    (for all J in Pos (T) .. Lens (T) - 1 =>
                       Store (T, J) <= Store (T, J + 1))));

            if Pos (I) <= Lens (I)
              and then (Best = 0 or else Store (I, Pos (I)) < Min_Val)
            then
               Best := I;
               Min_Val := Store (I, Pos (I));
            end if;
         end loop;

         pragma Assert (Remaining = Live_Count (Pos, Lens, K));
         pragma Assert (Remaining > 0);
         pragma Assert (Best in 1 .. K);
         pragma Assert (Pos (Best) <= Lens (Best));
         pragma Assert (Min_Val = Store (Best, Pos (Best)));
         pragma Assert
           (for all J in 1 .. K =>
              (if Pos (J) <= Lens (J)
               then Min_Val <= Store (J, Pos (J))));
         pragma Assert (OI = 0 or else Output (OI) <= Min_Val);

         OI := OI + 1;
         Output (OI) := Min_Val;
         pragma Assert (Sorted_Slice (Output, 1, OI));

         Old_Pos := Pos (Best);
         Pos (Best) := Old_Pos + 1;
         Remaining := Remaining - 1;

         --  New live heads are all >= Min_Val = Output (OI).
         pragma Assert
           (for all I in 1 .. K =>
              (if I /= Best and then Pos (I) <= Lens (I)
               then Output (OI) <= Store (I, Pos (I))));
         pragma Assert
           (if Pos (Best) <= Lens (Best)
            then Store (Best, Old_Pos) <= Store (Best, Pos (Best)));
         pragma Assert
           (if Pos (Best) <= Lens (Best)
            then Output (OI) <= Store (Best, Pos (Best)));
      end loop;

      Last := OI;
      pragma Assert (Last = Total);
      pragma Assert (Sorted_Slice (Output, 1, Last));
      pragma Assert (In_Bounds (Output (1 .. Last)));
      pragma Assert (Is_Sorted (Output (1 .. Last)));
   end Merge_K;

   -------------------------------------------------------------------------
   -- Merge — educational 2-way scan
   -------------------------------------------------------------------------

   procedure Merge
     (A, B   : Element_Array;
      Output : out Element_Array;
      Last   : out Natural)
   is
      IA   : Natural := 1;
      IB   : Natural := 1;
      OI   : Natural := 0;
      Need : constant Natural := Natural (A'Last) + Natural (B'Last);
      LA   : constant Natural := A'Last;
      LB   : constant Natural := B'Last;
   begin
      Output := [others => 0];

      if Need = 0 then
         Last := 0;
         pragma Assert (Is_Sorted (Output (1 .. Last)));
         return;
      end if;

      while IA <= LA and then IB <= LB loop
         pragma Loop_Invariant (IA in 1 .. LA + 1);
         pragma Loop_Invariant (IB in 1 .. LB + 1);
         pragma Loop_Invariant (OI = (IA - 1) + (IB - 1));
         pragma Loop_Invariant (OI <= Need);
         pragma Loop_Invariant (Sorted_Slice (Output, 1, OI));
         pragma Loop_Invariant
           (OI = 0 or else (IA <= LA and then Output (OI) <= A (IA)));
         pragma Loop_Invariant
           (OI = 0 or else (IB <= LB and then Output (OI) <= B (IB)));
         pragma Loop_Invariant
           (for all T in IA .. LA - 1 => A (T) <= A (T + 1));
         pragma Loop_Invariant
           (for all T in IB .. LB - 1 => B (T) <= B (T + 1));
         pragma Loop_Variant (Decreases => (LA - IA + 1) + (LB - IB + 1));

         if A (IA) <= B (IB) then
            OI := OI + 1;
            Output (OI) := A (IA);
            IA := IA + 1;
         else
            OI := OI + 1;
            Output (OI) := B (IB);
            IB := IB + 1;
         end if;
      end loop;

      while IA <= LA loop
         pragma Loop_Invariant (IA in 1 .. LA);
         pragma Loop_Invariant (IB = LB + 1);
         pragma Loop_Invariant (OI = (IA - 1) + (IB - 1));
         pragma Loop_Invariant (OI < Need);
         pragma Loop_Invariant (Sorted_Slice (Output, 1, OI));
         pragma Loop_Invariant
           (OI = 0 or else Output (OI) <= A (IA));
         pragma Loop_Invariant
           (for all T in IA .. LA - 1 => A (T) <= A (T + 1));
         pragma Loop_Variant (Decreases => LA - IA + 1);

         OI := OI + 1;
         Output (OI) := A (IA);
         IA := IA + 1;
      end loop;

      while IB <= LB loop
         pragma Loop_Invariant (IB in 1 .. LB);
         pragma Loop_Invariant (IA = LA + 1);
         pragma Loop_Invariant (OI = (IA - 1) + (IB - 1));
         pragma Loop_Invariant (OI < Need);
         pragma Loop_Invariant (Sorted_Slice (Output, 1, OI));
         pragma Loop_Invariant
           (OI = 0 or else Output (OI) <= B (IB));
         pragma Loop_Invariant
           (for all T in IB .. LB - 1 => B (T) <= B (T + 1));
         pragma Loop_Variant (Decreases => LB - IB + 1);

         OI := OI + 1;
         Output (OI) := B (IB);
         IB := IB + 1;
      end loop;

      Last := OI;
      pragma Assert (Last = Need);
      pragma Assert (Sorted_Slice (Output, 1, Last));
      pragma Assert (Is_Sorted (Output (1 .. Last)));
   end Merge;

end K_Way_Merge;
