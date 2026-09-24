with Ada.Assertions; use Ada.Assertions;
with Recent_Counter; use Recent_Counter;
procedure Tests is
   Requests : Timestamp_Array := (100, 2_000, 3_000, 4_000, others => 0);
begin
   Assert (Count_Recent (Requests, 0, 4_000) = 0);
   Assert (Count_Recent (Requests, 4, 4_000) = 3);
   Assert (Count_Recent (Requests, 4, 100_000) = 0);
end Tests;
