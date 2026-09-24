-- difference_map.adb
-- Implementation of the Difference-map algorithm and its helper functions.
with Ada.Numerics.Elementary_Functions;

package body Difference_Map is

   -- Helper: Vector Addition
   function "+" (Left, Right : Vector) return Vector is
   begin
      if Left'Length /= Right'Length then
         raise Dimension_Error with "Vectors must have the same length for addition.";
      end if;
      declare
         Result : Vector (Left'Range);
         R_Idx  : Positive := Right'First;
      begin
         for L_Idx in Left'Range loop
            Result (L_Idx) := Left (L_Idx) + Right (R_Idx);
            R_Idx := R_Idx + 1;
         end loop;
         return Result;
      end;
   end "+";

   -- Helper: Vector Subtraction
   function "-" (Left, Right : Vector) return Vector is
   begin
      if Left'Length /= Right'Length then
         raise Dimension_Error with "Vectors must have the same length for subtraction.";
      end if;
      declare
         Result : Vector (Left'Range);
         R_Idx  : Positive := Right'First;
      begin
         for L_Idx in Left'Range loop
            Result (L_Idx) := Left (L_Idx) - Right (R_Idx);
            R_Idx := R_Idx + 1;
         end loop;
         return Result;
      end;
   end "-";

   -- Helper: Scalar Multiplication
   function "*" (Left : Real; Right : Vector) return Vector is
      Result : Vector (Right'Range);
   begin
      for I in Right'Range loop
         Result (I) := Left * Right (I);
      end loop;
      return Result;
   end "*";

   -- Helper: L2 Norm (Euclidean distance)
   function Norm (X : Vector) return Real is
      use Ada.Numerics.Elementary_Functions;
      Sum_Sq : Real := 0.0;
   begin
      if X'Length = 0 then
         return 0.0;
      end if;
      for I in X'Range loop
         Sum_Sq := Sum_Sq + (X (I) * X (I));
      end loop;
      return Real (Sqrt (Float (Sum_Sq)));
   end Norm;

   -- Generalized Difference-map Step
   function Generalized_Step
     (X       : Vector;
      P_A     : Projection_Function;
      P_B     : Projection_Function;
      Beta    : Real;
      Gamma_A : Real;
      Gamma_B : Real) return Vector
   is
      P_A_X, P_B_X : Vector (X'Range);
      F_A_X, F_B_X : Vector (X'Range);
   begin
      if X'Length = 0 then
         raise Parameter_Error with "Cannot step with an empty vector.";
      end if;

      -- Calculate initial projections
      P_A_X := P_A (X);
      P_B_X := P_B (X);

      -- Calculate F_A(x) = P_A(x) - Gamma_A * (P_A(x) - x)
      F_A_X := P_A_X - (Gamma_A * (P_A_X - X));
      
      -- Calculate F_B(x) = P_B(x) + Gamma_B * (P_B(x) - x)
      F_B_X := P_B_X + (Gamma_B * (P_B_X - X));

      -- Return x + Beta * (P_A(F_B(x)) - P_B(F_A(x)))
      return X + (Beta * (P_A (F_B_X) - P_B (F_A_X)));
   end Generalized_Step;

   -- Standard Difference-map Step
   function Standard_Step
     (X    : Vector;
      P_A  : Projection_Function;
      P_B  : Projection_Function;
      Beta : Real) return Vector
   is
      Gamma : Real;
   begin
      if Beta = 0.0 then
         raise Parameter_Error with "Beta cannot be zero in Standard Difference Map.";
      end if;
      Gamma := 1.0 / Beta;
      return Generalized_Step (X, P_A, P_B, Beta, Gamma, Gamma);
   end Standard_Step;

   -- Douglas-Rachford Step
   function Douglas_Rachford_Step
     (X   : Vector;
      P_A : Projection_Function;
      P_B : Projection_Function) return Vector
   is
   begin
      -- Douglas-Rachford is exactly Difference Map with Beta=1, Gamma_A=1, Gamma_B=1
      return Generalized_Step (X, P_A, P_B, 1.0, 1.0, 1.0);
   end Douglas_Rachford_Step;

   -- Alternating Projections Step
   function Alternating_Projections_Step
     (X   : Vector;
      P_A : Projection_Function;
      P_B : Projection_Function) return Vector
   is
   begin
      if X'Length = 0 then
         raise Parameter_Error with "Cannot step with an empty vector.";
      end if;
      return P_B (P_A (X));
   end Alternating_Projections_Step;

   -- Main Iterative Solver
   procedure Solve
     (X          : in out Vector;
      P_A        : Projection_Function;
      P_B        : Projection_Function;
      Beta       : Real;
      Max_Iter   : Positive;
      Tolerance  : Real;
      Converged  : out Boolean;
      Iterations : out Natural)
   is
      X_Next : Vector (X'Range);
      Error  : Real;
   begin
      Converged  := False;
      Iterations := 0;

      for I in 1 .. Max_Iter loop
         X_Next := Standard_Step (X, P_A, P_B, Beta);
         
         -- Calculate error as the norm of the difference between iterations
         Error := Norm (X_Next - X);
         X := X_Next;
         Iterations := I;

         if Error <= Tolerance then
            Converged := True;
            return;
         end if;
      end loop;
   end Solve;

end Difference_Map;
