pragma Ada_2022;
with Number_Of_Steps_To_Reduce;
procedure Tests is
   use Number_Of_Steps_To_Reduce;
begin
   pragma Assert (Steps (1) = 0);
   pragma Assert (Steps (3) = 2);
   pragma Assert (Steps (8) = 3);
   pragma Assert (Steps (12) = 4);
   pragma Assert (Steps (15) = 6);
end Tests;
