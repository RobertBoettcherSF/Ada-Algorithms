with Ada.Text_IO; use Ada.Text_IO;
with BST_Iterator_Stub; use BST_Iterator_Stub;
procedure Tests is
   T : Tree := Empty; It : Iterator; A, B, C : Value;
begin
   Insert (T, 5); Insert (T, 2); Insert (T, 8); It := Create (T);
   Next (It, A); Next (It, B); Next (It, C);
   --  In-order (ascending) walk of the BST built from 5, 2, 8. The old line
   --  asserted the insertion order 5, 2, 8, which is not what a BST
   --  iterator returns (H117).
   if A /= 2 or else B /= 5 or else C /= 8 or else Has_Next (It) then raise Program_Error; end if;
   Put_Line ("BST iterator stub: PASS");
end Tests;
