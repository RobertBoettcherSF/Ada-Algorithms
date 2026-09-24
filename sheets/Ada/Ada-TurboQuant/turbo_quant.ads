-- turbo_quant.ads
-- Specification for the TurboQuant vector quantization algorithm variants.
-- Variants included: TurboQuant_mse and TurboQuant_prod.
-- Note: As a data-oblivious algorithm, the Rotation Matrices, QJL projection 
-- matrices, and Lloyd-Max Centroids are provided as external inputs.

package Turbo_Quant is

   -- Strong typing for algorithm-specific data
   type Real is new Float;
   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;
   
   type Quantized_Index is new Natural;
   type Index_Array is array (Positive range <>) of Quantized_Index;
   
   type Sign_Bit is (Minus_One, Plus_One);
   type Sign_Vector is array (Positive range <>) of Sign_Bit;

   -- Data structure for TurboQuant mse variant (optimized for Mean Squared Error)
   type TurboQuant_MSE_Data (Dimension : Positive) is record
      Quantized_Coordinates : Index_Array (1 .. Dimension);
   end record;
   
   -- Data structure for TurboQuant prod variant (optimized for Inner Products)
   type TurboQuant_Prod_Data (Dimension : Positive; QJL_Dimension : Positive) is record
      MSE_Base       : TurboQuant_MSE_Data (Dimension);
      QJL_Signs      : Sign_Vector (1 .. QJL_Dimension);
      Residual_Norm  : Real;
   end record;
   
   -- Exceptions
   Dimension_Mismatch : exception;
   
   -- Helper mathematical functions exposed for testing and internal use
   function Norm (V : Vector) return Real;
   function Inner_Product (V1, V2 : Vector) return Real;
   function Multiply (M : Matrix; V : Vector) return Vector;
   function Transpose_Multiply (M : Matrix; V : Vector) return Vector;

   -- =========================================================================
   -- VARIANT 1: TurboQuant_mse (Preemptive/Base execution for MSE)
   -- =========================================================================
   
   function Quantize_MSE (
      Input           : Vector;
      Rotation_Matrix : Matrix;
      Centroids       : Vector
   ) return TurboQuant_MSE_Data;
   
   function Dequantize_MSE (
      Data            : TurboQuant_MSE_Data;
      Rotation_Matrix : Matrix;
      Centroids       : Vector
   ) return Vector;
   
   -- =========================================================================
   -- VARIANT 2: TurboQuant_prod (Dynamic adjustment for Inner Products via QJL)
   -- =========================================================================
   
   function Quantize_Prod (
      Input           : Vector;
      Rotation_Matrix : Matrix;
      Centroids       : Vector;
      QJL_Matrix      : Matrix
   ) return TurboQuant_Prod_Data;
   
   function Dequantize_Prod (
      Data            : TurboQuant_Prod_Data;
      Rotation_Matrix : Matrix;
      Centroids       : Vector;
      QJL_Matrix      : Matrix
   ) return Vector;

end Turbo_Quant;
