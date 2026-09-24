with Ada.Assertions; use Ada.Assertions;
with Missing_Ranges_Stub; use Missing_Ranges_Stub;

procedure Tests is
   No_Values : constant Presence := [others => False];
   Every_Value : constant Presence := [others => True];
   A_Few : Presence := [others => True];
begin
   A_Few (2) := False;
   A_Few (9) := False;
   A_Few (15) := False;
   Assert (Count_Missing (No_Values) = 16);
   Assert (Count_Missing (Every_Value) = 0);
   Assert (Count_Missing (A_Few) = 3);
end Tests;
