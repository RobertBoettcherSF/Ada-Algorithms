pragma SPARK_Mode (On);

package body Binary_Tree_Postorder is
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


   subtype Stack_Position is Natural range 0 .. 256;
   type Node_Stack is array (Positive range 1 .. 256) of Index;
   type Flag_Stack is array (Positive range 1 .. 256) of Boolean;

   function Postorder_Sum (T : Tree; Root : Index) return Sum is
      Nodes : Node_Stack := (others => 0); Flags : Flag_Stack := (others => False);
      Top : Stack_Position; Total : Sum := 0;
   begin
      if Root = 0 or else not T.Used (Root) then return 0; end if;
      Top := 1; Nodes (Top) := Root;
      for Step in 1 .. 256 loop
         pragma Loop_Invariant (Top in Stack_Position);
         if Top > 0 then
            declare N : constant Index := Nodes (Top);
            begin
               if Flags (Top) then
                  Top := Top - 1; if T.Values (N) > 0 then
                        if Total <= Sum'Last - T.Values (N) then
                           Total := Total + T.Values (N);
                        end if;
                     elsif Total >= Sum'First - T.Values (N) then
                        Total := Total + T.Values (N);
                     end if;
               else
                  Flags (Top) := True;
                  if T.Rights (N) /= 0 and then Top < Stack_Position'Last then
                     Top := Top + 1; Nodes (Top) := T.Rights (N); Flags (Top) := False;
                  end if;
                  if T.Lefts (N) /= 0 and then Top < Stack_Position'Last then
                     Top := Top + 1; Nodes (Top) := T.Lefts (N); Flags (Top) := False;
                  end if;
               end if;
            end;
         end if;
      end loop;
      return Total;
   end Postorder_Sum;
end Binary_Tree_Postorder;
