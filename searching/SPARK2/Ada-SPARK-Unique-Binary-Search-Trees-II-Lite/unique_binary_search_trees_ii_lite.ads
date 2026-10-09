--  PLACEHOLDER: Root_Choices (N) returns N; no trees are generated; see tools/vv/hidden_stub.csv
pragma Ada_2022;
package Unique_Binary_Search_Trees_II_Lite with SPARK_Mode => On is
   subtype Node_Count is Natural range 0 .. 16;
   function Root_Choices (N : Node_Count) return Node_Count with Global => null;
end Unique_Binary_Search_Trees_II_Lite;
