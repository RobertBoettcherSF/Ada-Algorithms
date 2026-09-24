with Ada.Assertions; use Ada.Assertions;
with Longest_Mountain_In_Array; use Longest_Mountain_In_Array;

procedure Tests is
   Data : constant Values := (2, 1, 4, 7, 3, 2, 5, others => 0);
begin
   Assert (Longest (Data, 7) = 5);
end Tests;
