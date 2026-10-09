with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Design_Browser_History; use Design_Browser_History;
with Own_Checks;
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
   --  Hand-worked (agent A3): a full history (4 pages) refuses a fifth
   --  visit at the last page but accepts one after Back (the last page
   --  is dropped); Forward at the newest page and Back at the first are
   --  refused; nothing changes on a refused call.
   declare
      F       : History := Empty;
      Refused : Boolean;
   begin
      if Length (F) /= 0 or else Current_Index (F) /= 0 then
         raise Program_Error with "empty";
      end if;
      Visit (F, 1); Visit (F, 2); Visit (F, 3); Visit (F, 4);
      Refused := False;
      begin
         Visit (F, 5);
      exception
         when Ada.Assertions.Assertion_Error => Refused := True;
      end;
      if not Refused or else Length (F) /= 4 or else Current_Page (F) /= 4 then
         raise Program_Error with "fifth visit";
      end if;
      Refused := False;
      begin
         Forward (F);
      exception
         when Ada.Assertions.Assertion_Error => Refused := True;
      end;
      if not Refused or else Current_Index (F) /= 4 then
         raise Program_Error with "forward at the newest page";
      end if;
      Back (F);
      Visit (F, 100);
      if Length (F) /= 4 or else Page_At (F, 3) /= 3
        or else Current_Page (F) /= 100
      then
         raise Program_Error with "visit after back in a full history";
      end if;
      Back (F); Back (F); Back (F);
      Refused := False;
      begin
         Back (F);
      exception
         when Ada.Assertions.Assertion_Error => Refused := True;
      end;
      if not Refused or else Current_Page (F) /= 1 then
         raise Program_Error with "back at the first page";
      end if;
      Forward (F); Forward (F);
      if Current_Page (F) /= 3 or else Length (F) /= 4 then
         raise Program_Error with "forward keeps the pages";
      end if;
   end;
   Own_Checks;
   Put_Line ("Design Browser History: PASS");
end Tests;
