with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Implement_Trie; use Implement_Trie;
procedure Tests is
   Cat : constant Word := (Len => 3, Chars => ['c','a','d','a','a','a','a','a']);
   Dog : constant Word := (Len => 3, Chars => ['d','d','d','a','a','a','a','a']);
   T : Trie := (others => <>);
begin
   Insert (T, Cat);
   Assert (Contains (T, Cat));
   Assert (not Contains (T, Dog));
   Put_Line ("PASS Implement_Trie");
end Tests;
