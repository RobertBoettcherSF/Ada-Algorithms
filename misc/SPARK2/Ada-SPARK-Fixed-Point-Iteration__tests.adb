pragma Ada_2022;
with Fixed_Point_Iteration;
procedure Tests is
   Value : constant Integer := Fixed_Point_Iteration.Iterate (0, 100);
begin
   pragma Assert (Value = 99);
   pragma Assert (Fixed_Point_Iteration.Iterate (100, 100) = 100);
end Tests;
