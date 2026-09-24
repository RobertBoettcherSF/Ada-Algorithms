--  Sorted_List body — SPARK Level 4 array-backed ordered multiset with
--  inline binary search for insertion point and membership. Do not `with`
--  Binary_Search. Loop invariants track Lower_Bound partitions and the
--  shift that preserves Is_Sorted_Rep / Type_Invariant.

package body Sorted_List
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Ghost lemmas: adjacent sortedness ⇒ extremum / miss properties
   ---------------------------------------------------------------------------

   --  Data (1) is ≤ every live element when the live prefix is sorted.
   procedure Lemma_First_Is_Min (Data : Store; Len : Index)
     with
       Ghost  => True,
       Global => null,
       Pre    => Len >= 1 and then Is_Sorted_Rep (Data, Len),
       Post   => (for all K in 1 .. Len => Data (1) <= Data (K))
   is
   begin
      for K in 2 .. Len loop
         pragma Loop_Invariant
           (for all J in 1 .. K - 1 => Data (1) <= Data (J));
         pragma Assert (Data (K - 1) <= Data (K));
         pragma Assert (Data (1) <= Data (K - 1));
         pragma Assert (Data (1) <= Data (K));
      end loop;
   end Lemma_First_Is_Min;

   --  Data (Len) is ≥ every live element when the live prefix is sorted.
   procedure Lemma_Last_Is_Max (Data : Store; Len : Index)
     with
       Ghost  => True,
       Global => null,
       Pre    => Len >= 1 and then Is_Sorted_Rep (Data, Len),
       Post   => (for all K in 1 .. Len => Data (K) <= Data (Len))
   is
   begin
      for K in reverse 1 .. Len - 1 loop
         pragma Loop_Invariant
           (for all J in K + 1 .. Len => Data (J) <= Data (Len));
         pragma Assert (Data (K) <= Data (K + 1));
         pragma Assert (Data (K + 1) <= Data (Len));
         pragma Assert (Data (K) <= Data (Len));
      end loop;
   end Lemma_Last_Is_Max;

   --  From Lower_Bound miss (Pos past end, or Data (Pos) > X) and adjacent
   --  sortedness, no live element equals X.
   procedure Lemma_Miss_No_Equal
     (Data : Store; Len : Index; X : Integer; Pos : Ext_Index)
     with
       Ghost  => True,
       Global => null,
       Pre    =>
         Len <= Max_N
         and then Is_Sorted_Rep (Data, Len)
         and then Pos in 1 .. Len + 1
         and then (for all K in 1 .. Pos - 1 => Data (K) < X)
         and then (for all K in Pos .. Len => Data (K) >= X)
         and then (Pos > Len or else Data (Pos) /= X),
       Post   => (for all K in 1 .. Len => Data (K) /= X)
   is
   begin
      if Pos <= Len then
         pragma Assert (Data (Pos) >= X and then Data (Pos) /= X);
         pragma Assert (Data (Pos) > X);
         for K in Pos .. Len loop
            pragma Loop_Invariant
              (for all J in Pos .. K => Data (J) > X);
            if K < Len then
               pragma Assert (Data (K) <= Data (K + 1));
               pragma Assert (Data (K) > X);
               pragma Assert (Data (K + 1) > X);
            end if;
         end loop;
         pragma Assert (for all K in Pos .. Len => Data (K) > X);
      end if;
      pragma Assert (for all K in 1 .. Pos - 1 => Data (K) < X);
      pragma Assert (for all K in 1 .. Len => Data (K) /= X);
   end Lemma_Miss_No_Equal;

   ---------------------------------------------------------------------------
   -- Inline binary search helpers (no sibling package dependency)
   ---------------------------------------------------------------------------

   --  Leftmost index I in 1 .. L.Len with L.Data (I) >= X, or L.Len + 1
   --  if every element is < X. Overflow-safe midpoint.
   function Lower_Bound (L : List; X : Integer) return Ext_Index
     with
       Global => null,
       Pre    => L.Len <= Max_N and then Is_Sorted_Rep (L.Data, L.Len),
       Post   =>
         Lower_Bound'Result in 1 .. L.Len + 1
         and then (for all K in 1 .. Lower_Bound'Result - 1 =>
                     L.Data (K) < X)
         and then (for all K in Lower_Bound'Result .. L.Len =>
                     L.Data (K) >= X)
   is
      Lo  : Ext_Index := 1;
      Hi  : Ext_Index := L.Len + 1;
      Mid : Ext_Index;
   begin
      --  Half-open [Lo, Hi). While form makes Lo = Hi immediate on exit.
      while Lo < Hi loop
         pragma Loop_Invariant (Lo >= 1);
         pragma Loop_Invariant (Hi <= L.Len + 1);
         pragma Loop_Invariant (Lo <= Hi);
         pragma Loop_Invariant
           (for all K in 1 .. Lo - 1 => L.Data (K) < X);
         pragma Loop_Invariant
           (for all K in Hi .. L.Len => L.Data (K) >= X);
         pragma Loop_Variant (Decreases => Hi - Lo);

         Mid := Lo + (Hi - Lo) / 2;
         pragma Assert (Mid in Lo .. Hi - 1);
         pragma Assert (Mid in 1 .. L.Len);

         if L.Data (Mid) < X then
            Lo := Mid + 1;
         else
            Hi := Mid;
         end if;
      end loop;

      pragma Assert (Lo = Hi);
      pragma Assert (for all K in 1 .. Lo - 1 => L.Data (K) < X);
      pragma Assert (for all K in Lo .. L.Len => L.Data (K) >= X);
      return Lo;
   end Lower_Bound;

   --  Leftmost index of an equal key, or 0 if absent.
   function Find_First_Equal (L : List; X : Integer) return Index
     with
       Global => null,
       Pre    => L.Len <= Max_N and then Is_Sorted_Rep (L.Data, L.Len),
       Post   =>
         Find_First_Equal'Result <= L.Len
         and then
           (if Find_First_Equal'Result > 0 then
              L.Data (Find_First_Equal'Result) = X
              and then (for all K in 1 .. Find_First_Equal'Result - 1 =>
                          L.Data (K) < X)
            else
              (for all K in 1 .. L.Len => L.Data (K) /= X))
   is
      Pos : constant Ext_Index := Lower_Bound (L, X);
   begin
      if Pos <= L.Len and then L.Data (Pos) = X then
         return Pos;
      end if;

      Lemma_Miss_No_Equal (L.Data, L.Len, X, Pos);
      return 0;
   end Find_First_Equal;

   ---------------------------------------------------------------------------
   -- Construction / queries
   ---------------------------------------------------------------------------

   function Empty return List is
      L : List;
   begin
      L.Len := 0;
      return L;
   end Empty;

   procedure Clear (L : in out List) is
   begin
      L.Len := 0;
   end Clear;

   ---------------------------------------------------------------------------
   -- Mutation
   ---------------------------------------------------------------------------

   procedure Insert (L : in out List; X : Integer; Success : out Boolean) is
      Pos : Ext_Index;
   begin
      if L.Len = Max_N then
         Success := False;
         return;
      end if;

      Pos := Lower_Bound (L, X);
      pragma Assert (Pos in 1 .. L.Len + 1);
      pragma Assert (for all K in 1 .. Pos - 1 => L.Data (K) < X);
      pragma Assert (for all K in Pos .. L.Len => L.Data (K) >= X);

      --  Shift right tail [Pos .. Len] one slot toward the end.
      --  Invariant at the start of iteration I: slots I+1 .. Len have
      --  already been copied to I+2 .. Len+1 (vacuous when I = Len).
      for I in reverse Pos .. L.Len loop
         pragma Loop_Invariant (I in Pos - 1 .. L.Len);
         pragma Loop_Invariant (L.Len < Max_N);
         pragma Loop_Invariant (Pos in 1 .. L.Len + 1);
         pragma Loop_Invariant
           (for all K in 1 .. Pos - 1 => L.Data (K) = L.Data'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in 1 .. Pos - 1 => L.Data (K) < X);
         pragma Loop_Invariant
           (for all K in I + 1 .. L.Len =>
              L.Data (K + 1) = L.Data'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in I + 1 .. L.Len => L.Data (K + 1) >= X);
         pragma Loop_Invariant
           (for all K in Pos .. I =>
              L.Data (K) = L.Data'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Pos .. I => L.Data (K) >= X);
         pragma Loop_Invariant
           (Is_Sorted_Rep (L.Data, L.Len));

         L.Data (I + 1) := L.Data (I);
      end loop;

      pragma Assert (for all K in 1 .. Pos - 1 => L.Data (K) < X);
      pragma Assert
        (for all K in Pos .. L.Len => L.Data (K + 1) >= X);
      pragma Assert (Pos = 1 or else L.Data (Pos - 1) < X);
      pragma Assert
        (Pos > L.Len or else L.Data (Pos + 1) >= X);

      L.Data (Pos) := X;
      L.Len := L.Len + 1;

      pragma Assert (Pos = 1 or else L.Data (Pos - 1) <= L.Data (Pos));
      pragma Assert
        (Pos = L.Len or else L.Data (Pos) <= L.Data (Pos + 1));
      pragma Assert (Is_Sorted_Rep (L.Data, L.Len));

      Success := True;
   end Insert;

   procedure Delete (L : in out List; X : Integer; Success : out Boolean) is
      Pos : Index;
   begin
      Pos := Find_First_Equal (L, X);
      if Pos = 0 then
         Success := False;
         return;
      end if;

      pragma Assert (Pos in 1 .. L.Len);
      pragma Assert (L.Data (Pos) = X);
      pragma Assert (L.Len >= 1);

      for I in Pos + 1 .. L.Len loop
         pragma Loop_Invariant (I in Pos + 1 .. L.Len + 1);
         pragma Loop_Invariant (Pos in 1 .. L.Len);
         pragma Loop_Invariant (L.Len >= 1);
         pragma Loop_Invariant
           (for all K in 1 .. Pos - 1 =>
              L.Data (K) = L.Data'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Pos .. I - 2 =>
              L.Data (K) = L.Data'Loop_Entry (K + 1));
         pragma Loop_Invariant
           (for all K in I .. L.Len =>
              L.Data (K) = L.Data'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in 1 .. I - 2 => L.Data (K) <= L.Data (K + 1));
         pragma Loop_Invariant
           (for all K in I .. L.Len - 1 =>
              L.Data (K) <= L.Data (K + 1));
         pragma Loop_Invariant
           (if I > Pos + 1 then L.Data (I - 2) <= L.Data'Loop_Entry (I));

         L.Data (I - 1) := L.Data (I);
      end loop;

      L.Len := L.Len - 1;
      pragma Assert (Is_Sorted_Rep (L.Data, L.Len));
      Success := True;
   end Delete;

   procedure Delete_First (L : in out List; X : Integer) is
      Ok : Boolean;
   begin
      Delete (L, X, Ok);
      pragma Assert (Ok);
   end Delete_First;

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Contains (L : List; X : Integer) return Boolean is
   begin
      return Find_First_Equal (L, X) /= 0;
   end Contains;

   function Find (L : List; X : Integer) return Index is
   begin
      return Find_First_Equal (L, X);
   end Find;

   ---------------------------------------------------------------------------
   -- Ends / indexed access
   ---------------------------------------------------------------------------

   function Min (L : List) return Integer is
   begin
      Lemma_First_Is_Min (L.Data, L.Len);
      return L.Data (1);
   end Min;

   function Max (L : List) return Integer is
   begin
      Lemma_Last_Is_Max (L.Data, L.Len);
      return L.Data (L.Len);
   end Max;

end Sorted_List;
