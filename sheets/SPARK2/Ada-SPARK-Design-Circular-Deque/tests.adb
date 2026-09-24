with Ada.Text_IO; use Ada.Text_IO;
with Design_Circular_Deque; use Design_Circular_Deque;
procedure Tests is
   D : Deque := Empty;
begin
   Push_Back (D, 4); Push_Front (D, 2); Push_Back (D, 6);
   if Front (D) /= 2 or else Length (D) /= 3 then raise Program_Error; end if;
   Pop_Front (D);
   if Front (D) /= 4 then raise Program_Error; end if;
   Put_Line ("Design Circular Deque: PASS");
end Tests;
