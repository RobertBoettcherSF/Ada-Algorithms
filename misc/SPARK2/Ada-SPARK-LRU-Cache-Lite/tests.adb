with Ada.Text_IO;
with LRU_Cache_Lite;
procedure Tests is
   use LRU_Cache_Lite;
   C : Cache := Empty;
   V : Value;
begin
   Put (C, 4, 40); Put (C, 4, 41);
   V := Lookup (C, 4);
   pragma Assert (Contains (C, 4) and then V = 41 and then Length (C) = 1);
   Ada.Text_IO.Put_Line ("LRU cache lite: OK");
end Tests;
