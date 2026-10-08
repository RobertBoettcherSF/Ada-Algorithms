pragma SPARK_Mode (On);

package body Insert_Into_A_Binary_Search_Tree is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0), Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   procedure Insert (T : in out Tree; Root : in out Index; Node : Node_Index; V : Value) is
      Current : Node_Index;
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := 0;
      T.Rights (Node) := 0;
      T.Used (Node) := True;
      if Root = 0 then
         Root := Node;
         return;
      end if;
      --  Walk down from the root. The path stays among the old nodes
      --  (children of used nodes are used, Node was not), and it ends
      --  because the nodes reachable from Root form a tree (Well_Formed).
      Current := Root;
      loop
         pragma Loop_Invariant (Current /= Node and then T'Loop_Entry.Used (Current));
         pragma Loop_Invariant (T = T'Loop_Entry);
         if V < T.Values (Current) then
            if T.Lefts (Current) = 0 then
               T.Lefts (Current) := Node;
               return;
            end if;
            Current := T.Lefts (Current);
         else
            if T.Rights (Current) = 0 then
               T.Rights (Current) := Node;
               return;
            end if;
            Current := T.Rights (Current);
         end if;
      end loop;
   end Insert;
end Insert_Into_A_Binary_Search_Tree;
