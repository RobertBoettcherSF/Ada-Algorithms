with Ada.Numerics.Generic_Elementary_Functions;

package body Radial_Basis_Function_Network is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   --------------------
   -- Create_Network --
   --------------------

   function Create_Network
     (Centers       : Center_Matrix;
      Weights       : Weight_Vector;
      Bias          : Real;
      Shape         : Shape_Parameter;
      Function_Type : RBF_Type;
      Is_Normalized : Boolean) return RBF_Network
   is
   begin
      --  Double-check constraints in case assertions are off
      if Centers'Length (1) /= Weights'Length then
         raise Dimension_Mismatch_Error with "Mismatch between centers count and weights count.";
      end if;

      if Centers'Length (1) = 0 or else Centers'Length (2) = 0 then
         raise Dimension_Mismatch_Error with "Network must have at least one center and feature.";
      end if;

      declare
         --  Initialize the return record with proper discriminants
         Net : RBF_Network (Num_Centers  => Center_Index (Centers'Length (1)),
                            Num_Features => Dimension_Index (Centers'Length (2)));
         C_Idx : Center_Index := 1;
      begin
         --  Safely map multi-dimensional arrays without assuming bounds start at 1
         for I in Centers'Range (1) loop
            declare
               F_Idx : Dimension_Index := 1;
            begin
               for J in Centers'Range (2) loop
                  Net.Centers (C_Idx, F_Idx) := Centers (I, J);
                  F_Idx := F_Idx + 1;
               end loop;
            end;
            Net.Weights (C_Idx) := Weights (I);
            C_Idx := C_Idx + 1;
         end loop;

         Net.Bias          := Bias;
         Net.Shape         := Shape;
         Net.Function_Type := Function_Type;
         Net.Is_Normalized := Is_Normalized;

         return Net;
      end;
   end Create_Network;

   ------------------------
   -- Euclidean_Distance --
   ------------------------

   function Euclidean_Distance (A, B : Feature_Vector) return Distance is
      Sum   : Real := 0.0;
      B_Idx : Dimension_Index := B'First;
   begin
      if A'Length /= B'Length then
         raise Dimension_Mismatch_Error with "Distance requires equal length vectors.";
      end if;

      for I in A'Range loop
         Sum := Sum + (A (I) - B (B_Idx)) ** 2;
         if B_Idx < Dimension_Index'Last then
            B_Idx := B_Idx + 1;
         end if;
      end loop;

      --  Guard against floating point imprecision leading to negative zero
      if Sum <= 0.0 then
         return 0.0;
      else
         return Distance (Sqrt (Sum));
      end if;
   end Euclidean_Distance;

   --------------------------
   -- Calculate_Activation --
   --------------------------

   function Calculate_Activation
     (Dist   : Distance;
      Shape  : Shape_Parameter;
      F_Type : RBF_Type) return Real
   is
      Epsilon_R    : constant Real := Real (Shape) * Real (Dist);
      Squared_Term : constant Real := Epsilon_R ** 2;
   begin
      case F_Type is
         when Gaussian =>
            return Exp (-Squared_Term);
         when Multiquadric =>
            return Sqrt (1.0 + Squared_Term);
         when Inverse_Quadratic =>
            return 1.0 / (1.0 + Squared_Term);
         when Inverse_Multiquadric =>
            return 1.0 / Sqrt (1.0 + Squared_Term);
      end case;
   end Calculate_Activation;

   --------------
   -- Evaluate --
   --------------

   function Evaluate
     (Net   : RBF_Network;
      Input : Feature_Vector) return Real
   is
      Total_Sum  : Real := 0.0;
      Weight_Sum : Real := 0.0;
      Act        : Real;
      Dist       : Distance;
      Center_Vec : Feature_Vector (1 .. Net.Num_Features);
   begin
      if Input'Length /= Net.Num_Features then
         raise Dimension_Mismatch_Error with "Input features mismatch network features.";
      end if;

      for I in 1 .. Net.Num_Centers loop
         --  Extract the I-th center into a vector for distance calculation
         for J in 1 .. Net.Num_Features loop
            Center_Vec (J) := Net.Centers (I, J);
         end loop;

         Dist := Euclidean_Distance (Input, Center_Vec);
         Act  := Calculate_Activation (Dist, Net.Shape, Net.Function_Type);

         Total_Sum  := Total_Sum + Net.Weights (I) * Act;
         Weight_Sum := Weight_Sum + Act;
      end loop;

      --  Apply output generation variants (Standard vs Normalized)
      if Net.Is_Normalized then
         if abs (Weight_Sum) < 1.0e-15 then
            raise Normalization_Error with "Sum of activations is zero in normalized network.";
         end if;
         return (Total_Sum / Weight_Sum) + Net.Bias;
      else
         return Total_Sum + Net.Bias;
      end if;
   end Evaluate;

end Radial_Basis_Function_Network;
