pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Bloom_Filter; use Bloom_Filter;
procedure Tests is
   F : Filter := Empty;
begin
   Insert (F, 42);
   Assert (Might_Contain (F, 42));
   Put_Line ("PASS Bloom_Filter Insert/Might_Contain");
   Put_Line ("All Bloom_Filter SPARK topic tests passed.");
end Tests;
