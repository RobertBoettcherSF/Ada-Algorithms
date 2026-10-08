pragma Ada_2022;
pragma SPARK_Mode (On);

package body Range_Sum_BST is
   function Empty return Tree is
   begin
      return (Values => [others => 0], Lefts => [others => 0],
              Rights => [others => 0], Used => [others => False]);
   end Empty;

   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   function Node_Value (T : Tree; Node : Node_Index) return Value is
   begin
      return T.Values (Node);
   end Node_Value;

   function Left_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Lefts (Node);
   end Left_Child;

   function Right_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Rights (Node);
   end Right_Child;

   --  Pruned search of a binary search tree (left values <= node value <= right values): a left subtree is
   --  entered only when the node value >= Low, a right subtree only when it is <= High. Nodes are first
   --  marked (31 rounds over the 31 slots reach every node of a path; a node reached twice is still
   --  marked once, so cycles and shared nodes cannot repeat a value), then the marked in-range values are
   --  added: at most 31 values of at most 1000 in magnitude, so Total provably fits Sum.
   function Range_Sum (T : Tree; Root : Index; Low, High : Value) return Sum is
      Marked : array (Node_Index) of Boolean := [others => False];
      Total : Sum := 0;
   begin
      if Root = 0 or else not T.Used (Root) then
         return 0;
      end if;
      Marked (Root) := True;
      for Round in 1 .. 30 loop
         for K in Node_Index loop
            if Marked (K) then
               if T.Values (K) >= Low and then T.Lefts (K) /= 0 and then T.Used (T.Lefts (K)) then
                  Marked (T.Lefts (K)) := True;
               end if;
               if T.Values (K) <= High and then T.Rights (K) /= 0 and then T.Used (T.Rights (K)) then
                  Marked (T.Rights (K)) := True;
               end if;
            end if;
         end loop;
      end loop;
      for K in Node_Index loop
         if Marked (K) and then T.Values (K) in Low .. High then
            Total := Total + T.Values (K);
         end if;
         pragma Loop_Invariant (Total in -1000 * K .. 1000 * K);
      end loop;
      return Total;
   end Range_Sum;
end Range_Sum_BST;
