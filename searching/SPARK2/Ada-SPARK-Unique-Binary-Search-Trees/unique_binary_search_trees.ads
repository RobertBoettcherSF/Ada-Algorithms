pragma Ada_2022;
package Unique_Binary_Search_Trees with SPARK_Mode => On is
   subtype Node_Count is Natural range 0 .. 16;
   subtype Tree_Count is Natural range 0 .. 35357670;
   function Number_Of_Trees (N : Node_Count) return Tree_Count with Global => null;
end Unique_Binary_Search_Trees;
