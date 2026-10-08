pragma SPARK_Mode (On);

package Maximum_Performance_Of_A_Team_Lite is
   Member_Count : constant := 8;
   subtype Speed is Natural range 0 .. 100;
   subtype Efficiency is Natural range 0 .. 100;
   type Speed_Array is array (Positive range 1 .. Member_Count) of Speed;
   type Efficiency_Array is array (Positive range 1 .. Member_Count) of Efficiency;

   function Best_Single_Performance
     (Speeds : Speed_Array; Efficiencies : Efficiency_Array) return Natural;
end Maximum_Performance_Of_A_Team_Lite;
