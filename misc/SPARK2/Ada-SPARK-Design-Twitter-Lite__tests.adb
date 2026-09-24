pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Design_Twitter_Lite; use Design_Twitter_Lite;

procedure Tests is
   Messages : constant Message_Array := (10, 11, 12, 13, 14, 15, 16, 17);
   Active   : constant Active_Array := (True, False, True, True, False, False, True, False);
   Empty    : constant Active_Array := (False, False, False, False, False, False, False, False);
begin
   if Feed_Size (Messages, Active) /= 4 then raise Program_Error; end if;
   if Feed_Size (Messages, Empty) /= 0 then raise Program_Error; end if;
   Put_Line ("Design Twitter lite: PASS");
end Tests;
