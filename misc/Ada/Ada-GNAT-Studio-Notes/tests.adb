with Ada.Assertions; use Ada.Assertions;
with Studio_Probe; use Studio_Probe;

procedure Tests is
begin
   Assert (Abs_Diff (5, 2) = 3);
   Assert (Abs_Diff (2, 5) = 3);
   Assert (Abs_Diff (0, 0) = 0);
   Assert (Abs_Diff (-10, 10) = 20);
   Assert (Abs_Diff (1000, -1000) = 2000);
end Tests;
