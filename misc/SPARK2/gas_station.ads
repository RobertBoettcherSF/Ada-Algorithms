pragma Ada_2022;
pragma SPARK_Mode (On);
package Gas_Station is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Values is array (Index) of Natural;

   function Starting_Station (Fuel : Values; Cost : Values; N : Count) return Count
     with Pre => N > 0,
          Post => Starting_Station'Result = 1;
end Gas_Station;
