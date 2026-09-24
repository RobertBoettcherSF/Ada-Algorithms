with Ada.Text_IO; use Ada.Text_IO;
with Design_Browser_History; use Design_Browser_History;
procedure Tests is
   H : History := Empty;
begin
   Visit (H, 10); Visit (H, 20); Visit (H, 30);
   Back (H);
   if Current_Page (H) /= 20 then raise Program_Error; end if;
   Forward (H);
   if Current_Page (H) /= 30 then raise Program_Error; end if;
   Put_Line ("Design Browser History: PASS");
end Tests;
