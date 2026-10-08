pragma SPARK_Mode (On);

package Cheapest_Flights_Stub is
   City_Count : constant := 4;
   subtype City is Positive range 1 .. City_Count;
   subtype Fare is Integer range 1 .. 500;
   Flight_Count : constant := 5;
   type Flight is record
      Origin      : City;
      Destination : City;
      Price       : Fare;
   end record;
   type Flight_Array is array (Positive range 1 .. Flight_Count) of Flight;
   subtype Cost_Result is Integer range 0 .. 1500;

   function Find_Cost (Flights : Flight_Array; Source, Target : City; Stops : Natural) return Cost_Result;
end Cheapest_Flights_Stub;
