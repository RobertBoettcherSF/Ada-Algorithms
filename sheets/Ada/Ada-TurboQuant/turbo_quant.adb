-- turbo_quant.adb
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Turbo_Quant is

   -- Helper: Euclidean Norm
   function Norm (V : Vector) return Real is
      Sum : Real := 0.0;
   begin
      for I in V'Range loop
         Sum := Sum + V (I) * V (I);
      end loop;
      return Real (Sqrt (Float (Sum)));
   end Norm;

   -- Helper: Dot Product
   function Inner_Product (V1, V2 : Vector) return Real is
      Sum : Real := 0.0;
   begin
      if V1'Length /= V2'Length then
         raise Dimension_Mismatch;
      end if;
      for I in V1'Range loop
         Sum := Sum + V1 (I) * V2 (I - V1'First + V2'First);
      end loop;
      return Sum;
   end Inner_Product;

   -- Helper: Matrix-Vector Multiplication
   function Multiply (M : Matrix; V : Vector) return Vector is
      Result : Vector (M'Range (1));
      Sum    : Real;
   begin
      if M'Length (2) /= V'Length then
         raise Dimension_Mismatch;
      end if;
      for I in M'Range (1) loop
         Sum := 0.0;
         for J in M'Range (2) loop
            Sum := Sum + M (I, J) * V (J - M'First (2) + V'First);
         end loop;
         Result (I) := Sum;
      end loop;
      return Result;
   end Multiply;

   -- Helper: Transposed Matrix-Vector Multiplication
   function Transpose_Multiply (M : Matrix; V : Vector) return Vector is
      Result : Vector (M'Range (2));
      Sum    : Real;
   begin
      if M'Length (1) /= V'Length then
         raise Dimension_Mismatch;
      end if;
      for J in M'Range (2) loop
         Sum := 0.0;
         for I in M'Range (1) loop
            Sum := Sum + M (I, J) * V (I - M'First (1) + V'First);
         end loop;
         Result (J) := Sum;
      end loop;
      return Result;
   end Transpose_Multiply;

   -- VARIANT 1: TurboQuant_mse Implementation
   function Quantize_MSE (
      Input           : Vector;
      Rotation_Matrix : Matrix;
      Centroids       : Vector
   ) return TurboQuant_MSE_Data is
      Rotated       : Vector := Multiply (Rotation_Matrix, Input);
      Result        : TurboQuant_MSE_Data (Rotated'Length);
      Min_Dist      : Real;
      Dist          : Real;
      Closest_Index : Quantized_Index;
   begin
      -- Independent scalar quantization per rotated coordinate
      for I in Rotated'Range loop
         Min_Dist := Real'Last;
         Closest_Index := 1;
         for C in Centroids'Range loop
            Dist := abs (Rotated (I) - Centroids (C));
            if Dist < Min_Dist then
               Min_Dist := Dist;
               Closest_Index := Quantized_Index (C);
            end if;
         end loop;
         Result.Quantized_Coordinates (I - Rotated'First + 1) := Closest_Index;
      end loop;
      return Result;
   end Quantize_MSE;

   function Dequantize_MSE (
      Data            : TurboQuant_MSE_Data;
      Rotation_Matrix : Matrix;
      Centroids       : Vector
   ) return Vector is
      Reconstructed_Rotated : Vector (1 .. Data.Dimension);
   begin
      if Rotation_Matrix'Length (1) /= Data.Dimension then
         raise Dimension_Mismatch;
      end if;
      for I in 1 .. Data.Dimension loop
         Reconstructed_Rotated (I) := Centroids (Positive (Data.Quantized_Coordinates (I)));
      end loop;
      return Transpose_Multiply (Rotation_Matrix, Reconstructed_Rotated);
   end Dequantize_MSE;

   -- VARIANT 2: TurboQuant_prod Implementation
   function Quantize_Prod (
      Input           : Vector;
      Rotation_Matrix : Matrix;
      Centroids       : Vector;
      QJL_Matrix      : Matrix
   ) return TurboQuant_Prod_Data is
      MSE_Base     : TurboQuant_MSE_Data := Quantize_MSE (Input, Rotation_Matrix, Centroids);
      Reconstructed: Vector := Dequantize_MSE (MSE_Base, Rotation_Matrix, Centroids);
      Residual     : Vector (Input'Range);
      Res_Norm     : Real;
      QJL_Proj     : Vector (QJL_Matrix'Range (1));
      Result       : TurboQuant_Prod_Data (Input'Length, QJL_Matrix'Length (1));
   begin
      -- Compute quantization residual
      for I in Input'Range loop
         Residual (I) := Input (I) - Reconstructed (I - Input'First + Reconstructed'First);
      end loop;
      
      Res_Norm := Norm (Residual);
      Result.MSE_Base := MSE_Base;
      Result.Residual_Norm := Res_Norm;
      
      -- Apply Quantized Johnson-Lindenstrauss (QJL) transform on residual error
      if Res_Norm > 0.0001 then
         QJL_Proj := Multiply (QJL_Matrix, Residual);
         for I in QJL_Proj'Range loop
            if QJL_Proj (I) >= 0.0 then
               Result.QJL_Signs (I - QJL_Proj'First + 1) := Plus_One;
            else
               Result.QJL_Signs (I - QJL_Proj'First + 1) := Minus_One;
            end if;
         end loop;
      else
         -- Edge case: perfect MSE match, residual is negligible
         for I in 1 .. Result.QJL_Dimension loop
            Result.QJL_Signs (I) := Plus_One;
         end loop;
      end if;
      
      return Result;
   end Quantize_Prod;

   function Dequantize_Prod (
      Data            : TurboQuant_Prod_Data;
      Rotation_Matrix : Matrix;
      Centroids       : Vector;
      QJL_Matrix      : Matrix
   ) return Vector is
      Base_Recon   : Vector := Dequantize_MSE (Data.MSE_Base, Rotation_Matrix, Centroids);
      Sign_Vals    : Vector (1 .. Data.QJL_Dimension);
      Residual_Rec : Vector (Base_Recon'Range);
      Scaling      : Real;
   begin
      for I in 1 .. Data.QJL_Dimension loop
         if Data.QJL_Signs (I) = Plus_One then
            Sign_Vals (I) := 1.0;
         else
            Sign_Vals (I) := -1.0;
         end if;
      end loop;
      
      Residual_Rec := Transpose_Multiply (QJL_Matrix, Sign_Vals);
      
      -- Scale reconstructed residual back using QJL formula
      Scaling := Data.Residual_Norm / Real (Sqrt (Float (Data.QJL_Dimension)));
      for I in Base_Recon'Range loop
         Base_Recon (I) := Base_Recon (I) + Residual_Rec (I - Base_Recon'First + Residual_Rec'First) * Scaling;
      end loop;
      
      return Base_Recon;
   end Dequantize_Prod;

end Turbo_Quant;
