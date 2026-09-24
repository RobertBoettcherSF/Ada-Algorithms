with Ada.Assertions; use Ada.Assertions;
with Longest_Substring_Without_Repeat; use Longest_Substring_Without_Repeat;
procedure Tests is
begin
   Assert (Longest ((1 => 'a', 2 => 'b', 3 => 'c', 4 => 'a', 5 => 'b', 6 => 'b')) = 3);
   Assert (Longest ((1 => 'a', 2 => 'b', 3 => 'c', 4 => 'd', 5 => 'e', 6 => 'f')) = 6);
   Assert (Longest ((1 => 'a', 2 => 'a', 3 => 'a', 4 => 'a', 5 => 'a', 6 => 'a')) = 1);
end Tests;
