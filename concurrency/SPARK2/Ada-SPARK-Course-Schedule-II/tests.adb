pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Course_Schedule_II; use Course_Schedule_II;
procedure Tests is
   P : Prerequisite_Matrix := [others => [others => False]];
   R : Order_Result;
begin
   R := Build_Order (P);
   Assert (R.Success and then R.Items (1) = 1 and then R.Items (Capacity) = Capacity);
   P (4, 4) := True;
   R := Build_Order (P);
   Assert (not R.Success);
end Tests;
