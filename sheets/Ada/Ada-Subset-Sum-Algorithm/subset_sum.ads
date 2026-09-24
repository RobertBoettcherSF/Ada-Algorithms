-- subset_sum.ads
-- Specification for the Subset Sum Problem algorithms.
package Subset_Sum is
   
   -- Custom type to ensure strong typing for algorithm data.
   type Element_Type is new Integer;
   
   -- Unconstrained array type for subsets.
   type Element_Array is array (Positive range <>) of Element_Type;

   -----------------------------------------------------------------------------
   -- 1. Exponential Time Algorithm (Naive / Recursive Backtracking)
   -- Complexity: O(2^N) time.
   -- Validates if a subset sums to the target by exhaustively exploring paths.
   -- Supports both negative and positive integers.
   -----------------------------------------------------------------------------
   function Recursive_Subset_Sum (Set : Element_Array; Target : Element_Type) return Boolean;

   -----------------------------------------------------------------------------
   -- 2. Pseudo-Polynomial Time Algorithm (Dynamic Programming)
   -- Complexity: O(N * Target) time and space.
   -- Efficient for small, non-negative targets.
   -- Raises Constraint_Error if negative elements exist in the Set or Target.
   -----------------------------------------------------------------------------
   function DP_Subset_Sum (Set : Element_Array; Target : Element_Type) return Boolean;

   -----------------------------------------------------------------------------
   -- 3. Meet-In-The-Middle Algorithm
   -- Complexity: O(2^(N/2) * N) time.
   -- Substantially faster than simple recursion for N up to ~40.
   -- Splits the set in two, computes all sums, and uses binary search.
   -- Supports negative and positive integers.
   -----------------------------------------------------------------------------
   function Meet_In_The_Middle_Subset_Sum (Set : Element_Array; Target : Element_Type) return Boolean;

   -----------------------------------------------------------------------------
   -- 4. Fully Polynomial Time Approximation Scheme (FPTAS)
   -- Complexity: Polynomial relative to N and 1/C.
   -- Approximates the maximum subset sum <= Target within an error margin C.
   -- Margin C must be > 0.0. Returns the computed approximate maximum sum.
   -- Raises Constraint_Error if negative elements exist in the Set.
   -----------------------------------------------------------------------------
   function Approximate_Subset_Sum (Set : Element_Array; Target : Element_Type; C : Float) return Element_Type;

end Subset_Sum;
