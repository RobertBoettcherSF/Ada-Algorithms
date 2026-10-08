pragma SPARK_Mode (On);

package body Validate_BST_Stub is
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

   function Is_Valid (T : Tree; Root : Index) return Boolean is
      Nodes : array (Positive range 1 .. 31) of Index := (others => 0);
      Low : array (Positive range 1 .. 31) of Value := (others => Value'First);
      High : array (Positive range 1 .. 31) of Value := (others => Value'Last);
      Top : Natural range 0 .. 31;
      Good : Boolean := True;
   begin
      if Root = 0 or else not T.Used (Root) then return True; end if;
      Top := 1; Nodes (Top) := Root;
      for Step in 1 .. 31 loop
         if Top = 0 then null; else
            declare N : constant Index := Nodes (Top); L : constant Value := Low (Top); H : constant Value := High (Top); begin
               Top := Top - 1;
               if not T.Used (N) or else T.Values (N) < L or else T.Values (N) > H then
                  Good := False;
               else
                  if T.Lefts (N) /= 0 and then Top < 31 then
                     Top := Top + 1; Nodes (Top) := T.Lefts (N); Low (Top) := L; High (Top) := T.Values (N);
                  end if;
                  if T.Rights (N) /= 0 and then Top < 31 then
                     Top := Top + 1; Nodes (Top) := T.Rights (N); Low (Top) := T.Values (N); High (Top) := H;
                  end if;
               end if;
            end;
         end if;
      end loop;
      return Good;
   end Is_Valid;
end Validate_BST_Stub;
