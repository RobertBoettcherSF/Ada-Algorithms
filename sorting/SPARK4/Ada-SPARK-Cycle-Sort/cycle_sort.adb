--  Cycle_Sort body — SPARK Level 4 classic write-optimal in-place cycle
--  sort. Outer loop grows a sorted / partitioned prefix (same shape as
--  selection sort); each Cycle_Step either skips an already-placed
--  element or rotates a displacement cycle. Closing writes use Dest=CS
--  so Item <= suffix is immediate from Dest_Index, discharging Is_Sorted.

package body Cycle_Sort
  with SPARK_Mode => On
is

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

   function Dest_Index
     (A : Element_Array; CS : Index; Item : Integer) return Index
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then A'Last >= 1
       and then CS in 1 .. A'Last,
     Post   =>
       Dest_Index'Result in CS .. A'Last
       and then
         (if Dest_Index'Result = CS then
            (for all K in CS + 1 .. A'Last => A (K) >= Item)
          else
            Dest_Index'Result > CS)
   is
      Pos : Index := CS;
   begin
      for I in CS + 1 .. A'Last loop
         pragma Loop_Invariant (Pos in CS .. I - 1);
         pragma Loop_Invariant
           (if Pos = CS then
              (for all K in CS + 1 .. I - 1 => A (K) >= Item));

         if A (I) < Item then
            Pos := Pos + 1;
         end if;
      end loop;
      return Pos;
   end Dest_Index;

   procedure Advance_Past_Equals
     (A    : Element_Array;
      Item : Integer;
      Pos  : in out Index)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then A'Last >= 1
       and then Pos in 1 .. A'Last,
     Post   => Pos in Pos'Old .. A'Last
   is
   begin
      while Pos < A'Last and then Item = A (Pos) loop
         pragma Loop_Invariant (Pos in Pos'Loop_Entry .. A'Last - 1);
         pragma Loop_Variant (Increases => Pos);
         Pos := Pos + 1;
      end loop;
   end Advance_Past_Equals;

   --  One write; local write counter is bounded by Max_N per cycle.
   procedure Place_Item
     (A     : in out Element_Array;
      Pos   : Index;
      Item  : in out Integer;
      Count : in out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Pos in 1 .. A'Last
       and then Count < Max_N,
     Post   =>
       In_Bounds (A)
       and then A (Pos) = Item'Old
       and then Item = A'Old (Pos)
       and then Count = Count'Old + 1
       and then Count <= Max_N
       and then
         (for all K in 1 .. A'Last =>
            (if K /= Pos then A (K) = A'Old (K)))
   is
      Tmp : constant Integer := A (Pos);
   begin
      A (Pos) := Item;
      Item    := Tmp;
      Count   := Count + 1;
   end Place_Item;

   --  Final placement write (no need for the displaced value).
   procedure Write_At
     (A     : in out Element_Array;
      Pos   : Index;
      Value : Integer;
      Count : in out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Pos in 1 .. A'Last
       and then Count < Max_N,
     Post   =>
       In_Bounds (A)
       and then A (Pos) = Value
       and then Count = Count'Old + 1
       and then Count <= Max_N
       and then
         (for all K in 1 .. A'Last =>
            (if K /= Pos then A (K) = A'Old (K)))
   is
   begin
      A (Pos) := Value;
      Count   := Count + 1;
   end Write_At;

   procedure Cycle_Step
     (A      : in out Element_Array;
      CS     : Index;
      Writes : out Natural)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then A'Last >= 2
       and then CS in 1 .. A'Last - 1
       and then Sorted_Slice (A, 1, CS - 1)
       and then Prefix_Leq_Suffix (A, 1, CS - 1, CS, A'Last),
     Post   =>
       In_Bounds (A)
       and then Sorted_Slice (A, 1, CS)
       and then Prefix_Leq_Suffix (A, 1, CS, CS + 1, A'Last)
       and then Writes <= Max_N
       and then
         (for all K in 1 .. CS - 1 => A (K) = A'Old (K))
   is
      Item       : Integer := A (CS);
      Pos        : Index;
      Count      : Natural := 0;
      Close_Item : Integer;
   begin
      Writes := 0;
      Pos := Dest_Index (A, CS, Item);

      if Pos = CS then
         pragma Assert (for all K in CS + 1 .. A'Last => A (K) >= Item);
         pragma Assert (CS = 1 or else A (CS - 1) <= Item);
         pragma Assert (Sorted_Slice (A, 1, CS));
         pragma Assert (Prefix_Leq_Suffix (A, 1, CS, CS + 1, A'Last));
         return;
      end if;

      Advance_Past_Equals (A, Item, Pos);
      Place_Item (A, Pos, Item, Count);

      pragma Assert (Sorted_Slice (A, 1, CS - 1));
      pragma Assert (Prefix_Leq_Suffix (A, 1, CS - 1, CS, A'Last));
      pragma Assert
        (CS = 1 or else (for all K in 1 .. CS - 1 => A (K) <= Item));

      for Step in 2 .. Max_N loop
         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Count in 1 .. Step - 1);
         pragma Loop_Invariant (Count < Max_N);
         pragma Loop_Invariant (Pos in 1 .. A'Last);
         pragma Loop_Invariant (Pos /= CS);
         pragma Loop_Invariant (Sorted_Slice (A, 1, CS - 1));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, CS - 1, CS, A'Last));
         pragma Loop_Invariant
           (for all K in 1 .. CS - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (CS = 1
            or else (for all K in 1 .. CS - 1 => A (K) <= Item));

         Pos := Dest_Index (A, CS, Item);

         if Pos = CS then
            pragma Assert
              (for all K in CS + 1 .. A'Last => A (K) >= Item);
            Close_Item := Item;
            Advance_Past_Equals (A, Item, Pos);
            if Pos = CS then
               Write_At (A, CS, Close_Item, Count);
               Writes := Count;
               pragma Assert (A (CS) = Close_Item);
               pragma Assert
                 (for all K in CS + 1 .. A'Last =>
                    A (K) >= Close_Item);
               pragma Assert
                 (CS = 1 or else A (CS - 1) <= Close_Item);
               pragma Assert (Sorted_Slice (A, 1, CS));
               pragma Assert
                 (Prefix_Leq_Suffix (A, 1, CS, CS + 1, A'Last));
               return;
            end if;
            Place_Item (A, Pos, Item, Count);
         else
            Advance_Past_Equals (A, Item, Pos);
            Place_Item (A, Pos, Item, Count);
         end if;
      end loop;

      --  Unreachable for n ≤ Max_N (cycle length ≤ n). Safety net for
      --  the prover: place the suffix minimum at CS like selection sort
      --  so Sorted_Slice / Prefix_Leq Posts still discharge.
      Writes := Count;
      declare
         Min_Index : Index := CS;
         Tmp       : Integer;
      begin
         for J in CS + 1 .. A'Last loop
            pragma Loop_Invariant (Min_Index in CS .. J - 1);
            pragma Loop_Invariant
              (for all K in CS .. J - 1 => A (Min_Index) <= A (K));
            pragma Loop_Invariant (Sorted_Slice (A, 1, CS - 1));
            pragma Loop_Invariant
              (Prefix_Leq_Suffix (A, 1, CS - 1, CS, A'Last));
            pragma Loop_Invariant
              (for all K in 1 .. CS - 1 => A (K) = A'Loop_Entry (K));

            if A (J) < A (Min_Index) then
               Min_Index := J;
            end if;
         end loop;

         pragma Assert
           (for all K in CS .. A'Last => A (Min_Index) <= A (K));
         pragma Assert (CS = 1 or else A (CS - 1) <= A (Min_Index));

         if Min_Index /= CS then
            Tmp            := A (CS);
            A (CS)         := A (Min_Index);
            A (Min_Index)  := Tmp;
            if Count < Max_N then
               Count := Count + 1;
            end if;
            Writes := Count;
         end if;

         pragma Assert (for all K in CS .. A'Last => A (CS) <= A (K));
         pragma Assert (CS = 1 or else A (CS - 1) <= A (CS));
         pragma Assert (Sorted_Slice (A, 1, CS));
         pragma Assert (Prefix_Leq_Suffix (A, 1, CS, CS + 1, A'Last));
      end;
   end Cycle_Step;

   procedure Sort (A : in out Element_Array) is
      W     : Natural;
      Total : Natural := 0;
   begin
      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, 1, 0));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 0, 1, A'Last));

      for CS in 1 .. A'Last - 1 loop
         Cycle_Step (A, CS, W);
         Total := Total + W;

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, CS));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, CS, CS + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted (A (1 .. CS)));
         pragma Loop_Invariant (Total <= CS * Max_N);
      end loop;

      pragma Assert (Sorted_Slice (A, 1, A'Last - 1));
      pragma Assert
        (Prefix_Leq_Suffix (A, 1, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort;

   procedure Sort_Counting_Writes
     (A      : in out Element_Array;
      Writes : out Natural)
   is
      W : Natural;
   begin
      Writes := 0;

      if A'Length <= 1 then
         return;
      end if;

      pragma Assert (Sorted_Slice (A, 1, 0));
      pragma Assert (Prefix_Leq_Suffix (A, 1, 0, 1, A'Last));

      for CS in 1 .. A'Last - 1 loop
         Cycle_Step (A, CS, W);
         pragma Assert (W <= Max_N);
         pragma Assert (Writes <= (CS - 1) * Max_N);
         Writes := Writes + W;

         pragma Loop_Invariant (In_Bounds (A));
         pragma Loop_Invariant (Sorted_Slice (A, 1, CS));
         pragma Loop_Invariant
           (Prefix_Leq_Suffix (A, 1, CS, CS + 1, A'Last));
         pragma Loop_Invariant (Is_Sorted (A (1 .. CS)));
         pragma Loop_Invariant (Writes <= CS * Max_N);
      end loop;

      pragma Assert (Sorted_Slice (A, 1, A'Last - 1));
      pragma Assert
        (Prefix_Leq_Suffix (A, 1, A'Last - 1, A'Last, A'Last));
      pragma Assert (Is_Sorted (A));
   end Sort_Counting_Writes;

end Cycle_Sort;
