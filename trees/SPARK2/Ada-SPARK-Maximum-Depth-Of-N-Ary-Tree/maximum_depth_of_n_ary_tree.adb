pragma SPARK_Mode (On);

package body Maximum_Depth_Of_N_Ary_Tree is
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

   function Maximum_Depth (T : Tree; Root : Index) return Natural is
      Result : Depth;
   begin
      if Root = 0 or else not T.Used (Root) then
         return 0;
      end if;
      Result := 1;
      for Slot in Child_Slot loop
         declare
            Child : constant Index := T.Children (Root, Slot);
         begin
            if Child /= 0 and then T.Used (Child) then
               if Result < 2 then
                  Result := 2;
               end if;
               for Grand_Slot in Child_Slot loop
                  declare
                     Grandchild : constant Index := T.Children (Child, Grand_Slot);
                  begin
                     if Grandchild /= 0 and then T.Used (Grandchild) then
                        Result := 3;
                     end if;
                  end;
               end loop;
            end if;
         end;
      end loop;
      return Result;
   end Maximum_Depth;
end Maximum_Depth_Of_N_Ary_Tree;
