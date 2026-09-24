with Ada.Assertions; use Ada.Assertions;
with Formed_Words; use Formed_Words;
procedure Tests is
   Available : Text := [others => ' '];
   Word      : Text := [others => ' '];
begin
   Available (1 .. 5) := "catts";
   Word (1 .. 3) := "cat";
   Assert (Can_Be_Formed (Available, 5, Word, 3));
   Word (1 .. 4) := "cats";
   Assert (Can_Be_Formed (Available, 5, Word, 4));
   Word (1 .. 4) := "taco";
   Assert (not Can_Be_Formed (Available, 5, Word, 4));
end Tests;
