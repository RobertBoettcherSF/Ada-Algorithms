pragma SPARK_Mode (On);

package body Lowest_Common_Ancestor_Of_BST is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0),
              Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Set_Node
     (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin
      T.Values (Node) := V;
      T.Lefts (Node) := Left;
      T.Rights (Node) := Right;
      T.Used (Node) := True;
   end Set_Node;

   function Value_At (T : Tree; Node : Node_Index) return Value is
   begin
      return T.Values (Node);
   end Value_At;

   function Left_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Lefts (Node);
   end Left_Child;

   function Right_Child (T : Tree; Node : Node_Index) return Index is
   begin
      return T.Rights (Node);
   end Right_Child;


   function Lowest_Common_Ancestor
     (T : Tree; Root : Index; P, Q : Value) return Index is
      Current : Index := Root;
      Answer : Index := 0;
   begin
      for Step in 1 .. 16 loop
         pragma Loop_Invariant (Current in Index);
         if Current = 0 or else not T.Used (Current) then
            exit;
         elsif P < T.Values (Current) and then Q < T.Values (Current) then
            Current := T.Lefts (Current);
         elsif P > T.Values (Current) and then Q > T.Values (Current) then
            Current := T.Rights (Current);
         else
            Answer := Current; exit;
         end if;
      end loop;
      return Answer;
   end Lowest_Common_Ancestor;
end Lowest_Common_Ancestor_Of_BST;
