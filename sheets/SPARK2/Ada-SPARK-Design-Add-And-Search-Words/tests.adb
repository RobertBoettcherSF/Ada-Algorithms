with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Design_Add_And_Search_Words; use Design_Add_And_Search_Words;
procedure Tests is
   Bad : constant Word := (Len => 3, Chars => ['d','a','d','a','a','a','a','a']);
   Pattern : constant Word := (Len => 3, Chars => ['.','a','d','a','a','a','a','a']);
   D : Dictionary := (others => <>);
begin
   Add_Word (D, Bad);
   Assert (Search (D, Pattern));
   Assert (not Search (D, (Len => 2, Chars => ['a','d','a','a','a','a','a','a'])));
   Put_Line ("PASS Design_Add_And_Search_Words");
end Tests;
