pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Lru_Cache_Stub; use Lru_Cache_Stub;

procedure Tests is
   C : Cache := Empty;
begin
   C := Put (C, 1, 10); C := Put (C, 2, 20); C := Put (C, 1, 11);
   if not Contains (C, 1) or else Lookup (C, 1, -1) /= 11 then raise Program_Error; end if;
   Put_Line ("LRU cache stub: PASS");
end Tests;
