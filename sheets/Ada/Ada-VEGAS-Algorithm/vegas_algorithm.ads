--  vegas_algorithm.ads
--  Specification for the VEGAS Multidimensional Monte Carlo Integration Algorithm.
--  Includes variants for Static/Dynamic (Adaptive) Grids and Grid Smoothing.

package Vegas_Algorithm is

   --  Strong typing for algorithmic inputs
   type Dimension_Index is new Positive;
   type Vector is array (Dimension_Index range <>) of Float;
   
   type Domain_Bound is record
      Lower : Float;
      Upper : Float;
   end record;
   
   type Domain_Array is array (Dimension_Index range <>) of Domain_Bound;
   
   --  Pointer to the user-defined multidimensional function to be integrated
   type Integrand_Ptr is access function (X : Vector) return Float;

   --  Exceptions for error handling
   Algorithm_Error : exception;
   Invalid_Input_Error : exception;

   --  Main integration procedure
   --  Variants are controlled via the `Adaptive` and `Smooth_Grid` flags.
   procedure Integrate
     (Func                 : Integrand_Ptr;
      Bounds               : Domain_Array;
      Iterations           : Positive;
      Evaluations_Per_Iter : Positive;
      Result               : out Float;
      Variance             : out Float;
      Adaptive             : Boolean := True;   --  Dynamic grid vs static MC
      Smooth_Grid          : Boolean := True);  --  Smooths rapid grid changes

end Vegas_Algorithm;
