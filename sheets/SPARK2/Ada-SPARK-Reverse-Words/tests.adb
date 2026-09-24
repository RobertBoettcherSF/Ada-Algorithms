with Ada.Assertions; use Ada.Assertions;
with Reverse_Words; use Reverse_Words;
procedure Tests is
   Input : constant Word_List := ["one     ", "two     ", "three   ", "four    "];
   Expected : constant Word_List := ["four    ", "three   ", "two     ", "one     "];
begin
   Assert (Reversed (Input) = Expected);
end Tests;
