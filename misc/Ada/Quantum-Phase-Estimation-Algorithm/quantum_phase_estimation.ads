--  Quantum Phase Estimation (QPE) Algorithm Implementation in Ada 2023
--  Based on ISO/IEC 8652:2023 and Wikipedia description.

package Quantum_Phase_Estimation is

   -- Custom domain types
   type Qubit_Count is range 1 .. 24;
   type Phase is digits 12 range 0.0 .. 1.0;
   type Probability is digits 12 range 0.0 .. 1.0;

   -- Exceptions
   Invalid_Qubit_Count : exception;
   Invalid_Phase       : exception;
   Invalid_Argument    : exception;

   -- Record holding the simulation result of QPE
   type QPE_Result is record
      Outcome_Integer : Natural;
      Estimated_Phase : Phase;
      Prob            : Probability;
   end record;

   -- Record holding probabilities for 1-qubit toy QPE
   type Two_Probabilities is record
      P_Plus  : Probability;
      P_Minus : Probability;
   end record;

   -- Variant 1: Simulate standard QPE for given qubit count N and true phase Theta
   function Simulate_QPE (
      N     : Qubit_Count;
      Theta : Phase
   ) return QPE_Result
   with
      Pre  => N in 1 .. 24 and then Theta >= 0.0 and then Theta < 1.0,
      Post => Simulate_QPE'Result.Prob >= 0.0
              and then Simulate_QPE'Result.Prob <= 1.0;

   -- Variant 2: Compute exact success probability Pr(a) for measurement outcome a
   function Compute_Success_Probability (
      N     : Qubit_Count;
      Theta : Phase;
      A     : Natural
   ) return Probability
   with
      Pre  => N in 1 .. 24
              and then Theta >= 0.0 and then Theta < 1.0
              and then A < 2**Integer(N),
      Post => Compute_Success_Probability'Result >= 0.0
              and then Compute_Success_Probability'Result <= 1.0;

   -- Variant 3: Toy 1-qubit QPE variant (calculates p_plus and p_minus)
   function Toy_One_Qubit_QPE (
      Theta : Phase
   ) return Two_Probabilities
   with
      Pre  => Theta >= 0.0 and then Theta < 1.0,
      Post => abs (Toy_One_Qubit_QPE'Result.P_Plus + Toy_One_Qubit_QPE'Result.P_Minus - 1.0) < 1.0E-4
              and then Toy_One_Qubit_QPE'Result.P_Plus >= 0.0
              and then Toy_One_Qubit_QPE'Result.P_Minus >= 0.0;

   -- Variant 4: Required qubits for target additive error epsilon
   function Required_Qubits (
      Epsilon : Float
   ) return Qubit_Count
   with
      Pre  => Epsilon > 0.0 and then Epsilon < 1.0,
      Post => Required_Qubits'Result in 1 .. 24;

   -- Helper function: Validate phase range
   procedure Validate_Phase (Theta : Float);

end Quantum_Phase_Estimation;
