-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Trigonometric_Interpolation; use Trigonometric_Interpolation;
with Ada.Numerics;

procedure Main is
   -- A simple triangle-like dataset
   Data   : constant Real_Array (0 .. 3) := (0.0, 1.0, 0.0, -1.0);
   Coeffs : constant Interpolation_Coefficients := Calculate_Coefficients (Data);
   X_Val  : Long_Float;
begin
   Put_Line ("Trigonometric Interpolation Demonstration");
   Put_Line ("=========================================");
   Put_Line ("Interpolating 4 points: Y = [0, 1, 0, -1]");
   
   Put_Line ("Coefficients:");
   Put_Line ("A0 = " & Long_Float'Image (Coeffs.A(0)));
   for I in 1 .. Coeffs.K loop
      Put_Line ("A" & Integer'Image(I) & " = " & Long_Float'Image (Coeffs.A(I)));
      Put_Line ("B" & Integer'Image(I) & " = " & Long_Float'Image (Coeffs.B(I)));
   end loop;

   Put_Line ("");
   Put_Line ("Evaluations at nodes (should match input):");
   for I in 0 .. 3 loop
      X_Val := 2.0 * Ada.Numerics.Pi * Long_Float (I) / 4.0;
      Put_Line ("X = " & Long_Float'Image (X_Val) & " | f(X) = " & Long_Float'Image (Evaluate (Coeffs, X_Val)));
   end loop;
end Main;
