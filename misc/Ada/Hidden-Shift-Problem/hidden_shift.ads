-- ============================================================================
-- Package: Hidden_Shift
-- Description: Strongly typed Ada 2023 implementation of the Hidden Shift Problem.
--              Models exhaustive brute-force search and correlation-based peak
--              analysis over cyclic function domains.
-- ============================================================================

package Hidden_Shift is

   -- Domain and range types for the hidden shift problem functions (f and g mapping Z_16 -> R)
   type Domain_Element is mod 16; -- Cyclic domain of size 16 for efficient search & testing
   type Range_Element is range -1000 .. 1000;

   type Function_Table is array (Domain_Element) of Range_Element;

   -- Exceptions
   No_Shift_Found        : exception;
   Invalid_Function_Data : exception;

   -- Variant 1: Brute-Force Exhaustive Search
   -- Searches all possible shifts s in Domain_Element to find the exact shift such that g(x) = f(x + s) for all x.
   function Solve_Brute_Force (F : Function_Table; G : Function_Table) return Domain_Element
     with Pre  => True,
          Post => Verify_Shift (F, G, Solve_Brute_Force'Result);

   -- Variant 2: Correlation / Heuristic Peak Search (simulating Fourier/algebraic peak sampling)
   -- Computes cross-correlation scores for each shift s and selects the maximum correlation peak.
   function Solve_Correlation_Search (F : Function_Table; G : Function_Table) return Domain_Element
     with Pre  => True,
          Post => Compute_Correlation (F, G, Solve_Correlation_Search'Result) <= 16;

   -- Variant 3: Shift Verification (Helper / Public check)
   -- Verifies whether a given candidate shift s satisfies g(x) = f(x + s) for all x in the domain.
   function Verify_Shift (F : Function_Table; G : Function_Table; Shift : Domain_Element) return Boolean
     with Pre  => True,
          Post => Verify_Shift'Result = (for all X in Domain_Element => G (X) = F (X + Shift));

   -- Helper: Compute cross-correlation score between F and G shifted by S
   function Compute_Correlation (F : Function_Table; G : Function_Table; Shift : Domain_Element) return Natural
     with Pre  => True,
          Post => Compute_Correlation'Result <= 16;

end Hidden_Shift;
