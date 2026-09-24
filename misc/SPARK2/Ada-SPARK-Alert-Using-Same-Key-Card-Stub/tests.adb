with Ada.Assertions; use Ada.Assertions;
with Alert_Using_Same_Key_Card_Stub; use Alert_Using_Same_Key_Card_Stub;
procedure Tests is
   Safe   : Swipe_Times := (100, 2_000, 4_000, 8_000, others => 0);
   Alert  : Swipe_Times := (100, 2_000, 3_000, 8_000, others => 0);
begin
   Assert (not Has_Three_Within_Hour (Safe, 4));
   Assert (Has_Three_Within_Hour (Alert, 4));
   Assert (not Has_Three_Within_Hour (Alert, 2));
end Tests;
