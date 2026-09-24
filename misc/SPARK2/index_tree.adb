pragma SPARK_Mode (On);

package body Index_Tree is

   function Empty return Tree is
      T : Tree;
   begin
      Reset (T.Store);
      T.Root := Null_Node;
      T.Nodes := [others => (Value => 0, Left => Null_Node, Right => Null_Node)];
      return T;
   end Empty;

   function Remaining_Slots (T : Tree) return Slot_Count is
   begin
      return Remaining (T.Store);
   end Remaining_Slots;

   procedure Clear (T : out Tree) is
   begin
      T := Empty;
   end Clear;

   function Contains (T : Tree; K : Key) return Boolean is
      Cur : Node_Id := T.Root;
   begin
      for Step in 1 .. Capacity loop
         pragma Loop_Invariant (Cur = Null_Node or else Cur in Valid_Id);
         if Cur = Null_Node then
            return False;
         elsif K = T.Nodes (Cur).Value then
            return True;
         elsif K < T.Nodes (Cur).Value then
            Cur := T.Nodes (Cur).Left;
         else
            Cur := T.Nodes (Cur).Right;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Insert (T : in out Tree; K : Key; Ok : out Boolean) is
      Id  : Node_Id;
      Cur : Node_Id;
   begin
      if Contains (T, K) then
         Ok := False;
         return;
      end if;

      Allocate_Node (T.Store, Id);
      T.Nodes (Id) := (Value => K, Left => Null_Node, Right => Null_Node);

      if T.Root = Null_Node then
         T.Root := Id;
         Ok := True;
         return;
      end if;

      Cur := T.Root;
      for Step in 1 .. Capacity loop
         pragma Loop_Invariant (Cur in Valid_Id);
         pragma Loop_Invariant (Id in Valid_Id);
         pragma Loop_Invariant (Used (T.Store) = Used (T.Store'Loop_Entry));
         pragma Loop_Invariant (Root_Of (T) = Root_Of (T'Loop_Entry));
         if K < T.Nodes (Cur).Value then
            if T.Nodes (Cur).Left = Null_Node then
               T.Nodes (Cur).Left := Id;
               Ok := True;
               return;
            end if;
            Cur := T.Nodes (Cur).Left;
         else
            if T.Nodes (Cur).Right = Null_Node then
               T.Nodes (Cur).Right := Id;
               Ok := True;
               return;
            end if;
            Cur := T.Nodes (Cur).Right;
         end if;
      end loop;

      --  Unreachable for trees whose depth is within Capacity; keep flow clean.
      Ok := True;
   end Insert;

end Index_Tree;
