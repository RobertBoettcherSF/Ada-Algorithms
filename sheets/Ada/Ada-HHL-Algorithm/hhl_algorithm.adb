with Ada.Numerics.Generic_Elementary_Functions;

package body Hhl_Algorithm is

   package Real_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Functions;

   function Is_Hermitian (A : Matrix; Tolerance : Real := 1.0E-6) return Boolean is
      N : constant Natural := A'Length(1);
   begin
      if A'Length(2) /= N then
         return false;
      end if;
      for I in A'Range(1) loop
         for J in A'Range(2) loop
            if abs (A (I, J) - A (J, I)) > Tolerance then
               return false;
            end if;
         end loop;
      end loop;
      return true;
   end Is_Hermitian;

   function Vector_Norm (V : Vector) return Real is
      Sum : Real := 0.0;
   begin
      for X of V loop
         Sum := Sum + X * X;
      end loop;
      return Sqrt (Sum);
   end Vector_Norm;

   procedure Validate_Hhl_Inputs
     (A     : Matrix;
      B_Vec : Vector;
      Kappa : Condition_Number) is
   begin
      if A'Length(1) /= A'Length(2) or else B_Vec'Length /= A'Length(1) then
         raise Invalid_Dimension_Error;
      end if;

      if not Is_Hermitian (A) then
         raise Not_Hermitian_Error;
      end if;

      if Vector_Norm (B_Vec) = 0.0 then
         raise Zero_Vector_Error;
      end if;

      if Real (Kappa) < 1.0 then
         raise Condition_Number_Out_Of_Bounds;
      end if;
   end Validate_Hhl_Inputs;

   function Phase_Estimation_Sim
     (Eigenvalue : Real;
      T_Steps    : Positive) return Real is
      Scale : constant Real := Real (T_Steps);
   begin
      return Eigenvalue * (1.0 + (1.0 / (Scale * Scale)));
   end Phase_Estimation_Sim;

   function Controlled_Rotation_Sim
     (Lambda     : Real;
      C_Const    : Real;
      Kappa_Max  : Condition_Number) return Real is
      Ratio : Real;
      pragma Unreferenced (Kappa_Max);
   begin
      if abs (Lambda) < 1.0E-12 then
         raise Condition_Number_Out_Of_Bounds;
      end if;
      Ratio := C_Const / abs (Lambda);
      if Ratio > 1.0 then
         Ratio := 1.0;
      end if;
      return Ratio;
   end Controlled_Rotation_Sim;

   function Amplitude_Amplification_Success_Prob
     (Lambda    : Real;
      C_Const   : Real;
      Kappa     : Condition_Number) return Probability is
      Rot : constant Real := Controlled_Rotation_Sim (Lambda, C_Const, Kappa);
   begin
      declare
         Prob : constant Real := (Rot * Rot) / (Real (Kappa) * Real (Kappa));
      begin
         if Prob > 1.0 then
            return 1.0;
         elsif Prob < 0.0 then
            return 0.0;
         else
            return Probability (Prob);
         end if;
      end;
   end Amplitude_Amplification_Success_Prob;

   function Estimate_Quadratic_Form
     (A            : Matrix;
      B_Vec        : Vector;
      M_Observable : Matrix;
      Kappa        : Condition_Number;
      Error_Tol    : Real) return Real is
      Norm_B : Real;
   begin
      Validate_Hhl_Inputs (A, B_Vec, Kappa);

      if Error_Tol <= 0.0 then
         raise Constraint_Error;
      end if;

      Norm_B := Vector_Norm (B_Vec);

      declare
         N : constant Positive := A'Length(1);
         Approx_Result : Real := 0.0;
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               Approx_Result := Approx_Result + M_Observable (I, J) * B_Vec (I) * B_Vec (J) / (Real (Kappa) * Norm_B);
            end loop;
         end loop;
         return Approx_Result;
      end;
   end Estimate_Quadratic_Form;

end Hhl_Algorithm;
