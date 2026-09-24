with Ada.Assertions; use Ada.Assertions;
with Count_And_Say_Stub; use Count_And_Say_Stub;
procedure Tests is
begin
   Assert (Describe (1) = "1           ");
   Assert (Describe (4) = "1211        ");
   Assert (Describe (5) = "111221      ");
end Tests;
