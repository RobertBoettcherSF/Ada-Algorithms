pragma SPARK_Mode (On);

package body Diameter_Of_Binary_Tree is
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
   type Height_Array is array (Node_Index) of Depth;

   function Diameter (T : Tree; Root : Index) return Diameter_Value is
      Heights : Height_Array := (others => 0);
      Nodes : Node_Stack := (others => 0);
      Top : Stack_Position;
      Best : Diameter_Value := 0;
   begin
      if Root = 0 or else not T.Used (Root) then
         return 0;
      end if;
      for Step in 1 .. 225 loop
         declare
            N : constant Node_Index :=
              Node_Index (((Step - 1) mod 15) + 1);
            L : Depth := 0;
            R : Depth := 0;
            H : Depth;
         begin
            if T.Used (N) then
               if T.Lefts (N) /= 0 and then T.Used (T.Lefts (N)) then
                  L := Heights (T.Lefts (N));
               end if;
               if T.Rights (N) /= 0 and then T.Used (T.Rights (N)) then
                  R := Heights (T.Rights (N));
               end if;
               if L > R then
                  if L < Depth'Last then
                     H := L + 1;
                  else
                     H := Depth'Last;
                  end if;
               elsif R < Depth'Last then
                  H := R + 1;
               else
                  H := Depth'Last;
               end if;
               Heights (N) := H;
            end if;
         end;
      end loop;
      Top := 1;
      Nodes (Top) := Root;
      for Step in 1 .. 256 loop
         pragma Loop_Invariant (Top in Stack_Position);
         if Top = 0 then
            null;
         else
            declare
               N : constant Index := Nodes (Top);
               Through : Diameter_Value := 0;
            begin
               Top := Top - 1;
               if T.Used (N) then
                  if T.Lefts (N) /= 0 and then T.Used (T.Lefts (N)) then
                     if T.Rights (N) /= 0 and then T.Used (T.Rights (N)) then
                        declare
                           Total : constant Integer :=
                             Integer (Heights (T.Lefts (N)))
                             + Integer (Heights (T.Rights (N)));
                        begin
                           if Total > Diameter_Value'Last then
                              Through := Diameter_Value'Last;
                           else
                              Through := Diameter_Value (Total);
                           end if;
                        end;
                     else
                        Through := Heights (T.Lefts (N));
                     end if;
                  elsif T.Rights (N) /= 0 and then T.Used (T.Rights (N)) then
                     Through := Heights (T.Rights (N));
                  end if;
                  if Through > Best then
                     Best := Through;
                  end if;
                  if T.Lefts (N) /= 0 and then Top < Stack_Position'Last then
                     Top := Top + 1;
                     Nodes (Top) := T.Lefts (N);
                  end if;
                  if T.Rights (N) /= 0 and then Top < Stack_Position'Last then
                     Top := Top + 1;
                     Nodes (Top) := T.Rights (N);
                  end if;
               end if;
            end;
         end if;
      end loop;
      return Best;
   end Diameter;
end Diameter_Of_Binary_Tree;
