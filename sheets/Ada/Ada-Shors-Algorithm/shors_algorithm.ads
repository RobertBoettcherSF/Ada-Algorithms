--------------------------------------------------------------------------------
-- Package: Shors_Algorithm
-- Description: Ada 2023 implementation of Shor's algorithm and its variants:
--              1. Period-Finding (Order Finding)
--              2. Integer Factorization
--              3. Discrete Logarithm Problem
--------------------------------------------------------------------------------

package Shors_Algorithm is

   -- Domain types for strong typing
   type Number is range 0 .. 2_147_483_647;
   type Exponent is range 0 .. 2_147_483_647;
   type Period_Result is range 1 .. 2_147_483_647;

   type Factor_Pair is record
      Factor_1 : Number;
      Factor_2 : Number;
   end record;

   -- Named exceptions for algorithm error handling
   Invalid_Argument     : exception;
   Factorization_Failed : exception;
   Order_Not_Found      : exception;
   Discrete_Log_Failed  : exception;

   -- Variant 1: Period-Finding (Order-Finding)
   -- Given coprime integers A and N (1 < A < N, GCD(A, N) = 1),
   -- finds the smallest positive integer r such that A^r mod N = 1.
   function Find_Period (A : Number; N : Number) return Period_Result
     with Pre  => N > 2 and then A > 1 and then A < N,
          Post => Find_Period'Result > 0;

   -- Variant 2: Integer Factorization (Shor's Factoring Algorithm)
   -- Factors a composite integer N into two non-trivial factors.
   function Factor_Integer (N : Number) return Factor_Pair
     with Pre  => N > 3,
          Post => Factor_Integer'Result.Factor_1 > 1 
              and then Factor_Integer'Result.Factor_2 > 1
              and then (Factor_Integer'Result.Factor_1 * Factor_Integer'Result.Factor_2) = N;

   -- Variant 3: Discrete Logarithm Variant (Shor's Discrete Log Algorithm)
   -- Solves g^x = h mod p for x, where p is prime, g is a generator, h is the target.
   function Solve_Discrete_Logarithm (G : Number; H : Number; P : Number) return Exponent
     with Pre  => P > 2 and then G > 0 and then G < P and then H > 0 and then H < P,
          Post => Solve_Discrete_Logarithm'Result >= 0;

   -- Core arithmetic helper functions
   function GCD (A, B : Number) return Number
     with Post => GCD'Result >= 0;

   function Power_Mod (Base : Number; Exp : Exponent; Modulus_Val : Number) return Number
     with Pre  => Modulus_Val > 0,
          Post => Power_Mod'Result < Modulus_Val or else Modulus_Val = 1;

end Shors_Algorithm;
