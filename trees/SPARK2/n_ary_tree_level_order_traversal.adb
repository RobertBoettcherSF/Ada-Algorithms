pragma SPARK_Mode (On);

package body N_Ary_Tree_Level_Order_Traversal is
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

   function Level_Order (T : Tree; Root : Index) return Visit_Result is
      type Node_Array is array (Node_Index) of Index;
      Queue : Node_Array := (others => 0);
      Head : Natural range 0 .. 16 := 0;
      Tail : Natural range 0 .. 16;
      Current : Index;
      Result : Visit_Result := (Values => (others => 0), Length => 0);
   begin
      if Root = 0 or else not T.Used (Root) then
         return Result;
      end if;
      Tail := 1;
      Queue (Tail) := Root;
      for Step in 1 .. 16 loop
         exit when Head = Tail;
         Head := Head + 1;
         Current := Queue (Head);
         if Current /= 0 and then T.Used (Current) then
            if Result.Length < 16 then
               Result.Length := Result.Length + 1;
               Result.Values (Result.Length) := T.Values (Current);
            end if;
            for Slot in Child_Slot loop
               declare
                  Child : constant Index := T.Children (Current, Slot);
               begin
                  if Child /= 0 and then Tail < 16 then
                     Tail := Tail + 1;
                     Queue (Tail) := Child;
                  end if;
               end;
            end loop;
         end if;
      end loop;
      return Result;
   end Level_Order;
end N_Ary_Tree_Level_Order_Traversal;
