pragma SPARK_Mode (On);

package body Range_Sum_BST is
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

   function Range_Sum (T : Tree; Root : Index; Low, High : Value) return Sum is
      Stack : array (Positive range 1 .. 31) of Index := (others => 0);
      Top : Natural range 0 .. 31 := 0;
      Current : Index := Root;
      Total : Sum := 0;
   begin
      for Step in 1 .. 31 loop
         for Push in 1 .. 31 loop
            if Current = 0 or else not T.Used (Current) or else Top = 31 then
               exit;
            end if;
            Top := Top + 1; Stack (Top) := Current;
            if T.Values (Current) < Low then Current := T.Rights (Current);
            elsif T.Values (Current) > High then Current := T.Lefts (Current);
            else exit; end if;
         end loop;
         if Top = 0 then exit; end if;
         Current := Stack (Top); Top := Top - 1;
         if T.Values (Current) >= Low and then T.Values (Current) <= High then
            if Total >= Sum'First - Sum (T.Values (Current)) and then
              Total <= Sum'Last - Sum (T.Values (Current)) then
               Total := Total + Sum (T.Values (Current));
            end if;
            Current := T.Rights (Current);
         else
            Current := 0;
         end if;
      end loop;
      return Total;
   end Range_Sum;
end Range_Sum_BST;
