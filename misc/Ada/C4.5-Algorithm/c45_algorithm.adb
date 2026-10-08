with Ada.Numerics.Elementary_Functions;
with Ada.Unchecked_Deallocation;

package body C45_Algorithm is

   --  Memory management procedures
   procedure Free_Children is new Ada.Unchecked_Deallocation (Children_Array, Children_Access);
   procedure Free_Node is new Ada.Unchecked_Deallocation (Decision_Tree_Node, Decision_Tree);

   function Is_Null (Tree : Decision_Tree) return Boolean is
   begin
      return Tree = null;
   end Is_Null;

   --  Safe Log2 to prevent domain errors
   function Log2 (X : Float) return Float is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Ada.Numerics.Elementary_Functions.Log (X, 2.0);
      end if;
   end Log2;

   --  Calculates Shannon Entropy of a given dataset
   function Calculate_Entropy (Data : Dataset) return Float is
      Counts   : array (Class_Label range 0 .. 10_000) of Natural := [others => 0];
      Total    : constant Float := Float (Data'Length);
      Prob     : Float;
      Entropy  : Float := 0.0;
   begin
      for I in Data'Range loop
         Counts (Data (I).Class) := Counts (Data (I).Class) + 1;
      end loop;

      for C in Counts'Range loop
         if Counts (C) > 0 then
            Prob := Float (Counts (C)) / Total;
            Entropy := Entropy - (Prob * Log2 (Prob));
         end if;
      end loop;

      return Entropy;
   end Calculate_Entropy;

   --  Finds the most frequent class in a dataset (majority voting)
   function Majority_Class (Data : Dataset) return Class_Label is
      Counts : array (Class_Label range 0 .. 10_000) of Natural := [others => 0];
      Max_Count : Natural := 0;
      Best_Class : Class_Label := 0;
   begin
      if Data'Length = 0 then
         return 0;
      end if;
      
      for I in Data'Range loop
         Counts (Data (I).Class) := Counts (Data (I).Class) + 1;
         if Counts (Data (I).Class) > Max_Count then
            Max_Count := Counts (Data (I).Class);
            Best_Class := Data (I).Class;
         end if;
      end loop;
      return Best_Class;
   end Majority_Class;

   --  Internal recursive builder with configuration flags
   function Build_Internal
     (Data           : Dataset;
      Attrs          : Attribute_Set;
      Handle_Missing : Boolean) return Decision_Tree
   is
      Current_Entropy : Float;
      Best_Gain       : Float := -1.0;
      Best_Attr_Idx   : Attribute_Index := Attrs'First;
      Best_Threshold  : Attribute_Value := 0.0;
      Is_Pure         : Boolean := True;
      First_Class     : Class_Label;
   begin
      --  Base Case 1: Empty Dataset (Fallback, handled safely by parent usually)
      if Data'Length = 0 then
         return new Decision_Tree_Node'(Kind => Leaf, Predicted_Class => 0);
      end if;

      --  Base Case 2: All instances have the same class
      First_Class := Data (Data'First).Class;
      for I in Data'Range loop
         if Data (I).Class /= First_Class then
            Is_Pure := False;
            exit;
         end if;
      end loop;

      if Is_Pure then
         return new Decision_Tree_Node'(Kind => Leaf, Predicted_Class => First_Class);
      end if;

      Current_Entropy := Calculate_Entropy (Data);

      --  Evaluate all attributes to find the best split
      for A in Attrs'Range loop
         if Attrs (A).Kind = Continuous then
            --  Evaluate all unique thresholds for continuous attribute
            for I in Data'Range loop
               declare
                  Thresh : constant Attribute_Value := Data (I).Features (A);
                  Left_Count, Right_Count : Natural := 0;
                  Left_Entropy, Right_Entropy : Float := 0.0;
                  Gain : Float;
               begin
                  if Thresh /= Missing_Value then
                     for J in Data'Range loop
                        if Handle_Missing and then Data (J).Features (A) = Missing_Value then
                           null; -- Skip missing values in gain calc
                        elsif Data (J).Features (A) <= Thresh then
                           Left_Count := Left_Count + 1;
                        else
                           Right_Count := Right_Count + 1;
                        end if;
                     end loop;

                     if Left_Count > 0 and then Right_Count > 0 then
                        declare
                           Left_Data : Dataset (1 .. Left_Count);
                           Right_Data : Dataset (1 .. Right_Count);
                           L_Idx : Natural := 1;
                           R_Idx : Natural := 1;
                        begin
                           for J in Data'Range loop
                              if Data (J).Features (A) /= Missing_Value then
                                 if Data (J).Features (A) <= Thresh then
                                    Left_Data (L_Idx) := Data (J);
                                    L_Idx := L_Idx + 1;
                                 else
                                    Right_Data (R_Idx) := Data (J);
                                    R_Idx := R_Idx + 1;
                                 end if;
                              end if;
                           end loop;

                           Left_Entropy := Calculate_Entropy (Left_Data);
                           Right_Entropy := Calculate_Entropy (Right_Data);

                           Gain := Current_Entropy - 
                                   ((Float (Left_Count) / Float (Data'Length)) * Left_Entropy) -
                                   ((Float (Right_Count) / Float (Data'Length)) * Right_Entropy);

                           if Gain > Best_Gain then
                              Best_Gain := Gain;
                              Best_Attr_Idx := A;
                              Best_Threshold := Thresh;
                           end if;
                        end;
                     end if;
                  end if;
               end;
            end loop;

         else
            --  Discrete Attribute splitting
            declare
               Max_Val : constant Positive := Attrs (A).Max_Discrete_Value;
               Counts  : array (1 .. Max_Val) of Natural := [others => 0];
               Entropies : array (1 .. Max_Val) of Float := [others => 0.0];
               Gain : Float := Current_Entropy;
            begin
               for I in Data'Range loop
                  if Data (I).Features (A) /= Missing_Value then
                     Counts (Positive (Data (I).Features (A))) := Counts (Positive (Data (I).Features (A))) + 1;
                  end if;
               end loop;

               for V in 1 .. Max_Val loop
                  if Counts (V) > 0 then
                     declare
                        Subset : Dataset (1 .. Counts (V));
                        Idx : Natural := 1;
                     begin
                        for I in Data'Range loop
                           if Data (I).Features (A) = Attribute_Value (V) then
                              Subset (Idx) := Data (I);
                              Idx := Idx + 1;
                           end if;
                        end loop;
                        Entropies (V) := Calculate_Entropy (Subset);
                        Gain := Gain - ((Float (Counts (V)) / Float (Data'Length)) * Entropies (V));
                     end;
                  end if;
               end loop;

               if Gain > Best_Gain then
                  Best_Gain := Gain;
                  Best_Attr_Idx := A;
               end if;
            end;
         end if;
      end loop;

      --  Base Case 3: No information gain
      if Best_Gain <= 0.0 then
         return new Decision_Tree_Node'(Kind => Leaf, Predicted_Class => Majority_Class (Data));
      end if;

      --  Recursive Tree Construction
      if Attrs (Best_Attr_Idx).Kind = Continuous then
         declare
            Left_Count, Right_Count : Natural := 0;
            Default_Branch_Is_Left : Boolean := True;
         begin
            for I in Data'Range loop
               if Data (I).Features (Best_Attr_Idx) /= Missing_Value then
                  if Data (I).Features (Best_Attr_Idx) <= Best_Threshold then
                     Left_Count := Left_Count + 1;
                  else
                     Right_Count := Right_Count + 1;
                  end if;
               end if;
            end loop;
            
            Default_Branch_Is_Left := Left_Count >= Right_Count;

            declare
               -- If handling missing, route them to majority branch
               Actual_Left_Count : Natural := Left_Count;
               Actual_Right_Count : Natural := Right_Count;
            begin
               for I in Data'Range loop
                  if Data (I).Features (Best_Attr_Idx) = Missing_Value then
                     if Default_Branch_Is_Left then
                        Actual_Left_Count := Actual_Left_Count + 1;
                     else
                        Actual_Right_Count := Actual_Right_Count + 1;
                     end if;
                  end if;
               end loop;

               declare
                  Left_Data : Dataset (1 .. Actual_Left_Count);
                  Right_Data : Dataset (1 .. Actual_Right_Count);
                  L_Idx : Natural := 1;
                  R_Idx : Natural := 1;
               begin
                  for I in Data'Range loop
                     if Data (I).Features (Best_Attr_Idx) <= Best_Threshold or else 
                        (Data (I).Features (Best_Attr_Idx) = Missing_Value and then Default_Branch_Is_Left) then
                        Left_Data (L_Idx) := Data (I);
                        L_Idx := L_Idx + 1;
                     else
                        Right_Data (R_Idx) := Data (I);
                        R_Idx := R_Idx + 1;
                     end if;
                  end loop;

                  return new Decision_Tree_Node'
                    (Kind         => Continuous_Split,
                     Attr_Index_C => Best_Attr_Idx,
                     Threshold    => Best_Threshold,
                     Left_Child   => Build_Internal (Left_Data, Attrs, Handle_Missing),
                     Right_Child  => Build_Internal (Right_Data, Attrs, Handle_Missing));
               end;
            end;
         end;

      else
         declare
            Max_Val : constant Positive := Attrs (Best_Attr_Idx).Max_Discrete_Value;
            Counts  : array (1 .. Max_Val) of Natural := [others => 0];
            Most_Freq_Val : Positive := 1;
            Max_C : Natural := 0;
         begin
            for I in Data'Range loop
               if Data (I).Features (Best_Attr_Idx) /= Missing_Value then
                  Counts (Positive (Data (I).Features (Best_Attr_Idx))) := 
                    Counts (Positive (Data (I).Features (Best_Attr_Idx))) + 1;
               end if;
            end loop;

            for V in 1 .. Max_Val loop
               if Counts (V) > Max_C then
                  Max_C := Counts (V);
                  Most_Freq_Val := V;
               end if;
            end loop;

            declare
               Node : constant Decision_Tree := new Decision_Tree_Node'
                 (Kind => Discrete_Split,
                  Attr_Index_D => Best_Attr_Idx,
                  Children => new Children_Array (1 .. Max_Val));
            begin
               for V in 1 .. Max_Val loop
                  declare
                     Subset_Count : Natural := Counts (V);
                  begin
                     if Handle_Missing and then V = Most_Freq_Val then
                        for I in Data'Range loop
                           if Data (I).Features (Best_Attr_Idx) = Missing_Value then
                              Subset_Count := Subset_Count + 1;
                           end if;
                        end loop;
                     end if;

                     if Subset_Count = 0 then
                        Node.Children (V) := new Decision_Tree_Node'(Kind => Leaf, Predicted_Class => Majority_Class (Data));
                     else
                        declare
                           Subset : Dataset (1 .. Subset_Count);
                           Idx : Natural := 1;
                        begin
                           for I in Data'Range loop
                              if Data (I).Features (Best_Attr_Idx) = Attribute_Value (V) or else
                                 (Handle_Missing and then Data (I).Features (Best_Attr_Idx) = Missing_Value and then V = Most_Freq_Val) then
                                 Subset (Idx) := Data (I);
                                 Idx := Idx + 1;
                              end if;
                           end loop;
                           Node.Children (V) := Build_Internal (Subset, Attrs, Handle_Missing);
                        end;
                     end if;
                  end;
               end loop;
               return Node;
            end;
         end;
      end if;
   end Build_Internal;

   function Build_Tree
     (Data  : Dataset;
      Attrs : Attribute_Set) return Decision_Tree
   is
   begin
      return Build_Internal (Data, Attrs, False);
   end Build_Tree;

   function Build_Tree_Handle_Missing
     (Data  : Dataset;
      Attrs : Attribute_Set) return Decision_Tree
   is
   begin
      return Build_Internal (Data, Attrs, True);
   end Build_Tree_Handle_Missing;

   --  Recursively prune nodes if all children are leaves of the same class
   procedure Prune (Tree : in out Decision_Tree) is
      All_Leaves : Boolean := True;
      Target_Class : Class_Label;
   begin
      if Tree = null or else Tree.Kind = Leaf then
         return;
      end if;

      if Tree.Kind = Continuous_Split then
         Prune (Tree.Left_Child);
         Prune (Tree.Right_Child);

         if Tree.Left_Child.Kind = Leaf and then Tree.Right_Child.Kind = Leaf then
            if Tree.Left_Child.Predicted_Class = Tree.Right_Child.Predicted_Class then
               Target_Class := Tree.Left_Child.Predicted_Class;
               Free_Node (Tree.Left_Child);
               Free_Node (Tree.Right_Child);
               Free_Node (Tree);
               Tree := new Decision_Tree_Node'(Kind => Leaf, Predicted_Class => Target_Class);
            end if;
         end if;
      elsif Tree.Kind = Discrete_Split then
         for I in Tree.Children'Range loop
            Prune (Tree.Children (I));
         end loop;

         if Tree.Children (Tree.Children'First).Kind = Leaf then
            Target_Class := Tree.Children (Tree.Children'First).Predicted_Class;
            for I in Tree.Children'Range loop
               if Tree.Children (I).Kind /= Leaf or else Tree.Children (I).Predicted_Class /= Target_Class then
                  All_Leaves := False;
                  exit;
               end if;
            end loop;

            if All_Leaves then
               for I in Tree.Children'Range loop
                  Free_Node (Tree.Children (I));
               end loop;
               Free_Children (Tree.Children);
               Free_Node (Tree);
               Tree := new Decision_Tree_Node'(Kind => Leaf, Predicted_Class => Target_Class);
            end if;
         end if;
      end if;
   end Prune;

   function Build_Tree_Pruned
     (Data  : Dataset;
      Attrs : Attribute_Set) return Decision_Tree
   is
      Tree : Decision_Tree := Build_Internal (Data, Attrs, False);
   begin
      Prune (Tree);
      return Tree;
   end Build_Tree_Pruned;

   function Classify
     (Tree     : Decision_Tree;
      Features : Value_Array) return Class_Label
   is
      Current : Decision_Tree := Tree;
   begin
      if Current = null then
         raise Tree_Error;
      end if;

      while Current.Kind /= Leaf loop
         if Current.Kind = Continuous_Split then
            if Features (Current.Attr_Index_C) <= Current.Threshold then
               Current := Current.Left_Child;
            else
               Current := Current.Right_Child;
            end if;
         else
            declare
               F_Val : constant Attribute_Value := Features (Current.Attr_Index_D);
            begin
               -- Safely verify value against Missing_Value to avoid Constraint_Error on negatives
               if F_Val = Missing_Value then
                  return 0;
               end if;

               declare
                  Val : constant Integer := Integer (F_Val);
               begin
                  if Val >= Current.Children'First and then Val <= Current.Children'Last then
                     Current := Current.Children (Val);
                  else
                     -- Unknown discrete value fallback
                     return 0;
                  end if;
               end;
            end;
         end if;
      end loop;

      return Current.Predicted_Class;
   end Classify;

   procedure Destroy_Tree (Tree : in out Decision_Tree) is
   begin
      if Tree /= null then
         case Tree.Kind is
            when Leaf =>
               null;
            when Continuous_Split =>
               Destroy_Tree (Tree.Left_Child);
               Destroy_Tree (Tree.Right_Child);
            when Discrete_Split =>
               for I in Tree.Children'Range loop
                  Destroy_Tree (Tree.Children (I));
               end loop;
               Free_Children (Tree.Children);
         end case;
         Free_Node (Tree);
      end if;
   end Destroy_Tree;

end C45_Algorithm;
