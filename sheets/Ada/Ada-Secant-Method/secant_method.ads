package Secant_Method is

   -- Strong typing for numerical precision 
   type Real is digits 15;
   
   -- Enumeration for all possible terminal states (Edge Cases & Success)
   type Status_Type is 
     (Success, 
      Division_By_Zero, 
      Max_Iterations_Reached, 
      Invalid_Bracket);

   -- Custom record to return robust results instead of relying on out parameters
   type Root_Result is record
      Root           : Real;
      Value_At_Root  : Real;
      Iterations     : Natural;
      Status         : Status_Type;
   end record;

   -- Variant 1: Standard Secant Method
   -- Open method: Uses two initial points but does not require them to bracket the root.
   -- Uses an anonymous access parameter to allow downward closures (local functions).
   function Standard_Secant
     (Func       : not null access function (X : Real) return Real;
      X0         : Real;
      X1         : Real;
      Tolerance  : Real := 1.0E-7;
      Max_Iter   : Positive := 100) return Root_Result;

   -- Variant 2: False Position Method (Regula Falsi)
   -- Bracketed method: Requires initial points to bracket the root (opposite signs).
   function False_Position
     (Func       : not null access function (X : Real) return Real;
      X0         : Real;
      X1         : Real;
      Tolerance  : Real := 1.0E-7;
      Max_Iter   : Positive := 100) return Root_Result;

end Secant_Method;
