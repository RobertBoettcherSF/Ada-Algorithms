with Ada.Assertions; use Ada.Assertions;
with Online_Stock_Span; use Online_Stock_Span;
procedure Tests is
   P : constant Prices := [100, 80, 60, 70, 60, 75, 85, others => 0];
   S : constant Spans := All_Spans (P, 7);
begin
   Assert (S (1) = 1 and S (2) = 1 and S (3) = 1 and S (4) = 2);
   Assert (S (5) = 1 and S (6) = 4 and S (7) = 6);
end Tests;
