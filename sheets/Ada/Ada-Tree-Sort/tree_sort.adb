--  Tree_Sort body — fixed node-pool BST, iterative insert and in-order.

pragma Ada_2022;

package body Tree_Sort
  with SPARK_Mode => Off
is

   --  0 = null child / empty tree. Live nodes occupy 1 .. Used (<= Max_N).
   subtype Node_Index is Natural range 0 .. Max_N;
   None : constant Node_Index := 0;

   type BST_Node is record
      Value : Integer     := 0;
      Left  : Node_Index  := None;
      Right : Node_Index  := None;
   end record;

   type Node_Pool is array (1 .. Max_N) of BST_Node;

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
         Pool : Node_Pool;
         Used : Natural := 0;
         Root : Node_Index := None;

         function New_Node (V : Integer) return Node_Index is
            I : Node_Index;
         begin
            Used := Used + 1;
            I := Used;
            Pool (I).Value := V;
            Pool (I).Left  := None;
            Pool (I).Right := None;
            return I;
         end New_Node;

         --  Iterative insert. V < node.Value → left; otherwise → right
         --  (equals ride the right spine → in-order is stable).
         procedure Insert (V : Integer) is
            Cur : Node_Index;
         begin
            if Root = None then
               Root := New_Node (V);
               return;
            end if;

            Cur := Root;
            loop
               if V < Pool (Cur).Value then
                  if Pool (Cur).Left = None then
                     Pool (Cur).Left := New_Node (V);
                     return;
                  else
                     Cur := Pool (Cur).Left;
                  end if;
               else
                  if Pool (Cur).Right = None then
                     Pool (Cur).Right := New_Node (V);
                     return;
                  else
                     Cur := Pool (Cur).Right;
                  end if;
               end if;
            end loop;
         end Insert;

         --  Iterative in-order dump into A. Explicit stack of size N so a
         --  left-spine (reverse-sorted input) cannot overflow the call
         --  stack.
         procedure Inorder_Write is
            Stack : array (1 .. N) of Node_Index;
            Top   : Natural := 0;
            Cur   : Node_Index := Root;
            Out_I : Natural := A'First;
         begin
            loop
               while Cur /= None loop
                  Top := Top + 1;
                  Stack (Top) := Cur;
                  Cur := Pool (Cur).Left;
               end loop;

               exit when Top = 0;

               Cur := Stack (Top);
               Top := Top - 1;
               A (Out_I) := Pool (Cur).Value;
               Out_I := Out_I + 1;
               Cur := Pool (Cur).Right;
            end loop;
         end Inorder_Write;

      begin
         for I in A'Range loop
            Insert (A (I));
         end loop;
         Inorder_Write;
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

end Tree_Sort;
