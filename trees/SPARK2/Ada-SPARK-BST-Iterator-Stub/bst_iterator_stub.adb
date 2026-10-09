pragma SPARK_Mode (On);
pragma Ada_2022;
package body BST_Iterator_Stub is
   function Empty return Tree is
     (Nodes => [others => (Val => 0, Left => 0, Right => 0, Parent => 0)], Size => 0);

   function Size (T : Tree) return Count is (T.Size);

   procedure Insert (T : in out Tree; V : Value) is
      New_Node : constant Node := T.Size + 1;
      Cur      : Node := 1;
   begin
      T.Nodes (New_Node) := (Val => V, Left => 0, Right => 0, Parent => 0);
      if T.Size > 0 then
         loop
            pragma Loop_Invariant (Cur <= T.Size);
            pragma Loop_Invariant (T.Nodes (New_Node) = (Val => V, Left => 0, Right => 0, Parent => 0));
            pragma Loop_Invariant (T.Nodes'Loop_Entry = T.Nodes);
            pragma Loop_Variant (Increases => Cur);
            if V < T.Nodes (Cur).Val then
               exit when T.Nodes (Cur).Left = 0;
               Cur := T.Nodes (Cur).Left;
            else
               exit when T.Nodes (Cur).Right = 0;
               Cur := T.Nodes (Cur).Right;
            end if;
         end loop;
         if V < T.Nodes (Cur).Val then
            T.Nodes (Cur).Left := New_Node;
         else
            T.Nodes (Cur).Right := New_Node;
         end if;
         T.Nodes (New_Node).Parent := Cur;
      end if;
      T.Size := New_Node;
   end Insert;

   --  The leftmost node of the subtree rooted at N.
   function Leftmost (T : Tree; N : Node) return Node
     with Pre => Valid (T) and then N <= T.Size, Post => Leftmost'Result in N .. T.Size
   is
      Cur : Node := N;
   begin
      while T.Nodes (Cur).Left /= 0 loop
         pragma Loop_Invariant (Cur in N .. T.Size);
         pragma Loop_Variant (Increases => Cur);
         Cur := T.Nodes (Cur).Left;
      end loop;
      return Cur;
   end Leftmost;

   --  The in-order successor of N, 0 when N is the last node.
   function Successor (T : Tree; N : Node) return Node_Ref
     with Pre => Valid (T) and then N <= T.Size, Post => Successor'Result <= T.Size
   is
      Cur : Node := N;
      Up  : Node_Ref;
   begin
      if T.Nodes (N).Right /= 0 then
         return Leftmost (T, T.Nodes (N).Right);
      end if;
      loop
         pragma Loop_Invariant (Cur <= N);
         pragma Loop_Variant (Decreases => Cur);
         Up := T.Nodes (Cur).Parent;
         if Up = 0 then
            return 0;
         elsif T.Nodes (Up).Left = Cur then
            return Up;
         end if;
         Cur := Up;
      end loop;
   end Successor;

   function Create (T : Tree) return Iterator is
     (T => T, Current => (if T.Size = 0 then 0 else Leftmost (T, 1)));

   function Has_Next (It : Iterator) return Boolean is (It.Current /= 0);

   procedure Next (It : in out Iterator; Result : out Value) is
   begin
      Result := It.T.Nodes (It.Current).Val;
      It.Current := Successor (It.T, It.Current);
   end Next;
end BST_Iterator_Stub;
