pragma Ada_2022;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Containers.Ordered_Maps;

package body Fp_Growth is

   use type Item_Sets.Set;

   -----------------------------------------------------------------------------
   --  Internal Data Structures for FP-Tree
   -----------------------------------------------------------------------------

   type Node_Index is new Natural;
   Null_Index : constant Node_Index := 0;
   subtype Valid_Node_Index is Node_Index range 1 .. Node_Index'Last;

   --  FP_Node forms the nodes of the prefix tree.
   type FP_Node is record
      Item         : Item_Type := 1;
      Count        : Natural := 0;
      Parent       : Node_Index := Null_Index;
      First_Child  : Node_Index := Null_Index;
      Next_Sibling : Node_Index := Null_Index;
      Next_Homonym : Node_Index := Null_Index;
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Valid_Node_Index,
      Element_Type => FP_Node);

   --  Header_Entry tracks global frequency and homonym linked lists.
   type Header_Entry is record
      Support    : Natural := 0;
      First_Node : Node_Index := Null_Index;
      Last_Node  : Node_Index := Null_Index;
   end record;

   package Header_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Item_Type,
      Element_Type => Header_Entry);

   --  Linear vector of items used for sorting and conditional bases.
   package Item_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Item_Type);
   subtype Item_Vector is Item_Vectors.Vector;

   --  Internal transaction representation with occurrence multiplier.
   type Internal_Transaction is record
      Items : Item_Vector;
      Count : Positive := 1;
   end record;

   package Internal_Tx_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Internal_Transaction);
   subtype Internal_Tx_List is Internal_Tx_Vectors.Vector;

   --  Complete FP-Tree structure
   type FP_Tree is record
      Nodes   : Node_Vectors.Vector;
      Headers : Header_Maps.Map;
      Root    : Node_Index := Null_Index;
   end record;

   -----------------------------------------------------------------------------
   --  Helper Subprograms
   -----------------------------------------------------------------------------

   --  Finds the support count of a specific itemset from a previously mined list.
   function Get_Support (Itemsets : Frequent_Itemset_List; Target : Item_Set) return Natural is
   begin
      for Itemset of Itemsets loop
         if Itemset.Items = Target then
            return Itemset.Support;
         end if;
      end loop;
      return 0;
   end Get_Support;

   --  Sorts an item vector descending by frequency, ascending by ID (tie-break).
   procedure Sort_By_Frequency (Vec : in out Item_Vector; Freq_Map : Header_Maps.Map) is
      Temp           : Item_Type;
      J              : Natural;
      Freq_I, Freq_J : Natural;
   begin
      if Vec.Length < 2 then
         return;
      end if;

      for I in 2 .. Natural (Vec.Length) loop
         Temp := Vec.Element (I);
         Freq_I := Freq_Map.Element (Temp).Support;
         J := I - 1;
         
         while J >= 1 loop
            Freq_J := Freq_Map.Element (Vec.Element (J)).Support;
            if Freq_J < Freq_I or else (Freq_J = Freq_I and then Vec.Element (J) > Temp) then
               Vec.Replace_Element (J + 1, Vec.Element (J));
               J := J - 1;
            else
               exit;
            end if;
         end loop;
         Vec.Replace_Element (J + 1, Temp);
      end loop;
   end Sort_By_Frequency;

   -----------------------------------------------------------------------------
   --  FP-Tree Construction and Mining
   -----------------------------------------------------------------------------

   --  Constructs an FP-Tree from an internal transaction list.
   function Build_Tree (Txs : Internal_Tx_List; Min_Support : Positive) return FP_Tree is
      Tree  : FP_Tree;
      Freqs : Header_Maps.Map;

      --  Phase 1: Count item frequencies and filter those below threshold.
      procedure Count_Frequencies is
         C : Natural;
      begin
         for Tx of Txs loop
            for Item of Tx.Items loop
               if Freqs.Contains (Item) then
                  C := Freqs.Element (Item).Support;
                  Freqs.Include (Item, (Support => C + Tx.Count, First_Node => Null_Index, Last_Node => Null_Index));
               else
                  Freqs.Insert (Item, (Support => Tx.Count, First_Node => Null_Index, Last_Node => Null_Index));
               end if;
            end loop;
         end loop;

         declare
            Pos      : Header_Maps.Cursor := Freqs.First;
            Next_Pos : Header_Maps.Cursor;
         begin
            while Header_Maps.Has_Element (Pos) loop
               Next_Pos := Header_Maps.Next (Pos);
               if Header_Maps.Element (Pos).Support < Min_Support then
                  Freqs.Delete (Pos);
               end if;
               Pos := Next_Pos;
            end loop;
         end;
      end Count_Frequencies;

      function Add_Node (Item : Item_Type; Parent : Node_Index) return Node_Index is
         Idx      : Node_Index;
         New_Node : FP_Node;
      begin
         New_Node.Item := Item;
         New_Node.Parent := Parent;
         Tree.Nodes.Append (New_Node);
         Idx := Node_Index (Tree.Nodes.Length);
         return Idx;
      end Add_Node;

   begin
      Count_Frequencies;
      Tree.Headers := Freqs;

      declare
         Root_Node : FP_Node;
      begin
         Tree.Nodes.Append (Root_Node);
         Tree.Root := Node_Index (Tree.Nodes.Length);
      end;

      --  Phase 2: Insert sorted transactions into tree.
      for Tx of Txs loop
         declare
            Filtered : Item_Vector;
         begin
            for Item of Tx.Items loop
               if Freqs.Contains (Item) then
                  Filtered.Append (Item);
               end if;
            end loop;

            if not Filtered.Is_Empty then
               Sort_By_Frequency (Filtered, Freqs);

               declare
                  Curr       : Node_Index := Tree.Root;
                  Child      : Node_Index;
                  Found      : Boolean;
                  Item       : Item_Type;
                  Node_Val   : FP_Node;
               begin
                  for I in 1 .. Natural (Filtered.Length) loop
                     Item := Filtered.Element (I);
                     Found := False;
                     Child := Tree.Nodes.Element (Curr).First_Child;

                     while Child /= Null_Index loop
                        if Tree.Nodes.Element (Child).Item = Item then
                           Found := True;
                           exit;
                        end if;
                        Child := Tree.Nodes.Element (Child).Next_Sibling;
                     end loop;

                     if Found then
                        Node_Val := Tree.Nodes.Element (Child);
                        Node_Val.Count := Node_Val.Count + Tx.Count;
                        Tree.Nodes.Replace_Element (Child, Node_Val);
                        Curr := Child;
                     else
                        Child := Add_Node (Item, Curr);
                        Node_Val := Tree.Nodes.Element (Child);
                        Node_Val.Count := Tx.Count;

                        declare
                           Parent_Val : FP_Node := Tree.Nodes.Element (Curr);
                        begin
                           Node_Val.Next_Sibling := Parent_Val.First_Child;
                           Parent_Val.First_Child := Child;
                           Tree.Nodes.Replace_Element (Curr, Parent_Val);
                        end;

                        declare
                           H_Entry : Header_Entry := Tree.Headers.Element (Item);
                        begin
                           if H_Entry.First_Node = Null_Index then
                              H_Entry.First_Node := Child;
                           else
                              declare
                                 Last_Node_Val : FP_Node := Tree.Nodes.Element (H_Entry.Last_Node);
                              begin
                                 Last_Node_Val.Next_Homonym := Child;
                                 Tree.Nodes.Replace_Element (H_Entry.Last_Node, Last_Node_Val);
                              end;
                           end if;
                           H_Entry.Last_Node := Child;
                           Tree.Headers.Replace (Item, H_Entry);
                        end;

                        Tree.Nodes.Replace_Element (Child, Node_Val);
                        Curr := Child;
                     end if;
                  end loop;
               end;
            end if;
         end;
      end loop;

      return Tree;
   end Build_Tree;

   --  Recursively mines conditional FP-Trees.
   procedure Mine_Tree
     (Tree        : FP_Tree;
      Min_Support : Positive;
      Prefix      : Item_Set;
      Results     : in out Frequent_Itemset_List)
   is
      type Item_Freq is record
         Item    : Item_Type;
         Support : Natural;
      end record;
      package Item_Freq_Vectors is new Ada.Containers.Vectors (Positive, Item_Freq);
      Freqs_Vec : Item_Freq_Vectors.Vector;
   begin
      if Tree.Nodes.Is_Empty then
         return;
      end if;

      --  Extract and sort items ascending by support for bottom-up processing.
      for Cursor in Tree.Headers.Iterate loop
         Freqs_Vec.Append (Item_Freq'(Item => Header_Maps.Key (Cursor), Support => Header_Maps.Element (Cursor).Support));
      end loop;

      for I in 2 .. Natural (Freqs_Vec.Length) loop
         declare
            Temp : constant Item_Freq := Freqs_Vec.Element (I);
            J    : Natural := I - 1;
         begin
            while J >= 1 loop
               if Freqs_Vec.Element (J).Support > Temp.Support then
                  Freqs_Vec.Replace_Element (J + 1, Freqs_Vec.Element (J));
                  J := J - 1;
               else
                  exit;
               end if;
            end loop;
            Freqs_Vec.Replace_Element (J + 1, Temp);
         end;
      end loop;

      --  Mine conditionally
      for F of Freqs_Vec loop
         declare
            New_Prefix : Item_Set := Prefix;
            Cond_Txs   : Internal_Tx_List;
            Node_Idx   : Node_Index := Tree.Headers.Element (F.Item).First_Node;
         begin
            New_Prefix.Insert (F.Item);
            Results.Append (Frequent_Itemset'(Items => New_Prefix, Support => F.Support));

            while Node_Idx /= Null_Index loop
               declare
                  Path_Count : constant Natural := Tree.Nodes.Element (Node_Idx).Count;
                  Curr       : Node_Index := Tree.Nodes.Element (Node_Idx).Parent;
                  Path       : Item_Vector;
               begin
                  while Curr /= Null_Index and then Curr /= Tree.Root loop
                     Path.Append (Tree.Nodes.Element (Curr).Item);
                     Curr := Tree.Nodes.Element (Curr).Parent;
                  end loop;

                  if not Path.Is_Empty then
                     Cond_Txs.Append (Internal_Transaction'(Items => Path, Count => Path_Count));
                  end if;
               end;
               Node_Idx := Tree.Nodes.Element (Node_Idx).Next_Homonym;
            end loop;

            if not Cond_Txs.Is_Empty then
               declare
                  Cond_Tree : constant FP_Tree := Build_Tree (Cond_Txs, Min_Support);
               begin
                  Mine_Tree (Cond_Tree, Min_Support, New_Prefix, Results);
               end;
            end if;
         end;
      end loop;
   end Mine_Tree;

   -----------------------------------------------------------------------------
   --  Public API
   -----------------------------------------------------------------------------

   function Mine_Frequent_Itemsets
     (DB          : Transaction_Database;
      Min_Support : Positive) return Frequent_Itemset_List
   is
      Txs          : Internal_Tx_List;
      Tree         : FP_Tree;
      Results      : Frequent_Itemset_List;
      Empty_Prefix : Item_Set;
   begin
      if DB.Is_Empty then
         raise Empty_Database_Error;
      end if;

      for Tx of DB loop
         declare
            Int_Tx : Internal_Transaction;
         begin
            for Item of Tx loop
               Int_Tx.Items.Append (Item);
            end loop;
            Txs.Append (Int_Tx);
         end;
      end loop;

      Tree := Build_Tree (Txs, Min_Support);
      Mine_Tree (Tree, Min_Support, Empty_Prefix, Results);
      return Results;
   end Mine_Frequent_Itemsets;

   --  Generates all subsets (excluding empty and full) to derive rules.
   procedure Generate_Subsets (Items : Item_Set; Subsets : in out Itemset_Vectors.Vector) is
      Items_Vec : Item_Vectors.Vector;
   begin
      for Item of Items loop
         Items_Vec.Append (Item);
      end loop;

      declare
         Num_Subsets : constant Natural := 2 ** Natural (Items_Vec.Length);
      begin
         if Num_Subsets < 4 then
            return;
         end if;
         
         for I in 1 .. Num_Subsets - 2 loop
            declare
               Subset : Item_Set;
               Mask   : Natural := I;
               Idx    : Positive := 1;
            begin
               while Mask > 0 loop
                  if Mask mod 2 = 1 then
                     Subset.Insert (Items_Vec.Element (Idx));
                  end if;
                  Mask := Mask / 2;
                  Idx := Idx + 1;
               end loop;
               Subsets.Append (Frequent_Itemset'(Items => Subset, Support => 0));
            end;
         end loop;
      end;
   end Generate_Subsets;

   function Generate_Association_Rules
     (Itemsets       : Frequent_Itemset_List;
      Min_Confidence : Float) return Association_Rule_List
   is
      Rules : Association_Rule_List;
   begin
      if Min_Confidence < 0.0 or else Min_Confidence > 1.0 then
         raise Invalid_Threshold_Error;
      end if;

      for Freq_Set of Itemsets loop
         if Natural (Freq_Set.Items.Length) > 1 then
            declare
               Subsets : Itemset_Vectors.Vector;
            begin
               Generate_Subsets (Freq_Set.Items, Subsets);
               for Sub of Subsets loop
                  declare
                     A         : constant Item_Set := Sub.Items;
                     B         : Item_Set := Freq_Set.Items;
                     Support_A : Natural;
                  begin
                     B.Difference (A);
                     Support_A := Get_Support (Itemsets, A);
                     
                     if Support_A > 0 then
                        declare
                           Conf : constant Float := Float (Freq_Set.Support) / Float (Support_A);
                        begin
                           if Conf >= Min_Confidence then
                              Rules.Append
                                (Association_Rule'
                                   (Antecedent => A,
                                    Consequent => B,
                                    Support    => Freq_Set.Support,
                                    Confidence => Conf));
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end;
         end if;
      end loop;
      return Rules;
   end Generate_Association_Rules;

   function Mine_Association_Rules
     (DB             : Transaction_Database;
      Min_Support    : Positive;
      Min_Confidence : Float) return Association_Rule_List
   is
      Freq_Sets : Frequent_Itemset_List;
   begin
      Freq_Sets := Mine_Frequent_Itemsets (DB, Min_Support);
      return Generate_Association_Rules (Freq_Sets, Min_Confidence);
   end Mine_Association_Rules;

end Fp_Growth;
