with Ada.Text_IO; use Ada.Text_IO;
with Design_Ordered_Stream; use Design_Ordered_Stream;
procedure Tests is
   S : Stream := Empty;
begin
   Insert (S, 2, 22); Insert (S, 1, 11);
   if not Has_Next (S) or else Next (S) /= 11 then raise Program_Error; end if;
   Consume (S);
   if not Has_Next (S) or else Next (S) /= 22 then raise Program_Error; end if;
   Put_Line ("Design Ordered Stream: PASS");
end Tests;
