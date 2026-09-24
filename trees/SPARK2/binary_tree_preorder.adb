pragma SPARK_Mode (On);
package body Binary_Tree_Preorder is
   function Empty return Tree is begin return (Values => (others => 0), Lefts => (others => 0), Rights => (others => 0), Used => (others => False)); end Empty;
   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value; Left, Right : Index) is
   begin T.Values (Node) := V; T.Lefts (Node) := Left; T.Rights (Node) := Right; T.Used (Node) := True; end Set_Node;
   function Preorder_Sum (T : Tree; Root : Index) return Long_Long_Integer is
      Stack : array (Index) of Index := (others => 0); Top : Index; Current : Index := Root; Total : Long_Long_Integer := 0;
   begin
      if Current = 0 then return 0; end if; Top := 1; Stack (Top) := Current;
      for Step in 1 .. 16 loop
         pragma Loop_Invariant
           (Total in Long_Long_Integer (-100 * (Step - 1)) .. Long_Long_Integer (100 * (Step - 1)));
         exit when Top = 0; Current := Stack (Top); Top := Top - 1;
         if T.Used (Current) then Total := Total + Long_Long_Integer (T.Values (Current));
            if T.Rights (Current) /= 0 and then Top < Index'Last then Top := Top + 1; Stack (Top) := T.Rights (Current); end if;
            if T.Lefts (Current) /= 0 and then Top < Index'Last then Top := Top + 1; Stack (Top) := T.Lefts (Current); end if;
         end if;
      end loop; return Total;
   end Preorder_Sum;
end Binary_Tree_Preorder;
