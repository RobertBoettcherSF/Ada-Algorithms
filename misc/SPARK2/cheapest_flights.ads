pragma SPARK_Mode (On);

package Cheapest_Flights with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Airport is Positive range 1 .. Capacity;
   subtype Fare is Natural range 0 .. Capacity * Capacity;
   type Network is array (Airport, Airport) of Fare;

   function Cheapest_Direct
     (Flights : Network; From, To : Airport) return Fare
     with Global => null;
end Cheapest_Flights;
