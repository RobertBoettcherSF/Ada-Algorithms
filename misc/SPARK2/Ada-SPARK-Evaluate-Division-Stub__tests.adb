pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Evaluate_Division_Stub; use Evaluate_Division_Stub;

procedure Tests is
   Equations : constant Equation_Array :=
     (1 => (From => 1, To => 2, Numerator => 2, Denominator => 3),
      2 => (From => 2, To => 3, Numerator => 3, Denominator => 4),
      3 => (From => 3, To => 4, Numerator => 5, Denominator => 6));
   Direct : constant Fraction := Evaluate (Equations, 1, 2);
   Chain  : constant Fraction := Evaluate (Equations, 1, 3);
   Inverse : constant Fraction := Evaluate (Equations, 3, 2);
begin
   if Direct /= (Numerator => 2, Denominator => 3) then raise Program_Error; end if;
   if Chain /= (Numerator => 6, Denominator => 12) then raise Program_Error; end if;
   if Inverse /= (Numerator => 4, Denominator => 3) then raise Program_Error; end if;
   Put_Line ("Evaluate division: PASS");
end Tests;
