with Ada.Assertions; use Ada.Assertions;
with Design_HashMap_Stub; use Design_HashMap_Stub;

procedure Tests is
   Empty : constant Map_Entry := (Present => False, Key_Value => 1, Stored_Value => 0);
   Map : constant Table :=
     [1 => (True, 3, 30), 2 => Empty, 3 => (True, 7, 70), 4 => Empty];
begin
   Assert (Lookup (Map, 3) = 30);
   Assert (Lookup (Map, 7) = 70);
   Assert (Lookup (Map, 9) = 0);
end Tests;
