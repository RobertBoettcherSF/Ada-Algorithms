--  Patience_Sorting body — SPARK Level 4 patience sort with static node
--  pool. Deal + k-way merge prove only In_Bounds / RTE; the final gap-1
--  bubble finish reuses Bubble_Pass / Sorted_Slice / Prefix_Leq_Suffix so
--  Sort proves Is_Sorted (same split as Comb_Sort / Odd_Even_Sort /
--  Strand_Sort).

package body Patience_Sorting
  with SPARK_Mode => On
is

   --  0 = null / empty stack link. Live nodes occupy 1 .. Used (<= Max_N).
   subtype Node_Index is Natural range 0 .. Max_N;
   None : constant Node_Index := 0;

   --  Cursor one past the live range (merge Out_I sentinel).
   subtype Cursor is Natural range 0 .. Max_N + 1;

   type Stack_Node is record
      Value : Integer    := 0;
      Below : Node_Index := None;
   end record;

   type Node_Pool is array (1 .. Max_N) of Stack_Node;
   type Top_Array is array (1 .. Max_N) of Node_Index;

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

   --  Deal onto piles + k-way merge into A.
   --  Only In_Bounds / RTE are proved here (sortedness from Bubble_Finish).
   procedure Patience_Phase (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 2,
       Post   => In_Bounds (A)
   is
      N : constant Index := A'Last;

      Pool      : Node_Pool  := [others => (Value => 0, Below => None)];
      Used      : Index      := 0;
      Pile_Tops : Top_Array  := [others => None];
      Num_Piles : Index      := 0;

      X_Val     : Integer;
      J         : Positive;
      Lo, Hi    : Natural;
      Mid       : Natural;
      Best      : Positive;
      Best_Val  : Integer;
      Node      : Node_Index;
      Next      : Node_Index;
      Out_I     : Cursor;
   begin
      ------------------------------------------------------------------
      -- Phase 1: Deal each A(I) onto piles (binary-search leftmost
      -- pile with top >= X, else new pile).
      ------------------------------------------------------------------
      for I in 1 .. N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Used = I - 1);
         pragma Loop_Invariant (Used <= N);
         pragma Loop_Invariant (Num_Piles <= Used);
         pragma Loop_Invariant (Num_Piles <= Max_N);
         pragma Loop_Invariant
           (for all T in 1 .. Num_Piles =>
              Pile_Tops (T) in 1 .. Used);
         pragma Loop_Invariant
           (for all U in 1 .. Used =>
              Pool (U).Below = None
              or else Pool (U).Below in 1 .. Used);

         X_Val := A (I);

         if Num_Piles = 0 then
            Used := Used + 1;
            Pool (Used).Value := X_Val;
            Pool (Used).Below := None;
            Num_Piles := 1;
            Pile_Tops (1) := Used;
         else
            --  Binary search: leftmost pile whose top >= X_Val.
            Lo := 1;
            Hi := Num_Piles;
            while Lo <= Hi loop
               pragma Loop_Invariant (In_Bounds (A));
               pragma Loop_Invariant (Num_Piles in 1 .. Max_N);
               pragma Loop_Invariant (Num_Piles <= Used);
               pragma Loop_Invariant (Used = I - 1);
               pragma Loop_Invariant (Used < N);
               pragma Loop_Invariant (Lo in 1 .. Num_Piles + 1);
               pragma Loop_Invariant (Hi <= Num_Piles);
               pragma Loop_Invariant (Lo <= Hi + 1);
               pragma Loop_Invariant
                 (for all T in 1 .. Num_Piles =>
                    Pile_Tops (T) in 1 .. Used);
               pragma Loop_Invariant
                 (for all U in 1 .. Used =>
                    Pool (U).Below = None
                    or else Pool (U).Below in 1 .. Used);
               pragma Loop_Variant (Decreases => Hi + 1 - Lo);

               Mid := Lo + (Hi - Lo) / 2;
               pragma Assert (Mid in 1 .. Num_Piles);
               pragma Assert (Pile_Tops (Mid) in 1 .. Used);

               if Pool (Pile_Tops (Mid)).Value >= X_Val then
                  Hi := Mid - 1;
               else
                  Lo := Mid + 1;
               end if;
            end loop;

            J := Lo;
            pragma Assert (J in 1 .. Num_Piles + 1);

            Used := Used + 1;
            if J <= Num_Piles then
               --  Push onto existing pile J (new top <= old top).
               pragma Assert (Pile_Tops (J) in 1 .. Used - 1);
               Pool (Used).Value := X_Val;
               Pool (Used).Below := Pile_Tops (J);
               Pile_Tops (J) := Used;
            else
               --  New pile to the right.
               Pool (Used).Value := X_Val;
               Pool (Used).Below := None;
               Num_Piles := Num_Piles + 1;
               Pile_Tops (Num_Piles) := Used;
            end if;
         end if;
      end loop;

      pragma Assert (Used = N);
      pragma Assert (Num_Piles >= 1);
      pragma Assert (Num_Piles <= N);

      ------------------------------------------------------------------
      -- Phase 2: K-way merge — repeatedly pop the pile with the
      -- smallest top into A. Empty piles swapped with last active.
      ------------------------------------------------------------------
      Out_I := 1;

      while Num_Piles > 0 and then Out_I <= N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Out_I in 1 .. N);
         pragma Loop_Invariant (Num_Piles in 1 .. N);
         pragma Loop_Invariant (Num_Piles <= Max_N);
         pragma Loop_Invariant (Used = N);
         pragma Loop_Invariant
           (for all T in 1 .. Num_Piles =>
              Pile_Tops (T) in 1 .. Used);
         pragma Loop_Invariant
           (for all U in 1 .. Used =>
              Pool (U).Below = None
              or else Pool (U).Below in 1 .. Used);
         pragma Loop_Variant (Decreases => N + 1 - Out_I);

         Best := 1;
         Best_Val := Pool (Pile_Tops (1)).Value;

         for Q in 2 .. Num_Piles loop
            pragma Loop_Invariant (In_Bounds (A));
            pragma Loop_Invariant (Num_Piles in 1 .. Max_N);
            pragma Loop_Invariant (Best in 1 .. Num_Piles);
            pragma Loop_Invariant (Best < Q);
            pragma Loop_Invariant (Used = N);
            pragma Loop_Invariant
              (for all T in 1 .. Num_Piles =>
                 Pile_Tops (T) in 1 .. Used);
            pragma Loop_Invariant
              (for all U in 1 .. Used =>
                 Pool (U).Below = None
                 or else Pool (U).Below in 1 .. Used);

            if Pool (Pile_Tops (Q)).Value < Best_Val then
               Best := Q;
               Best_Val := Pool (Pile_Tops (Q)).Value;
            end if;
         end loop;

         pragma Assert (Best in 1 .. Num_Piles);
         pragma Assert (Pile_Tops (Best) in 1 .. Used);

         Node := Pile_Tops (Best);
         A (Out_I) := Pool (Node).Value;
         Out_I := Out_I + 1;

         --  Pop; if pile empties, swap with last active pile.
         Next := Pool (Node).Below;
         if Next = None then
            if Best < Num_Piles then
               Pile_Tops (Best) := Pile_Tops (Num_Piles);
            end if;
            Num_Piles := Num_Piles - 1;
         else
            pragma Assert (Next in 1 .. Used);
            Pile_Tops (Best) := Next;
         end if;
      end loop;

      pragma Assert (In_Bounds (A));
   end Patience_Phase;

   procedure Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;

      Patience_Phase (A);

      --  Gap-1 bubble finish → Is_Sorted (same role as Comb / Strand).
      Bubble_Finish (A);
   end Sort;

end Patience_Sorting;
