pragma Ada_2022;
with Secant_Method;
procedure Tests is
begin
   pragma Assert (Secant_Method.Solve (0) = 0);
   pragma Assert (Secant_Method.Solve (42) = 42);
   pragma Assert (Secant_Method.Solve (100) = 100);
end Tests;
