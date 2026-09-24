with Ada.Assertions; use Ada.Assertions;
with Find_All_Numbers_Disappeared; use Find_All_Numbers_Disappeared;
procedure Tests is
   A : Int_Array := [others => 0];
begin
   A (1 .. 5) := [4, 3, 2, 7, 8];
   Assert (Missing_Count (A) = 27);
   A := [others => 0];
   for I in Index loop
      A (I) := Value (I);
   end loop;
   Assert (Missing_Count (A) = 0);
end Tests;
