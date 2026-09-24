--  =========================================================================
--  Package: Boson_Sampling
--  Description: Implementation of Boson Sampling computational models,
--               matrix permanents (Ryser's algorithm), transition amplitudes,
--               Standard Boson Sampling, and Scattershot Boson Sampling variants.
--  Language: Ada 2023 (ISO/IEC 8652:2023)
--  =========================================================================

package Boson_Sampling is

   -- Domain-specific types (Strong typing principle)
   type Mode_Index is range 1 .. 64;
   type Mode_Count is range 0 .. 64;
   type Photon_Count is range 0 .. 32;

   type Real is digits 12;

   type Complex_Number is record
      Re : Real;
      Im : Real;
   end record;

   type Complex_Matrix is array (Positive range <>, Positive range <>) of Complex_Number;
   type Photon_Vector is array (Positive range <>) of Photon_Count;
   type Real_Vector is array (Positive range <>) of Real;

   -- Exceptions
   Invalid_Matrix_Dimension : exception;
   Unitarity_Violation      : exception;
   Invalid_Photon_Count     : exception;
   Mismatched_Dimensions    : exception;

   -- Complex arithmetic helpers
   function Add (A, B : Complex_Number) return Complex_Number;
   function Subtract (A, B : Complex_Number) return Complex_Number;
   function Multiply (A, B : Complex_Number) return Complex_Number;
   function Magnitude_Squared (Z : Complex_Number) return Real;

   -- Core Matrix Permanent calculation (Ryser's algorithm)
   -- Pre: Mat must be square.
   function Calculate_Permanent (Mat : Complex_Matrix) return Complex_Number
     with Pre => Mat'Length (1) = Mat'Length (2) and then Mat'Length (1) > 0
             and then Mat'Length (1) <= 12;

   -- Validation helper for interferometer unitary matrices (U*U^dagger = I)
   function Validate_Unitarity (Mat : Complex_Matrix; Tolerance : Real := 1.0E-4) return Boolean
     with Pre => Mat'Length (1) = Mat'Length (2) and then Mat'Length (1) > 0;

   -- Variant 1: Standard Boson Sampling Transition Amplitude
   -- Calculates the amplitude for transitioning from Input_State to Output_State
   function Standard_Transition_Amplitude
     (Interferometer : Complex_Matrix;
      Input_State    : Photon_Vector;
      Output_State   : Photon_Vector) return Complex_Number
     with Pre => Interferometer'Length (1) = Interferometer'Length (2)
             and then Input_State'Length = Interferometer'Length (1)
             and then Output_State'Length = Interferometer'Length (1);

   -- Variant 2: Standard Boson Sampling Probability
   -- Returns |Amplitude|^2 for the given input/output Fock states
   function Standard_Boson_Sampling_Probability
     (Interferometer : Complex_Matrix;
      Input_State    : Photon_Vector;
      Output_State   : Photon_Vector) return Real
     with Pre => Interferometer'Length (1) = Interferometer'Length (2)
             and then Input_State'Length = Interferometer'Length (1)
             and then Output_State'Length = Interferometer'Length (1),
          Post => Standard_Boson_Sampling_Probability'Result >= 0.0;

   -- Variant 3: Scattershot Boson Sampling Probability
   -- Models multiple photon pairs injected into selected input mode pairs (Mode_Mask)
   function Scattershot_Boson_Sampling_Probability
     (Interferometer : Complex_Matrix;
      Mode_Mask      : Photon_Vector;
      Output_State   : Photon_Vector) return Real
     with Pre => Interferometer'Length (1) = Interferometer'Length (2)
             and then Mode_Mask'Length = Interferometer'Length (1)
             and then Output_State'Length = Interferometer'Length (1),
          Post => Scattershot_Boson_Sampling_Probability'Result >= 0.0;

   -- Variant 4: Classical Simulation Complexity Estimation
   -- Estimates the #P-hard computational cost scaling based on photon and mode counts
   function Estimate_Classical_Simulation_Cost
     (Modes   : Mode_Count;
      Photons : Photon_Count) return Real
     with Pre => Natural (Photons) <= Natural (Modes);

end Boson_Sampling;
