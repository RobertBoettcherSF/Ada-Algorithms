pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Rabin_Karp; use Rabin_Karp;
procedure Tests is
begin
   Assert (Search ("abracadabra", "cad"));
   Assert (not Search ("abracadabra", "xyz"));
   Put_Line ("PASS Rabin_Karp.Search");
   Put_Line ("All Rabin_Karp SPARK topic tests passed.");
end Tests;
