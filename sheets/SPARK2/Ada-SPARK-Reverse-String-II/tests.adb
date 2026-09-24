with Ada.Assertions; use Ada.Assertions;
with Reverse_String_II; use Reverse_String_II;

procedure Tests is
   Data : Items := ('a', 'b', 'c', 'd', 'e', others => 'x');
begin
   Reverse_First (Data, 5);
   Assert (Data (1) = 'e' and Data (2) = 'd' and Data (3) = 'c'
           and Data (4) = 'b' and Data (5) = 'a');
end Tests;
