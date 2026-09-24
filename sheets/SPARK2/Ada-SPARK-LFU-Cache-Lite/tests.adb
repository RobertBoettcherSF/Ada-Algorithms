with Ada.Text_IO;
with LFU_Cache_Lite;
procedure Tests is
   use LFU_Cache_Lite;
   C : Cache := Empty;
begin
   Put (C, 4, 40); Put (C, 7, 70);
   Touch (C, 7); Touch (C, 7);
   pragma Assert (Most_Frequent_Key (C) = 7);
   Ada.Text_IO.Put_Line ("LFU cache lite: OK");
end Tests;
