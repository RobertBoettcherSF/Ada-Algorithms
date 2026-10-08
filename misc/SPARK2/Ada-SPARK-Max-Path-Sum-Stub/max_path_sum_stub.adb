pragma SPARK_Mode (On);

package body Max_Path_Sum_Stub is
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

   function Max_Path_Sum (T : Tree; Root : Index) return Sum is
      Nodes : array (Positive range 1 .. 31) of Index := (others => 0);
      Sums : array (Positive range 1 .. 31) of Sum := (others => 0);
      Top : Natural range 0 .. 31;
      Best : Sum := Sum'First;
   begin
      if Root = 0 or else not T.Used (Root) then return 0; end if;
      Top := 1; Nodes (Top) := Root; Sums (Top) := 0;
      for Step in 1 .. 31 loop
         if Top = 0 then null; else
            declare N : constant Index := Nodes (Top); P : constant Sum := Sums (Top); Total : Sum; begin
               Top := Top - 1;
               if P >= Sum'First - Sum (T.Values (N)) and then
                 P <= Sum'Last - Sum (T.Values (N)) then
                  Total := P + Sum (T.Values (N));
               else
                  Total := 0;
               end if;
               if T.Lefts (N) = 0 and then T.Rights (N) = 0 then
                  if Total > Best then Best := Total; end if;
               else
                  if T.Lefts (N) /= 0 and then Top < 31 then Top := Top + 1; Nodes (Top) := T.Lefts (N); Sums (Top) := Total; end if;
                  if T.Rights (N) /= 0 and then Top < 31 then Top := Top + 1; Nodes (Top) := T.Rights (N); Sums (Top) := Total; end if;
               end if;
            end;
         end if;
      end loop;
      return Best;
   end Max_Path_Sum;
end Max_Path_Sum_Stub;
