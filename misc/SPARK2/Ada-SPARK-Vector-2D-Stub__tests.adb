with Ada.Text_IO; use Ada.Text_IO;
with Vector_2D_Stub; use Vector_2D_Stub;
procedure Tests is
   A : constant Vector := (X => 2, Y => 3); B : constant Vector := (X => 4, Y => -1); C : Vector;
begin
   C := Add (A, B); if C /= (X => 6, Y => 2) then raise Program_Error; end if;
   if Dot (A, B) /= 5 or else Cross (A, B) /= -14 then raise Program_Error; end if;
   if not Equal (Scale (A, 2), (X => 4, Y => 6)) then raise Program_Error; end if;
   Put_Line ("Vector 2D stub: PASS");
end Tests;
