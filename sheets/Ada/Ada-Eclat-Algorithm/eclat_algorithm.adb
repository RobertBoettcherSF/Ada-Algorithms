pragma Ada_2022;
package body Eclat_Algorithm is

   -- | Node structure used during the depth-first recursion.
   -- | TIDs can represent an actual TID set (in Standard Eclat or Level 1 of dEclat)
   -- | or a Diffset (in Level 2+ of dEclat).
   type Equivalence_Node is record
      Item    : Item_ID;
      TIDs    : TID_Sets.Set; 
      Support : Support_Count;
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Equivalence_Node);

   -----------------------------------------------------------------------------
   -- Add_Item_TID
   -----------------------------------------------------------------------------
   procedure Add_Item_TID
     (DB   : in out Vertical_DB;
      Item : Item_ID;
      TID  : Transaction_ID)
   is
      use DB_Maps;
      Pos : constant Cursor := DB.Data.Find (Item);
   begin
      if Has_Element (Pos) then
         declare
            S : TID_Sets.Set := Element (Pos);
         begin
            S.Include (TID);
            DB.Data.Replace_Element (Pos, S);
         end;
      else
         declare
            S : TID_Sets.Set := TID_Sets.Empty_Set;
         begin
            S.Insert (TID);
            DB.Data.Insert (Item, S);
         end;
      end if;
   end Add_Item_TID;

   -----------------------------------------------------------------------------
   -- Item_Count
   -----------------------------------------------------------------------------
   function Item_Count (DB : Vertical_DB) return Natural is
   begin
      return Natural (DB.Data.Length);
   end Item_Count;

   -----------------------------------------------------------------------------
   -- Clear
   -----------------------------------------------------------------------------
   procedure Clear (DB : in out Vertical_DB) is
   begin
      DB.Data.Clear;
   end Clear;

   -----------------------------------------------------------------------------
   -- Eclat_Rec (Standard Recursive Step)
   -----------------------------------------------------------------------------
   procedure Eclat_Rec
     (Prefix  : Item_Sets.Set;
      Class   : Node_Vectors.Vector;
      Min_Sup : Support_Count;
      Results : in out Itemset_Vectors.Vector)
   is
   begin
      for I in 1 .. Natural (Class.Length) loop
         declare
            Curr_Node  : constant Equivalence_Node := Class.Element (I);
            New_Prefix : Item_Sets.Set := Prefix;
            New_Class  : Node_Vectors.Vector;
         begin
            -- Extend the current prefix with the current item
            New_Prefix.Insert (Curr_Node.Item);
            Results.Append (Itemset_Type'(Items => New_Prefix, Support => Curr_Node.Support));

            -- Generate the equivalence class for the extended prefix
            for J in I + 1 .. Natural (Class.Length) loop
               declare
                  Next_Node   : constant Equivalence_Node := Class.Element (J);
                  -- Support is calculated via Set Intersection of TID lists
                  New_TIDs    : constant TID_Sets.Set := 
                                  TID_Sets.Intersection (Curr_Node.TIDs, Next_Node.TIDs);
                  New_Support : constant Support_Count := Support_Count (New_TIDs.Length);
               begin
                  if New_Support >= Min_Sup then
                     New_Class.Append
                       (Equivalence_Node'(Item    => Next_Node.Item,
                                          TIDs    => New_TIDs,
                                          Support => New_Support));
                  end if;
               end;
            end loop;

            -- Recurse depth-first if the new class has viable frequent itemsets
            if not New_Class.Is_Empty then
               Eclat_Rec (New_Prefix, New_Class, Min_Sup, Results);
            end if;
         end;
      end loop;
   end Eclat_Rec;

   -----------------------------------------------------------------------------
   -- Mine_Standard
   -----------------------------------------------------------------------------
   function Mine_Standard
     (DB      : Vertical_DB;
      Min_Sup : Support_Count) return Itemset_Vectors.Vector
   is
      Results      : Itemset_Vectors.Vector;
      Root_Class   : Node_Vectors.Vector;
   begin
      if Min_Sup = 0 then
         raise Invalid_Min_Support with "Minimum support must be greater than 0.";
      end if;

      if DB.Data.Is_Empty then
         return Results;
      end if;

      -- Populate the initial equivalence class (Level 1 items)
      for Pos in DB.Data.Iterate loop
         declare
            Item_Key : constant Item_ID       := DB_Maps.Key (Pos);
            TID_Set  : constant TID_Sets.Set  := DB_Maps.Element (Pos);
            Sup      : constant Support_Count := Support_Count (TID_Set.Length);
         begin
            if Sup >= Min_Sup then
               Root_Class.Append (Equivalence_Node'(Item => Item_Key, TIDs => TID_Set, Support => Sup));
            end if;
         end;
      end loop;

      Eclat_Rec (Item_Sets.Empty_Set, Root_Class, Min_Sup, Results);
      return Results;
   end Mine_Standard;

   -----------------------------------------------------------------------------
   -- dEclat_Rec (Diffset Recursive Step for Level 3+)
   -----------------------------------------------------------------------------
   procedure dEclat_Rec
     (Prefix  : Item_Sets.Set;
      Class   : Node_Vectors.Vector;
      Min_Sup : Support_Count;
      Results : in out Itemset_Vectors.Vector)
   is
   begin
      for I in 1 .. Natural (Class.Length) loop
         declare
            Curr_Node  : constant Equivalence_Node := Class.Element (I);
            New_Prefix : Item_Sets.Set := Prefix;
            New_Class  : Node_Vectors.Vector;
         begin
            New_Prefix.Insert (Curr_Node.Item);
            Results.Append (Itemset_Type'(Items => New_Prefix, Support => Curr_Node.Support));

            for J in I + 1 .. Natural (Class.Length) loop
               declare
                  Next_Node   : constant Equivalence_Node := Class.Element (J);
                  -- For Level 3+, the Diffset of PXY is d(PY) \ d(PX)
                  -- Next_Node.TIDs represents d(PY), Curr_Node.TIDs represents d(PX)
                  New_Diffset : constant TID_Sets.Set := 
                                  TID_Sets.Difference (Next_Node.TIDs, Curr_Node.TIDs);
                  
                  -- Support(PXY) = Support(PX) - |d(PXY)|
                  Diff_Len    : constant Support_Count := Support_Count (New_Diffset.Length);
                  New_Support : constant Support_Count := Curr_Node.Support - Diff_Len;
               begin
                  if New_Support >= Min_Sup then
                     New_Class.Append
                       (Equivalence_Node'(Item    => Next_Node.Item,
                                          TIDs    => New_Diffset,
                                          Support => New_Support));
                  end if;
               end;
            end loop;

            if not New_Class.Is_Empty then
               dEclat_Rec (New_Prefix, New_Class, Min_Sup, Results);
            end if;
         end;
      end loop;
   end dEclat_Rec;

   -----------------------------------------------------------------------------
   -- dEclat_Level_1 (Transition from Standard TIDs to Diffsets)
   -----------------------------------------------------------------------------
   procedure dEclat_Level_1
     (Class   : Node_Vectors.Vector;
      Min_Sup : Support_Count;
      Results : in out Itemset_Vectors.Vector)
   is
   begin
      for I in 1 .. Natural (Class.Length) loop
         declare
            Curr_Node  : constant Equivalence_Node := Class.Element (I);
            New_Prefix : Item_Sets.Set := Item_Sets.Empty_Set;
            New_Class  : Node_Vectors.Vector;
         begin
            New_Prefix.Insert (Curr_Node.Item);
            Results.Append (Itemset_Type'(Items => New_Prefix, Support => Curr_Node.Support));

            for J in I + 1 .. Natural (Class.Length) loop
               declare
                  Next_Node   : constant Equivalence_Node := Class.Element (J);
                  -- For Level 2, the Diffset of XY is t(X) \ t(Y)
                  New_Diffset : constant TID_Sets.Set := 
                                  TID_Sets.Difference (Curr_Node.TIDs, Next_Node.TIDs);
                  
                  -- Support(XY) = Support(X) - |d(XY)|
                  Diff_Len    : constant Support_Count := Support_Count (New_Diffset.Length);
                  New_Support : constant Support_Count := Curr_Node.Support - Diff_Len;
               begin
                  if New_Support >= Min_Sup then
                     New_Class.Append
                       (Equivalence_Node'(Item    => Next_Node.Item,
                                          TIDs    => New_Diffset,
                                          Support => New_Support));
                  end if;
               end;
            end loop;

            if not New_Class.Is_Empty then
               -- Pass control to the purely Diffset-based recursion
               dEclat_Rec (New_Prefix, New_Class, Min_Sup, Results);
            end if;
         end;
      end loop;
   end dEclat_Level_1;

   -----------------------------------------------------------------------------
   -- Mine_Diffset
   -----------------------------------------------------------------------------
   function Mine_Diffset
     (DB      : Vertical_DB;
      Min_Sup : Support_Count) return Itemset_Vectors.Vector
   is
      Results    : Itemset_Vectors.Vector;
      Root_Class : Node_Vectors.Vector;
   begin
      if Min_Sup = 0 then
         raise Invalid_Min_Support with "Minimum support must be greater than 0.";
      end if;

      if DB.Data.Is_Empty then
         return Results;
      end if;

      -- Build initial Level 1 class using standard TID sets directly from DB
      for Pos in DB.Data.Iterate loop
         declare
            Item_Key : constant Item_ID       := DB_Maps.Key (Pos);
            TID_Set  : constant TID_Sets.Set  := DB_Maps.Element (Pos);
            Sup      : constant Support_Count := Support_Count (TID_Set.Length);
         begin
            if Sup >= Min_Sup then
               Root_Class.Append (Equivalence_Node'(Item => Item_Key, TIDs => TID_Set, Support => Sup));
            end if;
         end;
      end loop;

      dEclat_Level_1 (Root_Class, Min_Sup, Results);
      return Results;
   end Mine_Diffset;

end Eclat_Algorithm;
