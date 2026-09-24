with Ada.Text_IO; use Ada.Text_IO;
with Nested_Iterator_Stub; use Nested_Iterator_Stub;
procedure Tests is
   N : Nested_Data := Empty; It : Iterator; A, B : Value;
begin
   Add (N, 7); Add (N, 8); It := Create (N); Next (It, A); Next (It, B);
   if A /= 7 or else B /= 8 or else Has_Next (It) then raise Program_Error; end if;
   Put_Line ("Nested iterator stub: PASS");
end Tests;
