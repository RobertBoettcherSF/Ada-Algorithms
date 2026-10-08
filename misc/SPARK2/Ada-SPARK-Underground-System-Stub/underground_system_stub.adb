pragma SPARK_Mode (On);

package body Underground_System_Stub is
   function Average_Duration
     (Trips : Trip_Array; Used : Used_Count) return Natural is
      Total : Natural range 0 .. 4000 := 0;
   begin
      for I in Trip_Index loop
         if I <= Used and then Trips (I).End_Time >= Trips (I).Start_Time then
            Total := Total + (Trips (I).End_Time - Trips (I).Start_Time);
         end if;
      end loop;
      if Used = 0 then
         return 0;
      else
         return Total / Used;
      end if;
   end Average_Duration;
end Underground_System_Stub;
