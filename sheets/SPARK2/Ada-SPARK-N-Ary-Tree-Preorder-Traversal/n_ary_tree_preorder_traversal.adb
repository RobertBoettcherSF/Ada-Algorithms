pragma SPARK_Mode (On);

package body N_Ary_Tree_Preorder_Traversal is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Children => (others => (others => 0)), Used => (others => False));
   end Empty;

   procedure Set_Node (T : in out Tree; Node : Node_Index; V : Value) is
   begin
      T.Values (Node) := V;
      T.Used (Node) := True;
   end Set_Node;

   procedure Set_Child (T : in out Tree; Parent : Node_Index; Slot : Child_Slot; Child : Index) is
   begin
      T.Children (Parent, Slot) := Child;
   end Set_Child;

   function Preorder (T : Tree; Root : Index) return Visit_Result is
      type Node_Array is array (Node_Index) of Index;
      Stack : Node_Array := (others => 0);
      Top : Natural range 0 .. 16;
      Current : Index;
      Result : Visit_Result := (Values => (others => 0), Length => 0);
   begin
      if Root = 0 or else not T.Used (Root) then
         return Result;
      end if;
      Top := 1;
      Stack (Top) := Root;
      for Step in 1 .. 16 loop
         exit when Top = 0;
         Current := Stack (Top);
         Top := Top - 1;
         if Current /= 0 and then T.Used (Current) then
            if Result.Length < 16 then
               Result.Length := Result.Length + 1;
               Result.Values (Result.Length) := T.Values (Current);
            end if;
            for Slot in reverse Child_Slot loop
               declare
                  Child : constant Index := T.Children (Current, Slot);
               begin
                  if Child /= 0 and then Top < 16 then
                     Top := Top + 1;
                     Stack (Top) := Child;
                  end if;
               end;
            end loop;
         end if;
      end loop;
      return Result;
   end Preorder;
end N_Ary_Tree_Preorder_Traversal;
