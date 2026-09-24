pragma Ada_2022;
with Ada.Numerics.Elementary_Functions;
with Ada.Unchecked_Deallocation;

package body ID3 is

   package Class_Counts is new Ada.Containers.Ordered_Maps
     (Key_Type     => Class_ID,
      Element_Type => Natural);

   package Value_Datasets is new Ada.Containers.Ordered_Maps
     (Key_Type     => Value_ID,
      Element_Type => Dataset,
      "="          => Instance_Vectors."=");

   -----------------------------------------------------------------------------
   -- Helper: Finds the most frequent class in a dataset
   -----------------------------------------------------------------------------
   function Majority_Class (Data : Dataset) return Class_ID is
      Counts    : Class_Counts.Map;
      Max_Count : Natural := 0;
      Majority  : Class_ID := 0;
   begin
      for Inst of Data loop
         declare
            New_Count : Natural := 1;
         begin
            if Counts.Contains (Inst.Class) then
               New_Count := Counts.Element (Inst.Class) + 1;
            end if;
            Counts.Include (Inst.Class, New_Count);
            
            if New_Count > Max_Count then
               Max_Count := New_Count;
               Majority  := Inst.Class;
            end if;
         end;
      end loop;
      return Majority;
   end Majority_Class;

   -----------------------------------------------------------------------------
   -- Entropy calculation
   -----------------------------------------------------------------------------
   function Entropy (Data : Dataset) return Metric_Value is
      Counts : Class_Counts.Map;
      Total  : constant Metric_Value := Metric_Value (Data.Length);
      Result : Metric_Value := 0.0;
      Prob   : Metric_Value;
   begin
      if Data.Is_Empty then
         raise Empty_Dataset_Error with "Cannot calculate entropy of an empty dataset.";
      end if;

      for Inst of Data loop
         if Counts.Contains (Inst.Class) then
            Counts.Include (Inst.Class, Counts.Element (Inst.Class) + 1);
         else
            Counts.Insert (Inst.Class, 1);
         end if;
      end loop;

      for C in Counts.Iterate loop
         Prob := Metric_Value (Class_Counts.Element (C)) / Total;
         if Prob > 0.0 then
            Result := Result - (Prob * Metric_Value (Ada.Numerics.Elementary_Functions.Log (Float (Prob), 2.0)));
         end if;
      end loop;
      
      return Result;
   end Entropy;

   -----------------------------------------------------------------------------
   -- Shared logic to compute Information Gain and Gain Ratio
   -----------------------------------------------------------------------------
   procedure Calculate_Gains
     (Data  : Dataset;
      Attr  : Attribute_ID;
      Gain  : out Metric_Value;
      Ratio : out Metric_Value)
   is
      Base_Entropy : Metric_Value;
      Subsets      : Value_Datasets.Map;
      Total        : Metric_Value;
      Subset_Ent   : Metric_Value := 0.0;
      Intrinsic    : Metric_Value := 0.0;
      Prob         : Metric_Value;
   begin
      if Data.Is_Empty then
         raise Empty_Dataset_Error with "Cannot calculate gains of an empty dataset.";
      end if;

      Base_Entropy := Entropy (Data);
      Total        := Metric_Value (Data.Length);

      -- Partition the dataset by attribute values
      for Inst of Data loop
         if Attribute_Index (Attr) > Inst.Num_Attributes then
            raise Invalid_Data_Error with "Instance missing the specified attribute.";
         end if;
         
         declare
            Val : constant Value_ID := Inst.Attributes (Attr);
            Sub : Dataset;
         begin
            if Subsets.Contains (Val) then
               Sub := Subsets.Element (Val);
            end if;
            Sub.Append (Inst);
            Subsets.Include (Val, Sub);
         end;
      end loop;

      -- Calculate sub-entropy and intrinsic value
      for C in Subsets.Iterate loop
         declare
            Sub     : constant Dataset := Value_Datasets.Element (C);
            Sub_Len : constant Metric_Value := Metric_Value (Sub.Length);
         begin
            Prob := Sub_Len / Total;
            if Prob > 0.0 then
               Subset_Ent := Subset_Ent + (Prob * Entropy (Sub));
               Intrinsic  := Intrinsic - (Prob * Metric_Value (Ada.Numerics.Elementary_Functions.Log (Float (Prob), 2.0)));
            end if;
         end;
      end loop;

      Gain := Base_Entropy - Subset_Ent;
      
      if Intrinsic = 0.0 then
         Ratio := Gain;
      else
         Ratio := Gain / Intrinsic;
      end if;
   end Calculate_Gains;

   -----------------------------------------------------------------------------
   -- Public accessors for Gain variants
   -----------------------------------------------------------------------------
   function Information_Gain (Data : Dataset; Attr : Attribute_ID) return Metric_Value is
      Gain, Ratio : Metric_Value;
   begin
      Calculate_Gains (Data, Attr, Gain, Ratio);
      return Gain;
   end Information_Gain;

   function Gain_Ratio (Data : Dataset; Attr : Attribute_ID) return Metric_Value is
      Gain, Ratio : Metric_Value;
   begin
      Calculate_Gains (Data, Attr, Gain, Ratio);
      return Ratio;
   end Gain_Ratio;

   -----------------------------------------------------------------------------
   -- Build_Tree variant implementations
   -----------------------------------------------------------------------------
   function Build_Tree
     (Data       : Dataset;
      Attributes : Attribute_Set;
      Criterion  : Split_Criterion := Use_Information_Gain) return Tree
   is
      Majority : Class_ID;
      All_Same : Boolean := True;
      First_Cl : Class_ID;
   begin
      if Data.Is_Empty then
         raise Empty_Dataset_Error with "Cannot build tree from empty dataset.";
      end if;

      Majority := Majority_Class (Data);
      First_Cl := Data.First_Element.Class;

      -- 1. If all instances have the same class, return leaf
      for Inst of Data loop
         if Inst.Class /= First_Cl then
            All_Same := False;
            exit;
         end if;
      end loop;

      if All_Same then
         return new Tree_Node'(Kind => Leaf, Predicted_Class => First_Cl);
      end if;

      -- 2. If no more attributes, return majority leaf
      if Attributes.Is_Empty then
         return new Tree_Node'(Kind => Leaf, Predicted_Class => Majority);
      end if;

      -- 3. Select best attribute
      declare
         Best_Attr : Attribute_ID := Attributes.First_Element;
         Best_Val  : Metric_Value := -1.0;
         Subsets   : Value_Datasets.Map;
         Node      : Tree;
      begin
         for Attr of Attributes loop
            declare
               Gain, Ratio : Metric_Value;
               Val         : Metric_Value;
            begin
               Calculate_Gains (Data, Attr, Gain, Ratio);
               if Criterion = Use_Information_Gain then
                  Val := Gain;
               else
                  Val := Ratio;
               end if;
               
               if Val > Best_Val then
                  Best_Val  := Val;
                  Best_Attr := Attr;
               end if;
            end;
         end loop;

         -- Initialize decision node
         Node := new Tree_Node'(Kind          => Decision,
                                Attribute     => Best_Attr,
                                Branches      => Value_Tree_Maps.Empty_Map,
                                Default_Class => Majority);

         -- 4. Partition data by the best attribute
         for Inst of Data loop
            declare
               Val : constant Value_ID := Inst.Attributes (Best_Attr);
               Sub : Dataset;
            begin
               if Subsets.Contains (Val) then
                  Sub := Subsets.Element (Val);
               end if;
               Sub.Append (Inst);
               Subsets.Include (Val, Sub);
            end;
         end loop;

         -- 5. Recurse for each branch
         declare
            Remaining_Attrs : Attribute_Set := Attributes;
         begin
            Remaining_Attrs.Exclude (Best_Attr);
            
            for C in Subsets.Iterate loop
               declare
                  Val   : constant Value_ID := Value_Datasets.Key (C);
                  Sub   : constant Dataset := Value_Datasets.Element (C);
                  Child : constant Tree := Build_Tree (Sub, Remaining_Attrs, Criterion);
               begin
                  Node.Branches.Insert (Val, Child);
               end;
            end loop;
         end;

         return Node;
      end;
   end Build_Tree;

   -----------------------------------------------------------------------------
   -- Predictions
   -----------------------------------------------------------------------------
   function Predict (Model : Tree; Inst : Instance) return Class_ID is
   begin
      if Model = null then
         raise Prediction_Error with "Cannot predict with a null model.";
      end if;

      case Model.Kind is
         when Leaf =>
            return Model.Predicted_Class;
         when Decision =>
            if Attribute_Index (Model.Attribute) > Inst.Num_Attributes then
               raise Invalid_Data_Error with "Instance missing attribute required for prediction.";
            end if;

            declare
               Val : constant Value_ID := Inst.Attributes (Model.Attribute);
            begin
               if Model.Branches.Contains (Val) then
                  return Predict (Model.Branches.Element (Val), Inst);
               else
                  -- Handle unseen categorical values gracefully
                  return Model.Default_Class;
               end if;
            end;
      end case;
   end Predict;

   -----------------------------------------------------------------------------
   -- Recursive memory deallocation
   -----------------------------------------------------------------------------
   procedure Free_Tree (T : in out Tree) is
      procedure Free is new Ada.Unchecked_Deallocation (Tree_Node, Tree);
   begin
      if T /= null then
         case T.Kind is
            when Leaf =>
               null;
            when Decision =>
               -- Safely free children and remove them from map
               while not T.Branches.Is_Empty loop
                  declare
                     C     : Value_Tree_Maps.Cursor := T.Branches.First;
                     Child : Tree := Value_Tree_Maps.Element (C);
                  begin
                     Free_Tree (Child);
                     T.Branches.Delete (C);
                  end;
               end loop;
         end case;
         Free (T);
      end if;
   end Free_Tree;

end ID3;
