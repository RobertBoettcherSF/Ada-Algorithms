pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Bloom_Filter; use Bloom_Filter;
with Own_Checks;
procedure Tests is
   F : Filter := Empty;
begin
   Insert (F, 42);
   Assert (Might_Contain (F, 42));
   Put_Line ("PASS Bloom_Filter Insert/Might_Contain");

   --  Hand-worked (V&V sweep, agent A3). Key 42 sets bits 42 and 42 / 7 = 6.
   Assert (not Might_Contain (Empty, 0));
   Assert (not Might_Contain (Empty, 42));
   Assert (not Might_Contain (F, 6));      -- bits 6 and 0: 0 is clear
   Assert (not Might_Contain (F, 106));    -- bits 42 and 15: 15 is clear
   Assert (Might_Contain (F, 490));        -- 490 = 42 + 7 * 64: bits 42 and 70 mod 64 = 6
   Assert (not Might_Contain (F, 43));     -- bits 43 and 6: 43 is clear
   --  Natural'Last = 2147483647 sets bits 63 and 306783378 mod 64 = 18.
   Insert (F, Natural'Last);
   Assert (Might_Contain (F, Natural'Last));
   Assert (not Might_Contain (F, 146));    -- bits 18 and 146 / 7 = 20: 20 is clear
   Insert (F, 0);                           -- bit 0
   Assert (Might_Contain (F, 6));           -- bits 6 and 0 now set
   Assert (Might_Contain (F, 0));
   Assert (not Might_Contain (F, 63));     -- bits 63 and 9: 9 is clear

   Own_Checks;
   Put_Line ("All Bloom_Filter SPARK topic tests passed.");
end Tests;
