with Ada.Containers.Generic_Array_Sort;

package body Zero_Attribute_Rule is

   --  Helper instantiation for sorting Numeric_Array in Median calculation.
   --  Defaults to the implicit "<" operator for Numeric_Value.
   procedure Sort_Numeric is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Positive,
      Element_Type => Numeric_Value,
      Array_Type   => Numeric_Array);

   --  Helper instantiation for sorting Nominal_Array in Mode calculation.
   --  Defaults to the implicit "<" operator for Nominal_Value.
   procedure Sort_Nominal is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Positive,
      Element_Type => Nominal_Value,
      Array_Type   => Nominal_Array);

   -----------------------------------------------------------------------------
   --  Core Implementations
   -----------------------------------------------------------------------------

   function Predict_Numeric_Mean (Targets : Numeric_Array) return Numeric_Value is
      Sum : Numeric_Value := 0.0;
   begin
      --  Accumulate all target values
      for Val of Targets loop
         Sum := Sum + Val;
      end loop;
      
      --  Return the arithmetic mean
      return Sum / Numeric_Value (Targets'Length);
   end Predict_Numeric_Mean;

   function Predict_Numeric_Median (Targets : Numeric_Array) return Numeric_Value is
      Sorted : Numeric_Array (Targets'Range) := Targets;
      Mid    : Positive;
   begin
      --  Median requires sorted elements
      Sort_Numeric (Sorted);
      
      Mid := Sorted'First + (Sorted'Length / 2);
      
      if Sorted'Length mod 2 = 0 then
         --  For even number of elements, average the two middle values
         return (Sorted (Mid - 1) + Sorted (Mid)) / 2.0;
      else
         --  For odd number of elements, return the exact middle value
         return Sorted (Mid);
      end if;
   end Predict_Numeric_Median;

   function Predict_Nominal_Mode (Targets : Nominal_Array) return Nominal_Value is
      Sorted     : Nominal_Array (Targets'Range) := Targets;
      Max_Count  : Natural := 0;
      Curr_Count : Natural := 1;
      Mode_Val   : Nominal_Value;
   begin
      --  Short-circuit single element datasets
      if Targets'Length = 1 then
         return Targets (Targets'First);
      end if;

      --  Sort the array to group identical classes contiguously
      Sort_Nominal (Sorted);
      Mode_Val := Sorted (Sorted'First);

      for I in Sorted'First + 1 .. Sorted'Last loop
         if Sorted (I) = Sorted (I - 1) then
            Curr_Count := Curr_Count + 1;
         else
            --  Run ends, check if it's the longest run seen so far
            if Curr_Count > Max_Count then
               Max_Count := Curr_Count;
               Mode_Val  := Sorted (I - 1);
            end if;
            Curr_Count := 1;
         end if;
      end loop;

      --  Final check for the sequence that terminates at the array's end
      if Curr_Count > Max_Count then
         Mode_Val := Sorted (Sorted'Last);
      end if;

      return Mode_Val;
   end Predict_Nominal_Mode;

   -----------------------------------------------------------------------------
   --  Safe Wrappers
   -----------------------------------------------------------------------------

   function Safe_Predict_Numeric_Mean (Targets : Numeric_Array) return Numeric_Value is
   begin
      if Targets'Length = 0 then
         raise Empty_Dataset_Error;
      end if;
      return Predict_Numeric_Mean (Targets);
   end Safe_Predict_Numeric_Mean;

   function Safe_Predict_Numeric_Median (Targets : Numeric_Array) return Numeric_Value is
   begin
      if Targets'Length = 0 then
         raise Empty_Dataset_Error;
      end if;
      return Predict_Numeric_Median (Targets);
   end Safe_Predict_Numeric_Median;

   function Safe_Predict_Nominal_Mode (Targets : Nominal_Array) return Nominal_Value is
   begin
      if Targets'Length = 0 then
         raise Empty_Dataset_Error;
      end if;
      return Predict_Nominal_Mode (Targets);
   end Safe_Predict_Nominal_Mode;

end Zero_Attribute_Rule;
