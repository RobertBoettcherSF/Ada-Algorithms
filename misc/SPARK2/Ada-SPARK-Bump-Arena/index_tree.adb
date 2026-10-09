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
      --  Links point forward (Type_Invariant), so the walk ends: the loop
      --  exits only at a null link, when K is not in the tree.
      while Cur /= Null_Node loop
         pragma Loop_Invariant (Cur in 1 .. Used (T.Store));
         pragma Loop_Variant (Increases => Cur);
         if K = T.Nodes (Cur).Value then
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

      --  The old nodes 1 .. Id - 1 link only among themselves and the new
      --  node Id has no children, so the walk over old nodes visits
      --  strictly increasing ids and must reach a null link: there is no
      --  exit from this loop other than linking Id in.
      pragma Assert (Id = Used (T.Store));
      pragma Assert (T.Root in 1 .. Id - 1);
      Cur := T.Root;
      loop
         pragma Loop_Invariant (Cur in 1 .. Id - 1);
         pragma Loop_Invariant (Id = Used (T.Store));
         pragma Loop_Invariant (Used (T.Store) = Used (T.Store'Loop_Entry));
         pragma Loop_Invariant (Root_Of (T) = Root_Of (T'Loop_Entry));
         pragma Loop_Invariant (T.Nodes = T.Nodes'Loop_Entry);
         pragma Loop_Invariant
           (for all N in 1 .. Id - 1 =>
              (T.Nodes (N).Left = Null_Node or else T.Nodes (N).Left in N + 1 .. Id - 1)
              and then
              (T.Nodes (N).Right = Null_Node or else T.Nodes (N).Right in N + 1 .. Id - 1));
         pragma Loop_Variant (Increases => Cur);
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
   end Insert;

end Index_Tree;
