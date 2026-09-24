with Ada.Assertions; use Ada.Assertions;
with Word_Search; use Word_Search;
procedure Tests is
   B : Board := [others => [others => 'A']];
   W : Word := [others => 'A'];
begin
   W (1) := 'W';
   B (3, 4) := 'W';
   Assert (Exists (B, W, 1));
   Assert (not Exists (B, W, 0));
   W (1) := 'Z';
   Assert (not Exists (B, W, 1));
end Tests;
