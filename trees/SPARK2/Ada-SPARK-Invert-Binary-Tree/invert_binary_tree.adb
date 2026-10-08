pragma SPARK_Mode (On);

package body Invert_Binary_Tree is
   function Empty return Tree is
   begin
      return
        (Values => (others => 0),
         Lefts  => (others => 0),
         Rights => (others => 0),
         Used   => (others => False));
   end Empty;

   procedure Set_Node
     (T : in out Tree;
      Node : Node_Index;
      V : Value;
      Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   function Left_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Lefts (Node);
   end Left_Child;

   function Right_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Rights (Node);
   end Right_Child;

   procedure Invert (T : in out Tree) is
      Temp : Index;
   begin
      for N in Node_Index loop
         if T.Used (N) then
            Temp := T.Lefts (N);
            T.Lefts (N) := T.Rights (N);
            T.Rights (N) := Temp;
         end if;
      end loop;
   end Invert;
end Invert_Binary_Tree;
