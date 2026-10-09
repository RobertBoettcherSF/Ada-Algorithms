--  PLACEHOLDER: bounded stub (the folder name ends in -Stub), not a full Swim-In-Rising-Water implementation; see PROOFS.csv stub
pragma SPARK_Mode (On);

package Swim_In_Rising_Water_Stub is
   subtype Water_Level is Natural range 0 .. 1_000;
   type Grid is array (Positive range 1 .. 2, Positive range 1 .. 2) of Water_Level;

   function Minimum_Time (Heights : Grid) return Water_Level;
end Swim_In_Rising_Water_Stub;
