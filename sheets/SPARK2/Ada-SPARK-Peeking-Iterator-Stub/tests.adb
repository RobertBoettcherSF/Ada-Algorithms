with Ada.Text_IO; use Ada.Text_IO;
with Peeking_Iterator_Stub; use Peeking_Iterator_Stub;
procedure Tests is
   Data : constant Value_Array := (1 => 10, 2 => 20, 3 => 30, others => 0);
   It : Iterator := Create (Data, 3);
   A, B : Value;
begin
   if Peek (It) /= 10 then raise Program_Error; end if; Next (It, A); Next (It, B);
   if A /= 10 or else B /= 20 or else Peek (It) /= 30 then raise Program_Error; end if;
   Reset (It); Next (It, A); if A /= 10 then raise Program_Error; end if;
   Put_Line ("Peeking iterator stub: PASS");
end Tests;
