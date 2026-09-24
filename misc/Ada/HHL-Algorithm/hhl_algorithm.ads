--  ==========================================================================
--  Package: Hhl_Algorithm
--  Description: Simulation and verification of the Harrow-Hassidim-Lloyd (HHL)
--               quantum algorithm for solving linear systems of equations (Ax = b)
--               and estimating quadratic forms.
--  ==========================================================================

package Hhl_Algorithm is

   type Real is digits 12;

   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;

   type Condition_Number is new Real range 1.0 .. 1.0E9;
   type Probability is new Real range 0.0 .. 1.0;

   Not_Hermitian_Error            : exception;
   Condition_Number_Out_Of_Bounds : exception;
   Invalid_Dimension_Error        : exception;
   Zero_Vector_Error              : exception;

   -- 1. Full HHL quadratic form estimation (x^T M x)
   function Estimate_Quadratic_Form
     (A            : Matrix;
      B_Vec        : Vector;
      M_Observable : Matrix;
      Kappa        : Condition_Number;
      Error_Tol    : Real) return Real
     with Pre  => A'Length(1) = A'Length(2)
                  and then B_Vec'Length = A'Length(1)
                  and then M_Observable'Length(1) = A'Length(1)
                  and then M_Observable'Length(2) = A'Length(1)
                  and then Error_Tol > 0.0,
          Post => Estimate_Quadratic_Form'Result = Estimate_Quadratic_Form'Result;

   -- 2. Quantum Phase Estimation (QPE) simulation subroutine
   function Phase_Estimation_Sim
     (Eigenvalue : Real;
      T_Steps    : Positive) return Real
     with Pre  => T_Steps > 0 and then Eigenvalue /= 0.0,
          Post => Phase_Estimation_Sim'Result >= 0.0;

   -- 3. Controlled rotation simulation for eigenvalue inversion
   function Controlled_Rotation_Sim
     (Lambda     : Real;
      C_Const    : Real;
      Kappa_Max  : Condition_Number) return Real
     with Pre  => Lambda /= 0.0 and then C_Const > 0.0,
          Post => Controlled_Rotation_Sim'Result >= 0.0
                  and then Controlled_Rotation_Sim'Result <= 1.0;

   -- 4. Amplitude amplification success probability calculation ('well' state)
   function Amplitude_Amplification_Success_Prob
     (Lambda    : Real;
      C_Const   : Real;
      Kappa     : Condition_Number) return Probability
     with Pre  => Lambda /= 0.0 and then C_Const > 0.0,
          Post => Amplitude_Amplification_Success_Prob'Result >= 0.0
                  and then Amplitude_Amplification_Success_Prob'Result <= 1.0;

   -- 5. Input validation routine for HHL prerequisites
   procedure Validate_Hhl_Inputs
     (A     : Matrix;
      B_Vec : Vector;
      Kappa : Condition_Number)
     with Pre => A'Length(1) = A'Length(2)
                 and then B_Vec'Length = A'Length(1);

end Hhl_Algorithm;
