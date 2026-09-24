--  ========================================================================
--  Package: Hadamard_Test
--  Description: Classical simulation and implementation of the Hadamard test
--               quantum algorithmic primitive (estimating real and imaginary
--               parts of expectation values <psi | U | psi> and inner products).
--  ========================================================================

package Hadamard_Test is

   type Component_Value is digits 6;

   type Complex_Number is record
      Re : Component_Value;
      Im : Component_Value;
   end record;

   type State_Vector is array (Positive range <>) of Complex_Number;
   type Unitary_Matrix is array (Positive range <>, Positive range <>) of Complex_Number;

   -- Exceptions for error handling and edge cases
   Invalid_Dimension : exception;
   Not_Normalized    : exception;
   Not_Unitary       : exception;

   -- Variant 1: Estimate the real part of <psi | U | psi>
   function Estimate_Real_Part
     (State : State_Vector;
      U     : Unitary_Matrix) return Component_Value
     with Pre  => State'Length > 0
                  and then U'Length (1) > 0
                  and then U'Length (2) > 0,
          Post => Estimate_Real_Part'Result >= -1.0
                  and then Estimate_Real_Part'Result <= 1.0,
          Global => null;

   -- Variant 2: Estimate the imaginary part of <psi | U | psi>
   function Estimate_Imaginary_Part
     (State : State_Vector;
      U     : Unitary_Matrix) return Component_Value
     with Pre  => State'Length > 0
                  and then U'Length (1) > 0
                  and then U'Length (2) > 0,
          Post => Estimate_Imaginary_Part'Result >= -1.0
                  and then Estimate_Imaginary_Part'Result <= 1.0,
          Global => null;

   -- Variant 3: Modified Hadamard test for estimating inner product <state_a | state_b>
   function Estimate_Inner_Product
     (State_A : State_Vector;
      State_B : State_Vector) return Complex_Number
     with Pre  => State_A'Length > 0
                  and then State_B'Length > 0,
          Global => null;

   -- Helper validation functions
   function Is_Normalized (State : State_Vector) return Boolean
     with Global => null;

   function Is_Unitary (U : Unitary_Matrix) return Boolean
     with Global => null;

   function Compute_Expectation
     (State : State_Vector;
      U     : Unitary_Matrix) return Complex_Number
     with Pre  => State'Length > 0
                  and then U'Length (1) > 0
                  and then U'Length (2) > 0,
          Global => null;

end Hadamard_Test;
