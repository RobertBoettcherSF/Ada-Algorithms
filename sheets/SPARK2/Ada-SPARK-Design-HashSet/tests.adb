with Ada.Text_IO; use Ada.Text_IO;
with Design_HashSet; use Design_HashSet;
procedure Tests is
   S : Set := Empty;
begin
   Add (S, 3);
   if not Contains (S, 3) or else Contains (S, 4) then raise Program_Error; end if;
   Remove (S, 3);
   if Contains (S, 3) then raise Program_Error; end if;
   Put_Line ("Design HashSet: PASS");
end Tests;
