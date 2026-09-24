-------------------------------------------------------------------------------
-- Simon's Problem Algorithm Implementation in Ada 2023
-- Provides decision, classical search, randomized sampling, linear system
-- solver over GF(2), and promise verification variants.
-------------------------------------------------------------------------------

package Simons_Problem is

   -- Custom types for domain modeling
   type Bit is range 0 .. 1;
   for Bit'Size use 8;

   type Bit_Vector is array (Positive range <>) of Bit;

   type Function_Table is array (Natural range <>, Positive range <>) of Bit;

   type Equation_Matrix is array (Positive range <>, Positive range <>) of Bit;

   -- Named Exceptions
   Invalid_Function_Error   : exception;
   Invalid_Dimension_Error  : exception;
   Singular_System_Error    : exception;

   -- Variant 1: Decision version — determines if f is one-to-one (s = 0) or two-to-one
   function Is_One_To_One_Function (Table : Function_Table) return Boolean
     with Pre => Table'Length(1) > 0 and then Is_Power_Of_Two (Table'Length(1))
                 and then Table'Length(2) = Log2 (Table'Length(1));

   -- Variant 2: Secret String Reconstruction (Deterministic Classical Collision Search)
   function Find_Secret_Classical (Table : Function_Table) return Bit_Vector
     with Pre => Table'Length(1) > 0 and then Is_Power_Of_Two (Table'Length(1))
                 and then Table'Length(2) = Log2 (Table'Length(1));

   -- Variant 3: Algebraic System Solver over GF(2) (Simulating Simon's linear step)
   function Solve_Simon_System (Equations : Equation_Matrix; Dimension : Positive) return Bit_Vector
     with Pre => Equations'Length(1) > 0 and then Equations'Length(2) = Dimension + 1;

   -- Variant 4: Randomized Sampling Simulation (Quantum-inspired query and solve)
   function Find_Secret_Randomized_Sampling (Table : Function_Table) return Bit_Vector
     with Pre => Table'Length(1) > 0 and then Is_Power_Of_Two (Table'Length(1))
                 and then Table'Length(2) = Log2 (Table'Length(1));

   -- Variant 5: Promise Verification (Validates if f satisfies Simon's promise for secret s)
   function Verify_Simon_Promise (Table : Function_Table; S : Bit_Vector) return Boolean
     with Pre => Table'Length(1) > 0 and then Is_Power_Of_Two (Table'Length(1))
                 and then Table'Length(2) = Log2 (Table'Length(1))
                 and then S'Length = Table'Length(2);

   -- Helper Functions
   function Is_Power_Of_Two (N : Natural) return Boolean;
   
   function Log2 (N : Natural) return Natural
     with Pre => N > 0 and then Is_Power_Of_Two (N);

   function Bitwise_Xor (A, B : Bit_Vector) return Bit_Vector
     with Pre => A'Length = B'Length;

   function Dot_Product (A, B : Bit_Vector) return Bit
     with Pre => A'Length = B'Length;

   function Vector_To_Natural (V : Bit_Vector) return Natural;

   function Natural_To_Vector (N : Natural; Width : Positive) return Bit_Vector;

end Simons_Problem;
