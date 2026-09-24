with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Longest_Word_In_Dictionary; use Longest_Word_In_Dictionary;
procedure Tests is
   Words : constant Word_Array :=
     (1 => (Len => 1, Chars => ['a','a','a','a','a','a','a','a']),
      2 => (Len => 2, Chars => ['a','b','a','a','a','a','a','a']),
      3 => (Len => 3, Chars => ['a','b','c','a','a','a','a','a']),
      4 => (Len => 4, Chars => ['a','b','c','d','a','a','a','a']),
      others => (Len => 0, Chars => (others => 'a')));
begin
   Assert (Longest_Length (Words) = 4);
   Put_Line ("PASS Longest_Word_In_Dictionary");
end Tests;
