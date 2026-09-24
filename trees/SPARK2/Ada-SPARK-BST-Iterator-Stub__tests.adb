with Ada.Text_IO; use Ada.Text_IO;
with BST_Iterator_Stub; use BST_Iterator_Stub;
procedure Tests is
   T : Tree := Empty; It : Iterator; A, B, C : Value;
begin
   Insert (T, 5); Insert (T, 2); Insert (T, 8); It := Create (T);
   Next (It, A); Next (It, B); Next (It, C);
   if A /= 5 or else B /= 2 or else C /= 8 or else Has_Next (It) then raise Program_Error; end if;
   Put_Line ("BST iterator stub: PASS");
end Tests;
