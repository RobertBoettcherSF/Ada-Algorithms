-- shannon_fano_elias.adb
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;

package body Shannon_Fano_Elias is

   ----------------------------------------------------------------------
   -- Calculate_Length:
   -- Implements l(x) = ceil(-log2(p(x))) + 1
   -- Calculates the required bit length for a given probability.
   ----------------------------------------------------------------------
   function Calculate_Length (P : Probability) return Positive is
      Log_Val : Long_Float;
   begin
      if P = 0.0 then
         raise Invalid_Distribution;
      end if;
      
      -- Calculate base-2 logarithm
      Log_Val := -Log (Long_Float (P), 2.0);
      
      -- Apply ceiling function and add 1
      return Positive (Long_Float'Ceiling (Log_Val)) + 1;
   end Calculate_Length;

   ----------------------------------------------------------------------
   -- Float_To_Binary:
   -- Converts a fractional probability \bar{F}(x) to a binary string
   -- truncated to 'Len' bits.
   ----------------------------------------------------------------------
   function Float_To_Binary (Value : Probability; Len : Positive) return Unbounded_String is
      Result : Unbounded_String := Null_Unbounded_String;
      Temp   : Long_Float := Long_Float (Value);
   begin
      for I in 1 .. Len loop
         Temp := Temp * 2.0;
         if Temp >= 1.0 then
            Append (Result, "1");
            Temp := Temp - 1.0;
         else
            Append (Result, "0");
         end if;
      end loop;
      return Result;
   end Float_To_Binary;

   ----------------------------------------------------------------------
   -- Encode:
   -- Processes the Symbol_Array to generate a Shannon-Fano-Elias code.
   -- Handles probability accumulation, modified CDF, and code generation.
   ----------------------------------------------------------------------
   procedure Encode (Data : in out Symbol_Array) is
      -- We must use Long_Float for intermediate summation to prevent Ada's
      -- intrinsic CONSTRAINT_ERROR when testing invalid sums that exceed 1.0
      Sum        : Long_Float := 0.0;
      Cumulative : Long_Float := 0.0;
      Epsilon    : constant Long_Float := 0.0001; -- Tolerance for float math
   begin
      -- Edge Case: Empty Array
      if Data'Length = 0 then
         raise Empty_Input;
      end if;

      -- Validation: Ensure probabilities sum to 1.0 and are strictly positive
      for I in Data'Range loop
         if Data(I).Prob <= 0.0 then
            raise Invalid_Distribution;
         end if;
         Sum := Sum + Long_Float (Data(I).Prob);
      end loop;

      if abs (Sum - 1.0) > Epsilon then
         raise Invalid_Distribution;
      end if;

      -- Phase 1: Calculate CDF (F), Modified CDF (F_Bar), and lengths
      for I in Data'Range loop
         declare
            F_Bar_Temp : Long_Float;
            F_Temp     : Long_Float;
         begin
            -- F_bar(x_i) = sum_{j < i} p(x_j) + p(x_i)/2
            F_Bar_Temp := Cumulative + (Long_Float (Data(I).Prob) / 2.0);
            
            -- Update standard CDF
            Cumulative := Cumulative + Long_Float (Data(I).Prob);
            F_Temp     := Cumulative;
            
            -- Clamp to 1.0 to absorb any minute floating point inaccuracies, 
            -- ensuring we don't violate the 0.0..1.0 Probability constraint
            if F_Bar_Temp > 1.0 then F_Bar_Temp := 1.0; end if;
            if F_Temp > 1.0 then F_Temp := 1.0; end if;
            
            Data(I).F_Bar := Probability (F_Bar_Temp);
            Data(I).F     := Probability (F_Temp);
            
            -- Calculate l(x_i)
            Data(I).Length := Calculate_Length (Data(I).Prob);
            
            -- Generate the binary code by taking F_Bar to 'Length' fractional bits
            Data(I).Code := Float_To_Binary (Data(I).F_Bar, Data(I).Length);
         end;
      end loop;
      
   end Encode;

end Shannon_Fano_Elias;
