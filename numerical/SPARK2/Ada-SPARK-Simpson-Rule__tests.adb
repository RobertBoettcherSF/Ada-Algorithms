pragma Ada_2022;
with Simpson_Rule;
procedure Tests is
   Approximation : constant Integer := Simpson_Rule.Integrate (10);
begin
   pragma Assert (Approximation = 333);
end Tests;
