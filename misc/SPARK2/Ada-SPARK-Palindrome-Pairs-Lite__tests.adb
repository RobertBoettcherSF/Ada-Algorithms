with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Palindrome_Pairs_Lite; use Palindrome_Pairs_Lite;
procedure Tests is
   Words : constant Word_Array :=
     (1 => (Len => 2, Chars => ['a','b','a','a','a','a','a','a']),
      2 => (Len => 2, Chars => ['b','a','a','a','a','a','a','a']),
      others => (Len => 0, Chars => (others => 'a')));
begin
   Assert (Count_Reverse_Pairs (Words) = 2);
   Put_Line ("PASS Palindrome_Pairs_Lite");
end Tests;
