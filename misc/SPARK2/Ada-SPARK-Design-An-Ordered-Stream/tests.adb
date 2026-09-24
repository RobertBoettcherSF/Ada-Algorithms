with Ada.Text_IO; use Ada.Text_IO;
with Design_An_Ordered_Stream; use Design_An_Ordered_Stream;
procedure Tests is
   S : Stream := Empty;
begin
   Put (S, 1, 5); Put (S, 3, 15);
   if not Ready (S) or else Read (S) /= 5 then raise Program_Error; end if;
   Advance (S);
   if Ready (S) then raise Program_Error; end if;
   Put_Line ("Design An Ordered Stream: PASS");
end Tests;
