--  vegas_algorithm.adb
--  Implementation of the VEGAS algorithm.

with Ada.Numerics.Float_Random;
with Ada.Exceptions;

package body Vegas_Algorithm is

   use Ada.Numerics.Float_Random;

   procedure Integrate
     (Func                 : Integrand_Ptr;
      Bounds               : Domain_Array;
      Iterations           : Positive;
      Evaluations_Per_Iter : Positive;
      Result               : out Float;
      Variance             : out Float;
      Adaptive             : Boolean := True;
      Smooth_Grid          : Boolean := True)
   is
      Gen          : Generator;
      Num_Dim      : constant Natural := Bounds'Length;
      Num_Bins     : constant Positive := 50;  -- VEGAS standard grid granularity
      
      type Grid_Array is array (1 .. Num_Dim, 0 .. Num_Bins) of Float;
      type Weight_Array is array (1 .. Num_Dim, 1 .. Num_Bins) of Float;

      Edges        : Grid_Array;
      Bin_Weights  : Weight_Array := (others => (others => 0.0));
      
      --  Helper: Initialize grid with uniform spacing
      procedure Initialize_Grid is
         Step : Float;
      begin
         for D in 1 .. Num_Dim loop
            Step := (Bounds(Dimension_Index(D)).Upper - Bounds(Dimension_Index(D)).Lower) / Float(Num_Bins);
            for B in 0 .. Num_Bins loop
               Edges(D, B) := Bounds(Dimension_Index(D)).Lower + Step * Float(B);
            end loop;
         end loop;
      end Initialize_Grid;

      --  Helper: Adapts grid intervals to concentrate on regions with high variance/magnitude
      procedure Update_Grid is
         M_Smoothed : array (1 .. Num_Bins) of Float;
         Sum_M, Target, Acc, Fraction : Float;
         Old_Edges : array (0 .. Num_Bins) of Float;
         B : Positive;
      begin
         for D in 1 .. Num_Dim loop
            -- Variant 1: Grid Smoothing
            if Smooth_Grid then
               M_Smoothed(1) := (Bin_Weights(D, 1) + Bin_Weights(D, 2)) / 2.0;
               for I in 2 .. Num_Bins - 1 loop
                  M_Smoothed(I) := (Bin_Weights(D, I - 1) + 2.0 * Bin_Weights(D, I) + Bin_Weights(D, I + 1)) / 4.0;
               end loop;
               M_Smoothed(Num_Bins) := (Bin_Weights(D, Num_Bins - 1) + Bin_Weights(D, Num_Bins)) / 2.0;
            else
               -- Variant 2: Strict Grid Update (No smoothing)
               for I in 1 .. Num_Bins loop
                  M_Smoothed(I) := Bin_Weights(D, I);
               end loop;
            end if;

            Sum_M := 0.0;
            for I in 1 .. Num_Bins loop
               Sum_M := Sum_M + M_Smoothed(I);
            end loop;

            if Sum_M > 0.0 then
               Target := Sum_M / Float(Num_Bins);
               for I in 0 .. Num_Bins loop 
                  Old_Edges(I) := Edges(D, I); 
               end loop;

               Acc := 0.0;
               B := 1;
               
               -- Re-partition grid bounds to have equal area of smoothed weights
               for I in 1 .. Num_Bins - 1 loop
                  while B < Num_Bins and then Acc + M_Smoothed(B) < Target * Float(I) loop
                     Acc := Acc + M_Smoothed(B);
                     B := B + 1;
                  end loop;
                  
                  if M_Smoothed(B) > 0.0 then
                     Fraction := (Target * Float(I) - Acc) / M_Smoothed(B);
                  else
                     Fraction := 0.0;
                  end if;
                  Edges(D, I) := Old_Edges(B - 1) + Fraction * (Old_Edges(B) - Old_Edges(B - 1));
               end loop;
            end if;
         end loop;
      end Update_Grid;

      -- Runtime variables
      Current_Result, Current_Variance : Float;
      Cumulative_Result, Cumulative_Variance : Float := 0.0;
      Iter_Weight, Sum_Weights : Float := 0.0;
      
      Point : Vector(Bounds'Range);
      Prob, F_Val, Sample_Weight : Float;
      Bin_Indices : array (1 .. Num_Dim) of Positive;
      Bin_Width : Float;

   begin
      -- Edge cases / Validations
      if Func = null then
         raise Invalid_Input_Error with "Integrand cannot be null.";
      end if;
      if Num_Dim = 0 then
         raise Invalid_Input_Error with "Domain must have at least 1 dimension.";
      end if;
      for I in Bounds'Range loop
         if Bounds(I).Upper <= Bounds(I).Lower then
            raise Invalid_Input_Error with "Domain bounds invalid: Upper must be > Lower.";
         end if;
      end loop;

      Reset(Gen);
      Initialize_Grid;

      for Iter in 1 .. Iterations loop
         Current_Result := 0.0;
         Current_Variance := 0.0;
         Bin_Weights := (others => (others => 0.0));

         for Eval in 1 .. Evaluations_Per_Iter loop
            Prob := 1.0;
            
            -- Sample point
            for D in 1 .. Num_Dim loop
               Bin_Indices(D) := (Integer(Random(Gen) * Float(Num_Bins - 1))) + 1;
               if Bin_Indices(D) > Num_Bins then Bin_Indices(D) := Num_Bins; end if;
               
               Bin_Width := Edges(D, Bin_Indices(D)) - Edges(D, Bin_Indices(D) - 1);
               Point(Dimension_Index(D)) := Edges(D, Bin_Indices(D) - 1) + Random(Gen) * Bin_Width;
               
               Prob := Prob * (1.0 / (Float(Num_Bins) * Bin_Width));
            end loop;

            F_Val := Func(Point);
            if Prob > 0.0 then
               Sample_Weight := F_Val / Prob;
            else
               Sample_Weight := 0.0;
            end if;

            Current_Result := Current_Result + Sample_Weight;
            Current_Variance := Current_Variance + Sample_Weight * Sample_Weight;

            -- Accumulate magnitude for grid update (importance measure)
            for D in 1 .. Num_Dim loop
               Bin_Weights(D, Bin_Indices(D)) := Bin_Weights(D, Bin_Indices(D)) + abs (Sample_Weight);
            end loop;
         end loop;

         Current_Result := Current_Result / Float(Evaluations_Per_Iter);
         Current_Variance := abs (Current_Variance / Float(Evaluations_Per_Iter) - (Current_Result * Current_Result));
         
         if Current_Variance = 0.0 then
            Current_Variance := 1.0e-30; -- Avoid div-by-zero
         end if;

         -- Aggregate results inversely proportional to their variances
         Iter_Weight := 1.0 / Current_Variance;
         Cumulative_Result := Cumulative_Result + Current_Result * Iter_Weight;
         Sum_Weights := Sum_Weights + Iter_Weight;

         -- Variant 3: Adaptive Preemptive Grid Rescaling
         if Adaptive and Iter < Iterations then
            Update_Grid;
         end if;
      end loop;

      Result := Cumulative_Result / Sum_Weights;
      Variance := 1.0 / Sum_Weights;

   end Integrate;

end Vegas_Algorithm;
