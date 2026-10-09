with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO;
with Degree_Of_An_Array; use Degree_Of_An_Array;
with Own_Checks;
procedure Tests is
   A : Int_Array := [others => 0];
begin
   A (1 .. 7) := [1, 2, 2, 3, 1, 4, 2];
   Assert (Degree (A) = 25);
   A := [others => 7];
   Assert (Degree (A) = 32);
   --  Hand-worked (V&V sweep, agent A3; tests/SOURCES.txt).
   for I in Index loop
      A (I) := I - 16;  --  -15 .. 16, all different
   end loop;
   Assert (Degree (A) = 1);
   A (32) := -15;
   Assert (Degree (A) = 2);
   for I in Index loop
      A (I) := (if I mod 2 = 0 then -32 else 32);
   end loop;
   Assert (Degree (A) = 16);
   A (1) := 0;
   Assert (Degree (A) = 16);
   A (2) := 0;
   Assert (Degree (A) = 15);
   for I in Index loop
      A (I) := I mod 3;  --  0 occurs 10 times, 1 and 2 occur 11 times
   end loop;
   Assert (Degree (A) = 11);
   Own_Checks;
   Ada.Text_IO.Put_Line ("PASS Degree_Of_An_Array");
end Tests;
