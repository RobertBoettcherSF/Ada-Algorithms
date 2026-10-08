package body Ukkonen is

   -- Helper: Calculate the length of a specific edge
   function Edge_Length (Tree : Suffix_Tree; N_Idx : Node_Index) return Integer is
      N : constant Node := Tree.Nodes.Element (N_Idx);
   begin
      if N.Start_Index > N.End_Index then
         return 0;
      end if;
      
      if N.End_Index = Infinity then
         return Tree.Current_Phase - N.Start_Index + 1;
      else
         return N.End_Index - N.Start_Index + 1;
      end if;
   end Edge_Length;

   -- Internal: Implement a single phase of Ukkonen's online construction
   procedure Extend_Tree (Tree : in out Suffix_Tree; Pos : Integer) is
      Last_New_Node : Node_Index := Null_Node;
      Text_Str      : constant String := To_String (Tree.Text);
      Active_Char   : Character;
      Char          : constant Character := Text_Str (Pos);
      Child_Idx     : Node_Index;
   begin
      Tree.Remainder     := Tree.Remainder + 1;
      Tree.Current_Phase := Pos;

      while Tree.Remainder > 0 loop
         if Tree.Active_Length = 0 then
            Tree.Active_Edge := Pos;
         end if;

         Active_Char := Text_Str (Tree.Active_Edge);
         Child_Idx   := Tree.Nodes.Element (Tree.Active_Node).Children (Active_Char);

         if Child_Idx = Null_Node then
            -- Rule 2: No child exists, create a new leaf
            declare
               New_Leaf : Node;
               Active_N : Node := Tree.Nodes.Element (Tree.Active_Node);
            begin
               New_Leaf.Start_Index := Pos;
               New_Leaf.End_Index   := Infinity;
               Tree.Nodes.Append (New_Leaf);
               Active_N.Children (Active_Char) := Node_Vectors.Last_Index (Tree.Nodes);
               Tree.Nodes.Replace_Element (Tree.Active_Node, Active_N);
            end;

            -- Establish suffix link from previous extension
            if Last_New_Node /= Null_Node then
               declare
                  Last_N : Node := Tree.Nodes.Element (Last_New_Node);
               begin
                  Last_N.Suffix_Link := Tree.Active_Node;
                  Tree.Nodes.Replace_Element (Last_New_Node, Last_N);
               end;
               Last_New_Node := Null_Node;
            end if;

         else
            declare
               Child_Node : Node := Tree.Nodes.Element (Child_Idx);
               EL         : Integer := Edge_Length (Tree, Child_Idx);
            begin
               -- Walk down if active length surpasses edge length
               if Tree.Active_Length >= EL then
                  Tree.Active_Edge   := Tree.Active_Edge + EL;
                  Tree.Active_Length := Tree.Active_Length - EL;
                  Tree.Active_Node   := Child_Idx;
                  goto Continue_Phase;
               end if;

               -- Rule 3: Current character matches the edge character
               if Text_Str (Child_Node.Start_Index + Tree.Active_Length) = Char then
                  if Last_New_Node /= Null_Node and Tree.Active_Node /= Tree.Root then
                     declare
                        Last_N : Node := Tree.Nodes.Element (Last_New_Node);
                     begin
                        Last_N.Suffix_Link := Tree.Active_Node;
                        Tree.Nodes.Replace_Element (Last_New_Node, Last_N);
                     end;
                     Last_New_Node := Null_Node;
                  end if;
                  Tree.Active_Length := Tree.Active_Length + 1;
                  goto End_Phase;
               end if;

               -- Rule 2 (Split): Mismatch found, split the edge and insert new internal node
               declare
                  Split_Node : Node;
                  Split_Idx  : Node_Index;
                  New_Leaf   : Node;
                  Active_N   : Node := Tree.Nodes.Element (Tree.Active_Node);
               begin
                  Split_Node.Start_Index := Child_Node.Start_Index;
                  Split_Node.End_Index   := Child_Node.Start_Index + Tree.Active_Length - 1;
                  Tree.Nodes.Append (Split_Node);
                  Split_Idx := Node_Vectors.Last_Index (Tree.Nodes);

                  Active_N.Children (Active_Char) := Split_Idx;
                  Tree.Nodes.Replace_Element (Tree.Active_Node, Active_N);

                  Child_Node.Start_Index := Child_Node.Start_Index + Tree.Active_Length;
                  declare
                     S_Node : Node := Tree.Nodes.Element (Split_Idx);
                  begin
                     S_Node.Children (Text_Str (Child_Node.Start_Index)) := Child_Idx;
                     Tree.Nodes.Replace_Element (Split_Idx, S_Node);
                  end;
                  Tree.Nodes.Replace_Element (Child_Idx, Child_Node);

                  New_Leaf.Start_Index := Pos;
                  New_Leaf.End_Index   := Infinity;
                  Tree.Nodes.Append (New_Leaf);

                  declare
                     S_Node : Node := Tree.Nodes.Element (Split_Idx);
                  begin
                     S_Node.Children (Char) := Node_Vectors.Last_Index (Tree.Nodes);
                     Tree.Nodes.Replace_Element (Split_Idx, S_Node);
                  end;

                  if Last_New_Node /= Null_Node then
                     declare
                        Last_N : Node := Tree.Nodes.Element (Last_New_Node);
                     begin
                        Last_N.Suffix_Link := Split_Idx;
                        Tree.Nodes.Replace_Element (Last_New_Node, Last_N);
                     end;
                  end if;
                  Last_New_Node := Split_Idx;
               end;
            end;
         end if;

         -- Update active point dynamically for the next remainder resolution
         Tree.Remainder := Tree.Remainder - 1;
         if Tree.Active_Node = Tree.Root and Tree.Active_Length > 0 then
            Tree.Active_Length := Tree.Active_Length - 1;
            Tree.Active_Edge   := Pos - Tree.Remainder + 1;
         elsif Tree.Active_Node /= Tree.Root then
            declare
               Active_N : Node := Tree.Nodes.Element (Tree.Active_Node);
            begin
               if Active_N.Suffix_Link /= Null_Node then
                  Tree.Active_Node := Active_N.Suffix_Link;
               else
                  Tree.Active_Node := Tree.Root;
               end if;
            end;
         end if;

         <<Continue_Phase>>
         null;
      end loop;
      
      <<End_Phase>>
      null;
   end Extend_Tree;

   function Build_Suffix_Tree (Text : String) return Suffix_Tree is
      Tree : Suffix_Tree;
      Root_Node : Node;
   begin
      if Text'Length = 0 then
         raise Invalid_Input with "Cannot build suffix tree on an empty string.";
      end if;

      Tree.Text := To_Unbounded_String (Text);
      Tree.Nodes.Clear;
      Tree.Nodes.Append (Root_Node); -- Root is at index 1
      Tree.Root        := 1;
      Tree.Active_Node := 1;

      for I in Text'Range loop
         Extend_Tree (Tree, I);
      end loop;

      return Tree;
   end Build_Suffix_Tree;

   function Contains_Substring (Tree : Suffix_Tree; Substr : String) return Boolean is
      Current_Node : Node_Index := Tree.Root;
      Pos          : Integer := Substr'First;
      Edge_Pos     : Integer;
      Text_Str     : constant String := To_String (Tree.Text);
      Char         : Character;
      Child_Idx    : Node_Index;
      Node_Ref     : Node;
   begin
      if Substr'Length = 0 then 
         return True; 
      end if;

      while Pos <= Substr'Last loop
         Char := Substr (Pos);
         Node_Ref := Tree.Nodes.Element (Current_Node);
         Child_Idx := Node_Ref.Children (Char);

         if Child_Idx = Null_Node then
            return False; -- Mismatch at node
         end if;

         Node_Ref := Tree.Nodes.Element (Child_Idx);
         Edge_Pos := Node_Ref.Start_Index;

         -- Walk down traversing the edge
         declare
            EL : Integer := Edge_Length (Tree, Child_Idx);
            End_P : Integer := Node_Ref.Start_Index + EL - 1;
         begin
            while Pos <= Substr'Last and Edge_Pos <= End_P loop
               if Text_Str (Edge_Pos) /= Substr (Pos) then
                  return False; -- Mismatch mid-edge
               end if;
               Pos := Pos + 1;
               Edge_Pos := Edge_Pos + 1;
            end loop;
         end;
         Current_Node := Child_Idx;
      end loop;

      return True;
   end Contains_Substring;

end Ukkonen;
