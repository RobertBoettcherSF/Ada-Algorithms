with Ada.Text_IO; use Ada.Text_IO;
with Zigzag_Iterator_Stub; use Zigzag_Iterator_Stub;
procedure Tests is
   A : constant Value_Array := (1 => 1, 2 => 3, 3 => 5, others => 0); B : constant Value_Array := (1 => 2, 2 => 4, others => 0);
   It : Iterator := Create (A, 3, B, 2);
   V1, V2, V3, V4, V5 : Value;
begin
   Next (It, V1); Next (It, V2); Next (It, V3); Next (It, V4); Next (It, V5);
   if V1 /= 1 or else V2 /= 2 or else V3 /= 3 or else V4 /= 4 or else V5 /= 5 then raise Program_Error; end if;
   Put_Line ("Zigzag iterator stub: PASS");
end Tests;
