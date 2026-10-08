pragma SPARK_Mode (On);

package Design_Underground_System_Lite is
   subtype Station_Id is Natural range 0 .. 100;
   subtype Trip_Count is Natural range 0 .. 32;
   subtype Travel_Duration is Natural range 0 .. 100_000;
   type Trip is record
      From_Station : Station_Id;
      To_Station   : Station_Id;
      Duration     : Travel_Duration;
   end record;
   type Trip_Array is array (Positive range 1 .. 32) of Trip;

   function Average_Travel_Time
     (Trips : Trip_Array; Length : Trip_Count;
      From : Station_Id; To : Station_Id) return Travel_Duration
     with Pre => Length <= Trips'Length,
          Global => null;
end Design_Underground_System_Lite;
