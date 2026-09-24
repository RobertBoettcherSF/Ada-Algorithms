--  ========================================================================
--  Package: Swap_Test
--  Description: Ada 2023 implementation of the quantum Swap Test algorithm
--               for estimating overlaps and inner products of quantum states.
--  ========================================================================

package Swap_Test is

   type Real is digits 12;

   type Complex_Num is record
      Re : Real;
      Im : Real;
   end record;

   type State_Array is array (Natural range <>) of Complex_Num;

   type Probability is new Real range 0.0 .. 1.0;
   type Shot_Count is new Positive;
   type Overlap_Value is new Real range 0.0 .. 1.0;

   -- Exceptions
   Invalid_State_Exception       : exception;
   Dimension_Mismatch_Exception  : exception;
   Invalid_Argument_Exception    : exception;

   -- Helper: Computes magnitude squared of a complex number
   function Magnitude_Squared (Z : Complex_Num) return Real
     with Post => Magnitude_Squared'Result >= 0.0;

   -- Helper: Computes complex conjugation
   function Conjugate (Z : Complex_Num) return Complex_Num;

   -- Helper: Computes complex multiplication
   function Multiply (A, B : Complex_Num) return Complex_Num;

   -- Validates whether a state vector is normalized (sum of |psi_i|^2 = 1.0 within epsilon)
   function Is_Normalized (State : State_Array) return Boolean;

   -- Returns a normalized copy of the input state vector
   function Normalized_State (State : State_Array) return State_Array
     with Pre  => State'Length > 0,
          Post => Is_Normalized (Normalized_State'Result);

   -- Variant 1: Exact Analytical Swap Test (Calculates exact squared inner product)
   function Exact_Squared_Overlap (State_1, State_2 : State_Array) return Overlap_Value
     with Pre  => State_1'Length = State_2'Length and then State_1'Length > 0
                  and then Is_Normalized (State_1) and then Is_Normalized (State_2),
          Post => Exact_Squared_Overlap'Result >= 0.0 and then Exact_Squared_Overlap'Result <= 1.0;

   -- Variant 2: Ancilla Measurement Probability Calculation
   function Ancilla_Zero_Probability (State_1, State_2 : State_Array) return Probability
     with Pre  => State_1'Length = State_2'Length and then State_1'Length > 0
                  and then Is_Normalized (State_1) and then Is_Normalized (State_2),
          Post => Ancilla_Zero_Probability'Result >= 0.5 and then Ancilla_Zero_Probability'Result <= 1.0;

   -- Variant 3: Monte Carlo / Shot-Based Simulated Swap Test
   function Simulated_Swap_Test (State_1, State_2 : State_Array; Shots : Shot_Count) return Overlap_Value
     with Pre  => State_1'Length = State_2'Length and then State_1'Length > 0
                  and then Is_Normalized (State_1) and then Is_Normalized (State_2),
          Post => Simulated_Swap_Test'Result >= 0.0 and then Simulated_Swap_Test'Result <= 1.0;

   -- Variant 4: Parameterized / Weighted Swap Test with phase factor theta
   function Parameterized_Swap_Test (State_1, State_2 : State_Array; Theta : Real) return Overlap_Value
     with Pre  => State_1'Length = State_2'Length and then State_1'Length > 0
                  and then Is_Normalized (State_1) and then Is_Normalized (State_2);

   type Overlap_Matrix is array (Positive range <>, Positive range <>) of Overlap_Value;

   -- Variant 5: Batched Pairwise Overlap Matrix for Quantum State Clustering
   function Compute_Overlap_Matrix (States : access function (Index : Positive) return State_Array;
                                    Count  : Positive) return Overlap_Matrix
     with Pre  => Count > 0;

end Swap_Test;
