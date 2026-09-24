with Ada.Assertions; use Ada.Assertions;
with Number_Of_Recent_Calls; use Number_Of_Recent_Calls;
procedure Tests is
   Calls : Call_Times := (1_000, 2_000, 5_000, 5_000, others => 0);
begin
   Assert (Number_In_Window (Calls, 4, 5_000) = 3);
   Assert (Number_In_Window (Calls, 4, 8_000) = 2);
   Assert (Number_In_Window (Calls, 0, 8_000) = 0);
end Tests;
