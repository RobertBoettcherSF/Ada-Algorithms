pragma SPARK_Mode (On);

package body Path_Sum is
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

   subtype Stack_Position is Natural range 0 .. 256;
   type Node_Stack is array (Positive range 1 .. 256) of Index;
   subtype Accumulator is Integer range -4000 .. 4000;
   type Sum_Stack is array (Positive range 1 .. 256) of Accumulator;

   function Subtract_Value (Left : Accumulator; Right : Value) return Accumulator is
      R : constant Accumulator := Accumulator (Right);
   begin
      if Left > Accumulator'Last + R then
         return Accumulator'Last;
      elsif Left < Accumulator'First + R then
         return Accumulator'First;
      else
         return Left - R;
      end if;
   end Subtract_Value;

   function Has_Path_Sum (T : Tree; Root : Index; Wanted : Target) return Boolean is
      Nodes : Node_Stack := (others => 0);
      Sums : Sum_Stack := (others => 0);
      Top : Stack_Position;
   begin
      if Root = 0 or else not T.Used (Root) then
         return False;
      end if;
      Top := 1;
      Nodes (Top) := Root;
      Sums (Top) := Accumulator (Wanted);
      for Step in 1 .. 256 loop
         pragma Loop_Invariant (Top in Stack_Position);
         if Top = 0 then
            null;
         else
            declare
               N : constant Index := Nodes (Top);
               Remaining : constant Accumulator := Sums (Top);
               After_Node : constant Accumulator :=
                 Subtract_Value (Remaining, T.Values (N));
            begin
               Top := Top - 1;
               if T.Used (N) then
                  if T.Lefts (N) = 0 and then T.Rights (N) = 0 then
                     if After_Node = 0 then
                        return True;
                     end if;
                  else
                     if T.Lefts (N) /= 0 and then Top < Stack_Position'Last then
                        Top := Top + 1;
                        Nodes (Top) := T.Lefts (N);
                        Sums (Top) := After_Node;
                     end if;
                     if T.Rights (N) /= 0 and then Top < Stack_Position'Last then
                        Top := Top + 1;
                        Nodes (Top) := T.Rights (N);
                        Sums (Top) := After_Node;
                     end if;
                  end if;
               end if;
            end;
         end if;
      end loop;
      return False;
   end Has_Path_Sum;
end Path_Sum;
