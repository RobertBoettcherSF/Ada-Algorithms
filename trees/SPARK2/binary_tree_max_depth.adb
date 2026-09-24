pragma SPARK_Mode (On);

package body Binary_Tree_Max_Depth is
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
   type Depth_Stack is array (Positive range 1 .. 256) of Depth;

   function Max_Depth (T : Tree; Root : Index) return Depth is
      Nodes : Node_Stack := (others => 0);
      Levels : Depth_Stack := (others => 0);
      Top : Stack_Position;
      Best : Depth := 0;
   begin
      if Root = 0 or else not T.Used (Root) then
         return 0;
      end if;
      Top := 1;
      Nodes (Top) := Root;
      Levels (Top) := 1;
      for Step in 1 .. 256 loop
         pragma Loop_Invariant (Top in Stack_Position);
         if Top = 0 then
            null;
         else
            declare
               N : constant Index := Nodes (Top);
               D : constant Depth := Levels (Top);
            begin
               Top := Top - 1;
               if T.Used (N) then
                  if D > Best then
                     Best := D;
                  end if;
                  if D < Depth'Last then
                     if T.Lefts (N) /= 0 and then Top < Stack_Position'Last then
                        Top := Top + 1;
                        Nodes (Top) := T.Lefts (N);
                        Levels (Top) := D + 1;
                     end if;
                     if T.Rights (N) /= 0 and then Top < Stack_Position'Last then
                        Top := Top + 1;
                        Nodes (Top) := T.Rights (N);
                        Levels (Top) := D + 1;
                     end if;
                  end if;
               end if;
            end;
         end if;
      end loop;
      return Best;
   end Max_Depth;
end Binary_Tree_Max_Depth;
