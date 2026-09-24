pragma SPARK_Mode (On);

package body Kth_Smallest_BST_Stub is
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

   procedure Kth_Smallest (T : Tree; Root : Index; K : Positive; Result : out Value; Found : out Boolean) is
      Stack : array (Positive range 1 .. 31) of Index := (others => 0);
      Top : Natural range 0 .. 31 := 0;
      Current : Index := Root;
      Seen : Natural range 0 .. 31 := 0;
   begin
      Result := 0; Found := False;
      for Step in 1 .. 31 loop
         for Push in 1 .. 31 loop
            if Current = 0 or else not T.Used (Current) or else Top = 31 then
               exit;
            else
               Top := Top + 1; Stack (Top) := Current; Current := T.Lefts (Current);
            end if;
         end loop;
         if Top = 0 then exit; end if;
         Current := Stack (Top); Top := Top - 1;
         if Seen < 31 then Seen := Seen + 1; end if;
         if Seen = K then Result := T.Values (Current); Found := True; exit; end if;
         Current := T.Rights (Current);
      end loop;
   end Kth_Smallest;
end Kth_Smallest_BST_Stub;
