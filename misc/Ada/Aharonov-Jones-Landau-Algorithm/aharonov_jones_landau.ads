package Aharonov_Jones_Landau is

   --  Strongly typed mathematics to avoid bare floats
   type Real is new Long_Float;
   
   type Complex is record
      Re : Real := 0.0;
      Im : Real := 0.0;
   end record;

   type Matrix_2x2 is array (1 .. 2, 1 .. 2) of Complex;

   --  Generators for the Braid Group on 3 strands (B_3). 
   --  Valid values: 1 (sigma_1), -1 (sigma_1_inv), 2 (sigma_2), -2 (sigma_2_inv)
   type Braid_Generator is new Integer range -2 .. 2;
   
   subtype Valid_Generator is Braid_Generator
     with Dynamic_Predicate => Valid_Generator /= 0;

   type Braid is array (Positive range <>) of Valid_Generator;

   --  Algorithm variants demonstrating the core AJL methodology
   type Algorithm_Variant is 
     (Classical_Exact,   -- Exact exponential-time classical matrix trace
      Quantum_Simulated); -- Simulated BQP stochastic measurement (Hadamard test)

   Invalid_Braid_Exception : exception;

   --  Core AJL Subprograms
   
   --  Evaluates the Jones polynomial equivalent (topological trace) of a braid 
   --  at the K-th root of unity.
   function Evaluate_Jones_Polynomial
     (B       : Braid;
      K       : Positive;
      Variant : Algorithm_Variant := Classical_Exact;
      Samples : Positive := 10_000) return Complex
     with 
       Pre  => B'Length > 0 and K >= 3 and Samples > 0;

   --  Helper Subprograms (Public for rigorous testing)
   
   --  Constructs the unitary representation of the braid
   function Build_Unitary (B : Braid; K : Positive) return Matrix_2x2
     with Global => null;

   --  Exact mathematical trace (classical verification)
   function Classical_Trace (M : Matrix_2x2) return Complex
     with Global => null;

   --  Simulates the quantum Hadamard test to estimate the trace stochastically
   function Hadamard_Test_Trace (M : Matrix_2x2; Samples : Positive) return Complex;

   --  Mathematical Overloads
   function "+" (Left, Right : Complex) return Complex with Global => null;
   function "-" (Left, Right : Complex) return Complex with Global => null;
   function "*" (Left, Right : Complex) return Complex with Global => null;
   function "*" (Left : Real; Right : Complex) return Complex with Global => null;
   function "/" (Left : Complex; Right : Real) return Complex with Global => null;
   function "*" (Left, Right : Matrix_2x2) return Matrix_2x2 with Global => null;

end Aharonov_Jones_Landau;
