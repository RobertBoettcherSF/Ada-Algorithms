with Ada.Containers.Ordered_Maps;
with Ada.Containers.Vectors;

package body One_Attribute_Rule is

   -- Map to store counts of each target class
   package Class_Counts is new Ada.Containers.Ordered_Maps
     (Key_Type     => Class_Label,
      Element_Type => Natural);

   -- Map to store class frequency maps for each distinct attribute value
   package Value_Class_Counts is new Ada.Containers.Ordered_Maps
     (Key_Type     => Attribute_Value,
      Element_Type => Class_Counts.Map,
      "="          => Class_Counts."=");

   -- Dynamic vector to collect mapping rules before finalizing the array size
   package Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Value_Rule);

   -- Helper: Finds the absolute majority class across the entire dataset
   function Find_Majority_Class (Data : Dataset) return Class_Label is
      Counts    : Class_Counts.Map;
      Max_Count : Natural := 0;
      Majority  : Class_Label := 0;
   begin
      for I in 1 .. Data.Num_Instances loop
         declare
            C : constant Class_Label := Data.Classes (I);
         begin
            if Counts.Contains (C) then
               Counts.Replace (C, Counts.Element (C) + 1);
            else
               Counts.Insert (C, 1);
            end if;
         end;
      end loop;
      
      -- Iterate through class counts; ties inherently favor the smaller Class_Label
      for Pos in Counts.Iterate loop
         if Class_Counts.Element (Pos) > Max_Count then
            Max_Count := Class_Counts.Element (Pos);
            Majority  := Class_Counts.Key (Pos);
         end if;
      end loop;
      
      return Majority;
   end Find_Majority_Class;

   function Train_Basic (Data : Dataset) return Basic_Model is
      Best_Attr   : Attribute_Index := 1;
      Min_Error   : Natural := Natural'Last;
      Best_Rules  : Rule_Vectors.Vector;
   begin
      if Data.Num_Instances = 0 then
         raise Invalid_Dataset_Error with "Empty dataset provided to Train_Basic";
      end if;
      
      -- Evaluate each attribute independently
      for A in 1 .. Data.Num_Attributes loop
         declare
            use Value_Class_Counts;
            Value_Stats   : Map;
            Attr_Error    : Natural := 0;
            Current_Rules : Rule_Vectors.Vector;
         begin
            -- 1. Gather class distribution data for every distinct value in Attribute A
            for I in 1 .. Data.Num_Instances loop
               declare
                  Val : constant Attribute_Value := Data.Grid (I, A);
                  Cls : constant Class_Label     := Data.Classes (I);
                  
                  C_Map : Class_Counts.Map;
               begin
                  if Value_Stats.Contains (Val) then
                     C_Map := Value_Stats.Element (Val);
                  end if;
                  
                  if C_Map.Contains (Cls) then
                     C_Map.Replace (Cls, C_Map.Element (Cls) + 1);
                  else
                     C_Map.Insert (Cls, 1);
                  end if;
                  
                  -- Map enforces by-value copies, replace updated inner map
                  Value_Stats.Include (Val, C_Map);
               end;
            end loop;
            
            -- 2. Identify the majority class for each distinct attribute value
            for Position in Value_Stats.Iterate loop
               declare
                  Val   : constant Attribute_Value  := Value_Class_Counts.Key (Position);
                  C_Map : constant Class_Counts.Map := Value_Class_Counts.Element (Position);
                  
                  Total_Occurrences : Natural := 0;
                  Max_Class_Count   : Natural := 0;
                  Best_Class        : Class_Label := 0;
               begin
                  for C_Pos in C_Map.Iterate loop
                     declare
                        C   : constant Class_Label := Class_Counts.Key (C_Pos);
                        Cnt : constant Natural     := Class_Counts.Element (C_Pos);
                     begin
                        Total_Occurrences := Total_Occurrences + Cnt;
                        
                        -- Strict '>' implies ties favor the smaller Class_Label
                        if Cnt > Max_Class_Count then
                           Max_Class_Count := Cnt;
                           Best_Class      := C;
                        end if;
                     end;
                  end loop;
                  
                  -- The error contributed by this value is the frequency of all non-majority classes
                  Attr_Error := Attr_Error + (Total_Occurrences - Max_Class_Count);
                  Current_Rules.Append (Value_Rule'(Value => Val, Class => Best_Class));
               end;
            end loop;
            
            -- 3. Select this attribute if it achieves the lowest total error across the set
            -- Strict '<' implies ties favor the attribute appearing earlier (lower index)
            if Attr_Error < Min_Error then
               Min_Error  := Attr_Error;
               Best_Attr  := A;
               Best_Rules := Current_Rules;
            end if;
         end;
      end loop;
      
      -- 4. Allocate constrained output record
      declare
         Result : Basic_Model (Num_Rules => Natural (Best_Rules.Length));
      begin
         Result.Best_Attribute := Best_Attr;
         Result.Total_Error    := Min_Error;
         for I in 1 .. Result.Num_Rules loop
            Result.Rules (I) := Best_Rules.Element (I);
         end loop;
         return Result;
      end;
   end Train_Basic;

   function Train_Robust (Data : Dataset) return Robust_Model is
      Basic     : constant Basic_Model := Train_Basic (Data);
      Maj_Class : constant Class_Label := Find_Majority_Class (Data);
      Result    : Robust_Model (Num_Rules => Basic.Num_Rules);
   begin
      Result.Best_Attribute := Basic.Best_Attribute;
      Result.Total_Error    := Basic.Total_Error;
      Result.Rules          := Basic.Rules;
      Result.Default_Class  := Maj_Class;
      return Result;
   end Train_Robust;

   function Predict_Basic (Model : Basic_Model; Attrs : Attribute_Array) return Class_Label is
      Val : constant Attribute_Value := Attrs (Model.Best_Attribute);
   begin
      for I in 1 .. Model.Num_Rules loop
         if Model.Rules (I).Value = Val then
            return Model.Rules (I).Class;
         end if;
      end loop;
      
      raise Unseen_Value_Error with "Attribute value not encountered during training.";
   end Predict_Basic;

   function Predict_Robust (Model : Robust_Model; Attrs : Attribute_Array) return Class_Label is
      Val : constant Attribute_Value := Attrs (Model.Best_Attribute);
   begin
      for I in 1 .. Model.Num_Rules loop
         if Model.Rules (I).Value = Val then
            return Model.Rules (I).Class;
         end if;
      end loop;
      
      return Model.Default_Class;
   end Predict_Robust;

end One_Attribute_Rule;
