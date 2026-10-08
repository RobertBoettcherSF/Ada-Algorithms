pragma SPARK_Mode (On);
package body Binary_Tree_Inorder is
   function Empty return Tree is begin return (Values => (others => 0), Lefts => (others => 0), Rights => (others => 0), Used => (others => False)); end Empty;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True; end Set_Node;
   function Inorder_Sum (T : Tree; Root : Index) return Long_Long_Integer is
      Stack : array (Index) of Index := (others => 0); Top : Index := 0; Current : Index := Root; Total : Long_Long_Integer := 0;
   begin
      for Step in 1 .. 32 loop
         pragma Loop_Invariant
           (Total in Long_Long_Integer (-100 * (Step - 1)) .. Long_Long_Integer (100 * (Step - 1)));
         if Current /= 0 and then T.Used (Current) and then Top < Index'Last then Top := Top + 1; Stack (Top) := Current; Current := T.Lefts (Current);
         elsif Top /= 0 then Current := Stack (Top); Top := Top - 1; Total := Total + Long_Long_Integer (T.Values (Current)); Current := T.Rights (Current);
         else exit; end if;
      end loop; return Total;
   end Inorder_Sum;
end Binary_Tree_Inorder;
