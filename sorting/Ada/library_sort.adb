--  Library_Sort body — gapped insertion sort with ε = 1 (Cap = 2·n).

pragma Ada_2022;

package body Library_Sort
  with SPARK_Mode => Off
is

   type Slot is record
      Occupied : Boolean := False;
      Value    : Integer := 0;
   end record;

   type Working_Array is array (Positive range <>) of Slot;

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   function Capacity_For (N : Positive) return Positive is
      Extra : constant Natural :=
        (Epsilon_Numerator * N) / Epsilon_Denominator;
   begin
      return N + Extra;
   end Capacity_For;

   --  Pack occupied values densely into Dense(1 .. Count), clear W.
   procedure Gather
     (W     : in out Working_Array;
      Dense : out Element_Array;
      Count : out Natural)
   is
      K : Natural := 0;
   begin
      for I in W'Range loop
         if W (I).Occupied then
            K := K + 1;
            Dense (Dense'First + K - 1) := W (I).Value;
         end if;
         W (I) := (Occupied => False, Value => 0);
      end loop;
      Count := K;
   end Gather;

   --  Place Count dense values evenly into W(1 .. Cap) with gaps.
   --  Step = Cap / Count (>= 1). Element k goes at 1 + (k-1)*Step.
   procedure Spread
     (W     : in out Working_Array;
      Dense : Element_Array;
      Count : Natural;
      Cap   : Positive)
   is
      Step : Positive;
      Pos  : Positive;
   begin
      for I in W'First .. Cap loop
         W (I) := (Occupied => False, Value => 0);
      end loop;

      if Count = 0 then
         return;
      end if;

      Step := Cap / Count;

      for K in 1 .. Count loop
         Pos := 1 + (K - 1) * Step;
         if Pos > Cap then
            Pos := Cap;
         end if;
         while Pos <= Cap and then W (Pos).Occupied loop
            Pos := Pos + 1;
         end loop;
         if Pos <= Cap then
            W (Pos) :=
              (Occupied => True,
               Value    => Dense (Dense'First + K - 1));
         end if;
      end loop;
   end Spread;

   procedure Rebalance
     (W     : in out Working_Array;
      Cap   : Positive;
      Count : Natural)
   is
      Dense : Element_Array (1 .. Count);
      Got   : Natural;
   begin
      Gather (W, Dense, Got);
      pragma Assert (Got = Count);
      Spread (W, Dense, Count, Cap);
   end Rebalance;

   --  Binary search in W(1 .. Limit) for the insertion index of X.
   --  Gaps at Mid are resolved by scanning right, then left, for an
   --  occupied neighbour (Wikipedia library-sort binary search).
   function Binary_Search_Insert
     (W     : Working_Array;
      Limit : Natural;
      X     : Integer) return Positive
   is
      Lo : Natural := 1;
      Hi : Natural := Limit;
   begin
      if Limit < 1 then
         return 1;
      end if;

      while Lo <= Hi loop
         declare
            Mid     : Natural := Lo + (Hi - Lo) / 2;
            Mid_Val : Integer;
            Has_Val : Boolean := False;
            R       : Natural;
            L       : Natural;
         begin
            if W (Mid).Occupied then
               Mid_Val := W (Mid).Value;
               Has_Val := True;
            else
               R := Mid;
               while R <= Hi and then not W (R).Occupied loop
                  R := R + 1;
               end loop;
               if R <= Hi then
                  Mid     := R;
                  Mid_Val := W (R).Value;
                  Has_Val := True;
               else
                  L := Mid;
                  while L >= Lo and then not W (L).Occupied loop
                     exit when L = Lo;
                     L := L - 1;
                  end loop;
                  if L >= Lo and then W (L).Occupied then
                     Mid     := L;
                     Mid_Val := W (L).Value;
                     Has_Val := True;
                  end if;
               end if;
            end if;

            if not Has_Val then
               return Positive'Max (1, Lo);
            end if;

            if Mid_Val < X then
               Lo := Mid + 1;
            elsif Mid_Val > X then
               Hi := Mid - 1;
            else
               return Mid;
            end if;
         end;
      end loop;

      if Lo < 1 then
         return 1;
      elsif Lo > Limit then
         return Limit + 1;
      else
         return Lo;
      end if;
   end Binary_Search_Insert;

   --  Insert X at Pos: fill a gap, or shift right until a gap.
   --  Returns False if no gap exists (caller rebalances).
   function Try_Insert
     (W   : in out Working_Array;
      Cap : Positive;
      Pos : Positive;
      X   : Integer) return Boolean
   is
      P : Positive := Pos;
      J : Positive;
   begin
      if P > Cap then
         P := Cap;
      end if;

      if not W (P).Occupied then
         W (P) := (Occupied => True, Value => X);
         return True;
      end if;

      J := P;
      while J <= Cap and then W (J).Occupied loop
         J := J + 1;
      end loop;

      if J > Cap then
         J := P;
         while J > 1 and then W (J).Occupied loop
            J := J - 1;
         end loop;
         if not W (J).Occupied then
            for K in J + 1 .. P loop
               W (K - 1) := W (K);
            end loop;
            W (P) := (Occupied => True, Value => X);
            return True;
         end if;
         return False;
      end if;

      for K in reverse P .. J - 1 loop
         W (K + 1) := W (K);
      end loop;
      W (P) := (Occupied => True, Value => X);
      return True;
   end Try_Insert;

   procedure Sort (A : in out Element_Array) is
      N : constant Natural := A'Length;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      declare
         Cap       : constant Positive := Capacity_For (N);
         W         : Working_Array (1 .. Cap);
         Dense_Buf : Element_Array (1 .. N);
         Inserted  : Natural := 0;
         Next_Goal : Natural := 1;
         Src       : Natural;
         X         : Integer;
         Pos       : Positive;
         Ok        : Boolean;
         Got       : Natural;
      begin
         for I in W'Range loop
            W (I) := (Occupied => False, Value => 0);
         end loop;

         W (1) := (Occupied => True, Value => A (A'First));
         Inserted := 1;
         Src := A'First + 1;

         while Inserted < N loop
            if Inserted = Next_Goal and then Inserted < N then
               Rebalance (W, Cap, Inserted);
               if Next_Goal <= Natural'Last / 2 then
                  Next_Goal := Next_Goal * 2;
               else
                  Next_Goal := N;
               end if;
            end if;

            X := A (Src);
            Pos := Binary_Search_Insert (W, Cap, X);

            Ok := Try_Insert (W, Cap, Pos, X);
            if not Ok then
               Rebalance (W, Cap, Inserted);
               Pos := Binary_Search_Insert (W, Cap, X);
               Ok := Try_Insert (W, Cap, Pos, X);
               if not Ok then
                  Gather (W, Dense_Buf, Got);
                  Dense_Buf (Got + 1) := X;
                  Got := Got + 1;
                  Spread (W, Dense_Buf (1 .. Got), Got, Cap);
               end if;
            end if;

            Inserted := Inserted + 1;
            Src := Src + 1;
         end loop;

         declare
            K : Natural := 0;
         begin
            for I in W'Range loop
               if W (I).Occupied then
                  A (A'First + K) := W (I).Value;
                  K := K + 1;
               end if;
            end loop;
         end;
      end;
   end Sort;

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First + 1 .. A'Last loop
         if A (I - 1) > A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

end Library_Sort;
