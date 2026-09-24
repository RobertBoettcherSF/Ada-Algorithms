with Ada.Text_IO; use Ada.Text_IO;
with Flatten_Nested_List_Stub; use Flatten_Nested_List_Stub;
procedure Tests is
   N : Values := Empty; F : Values;
begin
   Add (N, 1); Add (N, 2); Add (N, 3); F := Flatten (N);
   if Length (F) /= 3 or else Element_At (F, 2) /= 2 then raise Program_Error; end if;
   Put_Line ("Flatten nested list stub: PASS");
end Tests;
