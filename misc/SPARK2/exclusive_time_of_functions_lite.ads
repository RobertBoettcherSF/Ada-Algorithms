pragma Ada_2022;
package Exclusive_Time_Of_Functions_Lite with SPARK_Mode => On is
   subtype Timestamp is Natural range 0 .. 1000;
   function Inclusive_Duration (Start_Time : Timestamp; End_Time : Timestamp) return Natural with Global => null, Pre => End_Time >= Start_Time;
end Exclusive_Time_Of_Functions_Lite;
