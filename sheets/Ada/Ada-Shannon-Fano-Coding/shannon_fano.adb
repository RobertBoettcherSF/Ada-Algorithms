with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Shannon_Fano is

   -- Helper: Sorts the array in descending order based on probability
   procedure Sort_Symbols (Symbols : in out Symbol_Array) is
      Temp : Symbol_Data;
   begin
      for I in Symbols'First .. Symbols'Last - 1 loop
         for J in I + 1 .. Symbols'Last loop
            if Symbols(J).Probability > Symbols(I).Probability then
               Temp := Symbols(I);
               Symbols(I) := Symbols(J);
               Symbols(J) := Temp;
            end if;
         end loop;
      end loop;
   end Sort_Symbols;

   -- Helper: Validates inputs and normalizes probabilities so they sum to 1.0
   procedure Validate_And_Normalize (Symbols : in out Symbol_Array) is
      Total : Float := 0.0;
   begin
      if Symbols'Length = 0 then
         raise Empty_Input;
      end if;

      for I in Symbols'Range loop
         if Symbols(I).Probability <= 0.0 then
            raise Invalid_Probability;
         end if;
         Total := Total + Symbols(I).Probability;
      end loop;

      -- Normalize weights into true probabilities summing to 1.0
      for I in Symbols'Range loop
         Symbols(I).Probability := Symbols(I).Probability / Total;
         Symbols(I).Code := Null_Unbounded_String; -- Reset codes
      end loop;
   end Validate_And_Normalize;

   -- Recursive helper for Fano's splitting logic
   procedure Fano_Recursive (Symbols : in out Symbol_Array; Start_Idx, End_Idx : Positive) is
      Total_Sum   : Float := 0.0;
      Current_Sum : Float := 0.0;
      Right_Sum   : Float;
      Diff        : Float;
      Min_Diff    : Float := Float'Last;
      Split_Idx   : Positive := Start_Idx;
   begin
      -- Base case: 1 element left
      if Start_Idx >= End_Idx then
         return;
      end if;

      -- Calculate total sum of this slice
      for I in Start_Idx .. End_Idx loop
         Total_Sum := Total_Sum + Symbols(I).Probability;
      end loop;

      -- Find the optimal split point minimizing the difference between halves
      for I in Start_Idx .. End_Idx - 1 loop
         Current_Sum := Current_Sum + Symbols(I).Probability;
         Right_Sum   := Total_Sum - Current_Sum;
         Diff        := abs (Current_Sum - Right_Sum);
         
         if Diff < Min_Diff then
            Min_Diff := Diff;
            Split_Idx := I;
         end if;
      end loop;

      -- Append '0' to the first half
      for I in Start_Idx .. Split_Idx loop
         Symbols(I).Code := Symbols(I).Code & "0";
      end loop;

      -- Append '1' to the second half
      for I in Split_Idx + 1 .. End_Idx loop
         Symbols(I).Code := Symbols(I).Code & "1";
      end loop;

      -- Recursively process both halves
      Fano_Recursive (Symbols, Start_Idx, Split_Idx);
      Fano_Recursive (Symbols, Split_Idx + 1, End_Idx);
   end Fano_Recursive;

   -------------------------------------------------------------------
   -- Variant 1: Fano's Method (Top-down splitting)
   -------------------------------------------------------------------
   procedure Generate_Fano_Codes (Symbols : in out Symbol_Array) is
   begin
      Validate_And_Normalize (Symbols);
      Sort_Symbols (Symbols);
      
      -- Edge case: If only 1 symbol, assign '0'
      if Symbols'Length = 1 then
         Symbols(Symbols'First).Code := To_Unbounded_String ("0");
      else
         Fano_Recursive (Symbols, Symbols'First, Symbols'Last);
      end if;
   end Generate_Fano_Codes;

   -------------------------------------------------------------------
   -- Variant 2: Shannon's Method (Cumulative probability)
   -------------------------------------------------------------------
   procedure Generate_Shannon_Codes (Symbols : in out Symbol_Array) is
      Cumulative : Float := 0.0;
      Temp_Cum   : Float;
      Prob       : Float;
      Code_Len   : Integer;
   begin
      Validate_And_Normalize (Symbols);
      Sort_Symbols (Symbols);
      
      -- Edge case: 1 symbol
      if Symbols'Length = 1 then
         Symbols(Symbols'First).Code := To_Unbounded_String ("0");
         return;
      end if;

      for I in Symbols'Range loop
         Prob := Symbols(I).Probability;
         
         -- Calculate l_i = ceil(-log2(p_i))
         -- Log base 2 = ln(Prob) / ln(2)
         Code_Len := Integer (Float'Ceiling (- (Log (Prob) / Log (2.0))));
         if Code_Len <= 0 then
            Code_Len := 1; 
         end if;
         
         -- Extract binary fractional representation of Cumulative probability
         Temp_Cum := Cumulative;
         for Bit in 1 .. Code_Len loop
            Temp_Cum := Temp_Cum * 2.0;
            if Temp_Cum >= 1.0 then
               Symbols(I).Code := Symbols(I).Code & "1";
               Temp_Cum := Temp_Cum - 1.0;
            else
               Symbols(I).Code := Symbols(I).Code & "0";
            end if;
         end loop;
         
         -- Add current probability to cumulative for the next symbol
         Cumulative := Cumulative + Prob;
      end loop;
   end Generate_Shannon_Codes;

end Shannon_Fano;
