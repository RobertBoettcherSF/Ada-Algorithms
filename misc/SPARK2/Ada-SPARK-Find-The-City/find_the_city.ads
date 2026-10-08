pragma SPARK_Mode (On);

package Find_The_City with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype City is Positive range 1 .. Capacity;
   subtype Cost is Natural range 0 .. Capacity;
   type Network is array (City, City) of Cost;

   function Find
     (Edges : Network; N : City; Threshold : Cost) return City
     with Global => null;
end Find_The_City;
