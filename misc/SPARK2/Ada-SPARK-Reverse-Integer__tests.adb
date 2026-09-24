with Ada.Assertions; use Ada.Assertions;
with Reverse_Integer; use Reverse_Integer;
procedure Tests is
begin
   Assert (Reversed (0) = 0);
   Assert (Reversed (12) = 21);
   Assert (Reversed (-98) = -89);
   Assert (Reversed (90) = 9);
end Tests;
