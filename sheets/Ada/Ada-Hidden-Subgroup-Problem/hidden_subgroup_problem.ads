--  ==========================================================================
--  Package: Hidden_Subgroup_Problem
--  Description: Implementation of algorithms for the Abelian Hidden Subgroup
--               Problem (HSP) and its key instances (Simon's Problem, Period
--               Finding, and General Abelian HSP) in Ada 2023.
--  ==========================================================================

package Hidden_Subgroup_Problem is

   -- Domain types and constraints
   type Group_Element is range 0 .. 65535;
   type Bit_Mask is mod 256; -- Modular type for bitwise operations in Simon's problem
   type Period_Type is range 1 .. 65535;

   -- Array types for group elements, vectors, and subgroups
   type Element_Array is array (Positive range <>) of Group_Element;
   type Bit_Mask_Array is array (Positive range <>) of Bit_Mask;

   -- Exceptions
   Invalid_Group_Order : exception;
   Invalid_Oracle      : exception;
   Subgroup_Not_Found  : exception;
   Singular_System     : exception;

   -- Function interface type representing an oracle f: G -> X
   type Oracle_Function is access function (X : Group_Element) return Group_Element;
   type Simon_Oracle_Function is access function (X : Bit_Mask) return Bit_Mask;

   ---------------------------------------------------------------------------
   -- Variant 1: Simon's Problem Solver
   -- Finds the hidden non-zero bit string s in Z_2^n such that f(x) = f(y) <=> x xor y in {0, s}
   ---------------------------------------------------------------------------
   function Solve_Simons_Problem
     (N_Bits : Positive;
      Oracle : Simon_Oracle_Function) return Bit_Mask
     with Pre  => N_Bits in 1 .. 8 and then Oracle /= null,
          Post => Solve_Simons_Problem'Result > 0;

   ---------------------------------------------------------------------------
   -- Variant 2: Period Finding (Order Finding)
   -- Finds the smallest positive integer r such that f(x) = f(x + r) for all x in Z_N.
   ---------------------------------------------------------------------------
   function Solve_Period_Finding
     (N       : Group_Element;
      Oracle : Oracle_Function) return Period_Type
     with Pre  => N > 1 and then Oracle /= null,
          Post => Solve_Period_Finding'Result > 0;

   ---------------------------------------------------------------------------
   -- Variant 3: General Abelian Hidden Subgroup Problem (HSP)
   -- Finds the generating set of the subgroup H <= Z_N hidden by Oracle.
   ---------------------------------------------------------------------------
   function Solve_Abelian_HSP
     (N       : Group_Element;
      Oracle : Oracle_Function) return Element_Array
     with Pre  => N > 1 and then Oracle /= null,
          Post => Solve_Abelian_HSP'Result'Length >= 0;

   ---------------------------------------------------------------------------
   -- Variant 4: Hidden Subgroup Verification
   -- Verifies if the given candidate subgroup elements correctly form a hidden
   -- subgroup for the oracle function.
   ---------------------------------------------------------------------------
   function Verify_Hidden_Subgroup
     (N          : Group_Element;
      Subgroup   : Element_Array;
      Oracle     : Oracle_Function) return Boolean
     with Pre  => N > 1 and then Oracle /= null;

   ---------------------------------------------------------------------------
   -- Helper Functions / Dual Group Character Evaluation
   ---------------------------------------------------------------------------
   function Evaluate_Character_Orthogonality
     (N        : Group_Element;
      G_Char   : Group_Element;
      Subgroup : Element_Array) return Boolean
     with Pre => N > 1;

   function Greatest_Common_Divisor
     (A, B : Group_Element) return Group_Element
     with Post => Greatest_Common_Divisor'Result > 0 or else (A = 0 and B = 0 and Greatest_Common_Divisor'Result = 0);

   ---------------------------------------------------------------------------
   -- Test Oracles (Library-level for test suite access)
   ---------------------------------------------------------------------------
   function Simon_Oracle_Sample_1 (X : Bit_Mask) return Bit_Mask;
   function Simon_Oracle_Sample_2 (X : Bit_Mask) return Bit_Mask;
   function Period_Oracle_Sample_3 (X : Group_Element) return Group_Element;
   function Period_Oracle_Sample_4 (X : Group_Element) return Group_Element;
   function Constant_Oracle (X : Group_Element) return Group_Element;

end Hidden_Subgroup_Problem;
