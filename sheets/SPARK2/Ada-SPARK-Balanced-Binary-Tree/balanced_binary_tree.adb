pragma SPARK_Mode (On);

package body Balanced_Binary_Tree is
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

   function Is_Balanced (T : Tree; Root : Index) return Boolean is
      Nodes : array (Positive range 1 .. 31) of Index := (others => 0);
      Levels : array (Positive range 1 .. 31) of Natural range 0 .. 31 := (others => 0);
      Top : Natural range 0 .. 31;
      Min_Depth : Natural range 0 .. 31 := 31;
      Max_Depth : Natural range 0 .. 31 := 0;
   begin
      if Root = 0 or else not T.Used (Root) then return True; end if;
      Top := 1; Nodes (Top) := Root; Levels (Top) := 1;
      for Step in 1 .. 31 loop
         if Top = 0 then null; else
            declare N : constant Index := Nodes (Top); D : constant Natural range 0 .. 31 := Levels (Top); begin
               Top := Top - 1;
               if D > Max_Depth then Max_Depth := D; end if;
               if T.Lefts (N) = 0 and then T.Rights (N) = 0 and then D < Min_Depth then Min_Depth := D; end if;
               if D < 31 then
                  if T.Lefts (N) /= 0 and then Top < 31 then Top := Top + 1; Nodes (Top) := T.Lefts (N); Levels (Top) := D + 1; end if;
                  if T.Rights (N) /= 0 and then Top < 31 then Top := Top + 1; Nodes (Top) := T.Rights (N); Levels (Top) := D + 1; end if;
               end if;
            end;
         end if;
      end loop;
      return Max_Depth - Min_Depth <= 1;
   end Is_Balanced;
end Balanced_Binary_Tree;
