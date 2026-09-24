pragma SPARK_Mode (On);

package Underground_System_Stub is
   Trip_Count : constant := 4;
   subtype Trip_Index is Positive range 1 .. Trip_Count;
   subtype Used_Count is Natural range 0 .. Trip_Count;
   subtype Station_Time is Natural range 0 .. 1000;
   type Trip is record
      Start_Time : Station_Time;
      End_Time : Station_Time;
   end record;
   type Trip_Array is array (Trip_Index) of Trip;

   function Average_Duration
     (Trips : Trip_Array; Used : Used_Count) return Natural;
end Underground_System_Stub;
