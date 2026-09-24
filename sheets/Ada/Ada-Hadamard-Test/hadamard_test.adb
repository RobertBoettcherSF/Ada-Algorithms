--  ========================================================================
--  Package Body: Hadamard_Test
--  Description: Implements complex arithmetic, quantum expectation values,
--               Hadamard test variants (real and imaginary parts), and inner
--               product estimations.
--  ========================================================================

package body Hadamard_Test is

   -- Adds two complex numbers
   function Add (A, B : Complex_Number) return Complex_Number is
   begin
      return (Re => A.Re + B.Re, Im => A.Im + B.Im);
   end Add;

   -- Multiplies two complex numbers
   function Multiply (A, B : Complex_Number) return Complex_Number is
   begin
      return (Re => A.Re * B.Re - A.Im * B.Im,
              Im => A.Re * B.Im + A.Im * B.Re);
   end Multiply;

   -- Computes the complex conjugate of a complex number
   function Conjugate (A : Complex_Number) return Complex_Number is
   begin
      return (Re => A.Re, Im => -A.Im);
   end Conjugate;

   -- Computes the squared magnitude of a complex number (|A|^2)
   function Magnitude_Squared (A : Complex_Number) return Component_Value is
   begin
      return A.Re * A.Re + A.Im * A.Im;
   end Magnitude_Squared;

   -- Validates if a quantum state vector is normalized (sum of squared magnitudes equals 1.0)
   function Is_Normalized (State : State_Vector) return Boolean is
      Total : Component_Value := 0.0;
      Tolerance : constant Component_Value := 1.0E-3;
   begin
      if State'Length = 0 then
         return False;
      end if;
      for I in State'Range loop
         Total := Total + Magnitude_Squared (State (I));
      end loop;
      return abs (Total - 1.0) <= Tolerance;
   end Is_Normalized;

   -- Validates if a matrix is unitary (U* * U = I)
   function Is_Unitary (U : Unitary_Matrix) return Boolean is
      N : constant Integer := U'Length (1);
      Tolerance : constant Component_Value := 1.0E-3;
   begin
      if N = 0 or else U'Length (2) /= N then
         return False;
      end if;

      for I in 1 .. N loop
         for J in 1 .. N loop
            declare
               Prod : Complex_Number := (Re => 0.0, Im => 0.0);
            begin
               for K in 1 .. N loop
                  Prod := Add (Prod, Multiply (Conjugate (U (K, I)), U (K, J)));
               end loop;

               if I = J then
                  if abs (Prod.Re - 1.0) > Tolerance or else abs (Prod.Im) > Tolerance then
                     return False;
                  end if;
               else
                  if abs (Prod.Re) > Tolerance or else abs (Prod.Im) > Tolerance then
                     return False;
                  end if;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end Is_Unitary;

   -- Computes the full expectation value <psi | U | psi>
   function Compute_Expectation
     (State : State_Vector;
      U     : Unitary_Matrix) return Complex_Number
   is
      Sum : Complex_Number := (Re => 0.0, Im => 0.0);
   begin
      if State'Length = 0 or else U'Length (1) /= State'Length or else U'Length (2) /= State'Length then
         raise Invalid_Dimension;
      end if;

      for I in State'Range loop
         declare
            Row_Sum : Complex_Number := (Re => 0.0, Im => 0.0);
         begin
            for J in State'Range loop
               Row_Sum := Add (Row_Sum, Multiply (U (I, J), State (J)));
            end loop;
            Sum := Add (Sum, Multiply (Conjugate (State (I)), Row_Sum));
         end;
      end loop;
      return Sum;
   end Compute_Expectation;

   -- Variant 1: Hadamard test estimating the real part of <psi | U | psi>
   function Estimate_Real_Part
     (State : State_Vector;
      U     : Unitary_Matrix) return Component_Value
   is
      Exp : constant Complex_Number := Compute_Expectation (State, U);
   begin
      return Exp.Re;
   end Estimate_Real_Part;

   -- Variant 2: Hadamard test estimating the imaginary part of <psi | U | psi>
   function Estimate_Imaginary_Part
     (State : State_Vector;
      U     : Unitary_Matrix) return Component_Value
   is
      Exp : constant Complex_Number := Compute_Expectation (State, U);
   begin
      return Exp.Im;
   end Estimate_Imaginary_Part;

   -- Variant 3: Modified Hadamard test estimating inner product <state_a | state_b>
   function Estimate_Inner_Product
     (State_A : State_Vector;
      State_B : State_Vector) return Complex_Number
   is
      Sum : Complex_Number := (Re => 0.0, Im => 0.0);
   begin
      if State_A'Length = 0 or else State_A'Length /= State_B'Length then
         raise Invalid_Dimension;
      end if;

      for I in State_A'Range loop
         Sum := Add (Sum, Multiply (Conjugate (State_A (I)), State_B (I)));
      end loop;
      return Sum;
   end Estimate_Inner_Product;

end Hadamard_Test;
