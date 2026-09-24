with Ada.Text_IO; use Ada.Text_IO;
with Design_HashMap; use Design_HashMap;
procedure Tests is
   M : Map := Empty;
begin
   Put (M, 2, 42);
   if not Contains (M, 2) or else Get (M, 2) /= 42 then raise Program_Error; end if;
   Put_Line ("Design HashMap: PASS");
end Tests;
