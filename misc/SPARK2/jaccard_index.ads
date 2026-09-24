pragma Ada_2022;
package Jaccard_Index with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 3;
   subtype Component is Integer range 0 .. 1;
   type Vector is array (Index) of Component;
   function Similarity (A, B : Vector) return Integer with Global => null;
end Jaccard_Index;
