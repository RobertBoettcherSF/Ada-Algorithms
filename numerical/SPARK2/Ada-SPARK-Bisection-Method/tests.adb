pragma Ada_2022;
with Bisection_Method;
procedure Tests is
begin
   pragma Assert (Bisection_Method.Sqrt (0) = 0);
   pragma Assert (Bisection_Method.Sqrt (144) = 12);
   pragma Assert (Bisection_Method.Sqrt (10_000) = 100);
end Tests;
