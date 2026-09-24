pragma Ada_2022;

package Unique_BSTs_Stub with SPARK_Mode => On is
   subtype Node_Count is Natural range 0 .. 8;
   subtype Count is Long_Long_Integer range 0 .. 1_000_000;
   function Number_Of_Trees (N : Node_Count) return Count with Global => null;
end Unique_BSTs_Stub;
