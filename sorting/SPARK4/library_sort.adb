--  Library_Sort body — SPARK Level 4 gapped insertion sort (ε = 1).
--  Library phase (Gather / Spread / Rebalance / binary-search insert)
--  proves only In_Bounds / RTE on a static Working buffer of size
--  Max_Cap. The final gap-1 bubble finish reuses Bubble_Pass /
--  Sorted_Slice / Prefix_Leq_Suffix so Sort proves Is_Sorted (same
--  split as Strand / Bitonic / Comb / Odd_Even). No Intentional Annotate.

package body Library_Sort
  with SPARK_Mode => On
is

   subtype Cap_Index is Natural range 0 .. Max_Cap;
   subtype Cap_Pos is Positive range 1 .. Max_Cap;
   --  One past Cap for binary-search Lo/Hi sentinels.
   subtype Cap_Cursor is Natural range 0 .. Max_Cap + 1;
   --  One past Max_N for Src after the last insertion.
   subtype Index_Ext is Natural range 0 .. Max_N + 1;

   type Slot is record
      Occupied : Boolean := False;
      Value    : Integer := 0;
   end record;

   type Working_Array is array (Positive range <>) of Slot;

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

   ---------------------------------------------------------------------------
   -- Library-sort helpers (In_Bounds / RTE only)
   ---------------------------------------------------------------------------

   --  Pack occupied values of W(1 .. Cap) into Dense(1 .. Count), clear W.
   procedure Gather
     (W     : in out Working_Array;
      Cap   : Cap_Pos;
      Dense : out Element_Array;
      Count : out Cap_Index)
     with
       Global => null,
       Pre    =>
         W'First = 1
         and then W'Last = Max_Cap
         and then Dense'First = 1
         and then Dense'Last = Max_N,
       Post   =>
         Count <= Cap
         and then Count <= Max_N
         and then
           (for all I in 1 .. Cap => not W (I).Occupied)
   is
      K : Cap_Index := 0;
   begin
      Dense := [others => 0];

      for I in 1 .. Cap loop
         pragma Loop_Invariant (K <= I - 1);
         pragma Loop_Invariant (K <= Max_N);
         pragma Loop_Invariant
           (for all T in 1 .. I - 1 => not W (T).Occupied);

         if W (I).Occupied then
            if K < Max_N then
               K := K + 1;
               Dense (K) := W (I).Value;
            end if;
         end if;
         W (I) := (Occupied => False, Value => 0);
      end loop;

      Count := K;
   end Gather;

   --  Place Count dense values evenly into W(1 .. Cap) with gaps.
   --  Step = Cap / Count (>= 1). Element k goes near 1 + (k-1)*Step.
   procedure Spread
     (W     : in out Working_Array;
      Dense : Element_Array;
      Count : Cap_Index;
      Cap   : Cap_Pos)
     with
       Global => null,
       Pre    =>
         W'First = 1
         and then W'Last = Max_Cap
         and then Count <= Cap
         and then Count <= Max_N
         and then Dense'First = 1
         and then Dense'Last = Max_N
   is
      Step : Cap_Pos;
      Pos  : Cap_Pos;
      K    : Cap_Index;
   begin
      for I in 1 .. Cap loop
         W (I) := (Occupied => False, Value => 0);
      end loop;

      if Count = 0 then
         return;
      end if;

      Step := Cap / Count;
      pragma Assert (Step >= 1);

      K := 0;
      while K < Count loop
         pragma Loop_Invariant (K < Count);
         pragma Loop_Invariant (K <= Max_N);
         pragma Loop_Invariant (Count <= Cap);
         pragma Loop_Invariant (Count <= Max_N);
         pragma Loop_Variant (Increases => K);

         K := K + 1;
         --  Pos := 1 + (K-1)*Step, clamped into 1 .. Cap, then walk
         --  forward on rare collisions.
         declare
            Offset : constant Natural := Natural (K - 1) * Natural (Step);
         begin
            if Offset >= Cap then
               Pos := Cap;
            else
               Pos := Cap_Pos (1 + Offset);
               if Pos > Cap then
                  Pos := Cap;
               end if;
            end if;
         end;

         while Pos < Cap and then W (Pos).Occupied loop
            pragma Loop_Invariant (Pos in 1 .. Cap);
            pragma Loop_Invariant (K in 1 .. Count);
            pragma Loop_Variant (Increases => Pos);
            Pos := Pos + 1;
         end loop;

         if not W (Pos).Occupied then
            W (Pos) :=
              (Occupied => True,
               Value    => Dense (K));
         else
            --  Cap full of collisions: scan from 1 for any free slot.
            declare
               P : Cap_Pos := 1;
            begin
               while P < Cap and then W (P).Occupied loop
                  pragma Loop_Invariant (P in 1 .. Cap);
                  pragma Loop_Variant (Increases => P);
                  P := P + 1;
               end loop;
               if not W (P).Occupied then
                  W (P) :=
                    (Occupied => True,
                     Value    => Dense (K));
               end if;
            end;
         end if;
      end loop;
   end Spread;

   procedure Rebalance
     (W     : in out Working_Array;
      Cap   : Cap_Pos;
      Count : Cap_Index)
     with
       Global => null,
       Pre    =>
         W'First = 1
         and then W'Last = Max_Cap
         and then Count <= Cap
         and then Count <= Max_N
   is
      Dense : Element_Array (1 .. Max_N);
      Got   : Cap_Index;
   begin
      pragma Assert (Count <= Cap);
      Gather (W, Cap, Dense, Got);
      if Got <= Cap and then Got <= Max_N then
         Spread (W, Dense, Got, Cap);
      end if;
   end Rebalance;

   --  Binary search in W(1 .. Limit) for the insertion index of X.
   --  Gaps at Mid are resolved by scanning right, then left.
   function Binary_Search_Insert
     (W     : Working_Array;
      Limit : Cap_Index;
      X     : Integer) return Cap_Pos
     with
       Global => null,
       Pre    =>
         W'First = 1
         and then W'Last = Max_Cap
         and then Limit <= Max_Cap,
       Post   => True
   is
      Lo : Cap_Cursor := 1;
      Hi : Cap_Cursor := Limit;
   begin
      if Limit < 1 then
         return 1;
      end if;

      while Lo <= Hi loop
         pragma Loop_Invariant (Lo >= 1);
         pragma Loop_Invariant (Hi <= Limit);
         pragma Loop_Invariant (Lo <= Hi + 1);
         pragma Loop_Invariant (Hi <= Max_Cap);
         pragma Loop_Variant (Decreases => Natural (Hi) - Natural (Lo) + 1);

         declare
            Mid     : Cap_Cursor := Lo + (Hi - Lo) / 2;
            Mid_Val : Integer := 0;
            Has_Val : Boolean := False;
            R       : Cap_Cursor;
            L       : Cap_Cursor;
         begin
            pragma Assert (Mid >= Lo and then Mid <= Hi);
            pragma Assert (Mid in 1 .. Max_Cap);

            if W (Mid).Occupied then
               Mid_Val := W (Mid).Value;
               Has_Val := True;
            else
               R := Mid;
               while R < Hi and then not W (R).Occupied loop
                  pragma Loop_Invariant (R in Mid .. Hi);
                  pragma Loop_Invariant (R <= Max_Cap);
                  pragma Loop_Variant (Increases => R);
                  R := R + 1;
               end loop;
               if R <= Hi and then R <= Max_Cap and then W (R).Occupied then
                  Mid     := R;
                  Mid_Val := W (R).Value;
                  Has_Val := True;
               else
                  L := Mid;
                  while L > Lo and then not W (L).Occupied loop
                     pragma Loop_Invariant (L in Lo .. Mid);
                     pragma Loop_Invariant (L >= 1);
                     pragma Loop_Variant (Decreases => L);
                     L := L - 1;
                  end loop;
                  if L >= Lo and then L >= 1 and then L <= Max_Cap
                    and then W (L).Occupied
                  then
                     Mid     := L;
                     Mid_Val := W (L).Value;
                     Has_Val := True;
                  end if;
               end if;
            end if;

            if not Has_Val then
               if Lo = 0 or else Lo > Max_Cap then
                  return 1;
               else
                  return Cap_Pos (Lo);
               end if;
            end if;

            if Mid_Val < X then
               Lo := Mid + 1;
            elsif Mid_Val > X then
               if Mid = 0 then
                  Hi := 0;
               else
                  Hi := Mid - 1;
               end if;
            else
               if Mid in 1 .. Max_Cap then
                  return Cap_Pos (Mid);
               else
                  return 1;
               end if;
            end if;
         end;
      end loop;

      if Lo = 0 then
         return 1;
      elsif Lo > Max_Cap then
         return Max_Cap;
      else
         return Cap_Pos (Lo);
      end if;
   end Binary_Search_Insert;

   --  Insert X at Pos: fill a gap, or shift right/left until a gap.
   --  Returns False if no gap exists in 1 .. Cap.
   procedure Try_Insert
     (W   : in out Working_Array;
      Cap : Cap_Pos;
      Pos : Cap_Pos;
      X   : Integer;
      Ok  : out Boolean)
     with
       Global => null,
       Pre    =>
         W'First = 1
         and then W'Last = Max_Cap,
       Post   => True
   is
      P : Cap_Pos := Pos;
      J : Cap_Pos;
   begin
      if P > Cap then
         P := Cap;
      end if;

      if not W (P).Occupied then
         W (P) := (Occupied => True, Value => X);
         Ok := True;
         return;
      end if;

      --  Scan right for a gap.
      J := P;
      while J < Cap and then W (J).Occupied loop
         pragma Loop_Invariant (J in P .. Cap);
         pragma Loop_Variant (Increases => J);
         J := J + 1;
      end loop;

      if not W (J).Occupied then
         --  Shift occupied slots right from P .. J-1 into P+1 .. J.
         declare
            K : Cap_Pos := J;
         begin
            while K > P loop
               pragma Loop_Invariant (K in P .. J);
               pragma Loop_Invariant (K >= 1);
               pragma Loop_Variant (Decreases => K);
               W (K) := W (K - 1);
               K := K - 1;
            end loop;
         end;
         W (P) := (Occupied => True, Value => X);
         Ok := True;
         return;
      end if;

      --  No gap to the right: scan left.
      J := P;
      while J > 1 and then W (J).Occupied loop
         pragma Loop_Invariant (J in 1 .. P);
         pragma Loop_Variant (Decreases => J);
         J := J - 1;
      end loop;

      if not W (J).Occupied then
         --  Shift occupied slots left from J+1 .. P into J .. P-1.
         declare
            K : Cap_Pos := J;
         begin
            while K < P loop
               pragma Loop_Invariant (K in J .. P);
               pragma Loop_Variant (Increases => K);
               W (K) := W (K + 1);
               K := K + 1;
            end loop;
         end;
         W (P) := (Occupied => True, Value => X);
         Ok := True;
         return;
      end if;

      Ok := False;
   end Try_Insert;

   --  Gapped insertion into static Working; pack back into A.
   --  Only In_Bounds / RTE are proved here (sortedness from Bubble_Finish).
   procedure Library_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      N         : constant Index := A'Last;
      Cap       : constant Cap_Pos := Cap_Pos (2 * N);
      W         : Working_Array (1 .. Max_Cap) :=
                    [others => (Occupied => False, Value => 0)];
      Dense     : Element_Array (1 .. Max_N);
      Inserted  : Cap_Index;
      Next_Goal : Cap_Index := 1;
      Src       : Index_Ext;
      X         : Integer;
      Pos       : Cap_Pos;
      Ok        : Boolean;
      Got       : Cap_Index;
      K         : Cap_Index;
   begin
      pragma Assert (N in 2 .. Max_N);
      pragma Assert (Cap = 2 * N);
      pragma Assert (Cap in 4 .. Max_Cap);
      pragma Assert (Cap <= Max_Cap);

      W (1) := (Occupied => True, Value => A (1));
      Inserted := 1;
      Src := 2;

      --  Cap outer insertions at Max_N (Inserted grows to N ≤ Max_N).
      for Iter in 1 .. Max_N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Inserted in 1 .. N);
         pragma Loop_Invariant (Inserted <= Max_N);
         pragma Loop_Invariant (Src = Inserted + 1);
         pragma Loop_Invariant (Src in 2 .. N + 1);
         pragma Loop_Invariant (Next_Goal >= 1);
         pragma Loop_Invariant (Cap = 2 * N);
         pragma Loop_Invariant (N in 2 .. Max_N);

         exit when Inserted >= N;

         if Inserted = Next_Goal then
            Rebalance (W, Cap, Inserted);
            if Next_Goal <= Max_N / 2 then
               Next_Goal := Next_Goal * 2;
            else
               Next_Goal := N;
            end if;
         end if;

         X := A (Src);
         Pos := Binary_Search_Insert (W, Cap, X);
         Try_Insert (W, Cap, Pos, X, Ok);

         if not Ok then
            Rebalance (W, Cap, Inserted);
            Pos := Binary_Search_Insert (W, Cap, X);
            Try_Insert (W, Cap, Pos, X, Ok);
            if not Ok then
               Gather (W, Cap, Dense, Got);
               if Got < Max_N then
                  Got := Got + 1;
                  Dense (Got) := X;
               end if;
               if Got <= Cap then
                  Spread (W, Dense, Got, Cap);
               end if;
            end if;
         end if;

         Inserted := Inserted + 1;
         Src := Src + 1;
      end loop;

      --  Pack occupied slots left-to-right back into A(1 .. N).
      K := 0;
      for I in 1 .. Cap loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (K <= N);
         pragma Loop_Invariant (K <= I - 1);
         pragma Loop_Invariant (N in 2 .. Max_N);

         if W (I).Occupied and then K < N then
            K := K + 1;
            A (K) := W (I).Value;
         end if;
      end loop;
   end Library_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Library_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (same role as Strand / Bitonic).
      Bubble_Finish (A);
   end Sort;

end Library_Sort;
