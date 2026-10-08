--  ===========================================================================
--  Package: Hidden_Linear_Function
--  Description: Specification for the Hidden Linear Function (HLF) problem
--               generalizing the Bernstein-Vazirani problem.
--  ===========================================================================

package Hidden_Linear_Function is

   -- Custom domain types
   type Bit is range 0 .. 1;
   type Mod_4 is range 0 .. 3;

   type Bit_Vector is array (Positive range <>) of Bit;
   type Matrix is array (Positive range <>, Positive range <>) of Bit;

   -- Domain exceptions
   Invalid_Matrix : exception;
   Invalid_Vector : exception;
   No_Solution    : exception;

   -- Dimension constraint subtype
   subtype Dimension is Positive range 1 .. 16;

   -- Validation helper functions
   function Is_Upper_Triangular (A : Matrix) return Boolean;
   function Is_Valid_Problem (A : Matrix; b : Bit_Vector) return Boolean;

   -- Variant 1: Evaluate quadratic form q(x) = (2 * x^T A x + b^T x) mod 4
   function Evaluate_Quadratic_Form 
     (A : Matrix; 
      b : Bit_Vector; 
      x : Bit_Vector) return Mod_4
   with
     Pre => Is_Valid_Problem (A, b) and then x'Length = A'Length (1);

   -- Variant 2: Subspace L_q membership test
   -- x in L_q if q(x xor y) = (q(x) + q(y)) mod 4 for all y
   function Is_In_Subspace_Lq 
     (A : Matrix; 
      b : Bit_Vector; 
      x : Bit_Vector) return Boolean
   with
     Pre => Is_Valid_Problem (A, b) and then x'Length = A'Length (1);

   -- Variant 3: Find hidden vector z such that q(x) = 2 * z^T x for all x in L_q
   function Find_Hidden_Vector 
     (A : Matrix; 
      b : Bit_Vector) return Bit_Vector
   with
     Pre => Is_Valid_Problem (A, b),
     Post => Find_Hidden_Vector'Result'Length = A'Length (1);

   -- Variant 4: Verify candidate hidden vector z against problem instance
   function Verify_Hidden_Vector 
     (A : Matrix; 
      b : Bit_Vector; 
      z : Bit_Vector) return Boolean
   with
     Pre => Is_Valid_Problem (A, b) and then z'Length = A'Length (1);

end Hidden_Linear_Function;
