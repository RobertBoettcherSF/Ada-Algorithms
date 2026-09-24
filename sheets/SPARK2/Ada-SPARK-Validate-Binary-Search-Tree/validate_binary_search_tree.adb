pragma SPARK_Mode (On);

package body Validate_Binary_Search_Tree is
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
   type Bound_Stack is array (Positive range 1 .. 256) of Integer;

   function Is_Valid_BST (T : Tree; Root : Index) return Boolean is
      Nodes : Node_Stack := (others => 0);
      Lows, Highs : Bound_Stack := (others => -101);
      Top : Stack_Position; Valid : Boolean := True;
   begin
      if Root = 0 or else not T.Used (Root) then return True; end if;
      Top := 1; Nodes (Top) := Root; Lows (Top) := -101; Highs (Top) := 101;
      for Step in 1 .. 256 loop
         pragma Loop_Invariant (Top in Stack_Position);
         if Top > 0 and then Valid then
            declare N : constant Index := Nodes (Top); Lo : constant Integer := Lows (Top);
               Hi : constant Integer := Highs (Top); V : constant Integer := T.Values (N);
            begin
               Top := Top - 1;
               if V <= Lo or else V >= Hi then
                  Valid := False;
               else
                  if T.Rights (N) /= 0 and then Top < Stack_Position'Last then
                     Top := Top + 1; Nodes (Top) := T.Rights (N);
                     Lows (Top) := V; Highs (Top) := Hi;
                  end if;
                  if T.Lefts (N) /= 0 and then Top < Stack_Position'Last then
                     Top := Top + 1; Nodes (Top) := T.Lefts (N);
                     Lows (Top) := Lo; Highs (Top) := V;
                  end if;
               end if;
            end;
         end if;
      end loop;
      return Valid;
   end Is_Valid_BST;
end Validate_Binary_Search_Tree;
