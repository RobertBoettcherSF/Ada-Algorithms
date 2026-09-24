pragma Ada_2022;
package body Exclusive_Time_Of_Functions_Lite with SPARK_Mode => On is
   function Inclusive_Duration (Start_Time : Timestamp; End_Time : Timestamp) return Natural is
   begin return End_Time - Start_Time + 1; end Inclusive_Duration;
end Exclusive_Time_Of_Functions_Lite;
