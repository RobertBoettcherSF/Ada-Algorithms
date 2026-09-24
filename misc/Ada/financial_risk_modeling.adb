with Ada.Numerics.Long_Elementary_Functions;
with Ada.Containers.Generic_Array_Sort;

package body Financial_Risk_Modeling is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   --  Instantiate the generic sort algorithm for Return_Array
   procedure Sort is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Positive,
      Element_Type => Rate,
      Array_Type   => Return_Array);

   -----------------------------------------------------------------------------
   --  Helper Functions
   -----------------------------------------------------------------------------

   function Mean (Returns : Return_Array) return Rate is
      Sum : Rate := 0.0;
   begin
      if Returns'Length = 0 then
         raise Insufficient_Data with "Mean requires at least 1 element.";
      end if;

      for Elem of Returns loop
         Sum := Sum + Elem;
      end loop;
      
      return Sum / Rate (Returns'Length);
   end Mean;

   function Standard_Deviation (Returns : Return_Array) return Rate is
      Mu       : Rate;
      Sum_Sq   : Rate := 0.0;
      Variance : Rate;
   begin
      if Returns'Length <= 1 then
         raise Insufficient_Data with "Standard Deviation requires at least 2 elements.";
      end if;

      Mu := Mean (Returns);

      for Elem of Returns loop
         Sum_Sq := Sum_Sq + (Elem - Mu) ** 2;
      end loop;

      Variance := Sum_Sq / Rate (Returns'Length - 1);
      
      return Rate (Math.Sqrt (Long_Float (Variance)));
   end Standard_Deviation;

   function Normal_PDF (X : Rate) return Rate is
      Pi_Val : constant Rate := 3.14159_26535_89793;
   begin
      --  Standard Normal PDF: (1 / sqrt(2 * pi)) * exp(-0.5 * x^2)
      return (1.0 / Rate (Math.Sqrt (2.0 * Long_Float (Pi_Val)))) * 
             Rate (Math.Exp (Long_Float (-0.5 * X * X)));
   end Normal_PDF;

   function Normal_Inverse_CDF (P : Confidence_Level) return Rate is
      --  Uses the Abramowitz and Stegun rational approximation (26.2.23)
      --  for the upper tail of the standard normal distribution.
      Tail : constant Rate := 1.0 - P;
      T    : constant Rate := Rate (Math.Sqrt (-2.0 * Math.Log (Long_Float (Tail))));
      
      C0   : constant Rate := 2.515517;
      C1   : constant Rate := 0.802853;
      C2   : constant Rate := 0.010328;
      
      D1   : constant Rate := 1.432788;
      D2   : constant Rate := 0.189269;
      D3   : constant Rate := 0.001308;
      
      Numerator   : Rate;
      Denominator : Rate;
   begin
      Numerator   := C0 + C1 * T + C2 * T ** 2;
      Denominator := 1.0 + D1 * T + D2 * T ** 2 + D3 * T ** 3;
      
      return T - (Numerator / Denominator);
   end Normal_Inverse_CDF;

   -----------------------------------------------------------------------------
   --  Risk Modeling Variants
   -----------------------------------------------------------------------------

   function Historical_VaR (Returns : Return_Array; Confidence : Confidence_Level) return Rate is
      Normalized : Return_Array (1 .. Returns'Length);
      Tail_Prob  : constant Rate := 1.0 - Confidence;
      Position   : constant Rate := Rate (Returns'Length) * Tail_Prob;
      Lower_Idx  : Integer;
      Upper_Idx  : Integer;
      Weight     : Rate;
   begin
      if Returns'Length = 0 then
         raise Insufficient_Data with "Historical VaR requires at least 1 element.";
      end if;

      --  Copy to a 1-based array for predictable indexing
      for I in 1 .. Returns'Length loop
         Normalized (I) := Returns (Returns'First + I - 1);
      end loop;

      Sort (Normalized);

      --  If the desired position is smaller than the first element, return the worst loss.
      if Position <= 1.0 then
         return Normalized (1);
      end if;

      --  Interpolate between the two nearest indices
      Lower_Idx := Integer (Rate'Floor (Position));
      Upper_Idx := Integer (Rate'Ceiling (Position));

      if Lower_Idx = Upper_Idx then
         return Normalized (Lower_Idx);
      end if;

      Weight := Position - Rate (Lower_Idx);
      return Normalized (Lower_Idx) * (1.0 - Weight) + Normalized (Upper_Idx) * Weight;
   end Historical_VaR;

   function Historical_ES (Returns : Return_Array; Confidence : Confidence_Level) return Rate is
      Normalized : Return_Array (1 .. Returns'Length);
      Tail_Prob  : constant Rate := 1.0 - Confidence;
      Position   : constant Rate := Rate (Returns'Length) * Tail_Prob;
      --  Add a tiny epsilon to handle floating point truncation of exact numbers (e.g. 1.999999999999999)
      Count      : constant Integer := Integer (Rate'Floor (Position + 1.0E-8));
      Sum        : Rate := 0.0;
   begin
      if Returns'Length = 0 then
         raise Insufficient_Data with "Historical ES requires at least 1 element.";
      end if;

      for I in 1 .. Returns'Length loop
         Normalized (I) := Returns (Returns'First + I - 1);
      end loop;

      Sort (Normalized);

      --  If tail count is less than 1, we fallback to the absolute worst case scenario.
      if Count < 1 then
         return Normalized (1);
      end if;

      --  Average the elements falling within the tail threshold
      for I in 1 .. Count loop
         Sum := Sum + Normalized (I);
      end loop;

      return Sum / Rate (Count);
   end Historical_ES;

   function Parametric_VaR (Returns : Return_Array; Confidence : Confidence_Level) return Rate is
      Mu    : Rate;
      Sigma : Rate;
      Z     : Rate;
   begin
      if Returns'Length <= 1 then
         raise Insufficient_Data with "Parametric VaR requires at least 2 elements.";
      end if;

      Mu    := Mean (Returns);
      Sigma := Standard_Deviation (Returns);
      Z     := Normal_Inverse_CDF (Confidence);

      --  VaR is typically quoted such that a negative number implies a loss.
      --  Mu - Z * Sigma finds the lower bound (loss threshold).
      return Mu - Z * Sigma;
   end Parametric_VaR;

   function Parametric_ES (Returns : Return_Array; Confidence : Confidence_Level) return Rate is
      Mu        : Rate;
      Sigma     : Rate;
      Z         : Rate;
      Tail_Prob : constant Rate := 1.0 - Confidence;
   begin
      if Returns'Length <= 1 then
         raise Insufficient_Data with "Parametric ES requires at least 2 elements.";
      end if;

      Mu    := Mean (Returns);
      Sigma := Standard_Deviation (Returns);
      Z     := Normal_Inverse_CDF (Confidence);

      --  Parametric ES formula for normal distribution tail expectation.
      return Mu - Sigma * (Normal_PDF (Z) / Tail_Prob);
   end Parametric_ES;

end Financial_Risk_Modeling;
