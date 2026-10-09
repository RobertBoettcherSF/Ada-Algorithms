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

   --  Visit after Back (agent A3): a browser history drops the forward
   --  pages and appends the new page after the current one. Pages 10 20
   --  30, back to 20, visit 40: history 10 20 40, current 40, no
   --  forward page, back gives 20 then 10.
   declare
      B : History := Empty;
   begin
      Visit (B, 10); Visit (B, 20); Visit (B, 30);
      Back (B);
      Visit (B, 40);
      if Current_Page (B) /= 40 or else Current_Index (B) /= 3
        or else Length (B) /= 3
      then
         raise Program_Error with "visit after back";
      end if;
      Back (B);
      if Current_Page (B) /= 20 then raise Program_Error; end if;
      Back (B);
      if Current_Page (B) /= 10 then raise Program_Error; end if;
      --  From the first page, a visit drops both forward pages.
      Visit (B, 50);
      if Length (B) /= 2 or else Current_Page (B) /= 50 then
         raise Program_Error with "visit from the first page";
      end if;
   end;
   Put_Line ("Design Browser History: PASS");
end Tests;
