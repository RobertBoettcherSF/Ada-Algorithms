pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Cheapest_Flights_Stub; use Cheapest_Flights_Stub;

procedure Tests is
   Flights : constant Flight_Array :=
     (1 => (Origin => 1, Destination => 2, Price => 100),
      2 => (Origin => 2, Destination => 3, Price => 100),
      3 => (Origin => 1, Destination => 3, Price => 500),
      4 => (Origin => 3, Destination => 4, Price => 100),
      5 => (Origin => 2, Destination => 4, Price => 400));
begin
   if Find_Cost (Flights, 1, 3, 1) /= 200 then raise Program_Error; end if;
   Put_Line ("Cheapest flights stub: PASS");
end Tests;
