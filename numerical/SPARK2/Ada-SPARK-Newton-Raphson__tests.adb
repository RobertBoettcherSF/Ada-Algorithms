pragma Ada_2022;
with Newton_Raphson;
procedure Tests is
begin
   pragma Assert (Newton_Raphson.Sqrt (1) = 1);
   pragma Assert (Newton_Raphson.Sqrt (144) = 12);
   pragma Assert (Newton_Raphson.Sqrt (10_000) = 100);
end Tests;
