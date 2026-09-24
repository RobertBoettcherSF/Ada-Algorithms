with Ada.Numerics.Elementary_Functions;
with Ada.Unchecked_Deallocation;

package body Decision_Tree_Learning is

   use Ada.Numerics.Elementary_Functions;

   -- Memory deallocation handler
   procedure Free is new Ada.Unchecked_Deallocation (Tree_Node, Tree_Node_Access);

   procedure Free_Tree (Tree : in out Tree_Node_Access) is
   begin
      if Tree /= null then
         if Tree.Kind = Split then
            Free_Tree (Tree.Left_Child);
            Free_Tree (Tree.Right_Child);
         end if;
         Free (Tree);
      end if;
   end Free_Tree;

   -- Internal array type to slice subsets without copying data
   type Index_Array is array (Positive range <>) of Instance_Index;

   -- Helper: Determine the majority class in a given subset
   function Majority_Class (Y : Label_Vector; Subset : Index_Array) return Class_Label is
      Max_C : Class_Label := 1;
   begin
      for I of Subset loop
         if Y (I) > Max_C then
            Max_C := Y (I);
         end if;
      end loop;

      declare
         Counts    : array (1 .. Max_C) of Natural := [others => 0];
         Best_C    : Class_Label := 1;
         Max_Count : Natural := 0;
      begin
         for I of Subset loop
            Counts (Y (I)) := Counts (Y (I)) + 1;
         end loop;
         for C in Counts'Range loop
            if Counts (C) > Max_Count then
               Max_Count := Counts (C);
               Best_C := C;
            end if;
         end loop;
         return Best_C;
      end;
   end Majority_Class;

   -- Helper: Compute Information Gain (Entropy)
   function Calculate_Entropy (Y : Label_Vector; Subset : Index_Array) return Float is
      Max_C : Class_Label := 1;
      Total : constant Float := Float (Subset'Length);
      Ent   : Float := 0.0;
   begin
      if Subset'Length = 0 then
         return 0.0;
      end if;

      for I of Subset loop
         if Y (I) > Max_C then
            Max_C := Y (I);
         end if;
      end loop;

      declare
         Counts : array (1 .. Max_C) of Natural := [others => 0];
      begin
         for I of Subset loop
            Counts (Y (I)) := Counts (Y (I)) + 1;
         end loop;

         for C of Counts loop
            if C > 0 then
               declare
                  P : constant Float := Float (C) / Total;
               begin
                  Ent := Ent - (P * Log (P, 2.0));
               end;
            end if;
         end loop;
      end;
      return Ent;
   end Calculate_Entropy;

   -- Helper: Compute Gini Impurity
   function Calculate_Gini (Y : Label_Vector; Subset : Index_Array) return Float is
      Max_C : Class_Label := 1;
      Total : constant Float := Float (Subset'Length);
      Gini  : Float := 1.0;
   begin
      if Subset'Length = 0 then
         return 0.0;
      end if;

      for I of Subset loop
         if Y (I) > Max_C then
            Max_C := Y (I);
         end if;
      end loop;

      declare
         Counts : array (1 .. Max_C) of Natural := [others => 0];
      begin
         for I of Subset loop
            Counts (Y (I)) := Counts (Y (I)) + 1;
         end loop;

         for C of Counts loop
            if C > 0 then
               Gini := Gini - (Float (C) / Total) ** 2;
            end if;
         end loop;
      end;
      return Gini;
   end Calculate_Gini;

   -- Recursive function to construct the tree structure
   function Build_Tree
     (X                 : Feature_Matrix;
      Y                 : Label_Vector;
      Subset            : Index_Array;
      Criterion         : Split_Criterion;
      Max_Depth         : Natural;
      Min_Samples_Split : Positive;
      Current_Depth     : Natural) return Tree_Node_Access
   is
      Is_Pure     : Boolean := True;
      First_Label : Class_Label;
   begin
      -- Base cases and thresholds
      if Subset'Length = 0 then
         -- Should never be reached via logical flow, but safeguarded.
         return null; 
      end if;

      First_Label := Y (Subset (Subset'First));
      for I in Subset'First + 1 .. Subset'Last loop
         if Y (Subset (I)) /= First_Label then
            Is_Pure := False;
            exit;
         end if;
      end loop;

      -- If leaf conditions are met, create a leaf node
      if Is_Pure or else Current_Depth >= Max_Depth or else Subset'Length < Min_Samples_Split then
         return new Tree_Node'(Kind => Leaf, Prediction => Majority_Class (Y, Subset));
      end if;

      -- Iterate to find the best feature and value to split on
      declare
         Best_Gain          : Float := -1.0;
         Best_F             : Feature_Index := X'First (2);
         Best_V             : Feature_Value := 0.0;
         Best_Left_Count    : Natural := 0;
         Best_Right_Count   : Natural := 0;
         Best_Left_Indices  : Index_Array (1 .. Subset'Length);
         Best_Right_Indices : Index_Array (1 .. Subset'Length);

         Current_Impurity : Float;
      begin
         if Criterion = Gini_Impurity then
            Current_Impurity := Calculate_Gini (Y, Subset);
         else
            Current_Impurity := Calculate_Entropy (Y, Subset);
         end if;

         -- Check all features
         for F in X'Range (2) loop
            -- Check all observed values as potential split thresholds
            for I of Subset loop
               declare
                  Split_Val     : constant Feature_Value := X (I, F);
                  Left_Indices  : Index_Array (1 .. Subset'Length);
                  Right_Indices : Index_Array (1 .. Subset'Length);
                  LC, RC        : Natural := 0;
                  Imp_L, Imp_R, Gain : Float;
               begin
                  -- Partition indices
                  for J of Subset loop
                     if X (J, F) <= Split_Val then
                        LC := LC + 1;
                        Left_Indices (LC) := J;
                     else
                        RC := RC + 1;
                        Right_Indices (RC) := J;
                     end if;
                  end loop;

                  if LC > 0 and RC > 0 then
                     -- Compute impurities of the splits
                     if Criterion = Gini_Impurity then
                        Imp_L := Calculate_Gini (Y, Left_Indices (1 .. LC));
                        Imp_R := Calculate_Gini (Y, Right_Indices (1 .. RC));
                     else
                        Imp_L := Calculate_Entropy (Y, Left_Indices (1 .. LC));
                        Imp_R := Calculate_Entropy (Y, Right_Indices (1 .. RC));
                     end if;

                     -- Weighted gain calculation
                     Gain := Current_Impurity -
                             (Float (LC) / Float (Subset'Length) * Imp_L +
                              Float (RC) / Float (Subset'Length) * Imp_R);

                     if Gain > Best_Gain then
                        Best_Gain := Gain;
                        Best_F    := F;
                        Best_V    := Split_Val;
                        Best_Left_Count  := LC;
                        Best_Right_Count := RC;
                        Best_Left_Indices (1 .. LC)  := Left_Indices (1 .. LC);
                        Best_Right_Indices (1 .. RC) := Right_Indices (1 .. RC);
                     end if;
                  end if;
               end;
            end loop;
         end loop;

         -- If a valid split is found, create an internal split node.
         -- Note: Best_Gain >= 0.0 allows learning non-linear XOR splits that initially yield 0 gain.
         if Best_Gain >= 0.0 and Best_Left_Count > 0 and Best_Right_Count > 0 then
            return new Tree_Node'
              (Kind          => Split,
               Split_Feature => Best_F,
               Split_Value   => Best_V,
               Left_Child    => Build_Tree (X, Y, Best_Left_Indices (1 .. Best_Left_Count),
                                            Criterion, Max_Depth, Min_Samples_Split, Current_Depth + 1),
               Right_Child   => Build_Tree (X, Y, Best_Right_Indices (1 .. Best_Right_Count),
                                            Criterion, Max_Depth, Min_Samples_Split, Current_Depth + 1));
         else
            return new Tree_Node'(Kind => Leaf, Prediction => Majority_Class (Y, Subset));
         end if;
      end;
   end Build_Tree;

   function Train
     (X                 : Feature_Matrix;
      Y                 : Label_Vector;
      Criterion         : Split_Criterion := Gini_Impurity;
      Max_Depth         : Natural := 10;
      Min_Samples_Split : Positive := 2) return Tree_Node_Access
   is
   begin
      if X'Length (1) = 0 then
         raise Empty_Dataset_Error;
      end if;

      if X'First (1) /= Y'First or else X'Last (1) /= Y'Last then
         raise Mismatched_Dimensions_Error;
      end if;

      declare
         Initial_Subset : Index_Array (1 .. X'Length (1));
         Idx            : Instance_Index := X'First (1);
      begin
         for I in Initial_Subset'Range loop
            Initial_Subset (I) := Idx;
            Idx := Idx + 1;
         end loop;
         return Build_Tree (X, Y, Initial_Subset, Criterion, Max_Depth, Min_Samples_Split, 0);
      end;
   end Train;

   function Predict
     (Tree : Tree_Node_Access;
      X    : Feature_Array) return Class_Label
   is
      Node : Tree_Node_Access := Tree;
   begin
      if Node = null then
         raise Null_Tree_Error;
      end if;

      loop
         case Node.Kind is
            when Leaf =>
               return Node.Prediction;
            when Split =>
               if Node.Split_Feature < X'First or else Node.Split_Feature > X'Last then
                  raise Invalid_Feature_Error;
               end if;

               if X (Node.Split_Feature) <= Node.Split_Value then
                  Node := Node.Left_Child;
               else
                  Node := Node.Right_Child;
               end if;
         end case;
      end loop;
   end Predict;

   function Train_ID3_Variant
     (X         : Feature_Matrix;
      Y         : Label_Vector;
      Max_Depth : Natural := 10) return Tree_Node_Access is
   begin
      return Train (X, Y, Information_Gain, Max_Depth, 2);
   end Train_ID3_Variant;

   function Train_CART_Variant
     (X         : Feature_Matrix;
      Y         : Label_Vector;
      Max_Depth : Natural := 10) return Tree_Node_Access is
   begin
      return Train (X, Y, Gini_Impurity, Max_Depth, 2);
   end Train_CART_Variant;

end Decision_Tree_Learning;
