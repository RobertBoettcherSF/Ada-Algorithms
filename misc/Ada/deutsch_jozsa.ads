--  =========================================================================
--  Package: Deutsch_Jozsa
--  Description: Implementation of the Deutsch-Jozsa quantum algorithm and its
--               classical deterministic and randomized simulation equivalents
--               in Ada 2023.
--  =========================================================================

package Deutsch_Jozsa is

   type Bit is mod 2;
   for Bit'Size use 1;

   type Bit_Vector is array (Positive range <>) of Bit;

   type Algorithm_Result is (Constant_Zero, Constant_One, Balanced, Invalid_Function);

   -- Exceptions
   Invalid_Function_Error : exception;
   Invalid_Dimension_Error  : exception;

   -- Solve Deutsch's original problem (n = 1) using a function pointer.
   function Solve_Deutsch (F : not null access function (X : Bit) return Bit) return Algorithm_Result
     with Pre  => True,
          Post => Solve_Deutsch'Result in Constant_Zero | Constant_One | Balanced;

   -- Solve the general Deutsch-Jozsa problem for n-bits using a truth table.
   function Solve_Deutsch_Jozsa (N : Positive; Truth_Table : Bit_Vector) return Algorithm_Result
     with Pre  => Truth_Table'Length = 2 ** N,
          Post => Solve_Deutsch_Jozsa'Result in Constant_Zero | Constant_One | Balanced | Invalid_Function;

   -- Solve the general Deutsch-Jozsa problem using a function pointer for n-bits.
   function Solve_Deutsch_Jozsa_Fn (N : Positive; F : not null access function (Input : Bit_Vector) return Bit) return Algorithm_Result
     with Pre  => N >= 1,
          Post => Solve_Deutsch_Jozsa_Fn'Result in Constant_Zero | Constant_One | Balanced | Invalid_Function;

   -- Solve using classical deterministic verification.
   function Solve_Classical_Deterministic (N : Positive; Truth_Table : Bit_Vector) return Algorithm_Result
     with Pre  => Truth_Table'Length = 2 ** N,
          Post => Solve_Classical_Deterministic'Result in Constant_Zero | Constant_One | Balanced;

   -- Solve using classical randomized verification.
   function Solve_Classical_Randomized (N : Positive; Truth_Table : Bit_Vector; Trials : Positive) return Algorithm_Result
     with Pre  => Truth_Table'Length = 2 ** N and Trials > 0,
          Post => Solve_Classical_Randomized'Result in Constant_Zero | Constant_One | Balanced;

end Deutsch_Jozsa;
