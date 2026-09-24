-- difference_map.ads
-- Specification for the Difference-map algorithm and its variants.

package Difference_Map is

   -- Custom types for algorithm-specific data to ensure strong typing
   type Real is new Float;
   type Vector is array (Positive range <>) of Real;

   -- Exceptions for edge cases and input validation
   Dimension_Error : exception;
   Parameter_Error : exception;

   -- Function pointer type for Set Projections (P_A and P_B)
   -- A projection function finds the closest point in a constraint set to X.
   type Projection_Function is access function (X : Vector) return Vector;

   -- =========================================================================
   -- Helper Functions
   -- =========================================================================
   function "+" (Left, Right : Vector) return Vector;
   function "-" (Left, Right : Vector) return Vector;
   function "*" (Left : Real; Right : Vector) return Vector;
   function Norm (X : Vector) return Real;

   -- =========================================================================
   -- Variant 1: Generalized Difference-map Step
   -- Uses explicit Gamma_A and Gamma_B parameters.
   -- =========================================================================
   function Generalized_Step
     (X       : Vector;
      P_A     : Projection_Function;
      P_B     : Projection_Function;
      Beta    : Real;
      Gamma_A : Real;
      Gamma_B : Real) return Vector;

   -- =========================================================================
   -- Variant 2: Standard Difference-map Step
   -- Gamma_A and Gamma_B are automatically set to 1 / Beta.
   -- =========================================================================
   function Standard_Step
     (X    : Vector;
      P_A  : Projection_Function;
      P_B  : Projection_Function;
      Beta : Real) return Vector;

   -- =========================================================================
   -- Variant 3: Douglas-Rachford Step
   -- A specific instance where Beta = 1.0, Gamma_A = 1.0, and Gamma_B = 1.0.
   -- =========================================================================
   function Douglas_Rachford_Step
     (X   : Vector;
      P_A : Projection_Function;
      P_B : Projection_Function) return Vector;

   -- =========================================================================
   -- Variant 4: Alternating Projections Step
   -- Related trivial variant: X_new = P_B(P_A(X))
   -- =========================================================================
   function Alternating_Projections_Step
     (X   : Vector;
      P_A : Projection_Function;
      P_B : Projection_Function) return Vector;

   -- =========================================================================
   -- Main Solver Routine
   -- Iterates the Standard Difference-map until convergence or Max_Iter.
   -- =========================================================================
   procedure Solve
     (X          : in out Vector;
      P_A        : Projection_Function;
      P_B        : Projection_Function;
      Beta       : Real;
      Max_Iter   : Positive;
      Tolerance  : Real;
      Converged  : out Boolean;
      Iterations : out Natural);

end Difference_Map;
