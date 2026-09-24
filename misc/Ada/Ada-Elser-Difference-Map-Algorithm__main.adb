-- main.adb
-- Example usage of the Difference Map Algorithm.
with Ada.Text_IO; use Ada.Text_IO;
with Difference_Map; use Difference_Map;

procedure Main is
   
   -- Set A: The X-axis (y = 0)
   function Proj_X_Axis (V : Vector) return Vector is
      Result : Vector := V;
   begin
      Result(2) := 0.0;
      return Result;
   end Proj_X_Axis;
   
   -- Set B: The line y = x
   function Proj_Y_Equals_X (V : Vector) return Vector is
      Result : Vector := V;
      Avg    : constant Real := (V(1) + V(2)) / 2.0;
   begin
      Result(1) := Avg;
      Result(2) := Avg;
      return Result;
   end Proj_Y_Equals_X;

   X          : Vector (1 .. 2) := (5.0, 10.0);
   Converged  : Boolean;
   Iterations : Natural;

begin
   Put_Line ("Starting Difference Map for Intersection of y=0 and y=x");
   Put_Line ("Initial Point: (" & Real'Image(X(1)) & ", " & Real'Image(X(2)) & ")");

   Solve (X          => X,
          P_A        => Proj_X_Axis'Unrestricted_Access,
          P_B        => Proj_Y_Equals_X'Unrestricted_Access,
          Beta       => 0.5,
          Max_Iter   => 100,
          Tolerance  => 0.0001,
          Converged  => Converged,
          Iterations => Iterations);

   if Converged then
      Put_Line ("Converged in " & Natural'Image(Iterations) & " iterations.");
   else
      Put_Line ("Did not converge within iteration limit.");
   end if;
   
   Put_Line ("Final Point: (" & Real'Image(X(1)) & ", " & Real'Image(X(2)) & ")");
   -- The true solution is the intersection at (0.0, 0.0).
end Main;
