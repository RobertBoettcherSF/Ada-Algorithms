with Ada.Text_IO; use Ada.Text_IO;
with Special_Array_With_X_Elements; use Special_Array_With_X_Elements;
procedure Tests is
   A : constant Array_Of_Values := (3, 3, 3, 1, 2, 4, 5, 6);
   B : constant Array_Of_Values := (3, 3, 1, 1, 2, 4, 5, 6);
begin
   if not Is_Special (A, 3) or else Is_Special (B, 3) then raise Program_Error; end if;
   Put_Line ("special array: PASS");
end Tests;
