pragma SPARK_Mode (On);

package body Design_Underground_System_Lite is
   function Average_Travel_Time
     (Trips : Trip_Array; Length : Trip_Count;
      From : Station_Id; To : Station_Id) return Travel_Duration is
      Total   : Integer := 0;
      Matches : Integer := 0;
   begin
      for I in Trips'Range loop
         pragma Loop_Invariant (Total >= 0);
         pragma Loop_Invariant
           (Total <= (I - Trips'First) * Travel_Duration'Last);
         pragma Loop_Invariant (Matches >= 0);
         pragma Loop_Invariant (Matches <= I - Trips'First);
         pragma Loop_Invariant (Total <= Matches * Travel_Duration'Last);
         if I <= Length
           and then Trips (I).From_Station = From
           and then Trips (I).To_Station = To
         then
            Total := Total + Trips (I).Duration;
            Matches := Matches + 1;
         end if;
      end loop;
      if Matches = 0 then
         return 0;
      else
         return Travel_Duration (Total / Matches);
      end if;
   end Average_Travel_Time;
end Design_Underground_System_Lite;
