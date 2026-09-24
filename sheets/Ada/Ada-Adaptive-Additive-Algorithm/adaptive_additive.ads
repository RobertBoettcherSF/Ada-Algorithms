with Ada.Numerics.Complex_Types;

-- Package: Adaptive_Additive
-- Implements the Adaptive-Additive iterative algorithm for spatial frequency 
-- phase reconstruction used in Fourier optics and related fields.
package Adaptive_Additive is

   -- Strong typing for algorithm-specific data arrays
   type Real_Array is array (Positive range <>) of Float;
   subtype Mixing_Ratio_Type is Float range 0.0 .. 1.0;

   -- Raised when input arrays have mismatching bounds, empty sizes, or invalid domain values
   Invalid_Input_Error : exception;

   -- 1. Standard Adaptive-Additive Algorithm Variant
   -- Configurable mixing ratio (a) allowing a blend of transformed and desired amplitudes.
   procedure AA_Algorithm
     (Input_Amplitude   : in Real_Array;
      Desired_Intensity : in Real_Array;
      Mixing_Ratio      : in Mixing_Ratio_Type;
      Max_Iterations    : in Positive;
      Tolerance         : in Float;
      Result_Phase      : out Real_Array;
      Converged         : out Boolean);

   -- 2. Gerchberg-Saxton Algorithm Variant
   -- Defined in literature as the limit where mixing ratio (a) = 1.0.
   procedure Gerchberg_Saxton
     (Input_Amplitude   : in Real_Array;
      Desired_Intensity : in Real_Array;
      Max_Iterations    : in Positive;
      Tolerance         : in Float;
      Result_Phase      : out Real_Array;
      Converged         : out Boolean);

   -- 3. Fixed-Amplitude Variant
   -- Defined in literature as the limit where mixing ratio (a) = 0.0.
   procedure Fixed_Amplitude
     (Input_Amplitude   : in Real_Array;
      Desired_Intensity : in Real_Array;
      Max_Iterations    : in Positive;
      Tolerance         : in Float;
      Result_Phase      : out Real_Array;
      Converged         : out Boolean);

   -- Exported fundamental helpers for testing and validation purposes
   use Ada.Numerics.Complex_Types;
   type Complex_Array is array (Positive range <>) of Complex;

   function Modulus_Helper (C : Complex) return Float;
   function Argument_Helper (C : Complex) return Float;
   function DFT (Input : Complex_Array; Inverse : Boolean := False) return Complex_Array;

end Adaptive_Additive;
