with Ada.Assertions; use Ada.Assertions;
with Car_Pooling; use Car_Pooling;

procedure Tests is
   Empty : constant Trip := (People => 0, Pickup => 1, Dropoff => 2);
   T : Trips := [others => Empty];
begin
   T (1) := (People => 2, Pickup => 1, Dropoff => 3);
   T (2) := (People => 1, Pickup => 2, Dropoff => 4);
   Assert (Feasible (T, 3));
   Assert (not Feasible (T, 2));
end Tests;
