--  Patience_Sorting body — fixed node-pool piles, binary-search deal,
--  linear min-top merge.

pragma Ada_2022;

package body Patience_Sorting
  with SPARK_Mode => Off
is

   --  0 = null / empty stack link. Live nodes occupy 1 .. Used (<= Max_N).
   subtype Node_Index is Natural range 0 .. Max_N;
   None : constant Node_Index := 0;

   type Stack_Node is record
      Value : Integer     := 0;
      Below : Node_Index  := None;  -- toward older cards (bottom)
   end record;

   type Node_Pool is array (1 .. Max_N) of Stack_Node;

   --  Active pile tops (left to right). At most Max_N piles.
   type Top_Array is array (1 .. Max_N) of Node_Index;

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   procedure Sort (A : in out Element_Array) is
      N : constant Natural := A'Length;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      declare
         Pool      : Node_Pool;
         Used      : Natural := 0;
         Pile_Tops : Top_Array := [others => None];
         Num_Piles : Natural := 0;

         function New_Node (V : Integer; Below : Node_Index) return Node_Index
         is
            I : Node_Index;
         begin
            Used := Used + 1;
            I := Used;
            Pool (I).Value := V;
            Pool (I).Below := Below;
            return I;
         end New_Node;

         --  Leftmost pile whose top >= X, or Num_Piles + 1 if none.
         --  Pile tops are strictly increasing, so binary search applies.
         function Find_Pile (X : Integer) return Positive is
            Lo  : Natural := 1;
            Hi  : Natural := Num_Piles;
            Mid : Natural;
         begin
            --  Invariant: answer is in Lo .. Hi+1; seek first top >= X.
            while Lo <= Hi loop
               Mid := Lo + (Hi - Lo) / 2;
               if Pool (Pile_Tops (Mid)).Value >= X then
                  Hi := Mid - 1;
               else
                  Lo := Mid + 1;
               end if;
            end loop;
            return Lo;
         end Find_Pile;

         procedure Deal (X : Integer) is
            J : Positive;
         begin
            if Num_Piles = 0 then
               Num_Piles := 1;
               Pile_Tops (1) := New_Node (X, None);
               return;
            end if;

            J := Find_Pile (X);
            if J <= Num_Piles then
               --  Push onto existing pile J (new top <= old top).
               Pile_Tops (J) := New_Node (X, Pile_Tops (J));
            else
               --  New pile to the right.
               Num_Piles := Num_Piles + 1;
               Pile_Tops (Num_Piles) := New_Node (X, None);
            end if;
         end Deal;

         --  K-way merge: repeatedly pop the pile with the smallest top.
         procedure Merge_Into_A is
            Out_I    : Natural := A'First;
            Best     : Positive;
            Best_Val : Integer;
            Node     : Node_Index;
         begin
            while Num_Piles > 0 loop
               Best := 1;
               Best_Val := Pool (Pile_Tops (1)).Value;
               for P in 2 .. Num_Piles loop
                  if Pool (Pile_Tops (P)).Value < Best_Val then
                     Best := P;
                     Best_Val := Pool (Pile_Tops (P)).Value;
                  end if;
               end loop;

               Node := Pile_Tops (Best);
               A (Out_I) := Pool (Node).Value;
               Out_I := Out_I + 1;

               --  Pop; if pile empties, swap with last active pile.
               Pile_Tops (Best) := Pool (Node).Below;
               if Pile_Tops (Best) = None then
                  Pile_Tops (Best) := Pile_Tops (Num_Piles);
                  Num_Piles := Num_Piles - 1;
               end if;
            end loop;
         end Merge_Into_A;

      begin
         for I in A'Range loop
            Deal (A (I));
         end loop;
         Merge_Into_A;
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

end Patience_Sorting;
