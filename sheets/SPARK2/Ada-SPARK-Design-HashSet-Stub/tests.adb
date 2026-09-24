pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Design_Hashset_Stub; use Design_Hashset_Stub;

procedure Tests is
   S : Set := Empty;
begin
   S := Insert (S, 7);
   S := Insert (S, -3);
   S := Insert (S, 7);
   if not Contains (S, 7) or else not Contains (S, -3) then raise Program_Error; end if;
   if S.Size /= 2 then raise Program_Error; end if;
   Put_Line ("Design hash-set stub: PASS");
end Tests;
