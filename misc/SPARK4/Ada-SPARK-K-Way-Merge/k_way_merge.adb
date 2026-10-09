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

   --  Loop invariants are proved by gnatprove and not re-evaluated at run
   --  time: the multiset invariants quantify over every Integer value.
   pragma Assertion_Policy (Loop_Invariant => Ignore);

   ---------------------------------------------------------------------------
   -- Multiset proof (ghost lemmas; contracts proved, not evaluated at run
   -- time because they quantify over every Integer value)
   ---------------------------------------------------------------------------

   package Count_Lemmas
     with Ghost
   is
      pragma Assertion_Policy (Pre => Ignore, Post => Ignore);

      --  Counts over A'First .. Last only see A'First .. Last.
      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Integer)
      with
        Global             => null,
        Pre                =>
          In_Bounds (A) and then In_Bounds (B)
          and then A'First = B'First
          and then Last <= A'Last and then Last <= B'Last
          and then (for all P in A'First .. Last => A (P) = B (P)),
        Post               =>
          (for all V in Integer => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

      --  Nothing taken yet from lists 1 .. K counts 0.
      procedure Lemma_Taken_Zero
        (Store : List_Store; U : Len_Array; K : List_Count)
      with
        Global             => null,
        Pre                => (for all I in 1 .. K => U (I) = 0),
        Post               =>
          (for all V in Integer => Taken (Store, U, V, K) = 0),
        Subprogram_Variant => (Decreases => K);

      --  Taken (.., K) only sees U (1 .. K).
      procedure Lemma_Taken_Frame
        (Store : List_Store; U1, U2 : Len_Array; K : List_Count)
      with
        Global             => null,
        Pre                => (for all I in 1 .. K => U1 (I) = U2 (I)),
        Post               =>
          (for all V in Integer =>
             Taken (Store, U1, V, K) = Taken (Store, U2, V, K)),
        Subprogram_Variant => (Decreases => K);

      --  Taking one more item from list B adds that item.
      procedure Lemma_Taken_Bump
        (Store : List_Store; U1, U2 : Len_Array; B : Index_K; K : List_Count)
      with
        Global             => null,
        Pre                =>
          B <= K
          and then U1 (B) < Max_Len
          and then U2 (B) = U1 (B) + 1
          and then (for all I in 1 .. K => (if I /= B then U1 (I) = U2 (I))),
        Post               =>
          (for all V in Integer =>
             Taken (Store, U2, V, K)
             = Taken (Store, U1, V, K)
               + (if Store (B, U2 (B)) = V then 1 else 0)),
        Subprogram_Variant => (Decreases => K);
   end Count_Lemmas;

   package body Count_Lemmas is

      procedure Lemma_Occ_Frame (A, B : Element_Array; Last : Integer) is
      begin
         if Last >= A'First then
            Lemma_Occ_Frame (A, B, Last - 1);
         end if;
      end Lemma_Occ_Frame;

      procedure Lemma_Taken_Zero
        (Store : List_Store; U : Len_Array; K : List_Count) is
      begin
         if K > 0 then
            Lemma_Taken_Zero (Store, U, K - 1);
         end if;
      end Lemma_Taken_Zero;

      procedure Lemma_Taken_Frame
        (Store : List_Store; U1, U2 : Len_Array; K : List_Count) is
      begin
         if K > 0 then
            Lemma_Taken_Frame (Store, U1, U2, K - 1);
         end if;
      end Lemma_Taken_Frame;

      procedure Lemma_Taken_Bump
        (Store : List_Store; U1, U2 : Len_Array; B : Index_K; K : List_Count) is
      begin
         if K > B then
            Lemma_Taken_Bump (Store, U1, U2, B, K - 1);
         else
            Lemma_Taken_Frame (Store, U1, U2, K - 1);
         end if;
      end Lemma_Taken_Bump;

   end Count_Lemmas;
   use Count_Lemmas;

   --  Adjacent nondecreasing on A (L .. R) (storage indices). Vacuous
   --  when L >= R.
   function Sorted_Slice
     (A : Element_Array; L, R : Natural) return Boolean
   is
     (L >= R
      or else (for all T in L .. R - 1 => A (T) <= A (T + 1)))
   with
     Ghost  => True,
     Global => null,
     Pre    => (if L < R then L >= A'First and then R <= A'Last);

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
      --  The OI-th merged value is stored at Output (OO + OI).
      OO        : constant Natural := Output'First - 1;
      Best      : Natural;
      Min_Val   : Integer;
      Old_Pos   : Pos_Cursor;
      Done      : Len_Array := [others => 0] with Ghost;
   begin
      Output := [others => 0];

      pragma Assert (Live_Count (Pos, Lens, K) = Total);
      Lemma_Taken_Zero (Store, Done, K);

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
         pragma Loop_Invariant (Sorted_Slice (Output, OO + 1, OO + OI));
         pragma Loop_Invariant
           (OI = 0
            or else
              (for all I in 1 .. K =>
                 (if Pos (I) <= Lens (I)
                  then Output (OO + OI) <= Store (I, Pos (I)))));
         pragma Loop_Invariant (for all I in 1 .. K => Done (I) = Pos (I) - 1);
         pragma Loop_Invariant
           (for all V in Integer =>
              Occ (Output, V, OO + OI) = Taken (Store, Done, V, K));
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
            pragma Loop_Invariant (Sorted_Slice (Output, OO + 1, OO + OI));
            pragma Loop_Invariant (OI + Remaining = Total);
            pragma Loop_Invariant
              (Remaining = Live_Count (Pos, Lens, K));
            pragma Loop_Invariant
              (OI = 0
               or else
                 (for all T in 1 .. K =>
                    (if Pos (T) <= Lens (T)
                     then Output (OO + OI) <= Store (T, Pos (T)))));
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
         pragma Assert (OI = 0 or else Output (OO + OI) <= Min_Val);

         declare
            Out_Before  : constant Element_Array := Output with Ghost;
            Done_Before : constant Len_Array := Done with Ghost;
         begin
            OI := OI + 1;
            Output (OO + OI) := Min_Val;
            pragma Assert (Sorted_Slice (Output, OO + 1, OO + OI));

            Old_Pos := Pos (Best);
            Pos (Best) := Old_Pos + 1;
            Done (Best) := Old_Pos;
            Remaining := Remaining - 1;
            Lemma_Occ_Frame (Out_Before, Output, OO + OI - 1);
            Lemma_Taken_Bump (Store, Done_Before, Done, Best, K);
         end;

         --  New live heads are all >= Min_Val = Output (OO + OI).
         pragma Assert
           (for all I in 1 .. K =>
              (if I /= Best and then Pos (I) <= Lens (I)
               then Output (OO + OI) <= Store (I, Pos (I))));
         pragma Assert
           (if Pos (Best) <= Lens (Best)
            then Store (Best, Old_Pos) <= Store (Best, Pos (Best)));
         pragma Assert
           (if Pos (Best) <= Lens (Best)
            then Output (OO + OI) <= Store (Best, Pos (Best)));
      end loop;

      Last := OI;
      pragma Assert (Last = Total);
      pragma Assert (for all I in 1 .. K => Pos (I) = Lens (I) + 1);
      Lemma_Taken_Frame (Store, Done, Lens, K);
      pragma Assert (Sorted_Slice (Output, OO + 1, OO + Last));
      pragma Assert (In_Bounds (Output (Output'First .. Output'First + (Last - 1))));
      pragma Assert (Is_Sorted (Output (Output'First .. Output'First + (Last - 1))));
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
      Need : constant Natural := A'Length + B'Length;
      LA   : constant Natural := A'Length;
      LB   : constant Natural := B'Length;
      --  The I-th element of A is A (AO + I), of B is B (BO + I), and the
      --  OI-th merged value goes to Output (OO + OI): any origins. AO / BO
      --  are Integer because an empty A may have A'First = 0.
      AO   : constant Integer := A'First - 1;
      BO   : constant Integer := B'First - 1;
      OO   : constant Natural := Output'First - 1;
   begin
      Output := [others => 0];

      if Need = 0 then
         Last := 0;
         pragma Assert (Is_Sorted (Output (Output'First .. Output'First + (Last - 1))));
         return;
      end if;

      while IA <= LA and then IB <= LB loop
         pragma Loop_Invariant (IA in 1 .. LA + 1);
         pragma Loop_Invariant (IB in 1 .. LB + 1);
         pragma Loop_Invariant (OI = (IA - 1) + (IB - 1));
         pragma Loop_Invariant (OI <= Need);
         pragma Loop_Invariant (Sorted_Slice (Output, OO + 1, OO + OI));
         pragma Loop_Invariant
           (OI = 0 or else (IA <= LA and then Output (OO + OI) <= A (AO + IA)));
         pragma Loop_Invariant
           (OI = 0 or else (IB <= LB and then Output (OO + OI) <= B (BO + IB)));
         pragma Loop_Invariant
           (for all T in IA .. LA - 1 => A (AO + T) <= A (AO + T + 1));
         pragma Loop_Invariant
           (for all T in IB .. LB - 1 => B (BO + T) <= B (BO + T + 1));
         pragma Loop_Invariant
           (for all V in Integer =>
              Occ (Output, V, OO + OI)
              = Occ (A, V, AO + (IA - 1)) + Occ (B, V, BO + (IB - 1)));
         pragma Loop_Variant (Decreases => (LA - IA + 1) + (LB - IB + 1));

         if A (AO + IA) <= B (BO + IB) then
            declare
               Before : constant Element_Array := Output with Ghost;
            begin
               OI := OI + 1;
               Output (OO + OI) := A (AO + IA);
               IA := IA + 1;
               Lemma_Occ_Frame (Before, Output, OO + OI - 1);
            end;
         else
            declare
               Before : constant Element_Array := Output with Ghost;
            begin
               OI := OI + 1;
               Output (OO + OI) := B (BO + IB);
               IB := IB + 1;
               Lemma_Occ_Frame (Before, Output, OO + OI - 1);
            end;
         end if;
      end loop;

      while IA <= LA loop
         pragma Loop_Invariant (IA in 1 .. LA);
         pragma Loop_Invariant (IB = LB + 1);
         pragma Loop_Invariant (OI = (IA - 1) + (IB - 1));
         pragma Loop_Invariant (OI < Need);
         pragma Loop_Invariant (Sorted_Slice (Output, OO + 1, OO + OI));
         pragma Loop_Invariant
           (OI = 0 or else Output (OO + OI) <= A (AO + IA));
         pragma Loop_Invariant
           (for all T in IA .. LA - 1 => A (AO + T) <= A (AO + T + 1));
         pragma Loop_Invariant
           (for all V in Integer =>
              Occ (Output, V, OO + OI)
              = Occ (A, V, AO + (IA - 1)) + Occ (B, V, BO + (IB - 1)));
         pragma Loop_Variant (Decreases => LA - IA + 1);

         declare
            Before : constant Element_Array := Output with Ghost;
         begin
            OI := OI + 1;
            Output (OO + OI) := A (AO + IA);
            IA := IA + 1;
            Lemma_Occ_Frame (Before, Output, OO + OI - 1);
         end;
      end loop;

      while IB <= LB loop
         pragma Loop_Invariant (IB in 1 .. LB);
         pragma Loop_Invariant (IA = LA + 1);
         pragma Loop_Invariant (OI = (IA - 1) + (IB - 1));
         pragma Loop_Invariant (OI < Need);
         pragma Loop_Invariant (Sorted_Slice (Output, OO + 1, OO + OI));
         pragma Loop_Invariant
           (OI = 0 or else Output (OO + OI) <= B (BO + IB));
         pragma Loop_Invariant
           (for all T in IB .. LB - 1 => B (BO + T) <= B (BO + T + 1));
         pragma Loop_Invariant
           (for all V in Integer =>
              Occ (Output, V, OO + OI)
              = Occ (A, V, AO + (IA - 1)) + Occ (B, V, BO + (IB - 1)));
         pragma Loop_Variant (Decreases => LB - IB + 1);

         declare
            Before : constant Element_Array := Output with Ghost;
         begin
            OI := OI + 1;
            Output (OO + OI) := B (BO + IB);
            IB := IB + 1;
            Lemma_Occ_Frame (Before, Output, OO + OI - 1);
         end;
      end loop;

      pragma Assert (if LA > 0 then AO + (IA - 1) = A'Last);
      pragma Assert (if LB > 0 then BO + (IB - 1) = B'Last);
      Last := OI;
      pragma Assert (Last = Need);
      pragma Assert (OO + Last = Output'First + (Last - 1));
      pragma Assert (Sorted_Slice (Output, OO + 1, OO + Last));
      pragma Assert (Is_Sorted (Output (Output'First .. Output'First + (Last - 1))));
   end Merge;

end K_Way_Merge;
