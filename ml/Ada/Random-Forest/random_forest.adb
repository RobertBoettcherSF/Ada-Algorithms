with Ada.Numerics.Float_Random;
with Ada.Numerics.Elementary_Functions;

package body Random_Forest is
   use Ada.Numerics.Float_Random;
   use Ada.Numerics.Elementary_Functions;

   type Index_Array is array (Positive range <>) of Positive;

   -----------------------------------------------------------------------------
   -- Helper Functions
   -----------------------------------------------------------------------------
   
   -- Shuffle an array of indices in-place
   procedure Shuffle (Arr : in out Index_Array; Gen : in out Generator) is
      J : Positive;
      Temp : Positive;
      Rand_Val : Float;
   begin
      for I in reverse Arr'First + 1 .. Arr'Last loop
         Rand_Val := Random (Gen);
         J := Arr'First + Integer (Float'Truncation (Rand_Val * Float (I - Arr'First + 1)));
         if J > I then J := I; end if;
         Temp := Arr (I);
         Arr (I) := Arr (J);
         Arr (J) := Temp;
      end loop;
   end Shuffle;

   -- Select random feature subspace (sqrt of total features)
   function Get_Subspace (Total_Features : Positive; Gen : in out Generator) return Index_Array is
      Sub_Size : constant Positive := Positive (Float'Max (1.0, Float'Rounding (Sqrt (Float (Total_Features)))));
      All_Feats : Index_Array (1 .. Total_Features);
   begin
      for I in All_Feats'Range loop
         All_Feats (I) := I;
      end loop;
      Shuffle (All_Feats, Gen);
      return All_Feats (1 .. Sub_Size);
   end Get_Subspace;

   -- Calculate Gini Impurity for a subset of classes
   function Gini (Indices : Index_Array; Labels : Class_Array) return Float is
      Score : Float := 1.0;
      Min_L : Class_Label := Class_Label'Last;
      Max_L : Class_Label := Class_Label'First;
      Prob  : Float;
   begin
      if Indices'Length = 0 then return 0.0; end if;
      
      for Idx of Indices loop
         if Labels (Idx) < Min_L then Min_L := Labels (Idx); end if;
         if Labels (Idx) > Max_L then Max_L := Labels (Idx); end if;
      end loop;
      
      declare
         Counts : array (Min_L .. Max_L) of Natural := [others => 0];
      begin
         for Idx of Indices loop
            Counts (Labels (Idx)) := Counts (Labels (Idx)) + 1;
         end loop;
         
         for C in Counts'Range loop
            if Counts (C) > 0 then
               Prob := Float (Counts (C)) / Float (Indices'Length);
               Score := Score - Prob * Prob;
            end if;
         end loop;
      end;
      return Score;
   end Gini;

   -- Calculate Variance for a subset of targets
   function Variance (Indices : Index_Array; Targets : Target_Array) return Float is
      Sum     : Float := 0.0;
      Mean    : Float := 0.0;
      Var_Sum : Float := 0.0;
   begin
      if Indices'Length <= 1 then return 0.0; end if;
      for Idx of Indices loop
         Sum := Sum + Float (Targets (Idx));
      end loop;
      Mean := Sum / Float (Indices'Length);
      
      for Idx of Indices loop
         Var_Sum := Var_Sum + (Float (Targets (Idx)) - Mean) ** 2;
      end loop;
      return Var_Sum / Float (Indices'Length);
   end Variance;

   -----------------------------------------------------------------------------
   -- Classification Tree Builder
   -----------------------------------------------------------------------------
   procedure Build_Classification_Node
     (Tree      : in out Decision_Tree;
      Node_Idx  : Positive;
      Data      : Matrix;
      Labels    : Class_Array;
      Indices   : Index_Array;
      Depth     : Natural;
      Max_Depth : Positive;
      Variant   : Forest_Variant;
      Gen       : in out Generator)
   is
      Is_Pure      : Boolean := True;
      First_Label  : Class_Label;
      Best_Score   : Float := Float'Last;
      Best_F       : Positive := 1;
      Best_Thresh  : Feature_Value := 0.0;
      Found_Split  : Boolean := False;
      
      Subspace     : constant Index_Array := Get_Subspace (Data'Length (2), Gen);
      Min_Val, Max_Val : Feature_Value;
      Test_Thresh  : Feature_Value;
      
      Left_Count, Right_Count : Natural;
      Score : Float;
   begin
      -- Check purity
      if Indices'Length > 0 then
         First_Label := Labels (Indices (Indices'First));
         for Idx of Indices loop
            if Labels (Idx) /= First_Label then
               Is_Pure := False;
               exit;
            end if;
         end loop;
      end if;

      -- Stop conditions
      if Depth = Max_Depth or else Indices'Length <= 1 or else Is_Pure or else Tree.Count + 2 > Max_Nodes_Per_Tree then
         Tree.Nodes (Node_Idx).Is_Leaf := True;
         -- Mode calculation (simplified to most frequent in bounding range)
         if Indices'Length > 0 then
            declare
               Min_L : Class_Label := Class_Label'Last;
               Max_L : Class_Label := Class_Label'First;
               Best_C : Class_Label := First_Label;
               Max_Cnt : Natural := 0;
            begin
               for Idx of Indices loop
                  if Labels (Idx) < Min_L then Min_L := Labels (Idx); end if;
                  if Labels (Idx) > Max_L then Max_L := Labels (Idx); end if;
               end loop;
               declare
                  Counts : array (Min_L .. Max_L) of Natural := [others => 0];
               begin
                  for Idx of Indices loop
                     Counts (Labels (Idx)) := Counts (Labels (Idx)) + 1;
                  end loop;
                  for C in Counts'Range loop
                     if Counts (C) > Max_Cnt then
                        Max_Cnt := Counts (C);
                        Best_C := C;
                     end if;
                  end loop;
                  Tree.Nodes (Node_Idx).Class_Pred := Best_C;
               end;
            end;
         end if;
         return;
      end if;

      -- Find best split
      for F of Subspace loop
         Min_Val := Feature_Value'Last;
         Max_Val := Feature_Value'First;
         for Idx of Indices loop
            if Data (Idx, F) < Min_Val then Min_Val := Data (Idx, F); end if;
            if Data (Idx, F) > Max_Val then Max_Val := Data (Idx, F); end if;
         end loop;
         
         if Min_Val < Max_Val then
            declare
               -- For standard RF, we sample 10 random values within range as thresholds to optimize speed.
               -- For Extra Trees, we sample exactly 1 completely random threshold.
               Trials : constant Positive := (if Variant = Extra_Trees then 1 else 10);
            begin
               for T in 1 .. Trials loop
                  if Variant = Extra_Trees then
                     Test_Thresh := Min_Val + Feature_Value (Random (Gen) * Float (Max_Val - Min_Val));
                  else
                     -- Randomly pick an existing value for Standard RF approximation
                     Test_Thresh := Data (Indices (Indices'First + Integer (Float'Truncation (Random (Gen) * Float (Indices'Length - 1)))), F);
                  end if;
                  
                  Left_Count := 0;
                  Right_Count := 0;
                  for Idx of Indices loop
                     if Data (Idx, F) <= Test_Thresh then
                        Left_Count := Left_Count + 1;
                     else
                        Right_Count := Right_Count + 1;
                     end if;
                  end loop;
                  
                  if Left_Count > 0 and Right_Count > 0 then
                     declare
                        Left_Inds  : Index_Array (1 .. Left_Count);
                        Right_Inds : Index_Array (1 .. Right_Count);
                        L_Idx : Natural := 0;
                        R_Idx : Natural := 0;
                     begin
                        for Idx of Indices loop
                           if Data (Idx, F) <= Test_Thresh then
                              L_Idx := L_Idx + 1;
                              Left_Inds (L_Idx) := Idx;
                           else
                              R_Idx := R_Idx + 1;
                              Right_Inds (R_Idx) := Idx;
                           end if;
                        end loop;
                        
                        Score := (Float (Left_Count) * Gini (Left_Inds, Labels) + 
                                  Float (Right_Count) * Gini (Right_Inds, Labels)) / Float (Indices'Length);
                        
                        if Score < Best_Score then
                           Best_Score := Score;
                           Best_F := F;
                           Best_Thresh := Test_Thresh;
                           Found_Split := True;
                        end if;
                     end;
                  end if;
               end loop;
            end;
         end if;
      end loop;

      if not Found_Split then
         Tree.Nodes (Node_Idx).Is_Leaf := True;
         Tree.Nodes (Node_Idx).Class_Pred := First_Label;
         return;
      end if;

      -- Apply best split
      Tree.Nodes (Node_Idx).Is_Leaf := False;
      Tree.Nodes (Node_Idx).Feature_Idx := Best_F;
      Tree.Nodes (Node_Idx).Threshold := Best_Thresh;

      declare
         L_Count : Natural := 0;
         R_Count : Natural := 0;
      begin
         for Idx of Indices loop
            if Data (Idx, Best_F) <= Best_Thresh then
               L_Count := L_Count + 1;
            else
               R_Count := R_Count + 1;
            end if;
         end loop;
         
         declare
            Left_Inds  : Index_Array (1 .. L_Count);
            Right_Inds : Index_Array (1 .. R_Count);
            L_Idx : Natural := 0;
            R_Idx : Natural := 0;
         begin
            for Idx of Indices loop
               if Data (Idx, Best_F) <= Best_Thresh then
                  L_Idx := L_Idx + 1;
                  Left_Inds (L_Idx) := Idx;
               else
                  R_Idx := R_Idx + 1;
                  Right_Inds (R_Idx) := Idx;
               end if;
            end loop;
            
            Tree.Count := Tree.Count + 1;
            Tree.Nodes (Node_Idx).Left_Child := Tree.Count;
            Build_Classification_Node (Tree, Tree.Count, Data, Labels, Left_Inds, Depth + 1, Max_Depth, Variant, Gen);
            
            Tree.Count := Tree.Count + 1;
            Tree.Nodes (Node_Idx).Right_Child := Tree.Count;
            Build_Classification_Node (Tree, Tree.Count, Data, Labels, Right_Inds, Depth + 1, Max_Depth, Variant, Gen);
         end;
      end;
   end Build_Classification_Node;

   -----------------------------------------------------------------------------
   -- Regression Tree Builder
   -----------------------------------------------------------------------------
   procedure Build_Regression_Node
     (Tree      : in out Decision_Tree;
      Node_Idx  : Positive;
      Data      : Matrix;
      Targets   : Target_Array;
      Indices   : Index_Array;
      Depth     : Natural;
      Max_Depth : Positive;
      Variant   : Forest_Variant;
      Gen       : in out Generator)
   is
      Is_Pure      : Boolean := True;
      First_Target : Target_Value;
      Best_Score   : Float := Float'Last;
      Best_F       : Positive := 1;
      Best_Thresh  : Feature_Value := 0.0;
      Found_Split  : Boolean := False;
      
      Subspace     : constant Index_Array := Get_Subspace (Data'Length (2), Gen);
      Min_Val, Max_Val : Feature_Value;
      Test_Thresh  : Feature_Value;
      
      Left_Count, Right_Count : Natural;
      Score : Float;
   begin
      if Indices'Length > 0 then
         First_Target := Targets (Indices (Indices'First));
         for Idx of Indices loop
            if Targets (Idx) /= First_Target then
               Is_Pure := False;
               exit;
            end if;
         end loop;
      end if;

      if Depth = Max_Depth or else Indices'Length <= 1 or else Is_Pure or else Tree.Count + 2 > Max_Nodes_Per_Tree then
         Tree.Nodes (Node_Idx).Is_Leaf := True;
         if Indices'Length > 0 then
            declare
               Sum : Float := 0.0;
            begin
               for Idx of Indices loop
                  Sum := Sum + Float (Targets (Idx));
               end loop;
               Tree.Nodes (Node_Idx).Value_Pred := Target_Value (Sum / Float (Indices'Length));
            end;
         end if;
         return;
      end if;

      for F of Subspace loop
         Min_Val := Feature_Value'Last;
         Max_Val := Feature_Value'First;
         for Idx of Indices loop
            if Data (Idx, F) < Min_Val then Min_Val := Data (Idx, F); end if;
            if Data (Idx, F) > Max_Val then Max_Val := Data (Idx, F); end if;
         end loop;
         
         if Min_Val < Max_Val then
            declare
               Trials : constant Positive := (if Variant = Extra_Trees then 1 else 10);
            begin
               for T in 1 .. Trials loop
                  if Variant = Extra_Trees then
                     Test_Thresh := Min_Val + Feature_Value (Random (Gen) * Float (Max_Val - Min_Val));
                  else
                     Test_Thresh := Data (Indices (Indices'First + Integer (Float'Truncation (Random (Gen) * Float (Indices'Length - 1)))), F);
                  end if;
                  
                  Left_Count := 0;
                  Right_Count := 0;
                  for Idx of Indices loop
                     if Data (Idx, F) <= Test_Thresh then
                        Left_Count := Left_Count + 1;
                     else
                        Right_Count := Right_Count + 1;
                     end if;
                  end loop;
                  
                  if Left_Count > 0 and Right_Count > 0 then
                     declare
                        Left_Inds  : Index_Array (1 .. Left_Count);
                        Right_Inds : Index_Array (1 .. Right_Count);
                        L_Idx : Natural := 0;
                        R_Idx : Natural := 0;
                     begin
                        for Idx of Indices loop
                           if Data (Idx, F) <= Test_Thresh then
                              L_Idx := L_Idx + 1;
                              Left_Inds (L_Idx) := Idx;
                           else
                              R_Idx := R_Idx + 1;
                              Right_Inds (R_Idx) := Idx;
                           end if;
                        end loop;
                        
                        Score := (Float (Left_Count) * Variance (Left_Inds, Targets) + 
                                  Float (Right_Count) * Variance (Right_Inds, Targets)) / Float (Indices'Length);
                        
                        if Score < Best_Score then
                           Best_Score := Score;
                           Best_F := F;
                           Best_Thresh := Test_Thresh;
                           Found_Split := True;
                        end if;
                     end;
                  end if;
               end loop;
            end;
         end if;
      end loop;

      if not Found_Split then
         Tree.Nodes (Node_Idx).Is_Leaf := True;
         Tree.Nodes (Node_Idx).Value_Pred := First_Target;
         return;
      end if;

      Tree.Nodes (Node_Idx).Is_Leaf := False;
      Tree.Nodes (Node_Idx).Feature_Idx := Best_F;
      Tree.Nodes (Node_Idx).Threshold := Best_Thresh;

      declare
         L_Count : Natural := 0;
         R_Count : Natural := 0;
      begin
         for Idx of Indices loop
            if Data (Idx, Best_F) <= Best_Thresh then
               L_Count := L_Count + 1;
            else
               R_Count := R_Count + 1;
            end if;
         end loop;
         
         declare
            Left_Inds  : Index_Array (1 .. L_Count);
            Right_Inds : Index_Array (1 .. R_Count);
            L_Idx : Natural := 0;
            R_Idx : Natural := 0;
         begin
            for Idx of Indices loop
               if Data (Idx, Best_F) <= Best_Thresh then
                  L_Idx := L_Idx + 1;
                  Left_Inds (L_Idx) := Idx;
               else
                  R_Idx := R_Idx + 1;
                  Right_Inds (R_Idx) := Idx;
               end if;
            end loop;
            
            Tree.Count := Tree.Count + 1;
            Tree.Nodes (Node_Idx).Left_Child := Tree.Count;
            Build_Regression_Node (Tree, Tree.Count, Data, Targets, Left_Inds, Depth + 1, Max_Depth, Variant, Gen);
            
            Tree.Count := Tree.Count + 1;
            Tree.Nodes (Node_Idx).Right_Child := Tree.Count;
            Build_Regression_Node (Tree, Tree.Count, Data, Targets, Right_Inds, Depth + 1, Max_Depth, Variant, Gen);
         end;
      end;
   end Build_Regression_Node;

   -----------------------------------------------------------------------------
   -- API Implementation
   -----------------------------------------------------------------------------

   function Train_Classifier
     (Data      : Matrix;
      Labels    : Class_Array;
      Num_Trees : Positive;
      Max_Depth : Positive;
      Variant   : Forest_Variant := Standard_Random_Forest) return Classification_Forest
   is
      Result : Classification_Forest (Num_Trees);
      Gen    : Generator;
      N_Rows : constant Positive := Data'Length (1);
      Boot_Inds : Index_Array (1 .. N_Rows);
   begin
      Reset (Gen);
      for T in 1 .. Num_Trees loop
         -- Bootstrap sampling
         for I in Boot_Inds'Range loop
            Boot_Inds (I) := Data'First (1) + Integer (Float'Truncation (Random (Gen) * Float (N_Rows)));
            if Boot_Inds (I) > Data'Last (1) then Boot_Inds (I) := Data'Last (1); end if;
         end loop;
         
         Result.Trees (T).Count := 1;
         Build_Classification_Node (Result.Trees (T), 1, Data, Labels, Boot_Inds, 1, Max_Depth, Variant, Gen);
      end loop;
      return Result;
   end Train_Classifier;

   function Predict_Class
     (Forest : Classification_Forest;
      Sample : Feature_Vector) return Class_Label
   is
      Preds  : Class_Array (1 .. Forest.Num_Trees);
      Curr   : Natural;
      Best_C : Class_Label;
      Max_C  : Natural := 0;
      Cnt    : Natural;
   begin
      for T in 1 .. Forest.Num_Trees loop
         Curr := 1;
         while not Forest.Trees (T).Nodes (Curr).Is_Leaf loop
            if Sample (Forest.Trees (T).Nodes (Curr).Feature_Idx) <= Forest.Trees (T).Nodes (Curr).Threshold then
               Curr := Forest.Trees (T).Nodes (Curr).Left_Child;
            else
               Curr := Forest.Trees (T).Nodes (Curr).Right_Child;
            end if;
            exit when Curr = 0; -- Safety fallback
         end loop;
         Preds (T) := Forest.Trees (T).Nodes (Curr).Class_Pred;
      end loop;

      -- Find mode (majority vote)
      Best_C := Preds (1);
      for I in Preds'Range loop
         Cnt := 0;
         for J in Preds'Range loop
            if Preds (J) = Preds (I) then
               Cnt := Cnt + 1;
            end if;
         end loop;
         if Cnt > Max_C then
            Max_C := Cnt;
            Best_C := Preds (I);
         end if;
      end loop;
      
      return Best_C;
   end Predict_Class;

   function Train_Regressor
     (Data      : Matrix;
      Targets   : Target_Array;
      Num_Trees : Positive;
      Max_Depth : Positive;
      Variant   : Forest_Variant := Standard_Random_Forest) return Regression_Forest
   is
      Result : Regression_Forest (Num_Trees);
      Gen    : Generator;
      N_Rows : constant Positive := Data'Length (1);
      Boot_Inds : Index_Array (1 .. N_Rows);
   begin
      Reset (Gen);
      for T in 1 .. Num_Trees loop
         for I in Boot_Inds'Range loop
            Boot_Inds (I) := Data'First (1) + Integer (Float'Truncation (Random (Gen) * Float (N_Rows)));
            if Boot_Inds (I) > Data'Last (1) then Boot_Inds (I) := Data'Last (1); end if;
         end loop;
         
         Result.Trees (T).Count := 1;
         Build_Regression_Node (Result.Trees (T), 1, Data, Targets, Boot_Inds, 1, Max_Depth, Variant, Gen);
      end loop;
      return Result;
   end Train_Regressor;

   function Predict_Value
     (Forest : Regression_Forest;
      Sample : Feature_Vector) return Target_Value
   is
      Sum  : Float := 0.0;
      Curr : Natural;
   begin
      for T in 1 .. Forest.Num_Trees loop
         Curr := 1;
         while not Forest.Trees (T).Nodes (Curr).Is_Leaf loop
            if Sample (Forest.Trees (T).Nodes (Curr).Feature_Idx) <= Forest.Trees (T).Nodes (Curr).Threshold then
               Curr := Forest.Trees (T).Nodes (Curr).Left_Child;
            else
               Curr := Forest.Trees (T).Nodes (Curr).Right_Child;
            end if;
            exit when Curr = 0;
         end loop;
         Sum := Sum + Float (Forest.Trees (T).Nodes (Curr).Value_Pred);
      end loop;
      
      return Target_Value (Sum / Float (Forest.Num_Trees));
   end Predict_Value;

end Random_Forest;
