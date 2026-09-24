with Ada.Assertions; use Ada.Assertions;
with Range_Module_Stub; use Range_Module_Stub;
procedure Tests is
   Ranges : Interval_Array :=
     ((First => 0, Last => 10), (First => 20, Last => 40), others => (First => 0, Last => 0));
begin
   Assert (Covers (Ranges, 2, 2, 8));
   Assert (Covers (Ranges, 2, 20, 40));
   Assert (not Covers (Ranges, 2, 10, 20));
end Tests;
