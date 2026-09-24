with Ada.Text_IO; use Ada.Text_IO;
with Combination_Iterator_Stub; use Combination_Iterator_Stub;
procedure Tests is
   Items : constant Value_Array := (1 => 1, 2 => 2, 3 => 3, others => 0); It : Iterator := Create (Items, 3, 2);
   C : Combination; N : Natural := 0;
begin
   while Has_Next (It) loop Next (It, C); N := N + 1; end loop;
   if N /= 3 then raise Program_Error; end if;
   Put_Line ("Combination iterator stub: PASS");
end Tests;
