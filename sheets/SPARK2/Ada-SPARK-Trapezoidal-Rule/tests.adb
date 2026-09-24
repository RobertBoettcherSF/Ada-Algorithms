pragma Ada_2022;
with Trapezoidal_Rule;
procedure Tests is
   Approximation : constant Integer := Trapezoidal_Rule.Integrate (10);
begin
   pragma Assert (Approximation = 33);
end Tests;
