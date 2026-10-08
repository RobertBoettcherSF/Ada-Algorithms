with Ada.Assertions; use Ada.Assertions;
with Sort_Colors; use Sort_Colors;
with Own_Checks;

procedure Tests is
   Data : Colors := (2, 0, 2, 1, 1, 0, others => 0);
begin
   Sort (Data, 6);
   Assert (Data (1) = 0 and Data (2) = 0 and Data (3) = 1
           and Data (4) = 1 and Data (5) = 2 and Data (6) = 2);
   Own_Checks;
end Tests;
