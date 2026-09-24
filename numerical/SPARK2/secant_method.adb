pragma Ada_2022;
package body Secant_Method with SPARK_Mode => On is
   function Solve (Target : Target_Value) return Integer is
      X0 : constant Integer := 0;
      X1 : constant Integer := 100;
      F0 : constant Integer := X0 - Target;
      F1 : constant Integer := X1 - Target;
      Denominator : constant Integer := F1 - F0;
   begin
      return X1 - ((X1 - X0) * F1) / Denominator;
   end Solve;
end Secant_Method;
