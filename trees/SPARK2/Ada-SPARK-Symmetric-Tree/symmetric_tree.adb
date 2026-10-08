pragma SPARK_Mode (On);

package body Symmetric_Tree is
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
   type Pair_Stack is array (Positive range 1 .. 256) of Index;

   function Is_Symmetric (T : Tree; Root : Index) return Boolean is
      Left_Nodes : Pair_Stack := (others => 0);
      Right_Nodes : Pair_Stack := (others => 0);
      Top : Stack_Position;
   begin
      if Root = 0 or else not T.Used (Root) then
         return True;
      end if;
      Top := 1;
      Left_Nodes (Top) := T.Lefts (Root);
      Right_Nodes (Top) := T.Rights (Root);
      for Step in 1 .. 256 loop
         pragma Loop_Invariant (Top in Stack_Position);
         if Top = 0 then
            null;
         else
            declare
               L : constant Index := Left_Nodes (Top);
               R : constant Index := Right_Nodes (Top);
            begin
               Top := Top - 1;
               if (L = 0 or else not T.Used (L)) and then
                 (R = 0 or else not T.Used (R)) then
                  null;
               elsif L = 0 or else R = 0 or else
                 not T.Used (L) or else not T.Used (R) or else
                 T.Values (L) /= T.Values (R) then
                  return False;
               elsif Top + 2 <= Stack_Position'Last then
                  Top := Top + 1;
                  Left_Nodes (Top) := T.Lefts (L);
                  Right_Nodes (Top) := T.Rights (R);
                  Top := Top + 1;
                  Left_Nodes (Top) := T.Rights (L);
                  Right_Nodes (Top) := T.Lefts (R);
               end if;
            end;
         end if;
      end loop;
      return True;
   end Is_Symmetric;
end Symmetric_Tree;
