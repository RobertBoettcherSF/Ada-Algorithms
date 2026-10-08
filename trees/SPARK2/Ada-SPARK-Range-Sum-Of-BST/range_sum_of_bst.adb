pragma SPARK_Mode (On);

package body Range_Sum_Of_BST is
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

   function Range_Sum (T : Tree; Root : Index; Low, High : Value) return Long_Long_Integer is
      Stack : array (Node_Index) of Index := (others => 0);
      Top : Natural range 0 .. 16;
      Current : Index;
      Total : Long_Long_Integer := 0;
   begin
      if Root = 0 or else not T.Used (Root) then
         return 0;
      end if;
      Top := 1;
      Stack (Top) := Root;
      for Step in 1 .. 16 loop
         pragma Loop_Invariant
           (Total in Long_Long_Integer (-100 * (Step - 1)) .. Long_Long_Integer (100 * (Step - 1)));
         exit when Top = 0;
         Current := Stack (Top);
         Top := Top - 1;
         if Current /= 0 and then T.Used (Current) then
            if T.Values (Current) >= Low and then T.Values (Current) <= High then
               Total := Total + Long_Long_Integer (T.Values (Current));
            end if;
            if T.Lefts (Current) /= 0 and then Top < 16 then
               Top := Top + 1; Stack (Top) := T.Lefts (Current);
            end if;
            if T.Rights (Current) /= 0 and then Top < 16 then
               Top := Top + 1; Stack (Top) := T.Rights (Current);
            end if;
         end if;
      end loop;
      return Total;
   end Range_Sum;
end Range_Sum_Of_BST;
