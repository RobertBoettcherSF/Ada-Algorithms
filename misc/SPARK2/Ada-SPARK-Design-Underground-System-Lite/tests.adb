with Ada.Assertions; use Ada.Assertions;
with Design_Underground_System_Lite; use Design_Underground_System_Lite;
procedure Tests is
   Trips : constant Trip_Array :=
     ((From_Station => 1, To_Station => 2, Duration => 10),
      (From_Station => 1, To_Station => 2, Duration => 20),
      (From_Station => 1, To_Station => 3, Duration => 99),
      others => (From_Station => 0, To_Station => 0, Duration => 0));
begin
   Assert (Average_Travel_Time (Trips, 3, 1, 2) = 15);
   Assert (Average_Travel_Time (Trips, 3, 1, 3) = 99);
   Assert (Average_Travel_Time (Trips, 3, 2, 3) = 0);
end Tests;
